class_name Turret
extends Node2D
## Defensive turret that auto-attacks enemies

signal died()
signal health_changed(current: float, maximum: float)

enum TurretType { ARROW, MAGIC, FIRE, LIGHTNING }

@export var turret_type: TurretType = TurretType.ARROW
@export var damage: float = 8.0
@export var attack_range: float = 100.0
@export var attack_speed: float = 1.0
@export var aoe_radius: float = 0.0
@export var max_health: float = 80.0

var health: float
var attack_timer: float = 0.0
var current_target: Enemy = null

var type_stats: Dictionary = {
	TurretType.ARROW: {"damage": 8, "range": 120, "speed": 0.8, "aoe": 0, "color": Color("#a3e635"), "health": 80},
	TurretType.MAGIC: {"damage": 12, "range": 100, "speed": 1.2, "aoe": 30, "color": Color("#c084fc"), "health": 100},
	TurretType.FIRE: {"damage": 20, "range": 80, "speed": 1.5, "aoe": 50, "color": Color("#f97316"), "health": 120},
	TurretType.LIGHTNING: {"damage": 6, "range": 150, "speed": 0.4, "aoe": 0, "color": Color("#38bdf8"), "health": 60},
}

var type_prices: Dictionary = {
	TurretType.ARROW: 80,
	TurretType.MAGIC: 200,
	TurretType.FIRE: 400,
	TurretType.LIGHTNING: 600,
}

func _ready() -> void:
	_apply_type_stats()
	health = max_health
	queue_redraw()

func _apply_type_stats() -> void:
	var stats = type_stats.get(turret_type, type_stats[TurretType.ARROW])
	damage = stats["damage"]
	attack_range = stats["range"]
	attack_speed = stats["speed"]
	aoe_radius = stats["aoe"]
	max_health = stats["health"]
	health = max_health

func _process(delta: float) -> void:
	attack_timer -= delta
	
	if attack_timer <= 0:
		_find_and_attack_target()
	
	queue_redraw()

func _find_and_attack_target() -> void:
	current_target = null
	var closest_dist = INF
	
	var main = get_parent().get_parent()
	if not main or not main.has_method("get_enemies"):
		return
	
	var enemies = main.get_enemies()
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist = position.distance_to(enemy.position)
		if dist <= attack_range and dist < closest_dist:
			closest_dist = dist
			current_target = enemy
	
	if current_target:
		_attack(current_target)

func _attack(target: Enemy) -> void:
	attack_timer = attack_speed
	
	# Single target attack only
	target.take_damage(damage)

func take_damage(amount: float) -> void:
	health -= amount
	health_changed.emit(health, max_health)
	if health <= 0:
		_die()

func _die() -> void:
	died.emit()
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2.ZERO, 0.2)
	tw.tween_property(self, "modulate", Color.TRANSPARENT, 0.2)
	tw.tween_callback(queue_free)

func _draw() -> void:
	var stats = type_stats.get(turret_type, type_stats[TurretType.ARROW])
	var color: Color = stats["color"]
	
	# Base
	draw_rect(Rect2(-12, -12, 24, 24), Color("#475569"))
	draw_rect(Rect2(-12, -12, 24, 24), Color("#64748b"), false, 2.0)
	
	# Tower top
	draw_circle(Vector2.ZERO, 10, color)
	draw_circle(Vector2.ZERO, 10, color.lightened(0.3), false, 2.0)
	
	# Type indicator
	match turret_type:
		TurretType.ARROW:
			draw_line(Vector2.ZERO, Vector2(0, -14), color.lightened(0.5), 3.0)
		TurretType.MAGIC:
			draw_circle(Vector2.ZERO, 5, color.lightened(0.5))
		TurretType.FIRE:
			draw_circle(Vector2.ZERO, 6, Color("#fbbf24"))
		TurretType.LIGHTNING:
			draw_line(Vector2(-3, -8), Vector2(3, 0), Color.WHITE, 2.0)
			draw_line(Vector2(3, 0), Vector2(-3, 8), Color.WHITE, 2.0)
	
	# Health bar
	var bar_width = 24
	var bar_height = 3
	var bar_y = 14
	var health_ratio = health / max_health
	draw_rect(Rect2(-bar_width/2, bar_y, bar_width, bar_height), Color("#1e1e1e"))
	draw_rect(Rect2(-bar_width/2, bar_y, bar_width * health_ratio, bar_height), Color("#22c55e"))
	
	# Range indicator (faint)
	if current_target:
		draw_arc(Vector2.ZERO, attack_range, 0, TAU, 32, Color(color.r, color.g, color.b, 0.1), 1.0)

static func get_price(ttype: TurretType) -> int:
	var prices = {
		TurretType.ARROW: 80,
		TurretType.MAGIC: 200,
		TurretType.FIRE: 400,
		TurretType.LIGHTNING: 600,
	}
	return prices.get(ttype, 100)

static func get_turret_name(ttype: TurretType) -> String:
	var names = {
		TurretType.ARROW: "Arrow Tower",
		TurretType.MAGIC: "Magic Tower",
		TurretType.FIRE: "Fire Tower",
		TurretType.LIGHTNING: "Lightning Tower",
	}
	return names.get(ttype, "Tower")
