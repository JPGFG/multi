
extends Node

# ===================
# =====NETCONFIG=====
# ===================
const DEFAULT_PORT : int = 42069
const DEFAULT_HOST : String = "127.0.0.1"
const DEFAULT_MAX_CLIENTS : int = 4
const SNAPSHOT_VERSION : int = 1

# STATE CONTROL
var is_server: bool = false
var client_connected: bool = false

# CLIENT-side peer_id -> Node / data is handled by whoever listens to the signals
# NO dictionary is stored here, just on the clients
# We set up the following signals in order to handle this logic.


# ===================
# ===== SIGNALS =====
# ===================
signal connected_to_server
signal connection_failed
signal server_disconnected


signal peer_joined(peer_id: int, data: Dictionary)
signal peer_left(peer_id: int)

signal world_received(map_data: Dictionary)

# Signal fires on every server snapshot.
signal snapshot_received(state: Dictionary)

func _ready() -> void:
	# allow boot from CLI
	var args = OS.get_cmdline_args()
	if "--server" in args:
		is_server = true
		call_deferred("start_server")
	else:
		# default to load a client (non-headless)
		call_deferred("start_client", DEFAULT_HOST, DEFAULT_PORT)

# ========================
# ===== START / STOP =====
# ========================

# physics implementation data
var world : WorldData
var server_world: ServerWorld

func start_server(port: int = DEFAULT_PORT, max_clients: int = DEFAULT_MAX_CLIENTS):
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var err := peer.create_server(port, max_clients)
	
	if err != OK:
		push_error("Net: failed to create server: %s" % err)
		return
	
	multiplayer.multiplayer_peer = peer
	client_connected = true
	
	print("Net: SERVER listening on %d" % port)
	
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	# new server side physics rendering
	world = WorldData.new()
	server_world = ServerWorld.new()
	get_tree().root.call_deferred("add_child", server_world)
	
	# build the server tilemap
	server_world.call_deferred("build_server_map", world)
	

func start_client(host: String, port: int):
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(host, port)
	if err != OK:
		push_error("Net: failed to connect to %s:%d - %s" % [host, port, err])
		return
	
	multiplayer.multiplayer_peer = peer
	is_server = false
	
	print("Net: CLIENT connecting to %s%d..." % [host, port])
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	# is_connected becomes true in _on_connected_to_server.

# ============================
# ===== CLIENT LIFECYCLE =====
# ============================

func _on_connected_to_server() -> void:
	client_connected = true
	print("Net: connected to server")
	emit_signal("connected_to_server")

func _on_connection_failed() -> void:
	client_connected = false
	print("Net: connection failed")
	emit_signal("connection_failed")

func _on_server_disconnected() -> void:
	client_connected = false
	print("Net: server disconnected.")
	emit_signal("server_disconnected")

# ===========================
# =====SERVER LIFECYCLE======
# ===========================

func _on_peer_connected(id: int) -> void:
	if not is_server:
		return
	
	# send world data to this client
	if world != null:
		rpc_id(id, "s2c_world", world.world_data)
	
	# choose a spawn position (stub)
	var spawn_pos := Vector2(200, 200)
	# register physics body on server
	server_world.register_player(id, spawn_pos)
	
	
	print("Net: peer joined ", id)
	
	# tell the new client about all existing players
	for existing_id in server_world.server_players.keys():
		var body = server_world.server_players[existing_id]
		var data := {"pos": body.global_position}
		rpc_id(id, "s2c_player_join", existing_id, data)
	
	# tell every client that this new player joined
	rpc("s2c_player_join", id, {"pos": spawn_pos})
	emit_signal("peer_joined", id, {"pos": spawn_pos})
	

func _on_peer_disconnected(id: int) -> void:
	if not is_server:
		return
	
	print("Net: peer left: ", id)
	server_world.unregister_player(id)
	
	rpc("s2c_player_leave", id)
	emit_signal("peer_left", id)

# =========================
# =====PUBLIC HELPERS =====
# =========================

func can_send() -> bool:
	var mp := multiplayer.get_multiplayer_peer()
	return mp != null and mp.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED

func send_input(dir: Vector2) -> void:
	# client convenience wrapper
	if is_server:
		return
	if not can_send():
		return
	# we always send to server (id 1)
	rpc_id(1, "c2s_input", dir)

# =========================
# SERVER TICK (authoratative sim)
# call this from a server only process/physics, or it can live here.
# =========================

var _accum := 0.0
const SNAPSHOT_DT := 0.05 # 20 HZ

func _physics_process(delta: float) -> void:
	if not is_server:
		return
	if not server_world:
		return
	
	# run physics sim for server players
	server_world.tick(delta)
	
	_accum += delta
	if _accum >= SNAPSHOT_DT:
		var snapshot: Dictionary = {
			"v": SNAPSHOT_VERSION,
			"players": server_world.build_snapshot()
		}
		rpc("s2c_state", snapshot)
		_accum = 0.0

# ==============
# ==== RPCs ====
# ==============

# CLIENT -> SERVER
@rpc("any_peer", "unreliable")
func c2s_input(dir: Vector2) -> void:
	if not is_server:
		return
	var from_id := multiplayer.get_remote_sender_id()
	if not server_world or not server_world.server_players.has(from_id):
		push_warning("Net: got input from unknown peer %s" % from_id)
		return
	server_world.process_input(from_id, dir)


# SERVER -> CLIENTS (state snapshot)
@rpc("unreliable")
func s2c_state(state: Dictionary) -> void:
	if is_server:
		return
	# basic version check
	var v = state.get("v", 0)
	if v!= SNAPSHOT_VERSION:
		print("Net: snapshot version mismatch, got %s, expected %s" % [v, SNAPSHOT_VERSION])
		return
	
	emit_signal("snapshot_received", state)

# SERVER -> CLIENTS (JOIN)
@rpc("reliable")
func s2c_player_join(peer_id: int, data: Dictionary) -> void:
	if is_server:
		return
	emit_signal("peer_joined", peer_id, data)

@rpc("reliable")
func s2c_world(world_data: Dictionary) -> void:
	emit_signal("world_received", world_data)

# SERVER -> CLIENTS (LEAVE)
@rpc("reliable")
func s2c_player_leave(peer_id: int) -> void:
	if is_server:
		return
	
	emit_signal("peer_left", peer_id)
