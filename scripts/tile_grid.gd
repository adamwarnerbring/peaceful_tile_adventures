class_name TileGrid
extends Node2D
## Manages the tile grid with different unlockable zones

signal zone_unlocked(zone: Zone)

var GRID_SIZE := Vector2i(20, 32)  # Grid size (now dynamic per stage)
const CELL_SIZE := 32  # Finer grid (was 40)
var BASE_CENTER_X := 10  # Center of base in grid (scaled with grid)
var BASE_CENTER_Y := 28  # Base center Y position (scaled with grid)
const BASE_RADIUS := 4.5  # Base radius in cells (curved area)

enum Zone { BASE, FOREST, CAVE, CRYSTAL, VOLCANO, ABYSS }

var grid_resources: Array[Array] = []
var grid_zones: Array[Array] = []
var resource_scene: PackedScene

var unlocked_zones: Dictionary = {
	Zone.BASE: true,
	Zone.FOREST: true,
	Zone.CAVE: false,
	Zone.CRYSTAL: false,
	Zone.VOLCANO: false,
	Zone.ABYSS: false,
}

var zone_prices: Dictionary = {
	Zone.CAVE: 100,
	Zone.CRYSTAL: 500,
	Zone.VOLCANO: 2000,
	Zone.ABYSS: 8000,
}

var zone_colors: Dictionary = {
	Zone.BASE: [Color("#1e293b"), Color("#263347")],
	Zone.FOREST: [Color("#14532d"), Color("#166534")],
	Zone.CAVE: [Color("#3b0764"), Color("#4c1d95")],
	Zone.CRYSTAL: [Color("#083344"), Color("#0e4f66")],
	Zone.VOLCANO: [Color("#7f1d1d"), Color("#991b1b")],
	Zone.ABYSS: [Color("#1a1a2e"), Color("#16213e")],
}

var locked_color := Color("#050510")  # Very dark for locked zones

var zone_tiers: Dictionary = {
	Zone.FOREST: [0, 1],
	Zone.CAVE: [1, 2],
	Zone.CRYSTAL: [2, 3],
	Zone.VOLCANO: [3, 4],
	Zone.ABYSS: [4, 5],
}

var zone_names: Dictionary = {
	Zone.FOREST: "Forest",
	Zone.CAVE: "Cave",
	Zone.CRYSTAL: "Crystal Mine",
	Zone.VOLCANO: "Volcano",
	Zone.ABYSS: "Abyss",
}

func _ready() -> void:
	resource_scene = preload("res://scenes/resource_pickup.tscn")
	_init_grid()
	_setup_zones()
	queue_redraw()

# Initialize grid with specific size (for stage progression)
func initialize_grid(grid_size: Vector2i) -> void:
	GRID_SIZE = grid_size
	# Recalculate base center based on grid size (bottom center, slightly up)
	BASE_CENTER_X = grid_size.x / 2
	BASE_CENTER_Y = int(grid_size.y * 0.875)  # 87.5% down from top
	_init_grid()
	_setup_zones()
	queue_redraw()

# Reset grid to starting state (for stage upgrade)
func reset_grid() -> void:
	# Clear all resources
	for x in GRID_SIZE.x:
		for y in GRID_SIZE.y:
			if grid_resources[x][y] != null:
				var resource = grid_resources[x][y]
				if is_instance_valid(resource):
					resource.queue_free()
				grid_resources[x][y] = null
	
	# Reset zones (only BASE and FOREST unlocked)
	unlocked_zones.clear()
	unlocked_zones[Zone.BASE] = true
	unlocked_zones[Zone.FOREST] = true
	unlocked_zones[Zone.CAVE] = false
	unlocked_zones[Zone.CRYSTAL] = false
	unlocked_zones[Zone.VOLCANO] = false
	unlocked_zones[Zone.ABYSS] = false
	
	queue_redraw()

func _init_grid() -> void:
	grid_resources.clear()
	grid_zones.clear()
	for x in GRID_SIZE.x:
		var res_column: Array = []
		var zone_column: Array = []
		res_column.resize(GRID_SIZE.y)
		zone_column.resize(GRID_SIZE.y)
		grid_resources.append(res_column)
		grid_zones.append(zone_column)

