extends Node2D
## Main game controller - handles input, economy, combat, and game state

@onready var tile_grid: TileGrid = $TileGrid
@onready var player: Player = $Player
@onready var base: Base = $Base
@onready var bots_container: Node2D = $Bots
@onready var enemies_container: Node2D = $Enemies
@onready var turrets_container: Node2D = $Turrets
@onready var coin_label: Label = $UI/CoinLabel
@onready var health_label: Label = $UI/HealthLabel
@onready var carry_label: Label = $UI/CarryLabel
@onready var shop_panel: PanelContainer = $UI/ShopPanel
@onready var shop_toggle_btn: Button = $UI/ShopToggleBtn
@onready var tab_buttons: HBoxContainer = $UI/ShopPanel/VBox/TabButtons
@onready var content_area: ScrollContainer = $UI/ShopPanel/VBox/ContentArea
@onready var stats_panel: PanelContainer = $UI/StatsPanel
@onready var stats_toggle_btn: Button = $UI/StatsToggleBtn

var current_tab: String = "Zones"
var tab_contents: Dictionary = {}  # tab_name -> GridContainer
@onready var base_health_label: Label = $UI/BaseHealthLabel

# Game configuration
var game_config: GameConfig = GameConfig.get_default_config()

var coins: int = 0
var max_coins: int = 1000  # Gold storage capacity
var previous_coins: int = 0  # Track for auto-refresh
var spawn_timer: float = 0.0
var enemy_spawn_timer: float = 0.0
var total_coins_earned: int = 0  # Stats tracking
var base_weapon_level: int = 0  # Base auto-attack level
var base_attack_timer: float = 0.0
var player_respawn_timer: float = 0.0
var is_player_dead: bool = false
var projectiles_container: Node2D  # Container for projectiles
var projectile_scene: PackedScene

var bot_scene: PackedScene
var enemy_scene: PackedScene
var turret_scene: PackedScene

var bot_prices: Dictionary = {
	TileGrid.Zone.FOREST: 50,
	TileGrid.Zone.CAVE: 200,
	TileGrid.Zone.CRYSTAL: 600,
	TileGrid.Zone.VOLCANO: 1500,
	TileGrid.Zone.ABYSS: 4000,
}
var bot_counts: Dictionary = {}

var owned_weapons: Array[Weapon] = []
var turret_counts: Dictionary = {}

# Upgrade system
var upgrade_levels: Dictionary = {}  # UpgradeType -> level
var player_armor: float = 0.0
var health_regen: float = 0.0
var damage_boost: float = 0.0

# Base upgrade system
var base_upgrade_levels: Dictionary = {}  # BaseUpgrade.UpgradeType -> level
var base_armor: float = 0.0
var base_health_regen: float = 0.0

# Tooltip system
var tooltip_label: Label = null

# Zone unlock order
var zone_unlock_order: Array[TileGrid.Zone] = [
	TileGrid.Zone.CAVE,
	TileGrid.Zone.CRYSTAL,
	TileGrid.Zone.VOLCANO,
	TileGrid.Zone.ABYSS
]

# Placement mode
var placing_turret: Turret.TurretType = Turret.TurretType.ARROW
var is_placing_turret := false

func _ready() -> void:
	bot_scene = preload("res://scenes/collector_bot.tscn")
	enemy_scene = preload("res://scenes/enemy.tscn")
	turret_scene = preload("res://scenes/turret.tscn")
	# Create projectiles container
	projectiles_container = Node2D.new()
	projectiles_container.name = "Projectiles"
	add_child(projectiles_container)
	# Projectile scene will be created programmatically
	
	# Initialize bot counts
	for zone in [TileGrid.Zone.FOREST, TileGrid.Zone.CAVE, TileGrid.Zone.CRYSTAL, TileGrid.Zone.VOLCANO, TileGrid.Zone.ABYSS]:
		bot_counts[zone] = 0
	
	# Initialize turret counts
	for ttype in [Turret.TurretType.ARROW, Turret.TurretType.MAGIC, Turret.TurretType.FIRE, Turret.TurretType.LIGHTNING]:
		turret_counts[ttype] = 0
	
	var viewport_size = get_viewport().get_visible_rect().size
	var grid_size = tile_grid.get_grid_pixel_size()
	# Position grid: centered horizontally, small top margin, minimal bottom space
	tile_grid.position = Vector2(
		(viewport_size.x - grid_size.x) / 2,
		48  # Small top margin for UI
	)
	# Adjust to minimize bottom space - align grid bottom with viewport bottom (with small margin)
	var bottom_margin = 20  # Small margin from bottom
	var target_bottom = viewport_size.y - bottom_margin
	var current_bottom = tile_grid.position.y + grid_size.y
	var adjustment = target_bottom - current_bottom
	tile_grid.position.y += adjustment
	
	player.grid_ref = tile_grid
	# Start player near base center
	var start_grid = Vector2i(TileGrid.BASE_CENTER_X, TileGrid.BASE_CENTER_Y - 2)
	player.position = tile_grid.position + tile_grid.grid_to_world(start_grid)
	player.died.connect(_on_player_died)
	
	# Position base at the base center in the grid
	base.position = tile_grid.position + tile_grid.get_base_center_world()
	
	base.resources_merged.connect(_on_resources_merged)
	base.health_changed.connect(_on_base_health_changed)
	base.base_destroyed.connect(_on_base_destroyed)
	tile_grid.zone_unlocked.connect(_on_zone_unlocked)
	
	shop_toggle_btn.pressed.connect(_toggle_shop)
	shop_panel.visible = false
	stats_toggle_btn.pressed.connect(_toggle_stats)
	stats_panel.visible = false
	
	# Initialize base upgrade levels
	for upgrade in BaseUpgrade.get_all_upgrades():
		base_upgrade_levels[upgrade.upgrade_type] = 0
	
	_setup_shop()
	_spawn_initial_resources()
	
	# Give player starting weapon
	var sword = Weapon.create_sword()
	owned_weapons.append(sword)
	player.equip_weapon(sword)
	
	coins = game_config.starting_coins
	max_coins = game_config.starting_max_coins
	_update_ui()

