class_name Server
extends Node

const PORT: int = 42069
const MAXCLIENTS : int = 8

var player_list : Dictionary = {} # peer_id -> {pos = Vector2.ZERO, vel = Vector2.ZERO}

func _ready():
	create_server()


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

func _on_peer_connected(id: int) -> void:
	player_list[id] = {
		"pos": Vector2(100, 100),
		"vel": Vector2.ZERO,
	}
	
	print("Client connected: ", id)

func _on_peer_disconnected(id: int) -> void:
	print("Client disconnected: ", id)