func _setup_zones() -> void:
	# Setup zones with curved boundaries around base
	for x in GRID_SIZE.x:
		for y in GRID_SIZE.y:
			var zone: Zone
			
			# Calculate distance from base center
			var dx = x - BASE_CENTER_X
			var dy = y - BASE_CENTER_Y
			var dist_from_base = sqrt(dx * dx + dy * dy)
			
			# Base area (circular)
			if dist_from_base <= BASE_RADIUS:
				zone = Zone.BASE
			# Curved zones based on distance and angle
			else:
				# Use distance and angle to create curved boundaries
				var angle = atan2(dy, dx)  # Angle from base center
				var normalized_dist = (dist_from_base - BASE_RADIUS) / (GRID_SIZE.y - BASE_RADIUS)
				
				# Create curved boundaries
				# Zones curve outward from base
				var zone_threshold = _get_zone_threshold(normalized_dist, angle)
				
				# Forest moved further from base (was 0.15, now 0.25)
				if normalized_dist < 0.25:
					zone = Zone.FOREST
				elif normalized_dist < 0.45:
					zone = Zone.CAVE
				elif normalized_dist < 0.65:
					zone = Zone.CRYSTAL
				elif normalized_dist < 0.80:
					zone = Zone.VOLCANO
				else:
					zone = Zone.ABYSS
			
			grid_zones[x][y] = zone

func _get_zone_threshold(dist: float, angle: float) -> float:
	# Add slight curvature variation based on angle
	var curve_factor = 1.0 + 0.1 * sin(angle * 3.0)  # Creates wavy boundaries
	return dist * curve_factor

func _draw() -> void:
	for x in GRID_SIZE.x:
		for y in GRID_SIZE.y:
			var rect = Rect2(Vector2(x, y) * CELL_SIZE, Vector2(CELL_SIZE, CELL_SIZE))
			var zone = grid_zones[x][y]
			var is_unlocked = unlocked_zones.get(zone, false)
			
			if is_unlocked:
				var colors = zone_colors[zone]
				var bg_color = colors[0] if (x + y) % 2 == 0 else colors[1]
				draw_rect(rect, bg_color)
			else:
				# Locked zones - very dark, no variation
				draw_rect(rect, locked_color)
	
	# Draw zone boundaries with curves
	_draw_curved_zone_boundaries()

func _draw_curved_zone_boundaries() -> void:
	# Draw subtle boundary lines between unlocked zones only
	for x in range(1, GRID_SIZE.x):
		for y in range(1, GRID_SIZE.y):
			var current_zone = grid_zones[x][y]
			var left_zone = grid_zones[x-1][y]
			var top_zone = grid_zones[x][y-1]
			
			# Only draw boundaries between unlocked zones
			var current_unlocked = unlocked_zones.get(current_zone, false)
			var left_unlocked = unlocked_zones.get(left_zone, false)
			var top_unlocked = unlocked_zones.get(top_zone, false)
			
			# Draw vertical boundary
			if current_zone != left_zone and current_zone != Zone.BASE and left_zone != Zone.BASE:
				if current_unlocked and left_unlocked:
					var colors = zone_colors[current_zone]
					draw_line(
						Vector2(x, y) * CELL_SIZE,
						Vector2(x, y + 1) * CELL_SIZE,
						colors[1].lightened(0.2),
						1.0
					)
			
			# Draw horizontal boundary
			if current_zone != top_zone and current_zone != Zone.BASE and top_zone != Zone.BASE:
				if current_unlocked and top_unlocked:
					var colors = zone_colors[current_zone]
					draw_line(
						Vector2(x, y) * CELL_SIZE,
						Vector2(x + 1, y) * CELL_SIZE,
						colors[1].lightened(0.2),
						1.0
					)

func unlock_zone(zone: Zone) -> bool:
	if unlocked_zones.get(zone, false):
		return false
	unlocked_zones[zone] = true
	zone_unlocked.emit(zone)
	queue_redraw()
	return true

func is_zone_unlocked(zone: Zone) -> bool:
	return unlocked_zones.get(zone, false)

func get_zone_price(zone: Zone) -> int:
	return zone_prices.get(zone, 0)

func get_zone_name(zone: Zone) -> String:
	return zone_names.get(zone, "Unknown")

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos) * CELL_SIZE + Vector2(CELL_SIZE, CELL_SIZE) / 2

func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(world_pos.x / CELL_SIZE), int(world_pos.y / CELL_SIZE))

func is_valid_cell(grid_pos: Vector2i) -> bool:
	return grid_pos.x >= 0 and grid_pos.x < GRID_SIZE.x and grid_pos.y >= 0 and grid_pos.y < GRID_SIZE.y