func _setup_shop() -> void:
	# Create tab buttons and content areas
	_create_tabs()
	_refresh_shop()
	_switch_tab("Zones")  # Default to Zones tab
	
	# Initialize upgrade levels
	for upgrade in Upgrade.get_all_upgrades():
		upgrade_levels[upgrade.upgrade_type] = 0

func _spawn_initial_resources() -> void:
	for _i in 4:
		tile_grid.spawn_resource_in_zone(TileGrid.Zone.FOREST)

func _process(delta: float) -> void:
	_process_player_respawn(delta)
	if not is_player_dead:
		_check_pickups()
		_check_base_deposit()
		_process_player_combat(delta)
	_process_enemy_attacks()
	if not is_player_dead:
		_process_health_regen(delta)
	_process_base_health_regen(delta)
	_process_base_weapon(delta)
	_check_shop_refresh()
	
	spawn_timer += delta
	if spawn_timer >= game_config.resource_spawn_interval:
		spawn_timer = 0.0
		_spawn_resources()
	
	enemy_spawn_timer += delta
	if enemy_spawn_timer >= game_config.enemy_spawn_interval:
		enemy_spawn_timer = 0.0
		_spawn_enemies()
	
	_update_ui()

func _spawn_resources() -> void:
	for zone in [TileGrid.Zone.FOREST, TileGrid.Zone.CAVE, TileGrid.Zone.CRYSTAL, TileGrid.Zone.VOLCANO, TileGrid.Zone.ABYSS]:
		if tile_grid.is_zone_unlocked(zone):
			if tile_grid.count_resources_in_zone(zone) < game_config.max_resources_per_zone:
				# Spawn resources up to tier 11 (new max)
				tile_grid.spawn_resource_in_zone(zone)

func _spawn_enemies() -> void:
	# Spawn enemies in unlocked zones based on danger level
	for zone in [TileGrid.Zone.FOREST, TileGrid.Zone.CAVE, TileGrid.Zone.CRYSTAL, TileGrid.Zone.VOLCANO, TileGrid.Zone.ABYSS]:
		if tile_grid.is_zone_unlocked(zone) and zone != TileGrid.Zone.BASE:
			var danger = tile_grid.get_zone_danger(zone)
			# Higher danger = more likely to spawn
			if randf() < danger * 0.15:
				_spawn_enemy_in_zone(zone)

func _spawn_enemy_in_zone(zone: TileGrid.Zone) -> void:
	# Spawn enemies at map edges only
	var cell = tile_grid.get_random_edge_cell_in_zone(zone)
	if cell.x < 0:
		return
	
	var enemy = enemy_scene.instantiate() as Enemy
	enemy.enemy_type = Enemy.get_type_for_zone(zone)
	enemy.grid_ref = tile_grid
	enemy.position = tile_grid.position + tile_grid.grid_to_world(cell)
	enemy.base_target = base  # Set base as wander target
	enemy.died.connect(_on_enemy_died.bind(enemy))
	enemy.attacked_target.connect(_on_enemy_attacked)
	
	enemies_container.add_child(enemy)

func get_enemies() -> Array:
	var enemies: Array = []
	for child in enemies_container.get_children():
		if child is Enemy and is_instance_valid(child):
			enemies.append(child)
	return enemies

func get_targets_by_priority(priority: EnemyConfig.AttackPriority, from_pos: Vector2, max_range: float) -> Array:
	var targets: Array = []
	
	match priority:
		EnemyConfig.AttackPriority.PLAYER:
			if is_instance_valid(player) and from_pos.distance_to(player.position) <= max_range:
				targets.append(player)
		EnemyConfig.AttackPriority.BOT:
			for bot in bots_container.get_children():
				if bot is CollectorBot and is_instance_valid(bot):
					if from_pos.distance_to(bot.position) <= max_range:
						targets.append(bot)
		EnemyConfig.AttackPriority.TURRET:
			for turret in turrets_container.get_children():
				if turret is Turret and is_instance_valid(turret):
					if from_pos.distance_to(turret.position) <= max_range:
						targets.append(turret)
	
	# Base is always a potential target (enemies can attack it)
	if is_instance_valid(base) and from_pos.distance_to(base.position) <= max_range * 1.5:
		targets.append(base)
	
	return targets

func get_base() -> Base:
	return base

func get_all_targets_with_scores() -> Array:
	# Helper for enemy scoring (not used directly but available)
	return []

func _process_health_regen(delta: float) -> void:
	if health_regen > 0 and player.health < player.max_health:
		player.heal(health_regen * delta)

