class_name Player
extends CharacterBody2D

const SPEED = 450

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
	
	if multiplayer.get_unique_id() != 1:
		rpc_id(1, "c2s_input", input_dir)
