extends Node2D
## Main game controller - handles input, economy, and game state

@onready var tile_grid: TileGrid = $TileGrid
@onready var player: Player = $Player
@onready var base: Base = $Base
@onready var bots_container: Node2D = $Bots
@onready var coin_label: Label = $UI/CoinLabel
@onready var carry_label: Label = $UI/CarryLabel
@onready var shop_panel: PanelContainer = $UI/ShopPanel
@onready var shop_toggle_btn: Button = $UI/ShopToggleBtn
@onready var tab_buttons: Control = $UI/ShopPanel/VBox/TabButtons
@onready var content_area: ScrollContainer = $UI/ShopPanel/VBox/ContentArea
@onready var stats_panel: PanelContainer = $UI/StatsPanel
@onready var stats_toggle_btn: Button = $UI/StatsToggleBtn

var current_tab: String = "Zones"
var tab_contents: Dictionary = {}  # tab_name -> GridContainer

# Game configuration
var game_config: GameConfig = GameConfig.get_default_config()

var coins: int = 0
var max_coins: int = 1000  # Gold storage capacity
var previous_coins: int = 0  # Track for auto-refresh
var spawn_timer: float = 0.0
var total_coins_earned: int = 0  # Stats tracking

var bot_scene: PackedScene
var bot_prices: Dictionary = {
	TileGrid.Zone.FOREST: 50,
	TileGrid.Zone.CAVE: 200,
	TileGrid.Zone.CRYSTAL: 600,
	TileGrid.Zone.VOLCANO: 1500,
	TileGrid.Zone.ABYSS: 4000,
}
var bot_counts: Dictionary = {}

# Base upgrade system
var base_upgrade_levels: Dictionary = {}  # BaseUpgrade.UpgradeType -> level
var collection_speed_multiplier: float = 1.0  # Global collection speed multiplier

# Tooltip system
var tooltip_label: Label = null

# Zone unlock order
var zone_unlock_order: Array[TileGrid.Zone] = [
	TileGrid.Zone.CAVE,
	TileGrid.Zone.CRYSTAL,
	TileGrid.Zone.VOLCANO,
	TileGrid.Zone.ABYSS
]

func _ready() -> void:
	bot_scene = preload("res://scenes/collector_bot.tscn")
	
	# Initialize bot counts
	for zone in [TileGrid.Zone.FOREST, TileGrid.Zone.CAVE, TileGrid.Zone.CRYSTAL, TileGrid.Zone.VOLCANO, TileGrid.Zone.ABYSS]:
		bot_counts[zone] = 0
	
	var viewport_size = get_viewport().get_visible_rect().size
	var grid_size = tile_grid.get_grid_pixel_size()
	# Position grid: centered horizontally, small top margin
	tile_grid.position = Vector2(
		(viewport_size.x - grid_size.x) / 2,
		50
	)
	# Adjust to minimize bottom space
	var bottom_margin = 20
	var target_bottom = viewport_size.y - bottom_margin
	var current_bottom = tile_grid.position.y + grid_size.y
	var adjustment = target_bottom - current_bottom
	tile_grid.position.y += adjustment
	
	player.grid_ref = tile_grid
	# Start player near base center
	var start_grid = Vector2i(TileGrid.BASE_CENTER_X, TileGrid.BASE_CENTER_Y - 2)
	player.position = tile_grid.position + tile_grid.grid_to_world(start_grid)
	
	# Position base at the base center in the grid
	base.position = tile_grid.position + tile_grid.get_base_center_world()
	
	base.resources_merged.connect(_on_resources_merged)
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
	
	coins = game_config.starting_coins
	max_coins = game_config.starting_max_coins
	_update_ui()

func _setup_shop() -> void:
	# Create tab buttons and content areas
	_create_tabs()
	_refresh_shop()
	_switch_tab("Zones")  # Default to Zones tab

func _spawn_initial_resources() -> void:
	for _i in 4:
		tile_grid.spawn_resource_in_zone(TileGrid.Zone.FOREST)

func _process(delta: float) -> void:
	_check_pickups()
	_check_base_deposit()
	_check_shop_refresh()
	
	# Spawn resources continuously
	spawn_timer += delta
	if spawn_timer >= game_config.resource_spawn_interval:
		spawn_timer = 0.0
		_spawn_resources()
	
	_update_ui()

func _spawn_resources() -> void:
	for zone in [TileGrid.Zone.FOREST, TileGrid.Zone.CAVE, TileGrid.Zone.CRYSTAL, TileGrid.Zone.VOLCANO, TileGrid.Zone.ABYSS]:
		if tile_grid.is_zone_unlocked(zone):
			if tile_grid.count_resources_in_zone(zone) < game_config.max_resources_per_zone:
				tile_grid.spawn_resource_in_zone(zone)

func get_bots() -> Array:
	var bots: Array = []
	for child in bots_container.get_children():
		if child is CollectorBot and is_instance_valid(child):
			bots.append(child)
	return bots

func get_player() -> Player:
	return player

func get_base() -> Base:
	return base