func _process_player_combat(_delta: float) -> void:
	if not player.equipped_weapon or not player.can_attack():
		return
	
	# Find nearest enemy in weapon range
	var nearest_enemy: Enemy = null
	var nearest_dist = INF
	var weapon_range = player.get_weapon_range()
	
	for enemy in get_enemies():
		var dist = player.position.distance_to(enemy.position)
		if dist <= weapon_range and dist < nearest_dist:
			nearest_dist = dist
			nearest_enemy = enemy
	
	if nearest_enemy:
		_player_attack(nearest_enemy)

func _player_attack(target: Enemy) -> void:
	player.attack_timer = player.equipped_weapon.attack_speed
	var damage = player.get_weapon_damage() + damage_boost
	
	# Single target attack only - create projectile for visual
	_create_weapon_projectile(player.position, target, damage, player.equipped_weapon.color)
	target.take_damage(damage)

func _process_enemy_attacks() -> void:
	for enemy in get_enemies():
		if not is_instance_valid(enemy):
			continue
		# Enemy attack is handled in enemy._try_attack()

func _on_enemy_attacked(target: Node2D) -> void:
	if not is_instance_valid(target):
		return
	
	# Find which enemy attacked
	for enemy in get_enemies():
		if enemy.target == target:
			# Check if ranged enemy - create projectile instead
			if enemy.config.is_ranged:
				_create_enemy_projectile(enemy, target)
			else:
				# Melee attack
				var damage = enemy.config.damage
				if target is Player:
					var actual_damage = max(1.0, damage - player_armor)
					target.take_damage(actual_damage)
				elif target is CollectorBot:
					target.take_damage(damage)
				elif target is Turret:
					target.take_damage(damage)
				elif target is Base:
					var actual_damage = max(1.0, damage - base_armor)
					target.take_damage(actual_damage)
			break

func _create_enemy_projectile(enemy: Enemy, target: Node2D) -> void:
	# Create projectile node
	var projectile = Node2D.new()
	projectile.set_script(preload("res://scripts/projectile.gd"))
	projectile.position = enemy.position
	projectile.target = target
	projectile.source = enemy
	projectile.damage = enemy.config.damage
	projectile.speed = enemy.config.projectile_speed
	projectile.color = enemy.config.color
	projectile.hit_target.connect(_on_projectile_hit.bind(projectile))
	projectiles_container.add_child(projectile)

func _on_projectile_hit(projectile: Projectile, target: Node2D) -> void:
	if not is_instance_valid(target):
		return
	
	var damage = projectile.damage
	if target is Player:
		var actual_damage = max(1.0, damage - player_armor)
		target.take_damage(actual_damage)
	elif target is CollectorBot:
		target.take_damage(damage)
	elif target is Turret:
		target.take_damage(damage)
	elif target is Base:
		var actual_damage = max(1.0, damage - base_armor)
		target.take_damage(actual_damage)
	elif target is Enemy:
		target.take_damage(damage)

func _create_weapon_projectile(from: Vector2, to: Node2D, damage: float, color: Color) -> void:
	var projectile = Node2D.new()
	projectile.set_script(preload("res://scripts/projectile.gd"))
	projectile.position = from
	projectile.target = to
	projectile.damage = damage
	projectile.speed = 300.0
	projectile.color = color
	projectile.hit_target.connect(_on_projectile_hit.bind(projectile))
	projectiles_container.add_child(projectile)

func _spawn_enemy_drops(enemy: Enemy) -> void:
	# Drop coins or resources based on enemy level
	var zone = tile_grid.get_zone_at(tile_grid.world_to_grid(enemy.position - tile_grid.position))
	var danger = tile_grid.get_zone_danger(zone)
	
	# Drop chance increases with danger level
	if randf() < 0.3 + (danger * 0.1):  # 30-80% drop chance
		# Spawn resource pickup at enemy position
		var drop_tier = min(2, danger - 1)  # Tier 0-2 based on zone
		if drop_tier >= 0:
			tile_grid.spawn_resource(tile_grid.world_to_grid(enemy.position - tile_grid.position), drop_tier)

func _on_enemy_died(enemy: Enemy) -> void:
	var reward = Enemy.get_coin_reward(enemy.enemy_type)
	coins = mini(coins + reward, max_coins)  # Respect gold capacity
	total_coins_earned += reward
	
	# Enemy drops based on level/zone
	_spawn_enemy_drops(enemy)

func _on_base_health_changed(current: float, maximum: float) -> void:
	if base_health_label:
		base_health_label.text = "🏰 " + str(int(current)) + "/" + str(int(maximum))

func _on_base_destroyed() -> void:
	# Game over
	get_tree().paused = true
	var game_over_label = Label.new()
	game_over_label.text = "GAME OVER\nBase Destroyed!"
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game_over_label.add_theme_font_size_override("font_size", 32)
	game_over_label.add_theme_color_override("font_color", Color("#ef4444"))
	game_over_label.anchors_preset = Control.PRESET_FULL_RECT
	$UI.add_child(game_over_label)

func _process_player_respawn(delta: float) -> void:
	if is_player_dead:
		player_respawn_timer -= delta
		if player_respawn_timer <= 0:
			# Respawn player at base
			var start_grid = Vector2i(TileGrid.GRID_SIZE.x / 2, TileGrid.GRID_SIZE.y - 4)
			player.position = tile_grid.position + tile_grid.grid_to_world(start_grid)
			player.respawn()
			player.visible = true
			is_player_dead = false

