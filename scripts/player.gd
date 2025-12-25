class_name Player
extends Node2D
## Player character that moves on the tile grid

signal resource_collected(tier: int)
signal reached_base()
signal died()
signal health_changed(current: float, maximum: float)

const PICKUP_DISTANCE := 20.0

@export var max_health: float = 100.0

var health: float
var move_speed: float = 180.0
var base_move_speed: float = 180.0
var target_position: Vector2
var is_moving := false
var carried_resource: int = -1
var grid_ref: TileGrid

# Weapon system
var equipped_weapon: Weapon = null
var attack_timer: float = 0.0

func _ready() -> void:
	health = max_health
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
	
	# Weapon cooldown (only decrease, don't reset - main.gd handles attacks)
	if attack_timer > 0:
		attack_timer -= delta
	
	queue_redraw()

func _draw() -> void:
	# Draw player body
	draw_circle(Vector2.ZERO, 18, Color("#fbbf24"))
	draw_circle(Vector2.ZERO, 18, Color("#f59e0b"), false, 3.0)
	
	# Draw eyes
	draw_circle(Vector2(-5, -4), 4, Color.WHITE)
	draw_circle(Vector2(5, -4), 4, Color.WHITE)
	draw_circle(Vector2(-5, -4), 2, Color("#1e293b"))
	draw_circle(Vector2(5, -4), 2, Color("#1e293b"))
	
	# Draw carried resource indicator
	if carried_resource >= 0:
		var carry_color = _get_tier_color(carried_resource)
		draw_circle(Vector2(0, -28), 10, carry_color)
		draw_circle(Vector2(0, -28), 10, Color.WHITE, false, 2.0)
	
	# Draw health bar
	var bar_width = 36
	var bar_height = 5
	var bar_y = 22
	var health_ratio = health / max_health
	
	draw_rect(Rect2(-bar_width/2, bar_y, bar_width, bar_height), Color("#1e1e1e"))
	draw_rect(Rect2(-bar_width/2, bar_y, bar_width * health_ratio, bar_height), Color("#22c55e"))
	
	# Draw weapon indicator
	if equipped_weapon:
		draw_circle(Vector2(15, -15), 6, equipped_weapon.color)
	
	# Draw attack range indicator
	if equipped_weapon:
		var range_val = equipped_weapon.attack_range
		draw_arc(Vector2.ZERO, range_val, 0, TAU, 32, Color(equipped_weapon.color.r, equipped_weapon.color.g, equipped_weapon.color.b, 0.2), 2.0)
		draw_circle(Vector2.ZERO, range_val, Color(equipped_weapon.color.r, equipped_weapon.color.g, equipped_weapon.color.b, 0.1))

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

func take_damage(amount: float) -> void:
	health -= amount
	health_changed.emit(health, max_health)
	if health <= 0:
		health = 0
		died.emit()

func heal(amount: float) -> void:
	health = min(health + amount, max_health)
	health_changed.emit(health, max_health)

func respawn() -> void:
	health = max_health
	carried_resource = -1
	health_changed.emit(health, max_health)
	queue_redraw()

func equip_weapon(weapon: Weapon) -> void:
	equipped_weapon = weapon
	queue_redraw()

func can_attack() -> bool:
	return equipped_weapon != null and attack_timer <= 0

func get_weapon_range() -> float:
	if equipped_weapon:
		return equipped_weapon.attack_range
	return 0.0

func get_weapon_damage() -> float:
	if equipped_weapon:
		return equipped_weapon.damage
	return 0.0

func _get_tier_color(tier: int) -> Color:
	var colors: Array[Color] = [
		Color("#4ade80"), Color("#22d3ee"), Color("#3b82f6"), Color("#a855f7"),
		Color("#f43f5e"), Color("#f97316"), Color("#eab308"), Color("#fafafa"),
	]
	return colors[mini(tier, colors.size() - 1)]
