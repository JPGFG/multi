# client.gd
class_name Client
extends Node

const PORT: int = 42069
const HOST: String = "127.0.0.1"

var player_nodes: Dictionary = {} # peer_id -> Node2D (player instances)
var local_player: Node2D


func _ready() -> void:
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(HOST, PORT)
	if err != OK:
		push_error("Failed to connect to server: %s" %err)
		return
		
	
	multiplayer.multiplayer_peer = peer
	print("Connecting to %s:%d..." % [HOST, PORT])
	
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func register_local_player(p: Node2D) -> void:
	#called from main.gd right after spawning in a player.
	local_player = p
	# also register it in the dictionary under OUR peer id.
	var my_id = multiplayer.get_unique_id()
	player_nodes[my_id] = p

func _on_connected() -> void:
	print("Connected to server")

func _on_connection_failed() -> void:
	print("Connection to Server failed")

func _on_server_disconnected() -> void:
	print("Server disconnected.")

# called from Main.s2c_state(...)
func apply_state(state: Dictionary) -> void:
	for id in state.keys():
		var pos: Vector2 = state[id]
		if not player_nodes.has(id):
			var p = preload("res://scenes/player.tscn").instantiate()
			p.name = "Player_%s" % id
			add_child(p)
			player_nodes[id] = p
		var node = player_nodes[id]
		if id == multiplayer.get_unique_id():
			node.global_position = node.global_position.lerp(pos, 0.4)
		else:
			node.global_position = pos