func _process_base_health_regen(delta: float) -> void:
	if base_health_regen > 0 and base.health < base.max_health:
		base.heal(base_health_regen * delta)

func _process_base_weapon(delta: float) -> void:
	if base_weapon_level <= 0:
		return
	
	base_attack_timer -= delta
	if base_attack_timer <= 0:
		base_attack_timer = 1.5  # Attack speed
		_base_attack_enemies()

func _base_attack_enemies() -> void:
	var damage = 5.0 + (base_weapon_level * 3.0)  # 5, 8, 11, 14, 17 damage
	var range = 80.0 + (base_weapon_level * 10.0)  # 80, 90, 100, 110, 120 range
	
	var nearest_enemy: Enemy = null
	var nearest_dist = INF
	
	for enemy in get_enemies():
		var dist = base.position.distance_to(enemy.position)
		if dist <= range and dist < nearest_dist:
			nearest_dist = dist
			nearest_enemy = enemy
	
	if nearest_enemy:
		nearest_enemy.take_damage(damage)

func _check_shop_refresh() -> void:
	# Auto-refresh shop if coins changed
	if coins != previous_coins and shop_panel.visible:
		_refresh_shop()
	previous_coins = coins

func _on_turret_died() -> void:
	pass  # Could add notification

func _on_player_died() -> void:
	is_player_dead = true
	player_respawn_timer = game_config.player_respawn_time
	player.visible = false

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_handle_touch(event.position)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_touch(event.global_position)

func _handle_touch(touch_pos: Vector2) -> void:
	if _is_touching_ui(touch_pos):
		return
	
	var local_pos = touch_pos - tile_grid.position
	var grid_pos = tile_grid.world_to_grid(local_pos)
	
	if is_placing_turret:
		_try_place_turret(grid_pos)
		return
	
	if tile_grid.is_cell_accessible(grid_pos):
		var target = tile_grid.position + tile_grid.grid_to_world(grid_pos)
		player.move_to(target)

func _try_place_turret(grid_pos: Vector2i) -> void:
	if not tile_grid.is_cell_accessible(grid_pos):
		return
	if tile_grid.is_base_area(grid_pos):
		return  # Cannot place turrets in base area
	if tile_grid.get_turret_at(grid_pos) != null:
		return
	
	var price = Turret.get_price(placing_turret)
	if coins < price:
		return
	
	coins -= price
	turret_counts[placing_turret] = turret_counts.get(placing_turret, 0) + 1
	
	var turret = turret_scene.instantiate() as Turret
	turret.turret_type = placing_turret
	turret.position = tile_grid.position + tile_grid.grid_to_world(grid_pos)
	turret.died.connect(_on_turret_died)
	tile_grid.place_turret(grid_pos, turret)
	turrets_container.add_child(turret)
	
	is_placing_turret = false
	tile_grid.show_turret_placement = false
	tile_grid.queue_redraw()
	_update_ui()

func _is_touching_ui(pos: Vector2) -> bool:
	if shop_panel.visible:
		if shop_panel.get_global_rect().has_point(pos):
			return true
	if shop_toggle_btn.get_global_rect().has_point(pos):
		return true
	if pos.y < 50:
		return true
	return false

func _check_pickups() -> void:
	if player.is_carrying():
		return
	
	var local_player = player.position - tile_grid.position
	var player_grid = tile_grid.world_to_grid(local_player)
	
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var check_pos = player_grid + Vector2i(dx, dy)
			var resource = tile_grid.get_resource_at(check_pos)
			if resource:
				var resource_global = tile_grid.position + resource.position
				var dist = player.position.distance_to(resource_global)
				if dist < game_config.pickup_distance:
					var tier = resource.collect()
					player.pickup_resource(tier)
					tile_grid.remove_resource_at(check_pos)
					return

func _check_base_deposit() -> void:
	if not player.is_carrying():
		return
	
	var slot = base.get_nearest_slot(player.position)
	if slot >= 0:
		var tier = player.carried_resource
		if base.can_deposit_at_slot(slot, tier):
			player.deposit_resource()
			base.deposit(tier, slot)
			_award_coins(tier)

func _award_coins(tier: int) -> void:
	var amount = int(pow(2, tier))
	coins = mini(coins + amount, max_coins)  # Respect gold capacity
	total_coins_earned += amount

func _on_resources_merged(new_tier: int) -> void:
	var amount = int(pow(2, new_tier)) * 2
	coins = mini(coins + amount, max_coins)  # Respect gold capacity
	total_coins_earned += amount

func _on_zone_unlocked(_zone: TileGrid.Zone) -> void:
	_refresh_shop()

func _toggle_shop() -> void:
	shop_panel.visible = not shop_panel.visible
	is_placing_turret = false
	if shop_panel.visible:
		_switch_tab(current_tab)  # Refresh current tab

