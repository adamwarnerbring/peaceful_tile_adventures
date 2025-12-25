class_name Mercenary
extends Node2D
## Mercenary unit that can guard, hunt, or patrol

signal died(mercenary: Mercenary)

enum BehaviorType { GUARD_BOTS, GUARD_PLAYER, HUNT_ENEMIES, PATROL_ZONE }
enum MercenaryType { WARRIOR, ARCHER, MAGE, KNIGHT }

@export var mercenary_type: MercenaryType = MercenaryType.WARRIOR
@export var behavior: BehaviorType = BehaviorType.HUNT_ENEMIES

var config: MercenaryConfig
var health: float
var target: Node2D = null
var attack_timer: float = 0.0
var grid_ref: TileGrid
var main_ref: Node2D  # Reference to main game controller
var patrol_zone: TileGrid.Zone = TileGrid.Zone.FOREST
var guard_target: Node2D = null  # Bot or player being guarded
var patrol_target_pos: Vector2 = Vector2.ZERO
var is_ranged: bool = false

func _ready() -> void:
	var configs = MercenaryConfig.get_all_configs()
	config = configs.get(mercenary_type)
	if not config:
		config = configs[MercenaryType.WARRIOR]
	
	health = config.max_health
	is_ranged = (mercenary_type == MercenaryType.ARCHER or mercenary_type == MercenaryType.MAGE)
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
	if not guard_target or not is_instance_valid(guard_target):
		_find_nearest_bot()
	
	if guard_target and is_instance_valid(guard_target):
		var dist_to_bot = position.distance_to(guard_target.position)
		var guard_distance = 30.0  # Stay this far from bot
		
		# Move to guard position
		if dist_to_bot > guard_distance:
			var speed_mult = 1.0
			if main_ref and "game_config" in main_ref:
				speed_mult = main_ref.game_config.global_speed_multiplier
			var direction = (guard_target.position - position).normalized()
			position += direction * config.move_speed * speed_mult * delta
		
		# Attack enemies near the bot
		_attack_nearby_enemies(delta)
	else:
		# No bot to guard, hunt enemies instead
		_hunt_enemies(delta)

func _guard_player(delta: float) -> void:
	# Follow player and attack nearby enemies
	if not main_ref or not main_ref.has_method("get_player"):
		return
	
	var player = main_ref.get_player()
	if not player or not is_instance_valid(player):
		return
	
	var dist_to_player = position.distance_to(player.position)
	var guard_distance = 40.0  # Stay this far from player
	
	# Move to guard position
	if dist_to_player > guard_distance:
		var speed_mult = 1.0
		if main_ref and "game_config" in main_ref:
			speed_mult = main_ref.game_config.global_speed_multiplier
		var direction = (player.position - position).normalized()
		position += direction * config.move_speed * speed_mult * delta
	
	# Attack enemies near player
	_attack_nearby_enemies(delta)

