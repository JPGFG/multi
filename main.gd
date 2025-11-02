# main.gd
extends Node2D

var player_scene = preload("res://scenes/player.tscn")

var is_server: bool = false
var server: Server
var client: Client

func _ready() -> void:
	var args = OS.get_cmdline_user_args()
	if "--server" in args:
		print("Starting in SERVER mode")
		is_server = true
		var net_server_scene = load("res://scenes/server.tscn")
		server = net_server_scene.instantiate()
		add_child(server)
	else:
		print("Staring in CLIENT mode")
		is_server = false
		client = Client.new() as Node
		add_child(client)
		
		var player = player_scene.instantiate()
		player.position = Vector2.ZERO
		add_child(player)
		
		client.register_local_player(player)


# Shared RPCs

# CLIENT -> SERVER
@rpc("any_peer", "unreliable")
func c2s_input(dir: Vector2) -> void:
	if not is_server:
		return
	# we are on the server here
	var from_id = multiplayer.get_remote_sender_id()
	server.handle_client_input(from_id, dir)

#SERVER -> CLIENTS
@rpc("unreliable")
func s2c_state(state: Dictionary) -> void:
	if is_server:
		return
	# client only code
	client.apply_state(state)