func _create_tabs() -> void:
	if not tab_buttons or not content_area:
		return
	
	# Clear existing tabs
	for child in tab_buttons.get_children():
		child.queue_free()
	for child in content_area.get_children():
		child.queue_free()
	tab_contents.clear()
	
	# Define tabs
	var tabs = [
		{"name": "Zones", "color": Color("#94a3b8")},
		{"name": "Bots", "color": Color("#22c55e")},
		{"name": "Weapons", "color": Color("#c084fc")},
		{"name": "Turrets", "color": Color("#f97316")},
		{"name": "Upgrades", "color": Color("#3b82f6")},
		{"name": "Base Upgrades", "color": Color("#fbbf24")}
	]
	
	# Create tab buttons and content containers
	for tab_info in tabs:
		var tab_name = tab_info["name"]
		var tab_color = tab_info["color"]
		
		# Create tab button
		var tab_btn = Button.new()
		tab_btn.text = tab_name
		tab_btn.add_theme_font_size_override("font_size", 11)
		tab_btn.add_theme_color_override("font_color", tab_color)
		tab_btn.custom_minimum_size = Vector2(100, 30)
		tab_btn.pressed.connect(_switch_tab.bind(tab_name))
		tab_buttons.add_child(tab_btn)
		
		# Create content grid for this tab
		var grid = GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		grid.visible = false
		content_area.add_child(grid)
		tab_contents[tab_name] = grid

func _switch_tab(tab_name: String) -> void:
	current_tab = tab_name
	
	# Update button states
	for btn in tab_buttons.get_children():
		if btn is Button:
			if btn.text == tab_name:
				btn.disabled = true
				btn.modulate = Color(1.2, 1.2, 1.2)  # Highlight selected
			else:
				btn.disabled = false
				btn.modulate = Color.WHITE
	
	# Show/hide content
	for content_name in tab_contents:
		var grid = tab_contents[content_name]
		grid.visible = (content_name == tab_name)
	
	_refresh_shop()

func _refresh_shop() -> void:
	if not tab_contents.has(current_tab):
		return
	
	# Clear current tab's content
	var grid = tab_contents[current_tab]
	for child in grid.get_children():
		child.queue_free()
	
	# Populate current tab
	match current_tab:
		"Zones":
			_populate_zones_tab(grid)
		"Bots":
			_populate_bots_tab(grid)
		"Weapons":
			_populate_weapons_tab(grid)
		"Turrets":
			_populate_turrets_tab(grid)
		"Upgrades":
			_populate_upgrades_tab(grid)
		"Base Upgrades":
			_populate_base_upgrades_tab(grid)

func _populate_zones_tab(grid: GridContainer) -> void:
	for zone in zone_unlock_order:
		var btn = _create_shop_button()
		var is_unlocked = tile_grid.is_zone_unlocked(zone)
		var price = tile_grid.get_zone_price(zone)
		var zname = tile_grid.get_zone_name(zone)
		var can_unlock = _can_unlock_zone(zone)
		
		if is_unlocked:
			btn.text = zname + " ✓"
			btn.disabled = true
		elif not can_unlock:
			var prev_zone = _get_previous_zone(zone)
			btn.text = "🔒 " + zname
			btn.text += "\n" + tile_grid.get_zone_name(prev_zone) + " first"
			btn.disabled = true
		else:
			btn.text = "🔓 " + zname
			btn.text += "\n" + str(price) + " 🪙"
			btn.disabled = coins < price
			btn.pressed.connect(_on_buy_zone.bind(zone))
			_add_tooltip_to_button(btn, "Spawns: T" + str(tile_grid.zone_tiers[zone][0]) + "-" + str(tile_grid.zone_tiers[zone][1]) + "\nEnemies: " + _get_zone_enemy_info(zone))
		grid.add_child(btn)

func _can_unlock_zone(zone: TileGrid.Zone) -> bool:
	if tile_grid.is_zone_unlocked(zone):
		return false
	var prev_zone = _get_previous_zone(zone)
	if prev_zone == null:
		return true  # First zone (Cave)
	return tile_grid.is_zone_unlocked(prev_zone)

func _get_previous_zone(zone: TileGrid.Zone) -> TileGrid.Zone:
	var index = zone_unlock_order.find(zone)
	if index <= 0:
		return TileGrid.Zone.BASE  # No previous zone
	return zone_unlock_order[index - 1]

func _get_zone_enemy_info(zone: TileGrid.Zone) -> String:
	match zone:
		TileGrid.Zone.CAVE:
			return "Goblins, Slimes"
		TileGrid.Zone.CRYSTAL:
			return "Demons, Goblins"
		TileGrid.Zone.VOLCANO:
			return "Demons"
		TileGrid.Zone.ABYSS:
			return "Shadows, Demons"
		_:
			return "Various"

func _populate_bots_tab(grid: GridContainer) -> void:
	for zone in [TileGrid.Zone.FOREST, TileGrid.Zone.CAVE, TileGrid.Zone.CRYSTAL, TileGrid.Zone.VOLCANO, TileGrid.Zone.ABYSS]:
		var btn = _create_shop_button()
		btn.add_theme_color_override("font_color", CollectorBot.get_zone_color(zone))
		var is_zone_unlocked = tile_grid.is_zone_unlocked(zone)
		var price = bot_prices.get(zone, 100)
		var count = bot_counts.get(zone, 0)
		var zname = tile_grid.get_zone_name(zone)
		
		if not is_zone_unlocked:
			btn.text = "🔒 " + zname + " Bot"
			btn.disabled = true
		else:
			btn.text = "🤖 " + zname + " Bot"
			btn.text += "\n(" + str(count) + ") " + str(price) + " 🪙"
			btn.disabled = coins < price
			btn.pressed.connect(_on_buy_bot.bind(zone))
		grid.add_child(btn)