func _hunt_enemies(delta: float) -> void:
	# Find and attack nearest enemy
	if not main_ref or not main_ref.has_method("get_enemies"):
		return
	
	var enemies = main_ref.get_enemies()
	if enemies.is_empty():
		return
	
	# Find nearest enemy
	var nearest_enemy: Enemy = null
	var nearest_dist = INF
	
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist = position.distance_to(enemy.position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest_enemy = enemy
	
	if nearest_enemy:
		target = nearest_enemy
		var dist = position.distance_to(nearest_enemy.position)
		
		if dist <= config.attack_range:
			_try_attack(nearest_enemy)
		else:
			# Move toward enemy
			var speed_mult = 1.0
			if main_ref and "game_config" in main_ref:
				speed_mult = main_ref.game_config.global_speed_multiplier
			var direction = (nearest_enemy.position - position).normalized()
			position += direction * config.move_speed * speed_mult * delta

func _patrol_zone(delta: float) -> void:
	# Patrol a specific zone
	if not grid_ref:
		return
	
	# If no patrol target or reached it, find new patrol point
	if patrol_target_pos == Vector2.ZERO or position.distance_to(patrol_target_pos) < 20.0:
		_find_patrol_point()
	
	if patrol_target_pos != Vector2.ZERO:
		var speed_mult = 1.0
		if main_ref and "game_config" in main_ref:
			speed_mult = main_ref.game_config.global_speed_multiplier
		var direction = (patrol_target_pos - position).normalized()
		position += direction * config.move_speed * speed_mult * delta * 0.7  # Slower when patrolling
	
	# Attack enemies while patrolling
	_attack_nearby_enemies(delta)

func _find_nearest_bot() -> void:
	if not main_ref or not main_ref.has_method("get_bots"):
		return
	
	var bots = main_ref.get_bots()
	if bots.is_empty():
		return
	
	var nearest_bot: CollectorBot = null
	var nearest_dist = INF
	
	for bot in bots:
		if not is_instance_valid(bot):
			continue
		var dist = position.distance_to(bot.position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest_bot = bot
	
	guard_target = nearest_bot

func _find_patrol_point() -> void:
	if not grid_ref:
		patrol_target_pos = Vector2.ZERO
		return
	
	# Ensure zone is unlocked, default to Forest if not
	if not grid_ref.is_zone_unlocked(patrol_zone):
		patrol_zone = TileGrid.Zone.FOREST
	
	var cells = grid_ref.get_random_cell_in_zone(patrol_zone)
	if cells.x >= 0:
		patrol_target_pos = grid_ref.position + grid_ref.grid_to_world(cells)
	else:
		patrol_target_pos = Vector2.ZERO

func _attack_nearby_enemies(delta: float) -> void:
	if not main_ref or not main_ref.has_method("get_enemies"):
		return
	
	var enemies = main_ref.get_enemies()
	var nearest_enemy: Enemy = null
	var nearest_dist = INF
	
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist = position.distance_to(enemy.position)
		if dist <= config.attack_range and dist < nearest_dist:
			nearest_dist = dist
			nearest_enemy = enemy
	
	if nearest_enemy:
		_try_attack(nearest_enemy)

func _try_attack(enemy: Enemy) -> void:
	if attack_timer > 0:
		return
	
	attack_timer = config.attack_cooldown
	
	if is_ranged:
		# Create projectile
		if main_ref and main_ref.has_method("_create_mercenary_projectile"):
			main_ref._create_mercenary_projectile(self, enemy)
	else:
		# Melee attack
		enemy.take_damage(config.damage)

func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0:
		_die()

func _die() -> void:
	died.emit(self)
	queue_free()

func _draw() -> void:
	if not config:
		return
	
	var size = config.size
	var color = config.color
	
	# Draw body based on type
	match mercenary_type:
		MercenaryType.WARRIOR:
			_draw_warrior(size, color)
		MercenaryType.ARCHER:
			_draw_archer(size, color)
		MercenaryType.MAGE:
			_draw_mage(size, color)
		MercenaryType.KNIGHT:
			_draw_knight(size, color)
	
	# Health bar
	var bar_width = size * 2
	var bar_height = 4
	var health_ratio = health / config.max_health
	draw_rect(Rect2(-bar_width/2, -size - 8, bar_width, bar_height), Color("#1e1e1e"))
	draw_rect(Rect2(-bar_width/2, -size - 8, bar_width * health_ratio, bar_height), Color("#22c55e"))

func _draw_warrior(size: float, color: Color) -> void:
	draw_circle(Vector2.ZERO, size, color)
	draw_circle(Vector2.ZERO, size, color.darkened(0.2), false, 2.0)
	# Sword
	draw_line(Vector2(size * 0.7, -size * 0.3), Vector2(size * 0.7, size * 0.5), color.lightened(0.3), 3.0)

func _draw_archer(size: float, color: Color) -> void:
	draw_circle(Vector2.ZERO, size, color)
	draw_circle(Vector2.ZERO, size, color.darkened(0.2), false, 2.0)
	# Bow
	draw_arc(Vector2(size * 0.6, 0), size * 0.3, 0, PI, 8, color.lightened(0.3), 2.0)

func _draw_mage(size: float, color: Color) -> void:
	draw_circle(Vector2.ZERO, size, color)
	draw_circle(Vector2.ZERO, size, color.darkened(0.2), false, 2.0)
	# Staff
	draw_line(Vector2(size * 0.6, -size * 0.4), Vector2(size * 0.6, size * 0.4), color.lightened(0.3), 2.0)
	draw_circle(Vector2(size * 0.6, -size * 0.4), 3, Color("#fbbf24"))

func _draw_knight(size: float, color: Color) -> void:
	draw_circle(Vector2.ZERO, size, color)
	draw_circle(Vector2.ZERO, size, color.darkened(0.2), false, 3.0)
	# Shield
	draw_rect(Rect2(size * 0.5, -size * 0.4, size * 0.4, size * 0.8), color.lightened(0.2))
