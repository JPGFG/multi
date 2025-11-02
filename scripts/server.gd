# server.gd
class_name Server
extends Node

const PORT: int = 42069
const MAXCLIENTS : int = 8
const PLAYER_SPEED: float = 400.0

var player_list : Dictionary = {} # peer_id -> {pos = Vector2.ZERO, vel = Vector2.ZERO}

func _ready():
	create_server()

func _physics_process(delta):
	# Simulate everyone
	for id in player_list.keys():
		var p = player_list[id]
		var dir = p["input"]
		if dir.length() > 1.0:
			dir = dir.normalized()
		p["pos"] += dir * PLAYER_SPEED * delta
		player_list[id] = p
	
	#broadcast snapshots to all peers on server
	var snapshot: Dictionary = {}
	for id in player_list.keys():
		snapshot[id] = player_list[id]["pos"]
	get_tree().root.get_node("Main").rpc("s2c_state", snapshot)

func create_server():
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(PORT, MAXCLIENTS)
	if err != OK:
		push_error("Failed on create server: %s" % err)
		return
	
	multiplayer.multiplayer_peer = peer
	print("Server listening on port %d" % PORT)
	
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func handle_client_input(peer_id: int, dir: Vector2) -> void:
	if not player_list.has(peer_id):
		return
	player_list[peer_id]["input"] = dir


func _on_peer_connected(id: int) -> void:
	player_list[id] = {
		"pos": Vector2(200, 200),
		"input": Vector2.ZERO,
	}
	
	print("Client connected: ", id)

func _on_peer_disconnected(id: int) -> void:
	print("Client disconnected: ", id)
	player_list.erase(id)