func _populate_weapons_tab(grid: GridContainer) -> void:
	var all_weapons = Weapon.get_all_weapons()
	for weapon in all_weapons:
		var btn = _create_shop_button()
		btn.add_theme_color_override("font_color", weapon.color)
		var owned = _has_weapon(weapon.weapon_type)
		var equipped = player.equipped_weapon and player.equipped_weapon.weapon_type == weapon.weapon_type
		
		if equipped:
			btn.text = "⚔️ " + weapon.name + "\n[EQUIPPED]"
			btn.disabled = true
		elif owned:
			btn.text = "⚔️ " + weapon.name + "\nEquip"
			btn.pressed.connect(_on_equip_weapon.bind(weapon.weapon_type))
		else:
			btn.text = "⚔️ " + weapon.name
			btn.text += "\n" + str(weapon.price) + " 🪙"
			btn.text += "\nDMG:" + str(int(weapon.damage)) + " RNG:" + str(int(weapon.attack_range))
			btn.disabled = coins < weapon.price
			btn.pressed.connect(_on_buy_weapon.bind(weapon))
		grid.add_child(btn)

func _populate_turrets_tab(grid: GridContainer) -> void:
	for ttype in [Turret.TurretType.ARROW, Turret.TurretType.MAGIC, Turret.TurretType.FIRE, Turret.TurretType.LIGHTNING]:
		var btn = _create_shop_button()
		var price = Turret.get_price(ttype)
		var tname = Turret.get_turret_name(ttype)
		var count = turret_counts.get(ttype, 0)
		
		btn.text = "🏰 " + tname
		btn.text += "\n(" + str(count) + ") " + str(price) + " 🪙"
		btn.disabled = coins < price
		btn.pressed.connect(_on_select_turret.bind(ttype))
		_add_tooltip_to_button(btn, "Tap grid to place after buying")
		grid.add_child(btn)

func _has_weapon(wtype: Weapon.WeaponType) -> bool:
	for w in owned_weapons:
		if w.weapon_type == wtype:
			return true
	return false

func _on_buy_zone(zone: TileGrid.Zone) -> void:
	if not _can_unlock_zone(zone):
		return
	var price = tile_grid.get_zone_price(zone)
	if coins >= price:
		coins -= price
		total_coins_earned += price  # Track spending
		tile_grid.unlock_zone(zone)
		_refresh_shop()

func _on_buy_bot(zone: TileGrid.Zone) -> void:
	if not tile_grid.is_zone_unlocked(zone):
		return
	var price = bot_prices.get(zone, 100)
	if coins < price:
		return
	
	coins -= price
	bot_counts[zone] = bot_counts.get(zone, 0) + 1
	bot_prices[zone] = int(price * 1.6)
	
	var bot = bot_scene.instantiate() as CollectorBot
	bot.assigned_zone = zone
	bot.bot_color = CollectorBot.get_zone_color(zone)
	bot.grid_ref = tile_grid
	bot.base_ref = base
	
	# Spawn bot in front of base
	var base_center = tile_grid.get_base_center_world()
	var spawn_offset = Vector2i(0, -3)  # 3 cells in front (up) of base
	var spawn_cell = Vector2i(TileGrid.BASE_CENTER_X, TileGrid.BASE_CENTER_Y - 3)
	
	# Try to find empty cell near base front
	var attempts = 10
	for i in attempts:
		var test_cell = spawn_cell + Vector2i(randi_range(-2, 2), 0)
		if tile_grid.is_valid_cell(test_cell) and not tile_grid.is_base_area(test_cell):
			var resource = tile_grid.get_resource_at(test_cell)
			if resource == null:
				spawn_cell = test_cell
				break
	
	bot.position = tile_grid.position + tile_grid.grid_to_world(spawn_cell)
	
	bot.deposited_resource.connect(_on_bot_deposited)
	bot.died.connect(_on_bot_died)
	bots_container.add_child(bot)
	_refresh_shop()

func _on_buy_weapon(weapon: Weapon) -> void:
	if coins < weapon.price:
		return
	coins -= weapon.price
	owned_weapons.append(weapon)
	player.equip_weapon(weapon)
	_refresh_shop()

func _on_equip_weapon(wtype: Weapon.WeaponType) -> void:
	for w in owned_weapons:
		if w.weapon_type == wtype:
			player.equip_weapon(w)
			break
	_refresh_shop()

func _on_select_turret(ttype: Turret.TurretType) -> void:
	var price = Turret.get_price(ttype)
	if coins < price:
		return
	placing_turret = ttype
	is_placing_turret = true
	shop_panel.visible = false

func _on_bot_deposited(tier: int) -> void:
	_award_coins(tier)

func _on_bot_died() -> void:
	pass  # Could add notification

func _populate_upgrades_tab(grid: GridContainer) -> void:
	var all_upgrades = Upgrade.get_all_upgrades()
	for upgrade in all_upgrades:
		var level = upgrade_levels.get(upgrade.upgrade_type, 0)
		var btn = _create_shop_button()
		var current_price = int(upgrade.price * pow(upgrade.price_multiplier, level))
		var is_maxed = level >= upgrade.max_level
		
		if is_maxed:
			btn.text = "⭐ " + upgrade.name + "\n[MAX]"
			btn.disabled = true
		else:
			btn.text = "⭐ " + upgrade.name
			btn.text += "\nLv " + str(level) + " → " + str(level + 1)
			btn.text += "\n" + str(current_price) + " 🪙"
			btn.disabled = coins < current_price
			btn.pressed.connect(_on_buy_upgrade.bind(upgrade))
		_add_tooltip_to_button(btn, _get_upgrade_tooltip(upgrade, level))
		grid.add_child(btn)

