class_name Client
extends Node

var demo: bool = true

const PORT: int = 42069
const HOST: String = "127.0.0.1"

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

func _on_connected() -> void:
	print("Connected to server")

func _on_connection_failed() -> void:
	print("Connection to Server failed")

func _on_server_disconnected() -> void:
	print("Server disconnected.")
