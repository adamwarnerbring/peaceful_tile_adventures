class_name MapLevel
extends Node2D
## Manages a single map level with its own grid, zones, and resources

signal level_unlocked

var level_index: int = 0
var grid_size: Vector2i = Vector2i(20, 32)
var cell_size: float = 32.0
var zoom_factor: float = 1.0  # How much this level is zoomed (1.0 = full size, 0.5 = half size)
var is_unlocked: bool = false

# Level-specific data
var tile_grid: TileGrid
var unlocked_zones: Dictionary = {}
var bot_counts: Dictionary = {}
var bot_prices: Dictionary = {}

# Zone unlock order for this level
var zone_unlock_order: Array[TileGrid.Zone] = [
	TileGrid.Zone.CAVE,
	TileGrid.Zone.CRYSTAL,
	TileGrid.Zone.VOLCANO,
	TileGrid.Zone.ABYSS
]

# Resource tier range for this level
var min_tier: int = 0
var max_tier: int = 5

func _ready() -> void:
	# Initialize unlocked zones (BASE and FOREST always unlocked)
	unlocked_zones[TileGrid.Zone.BASE] = true
	unlocked_zones[TileGrid.Zone.FOREST] = true
	unlocked_zones[TileGrid.Zone.CAVE] = false
	unlocked_zones[TileGrid.Zone.CRYSTAL] = false
	unlocked_zones[TileGrid.Zone.VOLCANO] = false
	unlocked_zones[TileGrid.Zone.ABYSS] = false
	
	# Initialize bot counts
	for zone in [TileGrid.Zone.FOREST, TileGrid.Zone.CAVE, TileGrid.Zone.CRYSTAL, TileGrid.Zone.VOLCANO, TileGrid.Zone.ABYSS]:
		bot_counts[zone] = 0
	
	# Initialize bot prices (scaled by level)
	var base_prices = {
		TileGrid.Zone.FOREST: 50,
		TileGrid.Zone.CAVE: 200,
		TileGrid.Zone.CRYSTAL: 600,
		TileGrid.Zone.VOLCANO: 1500,
		TileGrid.Zone.ABYSS: 4000,
	}
	var price_multiplier = pow(5.0, level_index)  # 5x per level
	for zone in base_prices:
		bot_prices[zone] = int(base_prices[zone] * price_multiplier)

func unlock() -> void:
	if is_unlocked:
		return
	is_unlocked = true
	level_unlocked.emit()

func unlock_zone(zone: TileGrid.Zone) -> bool:
	if unlocked_zones.get(zone, false):
		return false
	unlocked_zones[zone] = true
	if tile_grid:
		tile_grid.unlock_zone(zone)
	return true

func is_zone_unlocked(zone: TileGrid.Zone) -> bool:
	return unlocked_zones.get(zone, false)

func get_zone_price(zone: TileGrid.Zone) -> int:
	# Base prices scaled by level
	var base_prices = {
		TileGrid.Zone.CAVE: 100,
		TileGrid.Zone.CRYSTAL: 500,
		TileGrid.Zone.VOLCANO: 2000,
		TileGrid.Zone.ABYSS: 8000,
	}
	var price_multiplier = pow(5.0, level_index)  # 5x per level
	return int(base_prices.get(zone, 0) * price_multiplier)

func get_resource_tier_range() -> Array[int]:
	return [min_tier, max_tier]

func get_spawn_tier() -> int:
	# Spawn a random tier within this level's range
	return randi_range(min_tier, max_tier)

