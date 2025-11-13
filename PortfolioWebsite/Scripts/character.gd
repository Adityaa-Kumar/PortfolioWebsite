extends CharacterBody2D

@export var speed: float = 200.0
@export var acceleration: float = 10.0
@export var friction: float = 10.0

@onready var interactible: Sprite2D = $Interactible

var input_vector: Vector2
var last_facing_dir: Vector2 = Vector2.DOWN
var active_interaction_area: Area2D = null

func _ready():
	interactible.visible = false

func _physics_process(delta):
	handle_input()

	if input_vector.length() > 0:
		handle_keyboard_movement(delta)
	else:
		apply_friction(delta)

	move_and_slide()
	update_animation()

func _unhandled_input(event):
	if event.is_action_pressed("ui_accept"):
		attempt_interaction()

func handle_input():
	input_vector = Vector2.ZERO

	if Input.is_action_pressed("ui_up"):
		input_vector.y -= 1
	if Input.is_action_pressed("ui_down"):
		input_vector.y += 1
	if Input.is_action_pressed("ui_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("ui_right"):
		input_vector.x += 1

	input_vector = input_vector.normalized()

func handle_keyboard_movement(delta):
	var target_velocity = input_vector * speed
	velocity = velocity.move_toward(target_velocity, acceleration * speed * delta)
	
	if input_vector.length() > 0.1:
		last_facing_dir = input_vector

func apply_friction(delta):
	velocity = velocity.move_toward(Vector2.ZERO, friction * speed * delta)

func update_animation():
	var anim = "idle"
	if velocity.length() > 10:
		anim = "walk"

	if abs(last_facing_dir.x) > abs(last_facing_dir.y):
		if last_facing_dir.x > 0:
			$AnimatedSprite2D.play(anim + "_right")
		else:
			$AnimatedSprite2D.play(anim + "_left")
	else:
		if last_facing_dir.y > 0:
			$AnimatedSprite2D.play(anim + "_down")
		else:
			$AnimatedSprite2D.play(anim + "_up")

func attempt_interaction():
	if active_interaction_area != null:
		if active_interaction_area.has_method("interact"):
			active_interaction_area.interact()
		elif active_interaction_area.get_parent().has_method("interact"):
			active_interaction_area.get_parent().interact()

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("Interaction"):
		interactible.visible = true
		active_interaction_area = area

func _on_area_2d_area_exited(area: Area2D) -> void:
	if area == active_interaction_area:
		interactible.visible = false
		active_interaction_area = null

func _on_rich_text_label_meta_clicked(meta: Variant) -> void:
	OS.shell_open(meta)
