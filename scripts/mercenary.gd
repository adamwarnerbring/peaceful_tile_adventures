class_name Mercenary
extends Node2D
## Mercenary unit that can guard, hunt, or patrol

signal died(mercenary: Mercenary)

enum BehaviorType { GUARD_BOTS, GUARD_PLAYER, HUNT_ENEMIES, PATROL_ZONE }

@export var behavior: BehaviorType = BehaviorType.HUNT_ENEMIES
@export var max_health: float = 50.0
@export var damage: float = 10.0
@export var move_speed: float = 100.0
@export var attack_range: float = 40.0
@export var attack_cooldown: float = 1.0

var health: float
var target: Node2D = null
var attack_timer: float = 0.0
var grid_ref: TileGrid
var main_ref: Node2D  # Reference to main game controller

func _ready() -> void:
	health = max_health
	queue_redraw()

func _process(delta: float) -> void:
	attack_timer -= delta
	
	match behavior:
		BehaviorType.GUARD_BOTS:
			_guard_bots(delta)
		BehaviorType.GUARD_PLAYER:
			_guard_player(delta)
		BehaviorType.HUNT_ENEMIES:
			_hunt_enemies(delta)
		BehaviorType.PATROL_ZONE:
			_patrol_zone(delta)
	
	queue_redraw()

func _guard_bots(delta: float) -> void:
	# Find nearest bot and guard it
	# TODO: Implement bot finding and guarding logic
	pass

func _guard_player(delta: float) -> void:
	# Follow player and attack nearby enemies
	# TODO: Implement player following and protection
	pass

func _hunt_enemies(delta: float) -> void:
	# Find and attack nearest enemy
	# TODO: Implement enemy hunting logic
	pass

func _patrol_zone(delta: float) -> void:
	# Patrol a specific zone
	# TODO: Implement zone patrolling
	pass

func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0:
		_die()

func _die() -> void:
	died.emit(self)
	queue_free()

func _draw() -> void:
	# Draw mercenary
	draw_circle(Vector2.ZERO, 16, Color("#3b82f6"))
	draw_circle(Vector2.ZERO, 16, Color("#2563eb"), false, 2.0)
	
	# Health bar
	var bar_width = 32
	var bar_height = 4
	var health_ratio = health / max_health
	draw_rect(Rect2(-bar_width/2, -24, bar_width, bar_height), Color("#1e1e1e"))
	draw_rect(Rect2(-bar_width/2, -24, bar_width * health_ratio, bar_height), Color("#22c55e"))