func _get_upgrade_tooltip(upgrade: Upgrade, level: int) -> String:
	var tooltip = upgrade.description + "\n"
	tooltip += "Current Level: " + str(level) + "/" + str(upgrade.max_level) + "\n"
	if level < upgrade.max_level:
		tooltip += "Next Level: +" + str(upgrade.value) + "\n"
		tooltip += "Price: " + str(int(upgrade.price * pow(upgrade.price_multiplier, level))) + " 🪙"
	return tooltip

func _on_buy_upgrade(upgrade: Upgrade) -> void:
	var level = upgrade_levels.get(upgrade.upgrade_type, 0)
	if level >= upgrade.max_level:
		return
	
	var price = int(upgrade.price * pow(upgrade.price_multiplier, level))
	if coins < price:
		return
	
	coins -= price
	upgrade_levels[upgrade.upgrade_type] = level + 1
	
	# Apply upgrade
	match upgrade.upgrade_type:
		Upgrade.UpgradeType.MAX_HEALTH:
			player.max_health += upgrade.value
			player.health += upgrade.value
		Upgrade.UpgradeType.HEALTH_REGEN:
			health_regen += upgrade.value
		Upgrade.UpgradeType.ARMOR:
			player_armor += upgrade.value
		Upgrade.UpgradeType.MOVE_SPEED:
			player.move_speed += upgrade.value
		Upgrade.UpgradeType.DAMAGE_BOOST:
			damage_boost += upgrade.value
	
	_refresh_shop()

func _add_tooltip_to_button(btn: Button, text: String) -> void:
	btn.tooltip_text = text
	# Also add mouse enter/exit for better mobile support
	btn.mouse_entered.connect(_show_tooltip.bind(text))
	btn.mouse_exited.connect(_hide_tooltip)

func _show_tooltip(text: String) -> void:
	if not tooltip_label:
		tooltip_label = Label.new()
		tooltip_label.add_theme_font_size_override("font_size", 11)
		tooltip_label.add_theme_color_override("font_color", Color.WHITE)
		tooltip_label.add_theme_stylebox_override("normal", _create_tooltip_style())
		tooltip_label.z_index = 100
		$UI.add_child(tooltip_label)
	tooltip_label.text = text
	tooltip_label.visible = true

func _hide_tooltip() -> void:
	if tooltip_label:
		tooltip_label.visible = false

func _create_tooltip_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.4, 0.5, 1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	style.content_margin_left = 8
	style.content_margin_top = 6
	style.content_margin_right = 8
	style.content_margin_bottom = 6
	return style

func _populate_base_upgrades_tab(grid: GridContainer) -> void:
	var all_upgrades = BaseUpgrade.get_all_upgrades()
	for upgrade in all_upgrades:
		var level = base_upgrade_levels.get(upgrade.upgrade_type, 0)
		var btn = _create_shop_button()
		var current_price = int(upgrade.price * pow(upgrade.price_multiplier, level))
		var is_maxed = level >= upgrade.max_level and not upgrade.is_one_time
		
		if is_maxed:
			btn.text = "🏰 " + upgrade.name + "\n[MAX]"
			btn.disabled = true
		else:
			btn.text = "🏰 " + upgrade.name
			if upgrade.is_one_time:
				btn.text += "\n" + str(current_price) + " 🪙"
			else:
				btn.text += "\nLv " + str(level) + " → " + str(level + 1)
				btn.text += "\n" + str(current_price) + " 🪙"
			btn.disabled = coins < current_price
			btn.pressed.connect(_on_buy_base_upgrade.bind(upgrade))
		_add_tooltip_to_button(btn, _get_base_upgrade_tooltip(upgrade, level))
		grid.add_child(btn)

func _create_shop_button() -> Button:
	var btn = Button.new()
	btn.add_theme_font_size_override("font_size", 10)
	btn.custom_minimum_size = Vector2(160, 60)
	btn.text = ""
	return btn

func _get_base_upgrade_tooltip(upgrade: BaseUpgrade, level: int) -> String:
	var tooltip = upgrade.description + "\n"
	if upgrade.is_one_time:
		tooltip += "One-time purchase\n"
		tooltip += "Price: " + str(int(upgrade.price * pow(upgrade.price_multiplier, level))) + " 🪙"
		match upgrade.upgrade_type:
			BaseUpgrade.UpgradeType.REPAIR:
				tooltip += "\nRepairs: +" + str(int(upgrade.value)) + " HP"
	else:
		tooltip += "Current Level: " + str(level) + "/" + str(upgrade.max_level) + "\n"
		if level < upgrade.max_level:
			tooltip += "Next Level: +" + str(upgrade.value) + "\n"
			tooltip += "Price: " + str(int(upgrade.price * pow(upgrade.price_multiplier, level))) + " 🪙"
		match upgrade.upgrade_type:
			BaseUpgrade.UpgradeType.GOLD_CAPACITY:
				tooltip += "\nCurrent Max: " + str(max_coins) + " 🪙"
			BaseUpgrade.UpgradeType.BASE_WEAPON:
				tooltip += "\nDamage: " + str(5 + (level * 3)) + "\nRange: " + str(80 + (level * 10))
	return tooltip

