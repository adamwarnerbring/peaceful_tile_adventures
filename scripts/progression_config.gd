class_name ProgressionConfig
extends Resource
## Configuration for stage-based progression system

# Stage configuration class
class StageConfig:
	var stage_index: int
	var stage_name: String
	var grid_size: Vector2i
	var max_tier: int = 11  # Highest tier required to unlock next stage
	var difficulty_multiplier: float = 1.0  # Base difficulty multiplier for this stage
	var zone_price_multiplier: float = 1.0  # Multiplier for zone unlock prices
	var bot_price_multiplier: float = 1.0  # Multiplier for bot prices
	var merge_requirement_multiplier: float = 1.0  # Optional: multiplier for merge requirements
	var spawn_rate_multiplier: float = 1.0  # Optional: multiplier for resource spawn rates (lower = slower)
	
	func _init(p_stage_index: int = 0, p_stage_name: String = "", p_grid_size: Vector2i = Vector2i(20, 32)):
		stage_index = p_stage_index
		stage_name = p_stage_name
		grid_size = p_grid_size

# All stage configurations
@export var stages: Array[Dictionary] = []

func _init():
	# Initialize default stages if not set
	if stages.is_empty():
		stages = _get_default_stages()

static func get_default_config() -> ProgressionConfig:
	var config = ProgressionConfig.new()
	config.stages = _get_default_stages()
	return config

static func _get_default_stages() -> Array[Dictionary]:
	var stage_configs: Array[Dictionary] = []
	
	# Stage 0: Area (starting stage)
	stage_configs.append({
		"stage_index": 0,
		"stage_name": "Area",
		"grid_size": Vector2i(20, 32),
		"max_tier": 4,
		"difficulty_multiplier": 1.0,
		"zone_price_multiplier": 1.0,
		"bot_price_multiplier": 1.0,
		"merge_requirement_multiplier": 1.0,
		"spawn_rate_multiplier": 1.0,
	})
	
	# Stage 1: River
	stage_configs.append({
		"stage_index": 1,
		"stage_name": "River",
		"grid_size": Vector2i(24, 38),
		"max_tier": 5,
		"difficulty_multiplier": 1.5,
		"zone_price_multiplier": 1.5,
		"bot_price_multiplier": 1.5,
		"merge_requirement_multiplier": 1.0,
		"spawn_rate_multiplier": 0.95,  # Slightly slower spawns
	})
	
	# Stage 2: Valley
	stage_configs.append({
		"stage_index": 2,
		"stage_name": "Valley",
		"grid_size": Vector2i(28, 44),
		"max_tier": 6,
		"difficulty_multiplier": 2.0,
		"zone_price_multiplier": 2.0,
		"bot_price_multiplier": 2.0,
		"merge_requirement_multiplier": 1.0,
		"spawn_rate_multiplier": 0.9,
	})
	
	# Stage 3: Region
	stage_configs.append({
		"stage_index": 3,
		"stage_name": "Region",
		"grid_size": Vector2i(32, 50),
		"max_tier": 11,
		"difficulty_multiplier": 2.5,
		"zone_price_multiplier": 2.5,
		"bot_price_multiplier": 2.5,
		"merge_requirement_multiplier": 1.0,
		"spawn_rate_multiplier": 0.85,
	})
	
	# Stage 4: Country
	stage_configs.append({
		"stage_index": 4,
		"stage_name": "Country",
		"grid_size": Vector2i(36, 56),
		"max_tier": 11,
		"difficulty_multiplier": 3.0,
		"zone_price_multiplier": 3.0,
		"bot_price_multiplier": 3.0,
		"merge_requirement_multiplier": 1.0,
		"spawn_rate_multiplier": 0.8,
	})
	
	# Stage 5: Continent
	stage_configs.append({
		"stage_index": 5,
		"stage_name": "Continent",
		"grid_size": Vector2i(40, 64),
		"max_tier": 11,
		"difficulty_multiplier": 4.0,
		"zone_price_multiplier": 4.0,
		"bot_price_multiplier": 4.0,
		"merge_requirement_multiplier": 1.0,
		"spawn_rate_multiplier": 0.75,
	})
	
	# Stage 6: World
	stage_configs.append({
		"stage_index": 6,
		"stage_name": "World",
		"grid_size": Vector2i(44, 72),
		"max_tier": 11,
		"difficulty_multiplier": 5.0,
		"zone_price_multiplier": 5.0,
		"bot_price_multiplier": 5.0,
		"merge_requirement_multiplier": 1.0,
		"spawn_rate_multiplier": 0.7,
	})
	
	# Stage 7: Space (final stage)
	stage_configs.append({
		"stage_index": 7,
		"stage_name": "Space",
		"grid_size": Vector2i(48, 80),
		"max_tier": 11,
		"difficulty_multiplier": 6.0,
		"zone_price_multiplier": 6.0,
		"bot_price_multiplier": 6.0,
		"merge_requirement_multiplier": 1.0,
		"spawn_rate_multiplier": 0.65,
	})
	
	return stage_configs

# Get stage config by index
func get_stage_config(stage_index: int) -> Dictionary:
	for stage in stages:
		if stage.get("stage_index") == stage_index:
			return stage
	return {}

# Get stage config by name
func get_stage_config_by_name(stage_name: String) -> Dictionary:
	for stage in stages:
		if stage.get("stage_name") == stage_name:
			return stage
	return {}

# Get current stage config (for stage_index)
func get_current_stage_config(current_stage: int) -> Dictionary:
	return get_stage_config(current_stage)

# Get next stage config
func get_next_stage_config(current_stage: int) -> Dictionary:
	return get_stage_config(current_stage + 1)

# Check if next stage exists
func has_next_stage(current_stage: int) -> bool:
	return get_next_stage_config(current_stage) != {}

# Get total number of stages
func get_total_stages() -> int:
	return stages.size()

# Get stage name by index
func get_stage_name(stage_index: int) -> String:
	var config = get_stage_config(stage_index)
	return config.get("stage_name", "Unknown")

# Apply zone price multiplier
func get_zone_price(base_price: int, stage_index: int) -> int:
	var config = get_stage_config(stage_index)
	var multiplier = config.get("zone_price_multiplier", 1.0)
	return int(base_price * multiplier)

# Apply bot price multiplier
func get_bot_price(base_price: int, stage_index: int) -> int:
	var config = get_stage_config(stage_index)
	var multiplier = config.get("bot_price_multiplier", 1.0)
	return int(base_price * multiplier)

# Get max tier required for stage
func get_max_tier(stage_index: int) -> int:
	var config = get_stage_config(stage_index)
	return config.get("max_tier", 11)

# Get difficulty multiplier
func get_difficulty_multiplier(stage_index: int) -> float:
	var config = get_stage_config(stage_index)
	return config.get("difficulty_multiplier", 1.0)

# Get spawn rate multiplier
func get_spawn_rate_multiplier(stage_index: int) -> float:
	var config = get_stage_config(stage_index)
	return config.get("spawn_rate_multiplier", 1.0)

# Get merge requirement multiplier
func get_merge_requirement_multiplier(stage_index: int) -> float:
	var config = get_stage_config(stage_index)
	return config.get("merge_requirement_multiplier", 1.0)

# Get grid size for stage
func get_grid_size(stage_index: int) -> Vector2i:
	var config = get_stage_config(stage_index)
	return config.get("grid_size", Vector2i(20, 32))

