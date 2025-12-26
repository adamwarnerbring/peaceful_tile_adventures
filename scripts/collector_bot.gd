class_name CollectorBot
extends Node2D
## Automated collector that picks up resources and deposits them

signal deposited_resource(tier: int)

enum State { IDLE, MOVING_TO_RESOURCE, MOVING_TO_BASE }

const MOVE_SPEED := 100.0
var speed_multiplier: float = 1.0
const PICKUP_DISTANCE := 20.0
const DEPOSIT_DISTANCE := 30.0

@export var assigned_zone: TileGrid.Zone = TileGrid.Zone.FOREST
@export var bot_color: Color = Color("#22c55e")

var state: State = State.IDLE
var target_position: Vector2
var carried_resource: int = -1
var grid_ref  # TileGrid
var base_ref  # Base
var main_ref: Node2D = null  # Reference to main game controller
var idle_timer := 0.0

const IDLE_WAIT := 0.5

# Scale factor based on grid size (smaller bots on larger grids)
var scale_factor: float = 1.0

func _ready() -> void:
	queue_redraw()

func _process(delta: float) -> void:
	match state:
		State.IDLE:
			_process_idle(delta)
		State.MOVING_TO_RESOURCE, State.MOVING_TO_BASE:
			_process_moving(delta)
	queue_redraw()

func _process_idle(delta: float) -> void:
	idle_timer += delta
	if idle_timer >= IDLE_WAIT:
		idle_timer = 0.0
		_find_resource_target()

func _find_resource_target() -> void:
	if not grid_ref:
		return
	var resource_cell = grid_ref.find_resource_in_zone(assigned_zone)
	if resource_cell.x >= 0:
		target_position = grid_ref.global_position + grid_ref.grid_to_world(resource_cell)
		state = State.MOVING_TO_RESOURCE

func _process_moving(delta: float) -> void:
	var direction = (target_position - position).normalized()
	var distance = position.distance_to(target_position)
	
	var effective_speed = MOVE_SPEED * speed_multiplier
	if distance < effective_speed * delta:
		position = target_position
		_on_reached_target()
	else:
		position += direction * effective_speed * delta

func _on_reached_target() -> void:
	if state == State.MOVING_TO_RESOURCE:
		_try_pickup()
	elif state == State.MOVING_TO_BASE:
		_try_deposit()

func _try_pickup() -> void:
	if not grid_ref:
		state = State.IDLE
		return
	
	var local_pos = position - grid_ref.global_position
	var grid_pos = grid_ref.world_to_grid(local_pos)
	var resource = grid_ref.get_resource_at(grid_pos)
	
	if resource:
		carried_resource = resource.collect()
		grid_ref.remove_resource_at(grid_pos)
		_move_to_base()
	else:
		state = State.IDLE

func _move_to_base() -> void:
	if not base_ref or carried_resource < 0:
		state = State.IDLE
		return
	var slot_pos = base_ref.get_slot_world_position(carried_resource)
	target_position = slot_pos
	state = State.MOVING_TO_BASE

func _try_deposit() -> void:
	if not base_ref or carried_resource < 0:
		state = State.IDLE
		return
	
	var slot = base_ref.get_nearest_slot(position)
	if slot >= 0 and base_ref.can_deposit_at_slot(slot, carried_resource):
		var tier = carried_resource
		carried_resource = -1
		base_ref.deposit(tier, slot)
		deposited_resource.emit(tier)
	
	state = State.IDLE

func _draw() -> void:
	var size = 14.0 * scale_factor
	var border_width = 2.0 * scale_factor
	var antenna_length = 5.0 * scale_factor
	var antenna_light = 7.0 * scale_factor
	var antenna_circle = 3.0 * scale_factor
	var eye_size = 3.0 * scale_factor
	var carry_size = 7.0 * scale_factor
	var carry_y = -18.0 * scale_factor
	
	draw_rect(Rect2(-size/2, -size/2, size, size), bot_color)
	draw_rect(Rect2(-size/2, -size/2, size, size), bot_color.lightened(0.3), false, border_width)
	
	# Antenna
	draw_line(Vector2(0, -size/2), Vector2(0, -size/2 - antenna_length), bot_color.lightened(0.3), border_width)
	draw_circle(Vector2(0, -size/2 - antenna_light), antenna_circle, bot_color.lightened(0.5))
	
	# Eyes
	draw_rect(Rect2(-4 * scale_factor, -3 * scale_factor, eye_size, eye_size), Color("#1e293b"))
	draw_rect(Rect2(1 * scale_factor, -3 * scale_factor, eye_size, eye_size), Color("#1e293b"))
	
	# Carried resource
	if carried_resource >= 0:
		var carry_color = _get_tier_color(carried_resource)
		draw_circle(Vector2(0, carry_y), carry_size, carry_color)
		draw_circle(Vector2(0, carry_y), carry_size, Color.WHITE, false, 1.5 * scale_factor)

func set_scale_factor(factor: float) -> void:
	scale_factor = factor
	queue_redraw()

func _get_tier_color(tier: int) -> Color:
	var colors: Array[Color] = [
		Color("#4ade80"), Color("#22d3ee"), Color("#3b82f6"), Color("#a855f7"),
		Color("#f43f5e"), Color("#f97316"), Color("#eab308"), Color("#fafafa"),
	]
	return colors[mini(tier, colors.size() - 1)]

static func get_zone_color(zone: TileGrid.Zone) -> Color:
	match zone:
		TileGrid.Zone.FOREST:
			return Color("#22c55e")
		TileGrid.Zone.CAVE:
			return Color("#a855f7")
		TileGrid.Zone.CRYSTAL:
			return Color("#22d3ee")
		TileGrid.Zone.VOLCANO:
			return Color("#ef4444")
		TileGrid.Zone.ABYSS:
			return Color("#6366f1")
		_:
			return Color.WHITE
