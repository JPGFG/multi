extends Node2D

var player_scene = preload("res://scenes/player.tscn")

func _ready() -> void:
	var args = OS.get_cmdline_user_args()
	if "--server" in args:
		print("Starting in SERVER mode")
		var net_server_scene = load("res://scenes/server.tscn")
		var net_server = net_server_scene.instantiate()
		add_child(net_server)
	else:
		print("Staring in CLIENT mode")
		var net_client = Client.new() as Node
		add_child(net_client)
		
		var player = player_scene.instantiate()
		player.position = Vector2.ZERO
		add_child(player)
