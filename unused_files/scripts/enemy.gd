class_name Enemy
extends Node2D
## Enemy that attacks player, bots, turrets, and base based on priority

signal died(enemy: Enemy)
signal attacked_target(target: Node2D)

enum EnemyType { SLIME, GOBLIN, DEMON, SHADOW, ARCHER_GOBLIN, MAGE_DEMON }

@export var enemy_type: EnemyType = EnemyType.SLIME

const WANDER_SPEED_MULT := 0.5  # Slower when wandering
const RETARGET_DISTANCE := 80.0  # Retarget if something gets this close
const DISTANCE_SCORE_CONSTANT := 20.0  # Constant for distance scoring

var config: EnemyConfig
var health: float
var target: Node2D = null
var base_target: Node2D = null  # Base to wander toward
var attack_timer: float = 0.0
var grid_ref: TileGrid
var is_wandering := false

func _ready() -> void:
	var configs = EnemyConfig.get_all_configs()
	config = configs.get(enemy_type)
	if not config:
		config = configs[EnemyType.SLIME]
	
	health = config.max_health
	queue_redraw()

func _process(delta: float) -> void:
	attack_timer -= delta
	
	# Check for better targets nearby (distance-based scoring)
	_check_for_better_target()
	
	# If no target, try to find one
	if not target or not is_instance_valid(target):
		_find_new_target()
		# If still no target, check if base is close enough to attack
		if not target and base_target and is_instance_valid(base_target):
			var dist_to_base = position.distance_to(base_target.position)
			if dist_to_base <= config.attack_range * 1.5:
				target = base_target
	
	if target and is_instance_valid(target):
		var dist = position.distance_to(target.position)
		# Base has a larger attack range (it's a big target)
		var attack_range = config.attack_range
		if target is Base:
			attack_range = config.attack_range * 1.5
		if dist <= attack_range:
			_try_attack()
		else:
			_move_toward_target(delta)
	else:
		# No target - wander toward base
		_wander_toward_base(delta)
	
	queue_redraw()

func _check_for_better_target() -> void:
	# Score all potential targets and pick best
	var main = get_parent().get_parent()
	if not main or not main.has_method("get_all_targets_with_scores"):
		return
	
	var best_target = null
	var best_score = 0.0
	
	# Score targets based on priority and distance
	for priority in config.priority_list:
		var targets = main.get_targets_by_priority(priority, position, RETARGET_DISTANCE * 2.0)
		for t in targets:
			if not is_instance_valid(t):
				continue
			var dist = position.distance_to(t.position)
			# Score = priority_weight / (distance + constant)
			# Higher priority = higher weight, closer = higher score
			var priority_weight = 3.0 - config.priority_list.find(priority)  # 3, 2, 1
			var score = priority_weight / (dist + DISTANCE_SCORE_CONSTANT)
			
			if score > best_score:
				best_score = score
				best_target = t
	
	# Also check base
	if base_target and is_instance_valid(base_target):
		var dist = position.distance_to(base_target.position)
		var base_score = 0.5 / (dist + DISTANCE_SCORE_CONSTANT)  # Lower priority but still score it
		if base_score > best_score:
			best_score = base_score
			best_target = base_target
	
	if best_target and best_target != target:
		target = best_target
		is_wandering = false

func _move_toward_target(delta: float) -> void:
	if not target:
		return
	var main = get_parent().get_parent()
	var speed_mult = 1.0
	if main and "game_config" in main:
		speed_mult = main.game_config.global_speed_multiplier
	var direction = (target.position - position).normalized()
	position += direction * config.move_speed * speed_mult * delta

func _wander_toward_base(delta: float) -> void:
	if not base_target or not is_instance_valid(base_target):
		_find_base_target()
		return
	
	is_wandering = true
	var main = get_parent().get_parent()
	var speed_mult = 1.0
	if main and "game_config" in main:
		speed_mult = main.game_config.global_speed_multiplier
	var direction = (base_target.position - position).normalized()
	# Move slower when wandering
	position += direction * config.move_speed * WANDER_SPEED_MULT * speed_mult * delta

func _find_base_target() -> void:
	var main = get_parent().get_parent()
	if main and main.has_method("get_base"):
		base_target = main.get_base()

func _find_new_target() -> void:
	# Find targets based on priority list
	var main = get_parent().get_parent()
	if not main or not main.has_method("get_targets_by_priority"):
		return
	
	for priority in config.priority_list:
		var targets = main.get_targets_by_priority(priority, position, config.attack_range * 2.0)
		if targets.size() > 0:
			# Score all targets and pick best
			var best_target = null
			var best_score = 0.0
			for t in targets:
				var dist = position.distance_to(t.position)
				var priority_weight = 3.0 - config.priority_list.find(priority)
				var score = priority_weight / (dist + DISTANCE_SCORE_CONSTANT)
				if score > best_score:
					best_score = score
					best_target = t
			if best_target:
				target = best_target
				is_wandering = false
				return

func _try_attack() -> void:
	if attack_timer <= 0:
		attack_timer = config.attack_cooldown
		
		if config.is_ranged:
			# Fire projectile
			_fire_projectile()
		else:
			# Melee attack
			attacked_target.emit(target)

func _fire_projectile() -> void:
	if not target or not is_instance_valid(target):
		return
	
	# Create projectile (will be instantiated by main.gd)
	# Signal to main to create projectile
	attacked_target.emit(target)  # Main will handle projectile creation

