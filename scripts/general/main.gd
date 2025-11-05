# main.gd
extends Node2D

var player_scene = preload("res://scenes/player.tscn")
var player_nodes: Dictionary = {} # peer_id -> Node2D

var map_created: bool = false

@onready var tilemap = $TileMapLayer

func _ready() -> void:
	# listen to network events
	JPNet.snapshot_received.connect(_on_snapshot)
	JPNet.peer_joined.connect(_on_peer_joined)
	JPNet.peer_left.connect(_on_peer_left)
	JPNet.world_received.connect(_on_world_received)

func _spawn_local_player() -> void:
	var p = player_scene.instantiate()
	add_child(p)
	# local player's node is managed by the player script itself
	# remote players will be spawned in _on_peer_joined

func _on_peer_joined(peer_id: int, data: Dictionary) -> void:
	if player_nodes.has(peer_id):
		return
	
	var p := player_scene.instantiate()
	p.name = "Player_%s" % peer_id
	if data.has("pos"):
		p.global_position = data["pos"]
	add_child(p)
	player_nodes[peer_id] = p
	
	if peer_id == multiplayer.get_unique_id():
		# eg add child camera etc TODO
		pass

func _on_peer_left(peer_id: int) -> void:
	if player_nodes.has(peer_id):
		player_nodes[peer_id].queue_free()
		player_nodes.erase(peer_id)


func _on_snapshot(state: Dictionary) -> void:
	var players: Dictionary = state.get("players", {})
	for peer_id in players.keys():
		var pos: Vector2 = players[peer_id]
		
		if not player_nodes.has(peer_id):
			# late join case: spawn
			var p:= player_scene.instantiate()
			p.name = "Player_%s" % peer_id
			add_child(p)
			player_nodes[peer_id] = p
		
		var node: Node2D = player_nodes[peer_id]
		# simple smoothing
		if peer_id == multiplayer.get_unique_id():
			node.global_position = node.global_position.lerp(pos, 0.8)
		else:
			node.global_position = node.global_position.lerp(pos, 0.8)

func _on_world_received(map_data: Dictionary) -> void:
	# check for serverside, if I already have a map, don't make a new one!
	if map_created:
		return

	var w = map_data["w"]
	var h = map_data["h"]
	var map = map_data["map"]
	
	for x in range(w):
		for y in range(h):
			var v = map[x][y]
			if v == 1:
				tilemap.set_cell(Vector2i(x, y), 0, Vector2i(1, 0)) # wall
			if v == 0:
				tilemap.set_cell(Vector2i(x, y), 0, Vector2i(0, 0)) # floor
	
	map_created = true
