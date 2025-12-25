class_name GameConfig
extends Resource
## Central configuration file for game settings

@export var resource_spawn_interval: float = 2.5
@export var max_resources_per_zone: int = 8
@export var pickup_distance: float = 25.0
@export var starting_coins: int = 100
@export var starting_max_coins: int = 1000

# Global speed multiplier (0.6 = 60% speed, makes everything slower)
@export var global_speed_multiplier: float = 0.6

# Map scaling
@export var base_grid_size: Vector2i = Vector2i(20, 32)
@export var grid_size_per_upgrade: Vector2i = Vector2i(4, 6)  # How much grid expands per upgrade
@export var max_map_upgrades: int = 10

static func get_default_config() -> GameConfig:
	var config = GameConfig.new()
	# Default values are set in @export above
	return config