func _check_shop_refresh() -> void:
	# Auto-refresh shop if coins changed
	if coins != previous_coins and shop_panel.visible:
		_refresh_shop()
	previous_coins = coins

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
	
	if tile_grid.is_cell_accessible(grid_pos):
		var target = tile_grid.position + tile_grid.grid_to_world(grid_pos)
		player.move_to(target)

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
	if shop_panel.visible:
		_switch_tab(current_tab)  # Refresh current tab

func _create_tabs() -> void:
	if not tab_buttons or not content_area:
		return
	
	# Convert HBoxContainer to GridContainer for two rows if needed
	if tab_buttons is HBoxContainer:
		var parent = tab_buttons.get_parent()
		var old_buttons = tab_buttons
		var grid_container = GridContainer.new()
		grid_container.columns = 3  # 3 tabs per row
		grid_container.add_theme_constant_override("h_separation", 4)
		grid_container.add_theme_constant_override("v_separation", 4)
		grid_container.name = "TabButtons"
		parent.remove_child(old_buttons)
		parent.add_child(grid_container)
		old_buttons.queue_free()
		tab_buttons = grid_container
	
	# Clear existing tabs
	for child in tab_buttons.get_children():
		child.queue_free()
	for child in content_area.get_children():
		child.queue_free()
	tab_contents.clear()
	
	# Define tabs (only peaceful ones)
	var tabs = [
		{"name": "Zones", "color": Color("#94a3b8")},
		{"name": "Bots", "color": Color("#22c55e")},
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
		tab_btn.custom_minimum_size = Vector2(150, 45)
		tab_btn.pressed.connect(_switch_tab.bind(tab_name))
		tab_buttons.add_child(tab_btn)
		
		# Create content grid for this tab
		var grid = GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 3)
		grid.add_theme_constant_override("v_separation", 3)
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
			_add_tooltip_to_button(btn, "Spawns: T" + str(tile_grid.zone_tiers[zone][0]) + "-" + str(tile_grid.zone_tiers[zone][1]))
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
	bot.speed_multiplier = game_config.global_speed_multiplier * collection_speed_multiplier
	bot.main_ref = self
	
	bot.deposited_resource.connect(_on_bot_deposited)
	bots_container.add_child(bot)
	_refresh_shop()

func _on_bot_deposited(tier: int) -> void:
	_award_coins(tier)

func _add_tooltip_to_button(btn: Button, text: String) -> void:
	btn.tooltip_text = text
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
	btn.add_theme_font_size_override("font_size", 13)
	btn.custom_minimum_size = Vector2(200, 90)
	btn.text = ""
	return btn

func _get_base_upgrade_tooltip(upgrade: BaseUpgrade, level: int) -> String:
	var tooltip = upgrade.description + "\n"
	if upgrade.is_one_time:
		tooltip += "One-time purchase\n"
		tooltip += "Price: " + str(int(upgrade.price * pow(upgrade.price_multiplier, level))) + " 🪙"
	else:
		tooltip += "Current Level: " + str(level) + "/" + str(upgrade.max_level) + "\n"
		if level < upgrade.max_level:
			tooltip += "Next Level: +" + str(upgrade.value) + "\n"
			tooltip += "Price: " + str(int(upgrade.price * pow(upgrade.price_multiplier, level))) + " 🪙"
		match upgrade.upgrade_type:
			BaseUpgrade.UpgradeType.GOLD_CAPACITY:
				tooltip += "\nCurrent Max: " + str(max_coins) + " 🪙"
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
		BaseUpgrade.UpgradeType.GOLD_CAPACITY:
			max_coins += int(upgrade.value)
			base_upgrade_levels[upgrade.upgrade_type] = level + 1
		BaseUpgrade.UpgradeType.COLLECTION_SPEED:
			# Increase global collection speed multiplier
			collection_speed_multiplier += upgrade.value
			# Apply to all existing bots
			for bot in get_bots():
				if bot is CollectorBot:
					bot.speed_multiplier = game_config.global_speed_multiplier * collection_speed_multiplier
			base_upgrade_levels[upgrade.upgrade_type] = level + 1
		BaseUpgrade.UpgradeType.STORAGE_EXPANSION:
			# Could expand base storage slots
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
	
	# Economy
	var economy_label = Label.new()
	economy_label.text = "=== ECONOMY ==="
	economy_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(economy_label)
	
	var coins_label = Label.new()
	coins_label.text = "Current Coins: " + str(coins)
	vbox.add_child(coins_label)
	
	var total_coins_label = Label.new()
	total_coins_label.text = "Total Earned: " + str(total_coins_earned)
	vbox.add_child(total_coins_label)
	
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

func _update_ui() -> void:
	# Show coins with capacity: current / max
	coin_label.text = "🪙 " + str(coins) + " / " + str(max_coins)
	
	if player.is_carrying():
		var tier = player.carried_resource
		carry_label.text = "Carrying T%d → Slot %d" % [tier, tier]
		carry_label.modulate = Color.WHITE
	else:
		carry_label.text = "Tap to move"
		carry_label.modulate = Color("#94a3b8")
