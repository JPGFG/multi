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
	
	if not multiplayer.is_server() and JPNet.can_send():
		JPNet.send_input(input_dir)
