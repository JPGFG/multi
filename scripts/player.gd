# player.gd
class_name Player
extends CharacterBody2D


func _physics_process(delta):
	var input_dir: Vector2 = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		input_dir.x += 1
	if Input.is_action_pressed("ui_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("ui_down"):
		input_dir.y += 1
	if Input.is_action_pressed("ui_up"):
		input_dir.y -= 1
	
	if multiplayer.is_server():
		return
	
	var mp = multiplayer.get_multiplayer_peer()
	if mp == null:
		return
	if mp.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	
	var main = get_tree().root.get_node("Main")
	main.rpc_id(1, "c2s_input", input_dir)
