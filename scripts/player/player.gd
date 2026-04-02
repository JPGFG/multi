# player.gd
class_name Player
extends CharacterBody2D

@onready var playercam : Camera2D = $Camera2D

func _ready():
	pass

func _physics_process(delta):
	var input_dir: Vector2 = Vector2.ZERO
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_down"):
		input_dir.y += 1
	if Input.is_action_pressed("move_up"):
		input_dir.y -= 1
	
	if not multiplayer.is_server() and JPNet.can_send():
		JPNet.send_input(input_dir)
		
func set_player_name(name: String):
	$PlayerNameLabel.text = name
