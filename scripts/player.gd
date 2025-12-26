class_name Player
extends Node2D
## Player character that moves on the tile grid

signal resource_collected(tier: int)
signal reached_base()

const PICKUP_DISTANCE := 20.0

var move_speed: float = 180.0
var base_move_speed: float = 180.0
var target_position: Vector2
var is_moving := false
var carried_resource: int = -1
var grid_ref  # TileGrid

# Scale factor based on grid size (smaller player on larger grids)
var scale_factor: float = 1.0

func _ready() -> void:
	target_position = position
	queue_redraw()

func _process(delta: float) -> void:
	if is_moving:
		var direction = (target_position - position).normalized()
		var distance = position.distance_to(target_position)
		
		var main = get_tree().get_first_node_in_group("main")
		var speed_mult = 1.0
		if main and "game_config" in main:
			speed_mult = main.game_config.global_speed_multiplier
		var effective_speed = move_speed * speed_mult
		if distance < effective_speed * delta:
			position = target_position
			is_moving = false
		else:
			position += direction * effective_speed * delta
	
	queue_redraw()

func _draw() -> void:
	var body_radius = 18.0 * scale_factor
	var eye_size = 4.0 * scale_factor
	var eye_pupil = 2.0 * scale_factor
	var border_width = 3.0 * scale_factor
	
	# Draw player body
	draw_circle(Vector2.ZERO, body_radius, Color("#fbbf24"))
	draw_circle(Vector2.ZERO, body_radius, Color("#f59e0b"), false, border_width)
	
	# Draw eyes
	draw_circle(Vector2(-5 * scale_factor, -4 * scale_factor), eye_size, Color.WHITE)
	draw_circle(Vector2(5 * scale_factor, -4 * scale_factor), eye_size, Color.WHITE)
	draw_circle(Vector2(-5 * scale_factor, -4 * scale_factor), eye_pupil, Color("#1e293b"))
	draw_circle(Vector2(5 * scale_factor, -4 * scale_factor), eye_pupil, Color("#1e293b"))
	
	# Draw carried resource indicator
	if carried_resource >= 0:
		var carry_color = _get_tier_color(carried_resource)
		var carry_size = 10.0 * scale_factor
		draw_circle(Vector2(0, -28 * scale_factor), carry_size, carry_color)
		draw_circle(Vector2(0, -28 * scale_factor), carry_size, Color.WHITE, false, 2.0 * scale_factor)

func set_scale_factor(factor: float) -> void:
	scale_factor = factor
	queue_redraw()

func move_to(world_pos: Vector2) -> void:
	target_position = world_pos
	is_moving = true

func move_to_grid(grid_pos: Vector2i) -> void:
	if grid_ref:
		target_position = grid_ref.grid_to_world(grid_pos) + grid_ref.position
		is_moving = true

func pickup_resource(tier: int) -> bool:
	if carried_resource >= 0:
		return false
	carried_resource = tier
	queue_redraw()
	resource_collected.emit(tier)
	return true

func deposit_resource() -> int:
	var tier = carried_resource
	carried_resource = -1
	queue_redraw()
	return tier

func is_carrying() -> bool:
	return carried_resource >= 0

func _get_tier_color(tier: int) -> Color:
	var colors: Array[Color] = [
		Color("#4ade80"), Color("#22d3ee"), Color("#3b82f6"), Color("#a855f7"),
		Color("#f43f5e"), Color("#f97316"), Color("#eab308"), Color("#fafafa"),
	]
	return colors[mini(tier, colors.size() - 1)]
