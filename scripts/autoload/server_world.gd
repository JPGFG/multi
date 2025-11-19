class_name ServerWorld
extends Node2D

const MOVESPEED : float = 400.0

# prefab empty tilemap with proper tilesets added to atlas
var _tile_map_scene : PackedScene = preload("res://scenes/debug_tilemap.tscn") 


var server_players : Dictionary = {} # id (int) -> CharacterBody2D
var server_player_scene: PackedScene = preload("res://scenes/server_player.tscn") # same collision, no sprites prefab

func tick(delta: float) -> void:
	for body in server_players.values():
		body.move_and_slide()


func process_input(sending_id: int, input: Vector2) -> void:
	if not server_players.has(sending_id):
		return
	var dir := input
	if dir.length() > 1.0:
		dir = dir.normalized()
	var body = server_players[sending_id]
	body.velocity = dir * MOVESPEED


func register_player(id, spawn_position) -> void:
	var p = server_player_scene.instantiate()
	p.global_position = spawn_position
	server_players[id] = p
	add_child(p)

func unregister_player(sending_id) -> void:
	if not server_players.has(sending_id):
		return
	var body = server_players[sending_id]
	body.call_deferred("queue_free")
	server_players.erase(sending_id)

func build_snapshot() -> Dictionary:
	var snapshot = {}
	for id in server_players.keys():
		var body = server_players[id]
		snapshot[id] = {
			"pos": body.global_position,
			"vel": body.velocity,
		}
	return snapshot

func build_server_map(map_data: WorldData):
	var tile_map = _tile_map_scene.instantiate()
	add_child(tile_map)
	
	var w = map_data.world_data["w"]
	var h = map_data.world_data["h"]
	var map = map_data.world_data["map"]
	
	for x in range(w):
		for y in range(h):
			var v = map[x][y]
			if v == 1:
				tile_map.set_cell(Vector2i(x, y), 0, Vector2i(1, 0)) # wall
			if v == 0:
				tile_map.set_cell(Vector2i(x, y), 0, Vector2i(0, 0)) # floor