func _on_buy_base_upgrade(upgrade: BaseUpgrade) -> void:
	var level = base_upgrade_levels.get(upgrade.upgrade_type, 0)
	if not upgrade.is_one_time and level >= upgrade.max_level:
		return
	
	var price = int(upgrade.price * pow(upgrade.price_multiplier, level))
	if coins < price:
		return
	
	coins -= price
	total_coins_earned += price
	
	# Apply upgrade
	match upgrade.upgrade_type:
		BaseUpgrade.UpgradeType.MAX_HEALTH:
			base.upgrade_max_health(upgrade.value)
			base_upgrade_levels[upgrade.upgrade_type] = level + 1
		BaseUpgrade.UpgradeType.HEALTH_REGEN:
			base_health_regen += upgrade.value
			base_upgrade_levels[upgrade.upgrade_type] = level + 1
		BaseUpgrade.UpgradeType.ARMOR:
			base_armor += upgrade.value
			base_upgrade_levels[upgrade.upgrade_type] = level + 1
		BaseUpgrade.UpgradeType.REPAIR:
			base.heal(upgrade.value)
			# Repair is one-time purchase, don't increment level
		BaseUpgrade.UpgradeType.GOLD_CAPACITY:
			max_coins += int(upgrade.value)
			base_upgrade_levels[upgrade.upgrade_type] = level + 1
		BaseUpgrade.UpgradeType.BASE_WEAPON:
			base_weapon_level += 1
			base_upgrade_levels[upgrade.upgrade_type] = level + 1
	
	_refresh_shop()

func _toggle_stats() -> void:
	stats_panel.visible = not stats_panel.visible
	if stats_panel.visible:
		_populate_stats()

func _populate_stats() -> void:
	var vbox = stats_panel.get_node("VBox")
	if not vbox:
		return
	
	for child in vbox.get_children():
		child.queue_free()
	
	# Player stats
	var player_label = Label.new()
	player_label.text = "=== PLAYER ==="
	player_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(player_label)
	
	var player_health = Label.new()
	player_health.text = "Health: " + str(int(player.health)) + "/" + str(int(player.max_health))
	vbox.add_child(player_health)
	
	var player_weapon = Label.new()
	if player.equipped_weapon:
		player_weapon.text = "Weapon: " + player.equipped_weapon.name
	else:
		player_weapon.text = "Weapon: None"
	vbox.add_child(player_weapon)
	
	var player_armor_label = Label.new()
	player_armor_label.text = "Armor: " + str(int(player_armor))
	vbox.add_child(player_armor_label)
	
	# Base stats
	var base_label = Label.new()
	base_label.text = "\n=== BASE ==="
	base_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(base_label)
	
	var base_health = Label.new()
	base_health.text = "Health: " + str(int(base.health)) + "/" + str(int(base.max_health))
	vbox.add_child(base_health)
	
	var base_armor_label = Label.new()
	base_armor_label.text = "Armor: " + str(int(base_armor))
	vbox.add_child(base_armor_label)
	
	# Bots stats
	var bots_label = Label.new()
	bots_label.text = "\n=== BOTS ==="
	bots_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(bots_label)
	
	var total_bots = 0
	for zone in bot_counts:
		total_bots += bot_counts.get(zone, 0)
	
	var bot_count_label = Label.new()
	bot_count_label.text = "Total Bots: " + str(total_bots)
	vbox.add_child(bot_count_label)
	
	for zone in [TileGrid.Zone.FOREST, TileGrid.Zone.CAVE, TileGrid.Zone.CRYSTAL, TileGrid.Zone.VOLCANO, TileGrid.Zone.ABYSS]:
		var count = bot_counts.get(zone, 0)
		if count > 0:
			var zone_label = Label.new()
			zone_label.text = tile_grid.get_zone_name(zone) + ": " + str(count)
			vbox.add_child(zone_label)
	
	# Turrets stats
	var turrets_label = Label.new()
	turrets_label.text = "\n=== TURRETS ==="
	turrets_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(turrets_label)
	
	var total_turrets = 0
	for ttype in turret_counts:
		total_turrets += turret_counts.get(ttype, 0)
	
	var turret_count_label = Label.new()
	turret_count_label.text = "Total Turrets: " + str(total_turrets)
	vbox.add_child(turret_count_label)
	
	# Economy
	var economy_label = Label.new()
	economy_label.text = "\n=== ECONOMY ==="
	economy_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(economy_label)
	
	var coins_label = Label.new()
	coins_label.text = "Current Coins: " + str(coins)
	vbox.add_child(coins_label)
	
	var total_coins_label = Label.new()
	total_coins_label.text = "Total Earned: " + str(total_coins_earned)
	vbox.add_child(total_coins_label)

func _update_ui() -> void:
	# Show coins with capacity: current / max
	coin_label.text = "🪙 " + str(coins) + " / " + str(max_coins)
	health_label.text = "❤️ " + str(int(player.health)) + "/" + str(int(player.max_health))
	
	if base_health_label:
		base_health_label.text = "🏰 " + str(int(base.health)) + "/" + str(int(base.max_health))
	
	if is_placing_turret:
		carry_label.text = "Tap to place " + Turret.get_turret_name(placing_turret)
		carry_label.modulate = Color("#fbbf24")
	elif player.is_carrying():
		var tier = player.carried_resource
		carry_label.text = "Carrying T%d → Slot %d" % [tier, tier]
		carry_label.modulate = Color.WHITE
	else:
		carry_label.text = "Tap to move"
		carry_label.modulate = Color("#94a3b8")