func take_damage(amount: float) -> void:
	var actual_damage = max(1.0, amount - config.armor)
	health -= actual_damage
	if health <= 0:
		_die()

func _die() -> void:
	died.emit(self)
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2.ZERO, 0.2)
	tw.tween_callback(queue_free)

func set_target(new_target: Node2D) -> void:
	target = new_target
	is_wandering = false

func _draw() -> void:
	var size = config.size
	var color = config.color
	
	# Draw body based on type
	match enemy_type:
		EnemyType.SLIME:
			_draw_slime(size, color)
		EnemyType.GOBLIN:
			_draw_goblin(size, color)
		EnemyType.DEMON:
			_draw_demon(size, color)
		EnemyType.SHADOW:
			_draw_shadow(size, color)
		EnemyType.ARCHER_GOBLIN:
			_draw_archer_goblin(size, color)
		EnemyType.MAGE_DEMON:
			_draw_mage_demon(size, color)
	
	# Draw health bar
	var bar_width = size * 2
	var bar_height = 4
	var bar_y = -size - 8
	var health_ratio = health / config.max_health
	
	draw_rect(Rect2(-bar_width/2, bar_y, bar_width, bar_height), Color("#1e1e1e"))
	draw_rect(Rect2(-bar_width/2, bar_y, bar_width * health_ratio, bar_height), Color("#ef4444"))
	
	# Draw wandering indicator
	if is_wandering:
		draw_circle(Vector2(0, size + 4), 3, Color("#94a3b8"))

func _draw_slime(size: float, color: Color) -> void:
	draw_circle(Vector2.ZERO, size, color)
	draw_circle(Vector2(-size/3, -size/3), size/4, color.lightened(0.3))

func _draw_goblin(size: float, color: Color) -> void:
	var points = PackedVector2Array([
		Vector2(0, -size),
		Vector2(size, size),
		Vector2(-size, size)
	])
	draw_polygon(points, [color])
	draw_circle(Vector2(-4, -2), 3, Color.WHITE)
	draw_circle(Vector2(4, -2), 3, Color.WHITE)

func _draw_demon(size: float, color: Color) -> void:
	draw_circle(Vector2.ZERO, size, color)
	draw_line(Vector2(-size/2, -size), Vector2(-size, -size*1.5), color, 3)
	draw_line(Vector2(size/2, -size), Vector2(size, -size*1.5), color, 3)
	draw_circle(Vector2(-5, -3), 4, Color("#fbbf24"))
	draw_circle(Vector2(5, -3), 4, Color("#fbbf24"))

func _draw_shadow(size: float, color: Color) -> void:
	draw_circle(Vector2.ZERO, size, Color(color.r, color.g, color.b, 0.7))
	draw_circle(Vector2.ZERO, size * 0.6, color.lightened(0.2))
	draw_circle(Vector2(-4, -2), 3, Color.WHITE)
	draw_circle(Vector2(4, -2), 3, Color.WHITE)

func _draw_archer_goblin(size: float, color: Color) -> void:
	# Goblin with bow
	var points = PackedVector2Array([
		Vector2(0, -size),
		Vector2(size, size),
		Vector2(-size, size)
	])
	draw_polygon(points, [color])
	# Draw bow
	draw_line(Vector2(size * 0.7, -size * 0.3), Vector2(size * 0.7, size * 0.3), color, 2.0)
	draw_circle(Vector2(-4, -2), 3, Color.WHITE)
	draw_circle(Vector2(4, -2), 3, Color.WHITE)

func _draw_mage_demon(size: float, color: Color) -> void:
	# Demon with staff
	draw_circle(Vector2.ZERO, size, color)
	draw_line(Vector2(-size/2, -size), Vector2(-size, -size*1.5), color, 3)
	draw_line(Vector2(size/2, -size), Vector2(size, -size*1.5), color, 3)
	# Draw staff
	draw_line(Vector2(size * 0.8, -size * 0.5), Vector2(size * 0.8, size * 0.5), color, 3.0)
	draw_circle(Vector2(size * 0.8, -size * 0.5), 4, Color("#fbbf24"))  # Staff orb
	draw_circle(Vector2(-5, -3), 4, Color("#fbbf24"))
	draw_circle(Vector2(5, -3), 4, Color("#fbbf24"))

static func get_type_for_zone(zone: TileGrid.Zone) -> EnemyType:
	match zone:
		TileGrid.Zone.FOREST:
			return EnemyType.SLIME
		TileGrid.Zone.CAVE:
			return EnemyType.GOBLIN if randf() > 0.3 else EnemyType.SLIME
		TileGrid.Zone.CRYSTAL:
			# Mix of melee and ranged
			var rand = randf()
			if rand > 0.6:
				return EnemyType.ARCHER_GOBLIN
			elif rand > 0.3:
				return EnemyType.DEMON
			else:
				return EnemyType.GOBLIN
		TileGrid.Zone.VOLCANO:
			# More ranged enemies
			return EnemyType.MAGE_DEMON if randf() > 0.4 else EnemyType.DEMON
		TileGrid.Zone.ABYSS:
			return EnemyType.SHADOW if randf() > 0.3 else EnemyType.DEMON
		_:
			return EnemyType.SLIME

static func get_coin_reward(etype: EnemyType) -> int:
	var configs = EnemyConfig.get_all_configs()
	var config = configs.get(etype)
	if config:
		return config.coin_reward
	return 2