func is_cell_accessible(grid_pos: Vector2i) -> bool:
	if not is_valid_cell(grid_pos):
		return false
	var zone = get_zone_at(grid_pos)
	return is_zone_unlocked(zone)

func get_zone_at(grid_pos: Vector2i) -> Zone:
	if not is_valid_cell(grid_pos):
		return Zone.BASE
	return grid_zones[grid_pos.x][grid_pos.y]

func is_base_area(grid_pos: Vector2i) -> bool:
	return get_zone_at(grid_pos) == Zone.BASE

func get_base_center_world() -> Vector2:
	return grid_to_world(Vector2i(BASE_CENTER_X, BASE_CENTER_Y))

func get_resource_at(grid_pos: Vector2i) -> ResourcePickup:
	if not is_valid_cell(grid_pos):
		return null
	return grid_resources[grid_pos.x][grid_pos.y]

func spawn_resource(grid_pos: Vector2i, tier: int = 0, scale_factor: float = 1.0) -> bool:
	if not is_valid_cell(grid_pos):
		return false
	if grid_resources[grid_pos.x][grid_pos.y] != null:
		return false
	if is_base_area(grid_pos):
		return false
	if not is_cell_accessible(grid_pos):
		return false
	
	var resource = resource_scene.instantiate()
	resource.tier = tier
	resource.position = grid_to_world(grid_pos)
	if resource.has_method("set_scale_factor"):
		resource.set_scale_factor(scale_factor)
	add_child(resource)
	grid_resources[grid_pos.x][grid_pos.y] = resource
	return true

func spawn_resource_in_zone(zone: Zone, scale_factor: float = 1.0) -> bool:
	if zone == Zone.BASE or not is_zone_unlocked(zone):
		return false
	
	var valid_cells: Array[Vector2i] = []
	for x in GRID_SIZE.x:
		for y in GRID_SIZE.y:
			if grid_zones[x][y] == zone and grid_resources[x][y] == null:
				valid_cells.append(Vector2i(x, y))
	
	if valid_cells.is_empty():
		return false
	
	var cell = valid_cells[randi() % valid_cells.size()]
	var tiers = zone_tiers[zone]
	var tier = tiers[randi() % tiers.size()]
	return spawn_resource(cell, tier, scale_factor)

func remove_resource_at(grid_pos: Vector2i) -> void:
	if is_valid_cell(grid_pos):
		grid_resources[grid_pos.x][grid_pos.y] = null

func find_empty_cell_in_zone(zone: Zone) -> Vector2i:
	if not is_zone_unlocked(zone):
		return Vector2i(-1, -1)
	
	var empty_cells: Array[Vector2i] = []
	for x in GRID_SIZE.x:
		for y in GRID_SIZE.y:
			if grid_zones[x][y] == zone and grid_resources[x][y] == null:
				empty_cells.append(Vector2i(x, y))
	
	if empty_cells.is_empty():
		return Vector2i(-1, -1)
	return empty_cells[randi() % empty_cells.size()]

func find_resource_in_zone(zone: Zone) -> Vector2i:
	if not is_zone_unlocked(zone):
		return Vector2i(-1, -1)
	
	var cells: Array[Vector2i] = []
	for x in GRID_SIZE.x:
		for y in GRID_SIZE.y:
			if grid_zones[x][y] == zone and grid_resources[x][y] != null:
				cells.append(Vector2i(x, y))
	
	if cells.is_empty():
		return Vector2i(-1, -1)
	return cells[randi() % cells.size()]

func get_random_cell_in_zone(zone: Zone) -> Vector2i:
	var cells: Array[Vector2i] = []
	for x in GRID_SIZE.x:
		for y in GRID_SIZE.y:
			if grid_zones[x][y] == zone:
				cells.append(Vector2i(x, y))
	if cells.is_empty():
		return Vector2i(-1, -1)
	return cells[randi() % cells.size()]

func get_grid_pixel_size() -> Vector2:
	return Vector2(GRID_SIZE) * CELL_SIZE

func count_resources_in_zone(zone: Zone) -> int:
	var count = 0
	for x in GRID_SIZE.x:
		for y in GRID_SIZE.y:
			if grid_zones[x][y] == zone and grid_resources[x][y] != null:
				count += 1
	return count

func get_unlockable_zones() -> Array[Zone]:
	var zones: Array[Zone] = []
	for zone in [Zone.CAVE, Zone.CRYSTAL, Zone.VOLCANO, Zone.ABYSS]:
		if not unlocked_zones.get(zone, false):
			zones.append(zone)
	return zones
