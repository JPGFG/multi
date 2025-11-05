class_name WorldData
extends RefCounted

var world_data = {}

func _init(map_w : int = 32, map_h : int = 32):
	var w = map_w
	var h = map_h
	var map = []
	
	for x in range(w):
		# placeholder values, 0 = floor, 1 = walls
		map.append([])
		for y in range(h):
			if y == 0 or y == h - 1 or x == 0 or x == w - 1:
				map[x].append(1)
			else:
				map[x].append(0)
	
	world_data["w"] = w
	world_data["h"] = h
	world_data["map"] = map

func debug_render(data: Dictionary = world_data) -> void:
	var w: int = data["w"]
	var h: int = data["h"]
	var map: Array = data["map"]

	for y in range(h):
		var line := ""
		for x in range(w):
			line += str(map[y][x]) + " "
		print(line)
