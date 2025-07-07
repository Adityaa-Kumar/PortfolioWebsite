extends CharacterBody2D

@export var speed: float = 200.0
@export var acceleration: float = 10.0
@export var friction: float = 10.0
@onready var tile_map_layer_1: TileMapLayer = $"../TileMapLayer1"
@onready var tile_map_layer_2: TileMapLayer = $"../TileMapLayer2"

var input_vector: Vector2
var astar_grid: AStarGrid2D
var current_id_path: Array[Vector2i]
var target_position: Vector2
var is_moving: bool
var last_facing_dir: Vector2 = Vector2.DOWN
var obstacle_facing_pos: Variant = null  # allows null assignment

func _ready():
	astar_grid = AStarGrid2D.new()

	var combined_rect = tile_map_layer_1.get_used_rect()
	var layer2_rect = tile_map_layer_2.get_used_rect()

	if layer2_rect.has_area():
		combined_rect = combined_rect.merge(layer2_rect)

	astar_grid.region = combined_rect
	astar_grid.cell_size = Vector2(16, 16)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()

	for x in combined_rect.size.x:
		for y in combined_rect.size.y:
			var tile_position = Vector2i(x + combined_rect.position.x, y + combined_rect.position.y)
			var is_solid = false

			var tile_data_1 = tile_map_layer_1.get_cell_tile_data(tile_position)
			if tile_data_1 != null:
				if tile_data_1.get_custom_data("Ignore") == true:
					is_solid = false
				elif tile_data_1.get_custom_data("Walkable") == false:
					is_solid = true

			if not is_solid:
				var tile_data_2 = tile_map_layer_2.get_cell_tile_data(tile_position)
				if tile_data_2 != null:
					if tile_data_2.get_custom_data("Ignore") == true:
						is_solid = false
					elif tile_data_2.get_custom_data("Walkable") == false:
						is_solid = true

			if is_solid:
				astar_grid.set_point_solid(tile_position, true)

func _input(event):
	if event.is_action_pressed("move") == false:
		return

	var raw_end_pos = tile_map_layer_1.local_to_map(get_global_mouse_position())
	var end_pos: Vector2i
	var is_target_walkable = not astar_grid.is_point_solid(raw_end_pos)

	var start_pos: Vector2i
	if is_moving:
		start_pos = tile_map_layer_1.local_to_map(target_position)
	else:
		start_pos = tile_map_layer_1.local_to_map(global_position)

	start_pos = find_nearest_walkable_cell(start_pos)

	if is_target_walkable:
		end_pos = find_nearest_walkable_cell(raw_end_pos)
	else:
		end_pos = find_adjacent_walkable_cell(raw_end_pos)

	var id_path = astar_grid.get_id_path(start_pos, end_pos)
	if id_path.size() > 1 and id_path[0] == start_pos:
		id_path = id_path.slice(1)

	if id_path.is_empty() == false:
		current_id_path = id_path
		target_position = tile_map_layer_1.map_to_local(current_id_path.front())
		is_moving = true

		if not is_target_walkable:
			obstacle_facing_pos = tile_map_layer_1.map_to_local(raw_end_pos)
		else:
			obstacle_facing_pos = null

func _physics_process(delta):
	handle_input()

	if input_vector.length() > 0:
		current_id_path.clear()
		is_moving = false
		obstacle_facing_pos = null
		handle_keyboard_movement(delta)
	elif is_moving:
		handle_pathfinding_movement()
	else:
		apply_friction(delta)

	move_and_slide()
	update_animation()

func handle_input():
	input_vector = Vector2.ZERO

	if Input.is_action_pressed("ui_up") or Input.is_action_pressed("move_up"):
		input_vector.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_action_pressed("move_down"):
		input_vector.y += 1
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("move_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_action_pressed("move_right"):
		input_vector.x += 1

	input_vector = input_vector.normalized()

func handle_pathfinding_movement():
	if current_id_path.is_empty():
		is_moving = false
		return

	if not is_moving:
		target_position = tile_map_layer_1.map_to_local(current_id_path.front())
		is_moving = true

	var direction = (target_position - global_position).normalized()
	var distance = global_position.distance_to(target_position)

	if distance > 5:
		velocity = direction * speed
		last_facing_dir = direction
	else:
		current_id_path.pop_front()
		if not current_id_path.is_empty():
			target_position = tile_map_layer_1.map_to_local(current_id_path.front())
		else:
			is_moving = false
			velocity = Vector2.ZERO

			if obstacle_facing_pos != null:
				var face_dir = (obstacle_facing_pos - global_position).normalized()
				if face_dir.length() > 0.1:
					last_facing_dir = face_dir
				obstacle_facing_pos = null

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

func find_nearest_walkable_cell(cell_pos: Vector2i) -> Vector2i:
	if not astar_grid.is_point_solid(cell_pos):
		return cell_pos

	for radius in range(1, 5):
		for x in range(-radius, radius + 1):
			for y in range(-radius, radius + 1):
				var check_pos = Vector2i(cell_pos.x + x, cell_pos.y + y)
				if astar_grid.region.has_point(check_pos) and not astar_grid.is_point_solid(check_pos):
					return check_pos

	return cell_pos

func find_adjacent_walkable_cell(cell_pos: Vector2i) -> Vector2i:
	var offsets = [
		Vector2i(0, -1), Vector2i(1, 0),
		Vector2i(0, 1), Vector2i(-1, 0)
	]

	for offset in offsets:
		var adj = cell_pos + offset
		if astar_grid.region.has_point(adj) and not astar_grid.is_point_solid(adj):
			return adj

	return cell_pos

func get_movement_state() -> String:
	return "moving" if velocity.length() > 10 else "idle"

func get_facing_direction() -> Vector2:
	return velocity.normalized() if velocity.length() > 10 else last_facing_dir
