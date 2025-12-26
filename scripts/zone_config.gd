class_name ZoneConfig
extends Resource
## Configuration for zone shapes and properties

# Zone shape types
enum ShapeType {
	 CIRCLE,      # Simple circular zone
	 RECTANGLE,   # Rectangular zone
	 POLYGON,     # Custom polygon
	 DISTANCE_LAYERS  # Multiple distance-based layers (current system)
}

# A single zone definition
class ZoneDef:
	var zone_id: int  # Maps to TileGrid.Zone enum
	var zone_name: String
	var zone_colors: Array = []  # [dark, light] - Array of Color
	var zone_tiers: Array = []  # [min, max] tier range - Array of int
	var base_price: int = 100
	var shape_type: ShapeType = ShapeType.DISTANCE_LAYERS
	var shape_data: Dictionary = {}  # Shape-specific parameters
	
	func _init():
		pass

# Get zone configuration for a stage (checks for saved files first, then defaults)
static func get_zones_for_stage(stage_name: String) -> Array:
	# Try to load from saved file first
	var saved_zones = _load_zones_from_file(stage_name)
	if saved_zones.size() > 0:
		return saved_zones
	
	# Fall back to default zones
	return _get_default_zones_for_stage(stage_name)

static func _get_default_zones_for_stage(stage_name: String) -> Array:
	var result: Array = []
	
	match stage_name:
		"Area":
			result = _get_area_zones()
		"River":
			result = _get_river_zones()
		"Valley":
			result = _get_valley_zones()
		"Region":
			result = _get_region_zones()
		"Country":
			result = _get_country_zones()
		"Continent":
			result = _get_continent_zones()
		"World":
			result = _get_world_zones()
		"Space":
			result = _get_space_zones()
		_:
			result = _get_area_zones()
	
	return result

static func _get_area_zones() -> Array:
	var zones: Array = []
	
	# Zone 1: Forest (distance layer)
	var forest = ZoneDef.new()
	forest.zone_id = TileGrid.Zone.FOREST
	forest.zone_name = "Forest"
	forest.zone_colors = [Color("#14532d"), Color("#166534")]
	forest.zone_tiers = [0, 1]
	forest.base_price = 0  # Free
	forest.shape_type = ZoneConfig.ShapeType.DISTANCE_LAYERS
	forest.shape_data = {"min_dist": 5.0, "max_dist": 8.0}  # In base grid units (20x32)
	zones.append(forest)
	
	# Zone 2: Cave
	var cave = ZoneDef.new()
	cave.zone_id = TileGrid.Zone.CAVE
	cave.zone_name = "Cave"
	cave.zone_colors = [Color("#3b0764"), Color("#4c1d95")]
	cave.zone_tiers = [1, 2]
	cave.base_price = 100
	cave.shape_type = ZoneConfig.ShapeType.DISTANCE_LAYERS
	cave.shape_data = {"min_dist": 8.0, "max_dist": 12.0}
	zones.append(cave)
	
	# Zone 3: Crystal Mine
	var crystal = ZoneDef.new()
	crystal.zone_id = TileGrid.Zone.CRYSTAL
	crystal.zone_name = "Crystal Mine"
	crystal.zone_colors = [Color("#083344"), Color("#0e4f66")]
	crystal.zone_tiers = [2, 3]
	crystal.base_price = 500
	crystal.shape_type = ZoneConfig.ShapeType.DISTANCE_LAYERS
	crystal.shape_data = {"min_dist": 12.0, "max_dist": 16.0}
	zones.append(crystal)
	
	# Zone 4: Volcano
	var volcano = ZoneDef.new()
	volcano.zone_id = TileGrid.Zone.VOLCANO
	volcano.zone_name = "Volcano"
	volcano.zone_colors = [Color("#7f1d1d"), Color("#991b1b")]
	volcano.zone_tiers = [3, 4]
	volcano.base_price = 2000
	volcano.shape_type = ZoneConfig.ShapeType.DISTANCE_LAYERS
	volcano.shape_data = {"min_dist": 16.0, "max_dist": 20.0}
	zones.append(volcano)
	
	# Zone 5: Abyss
	var abyss = ZoneDef.new()
	abyss.zone_id = TileGrid.Zone.ABYSS
	abyss.zone_name = "Abyss"
	abyss.zone_colors = [Color("#1a1a2e"), Color("#16213e")]
	abyss.zone_tiers = [4, 4]
	abyss.base_price = 8000
	abyss.shape_type = ZoneConfig.ShapeType.DISTANCE_LAYERS
	abyss.shape_data = {"min_dist": 20.0, "max_dist": 999.0}
	zones.append(abyss)
	
	return zones

static func _get_river_zones() -> Array:
	var zones: Array = []
	
	var stream = ZoneDef.new()
	stream.zone_id = TileGrid.Zone.FOREST
	stream.zone_name = "Stream"
	stream.zone_colors = [Color("#0ea5e9"), Color("#0284c7")]
	stream.zone_tiers = [0, 1]
	stream.base_price = 0
	stream.shape_type = ZoneConfig.ShapeType.DISTANCE_LAYERS
	stream.shape_data = {"min_dist": 5.0, "max_dist": 8.0}
	zones.append(stream)
	
	var hills = ZoneDef.new()
	hills.zone_id = TileGrid.Zone.CAVE
	hills.zone_name = "Hills"
	hills.zone_colors = [Color("#78716c"), Color("#57534e")]
	hills.zone_tiers = [1, 2]
	hills.base_price = 100
	hills.shape_type = ZoneConfig.ShapeType.DISTANCE_LAYERS
	hills.shape_data = {"min_dist": 8.0, "max_dist": 12.0}
	zones.append(hills)
	
	var forest = ZoneDef.new()
	forest.zone_id = TileGrid.Zone.CRYSTAL
	forest.zone_name = "Deep Forest"
	forest.zone_colors = [Color("#14532d"), Color("#166534")]
	forest.zone_tiers = [2, 3]
	forest.base_price = 500
	forest.shape_type = ZoneConfig.ShapeType.DISTANCE_LAYERS
	forest.shape_data = {"min_dist": 12.0, "max_dist": 16.0}
	zones.append(forest)
	
	var mountains = ZoneDef.new()
	mountains.zone_id = TileGrid.Zone.VOLCANO
	mountains.zone_name = "Mountains"
	mountains.zone_colors = [Color("#64748b"), Color("#475569")]
	mountains.zone_tiers = [3, 4]
	mountains.base_price = 2000
	mountains.shape_type = ZoneConfig.ShapeType.DISTANCE_LAYERS
	mountains.shape_data = {"min_dist": 16.0, "max_dist": 20.0}
	zones.append(mountains)
	
	var peaks = ZoneDef.new()
	peaks.zone_id = TileGrid.Zone.ABYSS
	peaks.zone_name = "Peaks"
	peaks.zone_colors = [Color("#e2e8f0"), Color("#cbd5e1")]
	peaks.zone_tiers = [4, 4]
	peaks.base_price = 8000
	peaks.shape_type = ZoneConfig.ShapeType.DISTANCE_LAYERS
	peaks.shape_data = {"min_dist": 20.0, "max_dist": 999.0}
	zones.append(peaks)
	
	return zones

static func _get_space_zones() -> Array:
	var zones: Array = []
	
	var moon = ZoneDef.new()
	moon.zone_id = TileGrid.Zone.FOREST
	moon.zone_name = "Moon"
	moon.zone_colors = [Color("#e2e8f0"), Color("#cbd5e1")]
	moon.zone_tiers = [0, 1]
	moon.base_price = 0
	moon.shape_type = ZoneConfig.ShapeType.DISTANCE_LAYERS
	moon.shape_data = {"min_dist": 5.0, "max_dist": 8.0}
	zones.append(moon)
	
	var mars = ZoneDef.new()
	mars.zone_id = TileGrid.Zone.CAVE
	mars.zone_name = "Mars"
	mars.zone_colors = [Color("#dc2626"), Color("#b91c1c")]
	mars.zone_tiers = [1, 2]
	mars.base_price = 100
	mars.shape_type = ZoneConfig.ShapeType.DISTANCE_LAYERS
	mars.shape_data = {"min_dist": 8.0, "max_dist": 12.0}
	zones.append(mars)
	
	var jupiter = ZoneDef.new()
	jupiter.zone_id = TileGrid.Zone.CRYSTAL
	jupiter.zone_name = "Jupiter"
	jupiter.zone_colors = [Color("#f59e0b"), Color("#d97706")]
	jupiter.zone_tiers = [2, 3]
	jupiter.base_price = 500
	jupiter.shape_type = ZoneConfig.ShapeType.DISTANCE_LAYERS
	jupiter.shape_data = {"min_dist": 12.0, "max_dist": 16.0}
	zones.append(jupiter)
	
	var saturn = ZoneDef.new()
	saturn.zone_id = TileGrid.Zone.VOLCANO
	saturn.zone_name = "Saturn"
	saturn.zone_colors = [Color("#fbbf24"), Color("#f59e0b")]
	saturn.zone_tiers = [3, 4]
	saturn.base_price = 2000
	saturn.shape_type = ZoneConfig.ShapeType.DISTANCE_LAYERS
	saturn.shape_data = {"min_dist": 16.0, "max_dist": 20.0}
	zones.append(saturn)
	
	var nebula = ZoneDef.new()
	nebula.zone_id = TileGrid.Zone.ABYSS
	nebula.zone_name = "Nebula"
	nebula.zone_colors = [Color("#a855f7"), Color("#9333ea")]
	nebula.zone_tiers = [4, 4]
	nebula.base_price = 8000
	nebula.shape_type = ZoneConfig.ShapeType.DISTANCE_LAYERS
	nebula.shape_data = {"min_dist": 20.0, "max_dist": 999.0}
	zones.append(nebula)
	
	return zones

static func _get_valley_zones() -> Array:
	# Example: Mix of distance layers and rectangular zones
	var zones: Array = []
	
	var stream = ZoneDef.new()
	stream.zone_id = TileGrid.Zone.FOREST
	stream.zone_name = "Stream"
	stream.zone_colors = [Color("#0ea5e9"), Color("#0284c7")]
	stream.zone_tiers = [0, 1]
	stream.base_price = 0
	stream.shape_type = ZoneConfig.ShapeType.DISTANCE_LAYERS
	stream.shape_data = {"min_dist": 5.0, "max_dist": 8.0}
	zones.append(stream)
	
	# Example: Rectangular valley floor
	var valley_floor = ZoneDef.new()
	valley_floor.zone_id = TileGrid.Zone.CAVE
	valley_floor.zone_name = "Valley Floor"
	valley_floor.zone_colors = [Color("#78716c"), Color("#57534e")]
	valley_floor.zone_tiers = [1, 2]
	valley_floor.base_price = 100
	valley_floor.shape_type = ZoneConfig.ShapeType.RECTANGLE
	# Rectangle in base grid units: x, y, width, height
	valley_floor.shape_data = {
		"rect": {
			"x": 3.0,      # Left edge
			"y": 12.0,     # Top edge
			"width": 14.0, # Width
			"height": 10.0 # Height
		}
	}
	zones.append(valley_floor)
	
	# Continue with other zones...
	var mountains = ZoneDef.new()
	mountains.zone_id = TileGrid.Zone.CRYSTAL
	mountains.zone_name = "Mountains"
	mountains.zone_colors = [Color("#64748b"), Color("#475569")]
	mountains.zone_tiers = [2, 3]
	mountains.base_price = 500
	mountains.shape_type = ZoneConfig.ShapeType.DISTANCE_LAYERS
	mountains.shape_data = {"min_dist": 12.0, "max_dist": 999.0}
	zones.append(mountains)
	
	return zones

static func _get_region_zones() -> Array:
	# Example: Using polygon shapes for irregular regions
	var zones: Array = []
	
	var plains = ZoneDef.new()
	plains.zone_id = TileGrid.Zone.FOREST
	plains.zone_name = "Plains"
	plains.zone_colors = [Color("#84cc16"), Color("#65a30d")]
	plains.zone_tiers = [0, 1]
	plains.base_price = 0
	plains.shape_type = ZoneConfig.ShapeType.DISTANCE_LAYERS
	plains.shape_data = {"min_dist": 5.0, "max_dist": 8.0}
	zones.append(plains)
	
	# Example: Polygon-shaped forest region
	var forest_region = ZoneDef.new()
	forest_region.zone_id = TileGrid.Zone.CAVE
	forest_region.zone_name = "Forest Region"
	forest_region.zone_colors = [Color("#14532d"), Color("#166534")]
	forest_region.zone_tiers = [1, 2]
	forest_region.base_price = 100
	forest_region.shape_type = ZoneConfig.ShapeType.POLYGON
	# Polygon points in base grid units (relative to base grid)
	forest_region.shape_data = {
		"points": [
			Vector2(5, 8),   # Top-left
			Vector2(12, 6),  # Top-center
			Vector2(15, 10), # Top-right
			Vector2(18, 15), # Right
			Vector2(14, 20), # Bottom-right
			Vector2(8, 22),  # Bottom-center
			Vector2(3, 18),  # Bottom-left
			Vector2(2, 12)   # Left
		]
	}
	zones.append(forest_region)
	
	# Example: Circular mountain area
	var mountains = ZoneDef.new()
	mountains.zone_id = TileGrid.Zone.CRYSTAL
	mountains.zone_name = "Mountain Range"
	mountains.zone_colors = [Color("#64748b"), Color("#475569")]
	mountains.zone_tiers = [2, 3]
	mountains.base_price = 500
	mountains.shape_type = ZoneConfig.ShapeType.CIRCLE
	mountains.shape_data = {
		"center": Vector2(15, 10),  # Center in base grid units
		"radius": 6.0                # Radius in base grid units
	}
	zones.append(mountains)
	
	var desert = ZoneDef.new()
	desert.zone_id = TileGrid.Zone.VOLCANO
	desert.zone_name = "Desert"
	desert.zone_colors = [Color("#fbbf24"), Color("#f59e0b")]
	desert.zone_tiers = [3, 4]
	desert.base_price = 2000
	desert.shape_type = ZoneConfig.ShapeType.DISTANCE_LAYERS
	desert.shape_data = {"min_dist": 16.0, "max_dist": 999.0}
	zones.append(desert)
	
	return zones

static func _get_country_zones() -> Array:
	return _get_area_zones()  # TODO: Customize with complex shapes

static func _get_continent_zones() -> Array:
	return _get_area_zones()  # TODO: Customize with complex shapes

static func _get_world_zones() -> Array:
	return _get_area_zones()  # TODO: Customize with complex shapes

# Load zones from saved JSON file
static func _load_zones_from_file(stage_name: String) -> Array:
	var file_path = "res://zone_configs/" + stage_name.to_lower() + "_zones.json"
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return []
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		print("Error parsing zone file: ", file_path, " - ", error)
		return []
	
	var save_data = json.data as Dictionary
	var zones: Array = []
	
	for zone_dict in save_data.get("zones", []):
		var zone_def = ZoneDef.new()
		zone_def.zone_id = zone_dict.get("zone_id", 0)
		zone_def.zone_name = zone_dict.get("zone_name", "")
		
		# Load colors
		var color_strings = zone_dict.get("zone_colors", [])
		if color_strings.size() >= 2:
			zone_def.zone_colors = [Color(color_strings[0]), Color(color_strings[1])]
		else:
			zone_def.zone_colors = [Color.WHITE, Color.WHITE]
		
		zone_def.zone_tiers = zone_dict.get("zone_tiers", [0, 1])
		zone_def.base_price = zone_dict.get("base_price", 100)
		zone_def.shape_type = zone_dict.get("shape_type", ShapeType.DISTANCE_LAYERS)
		
		# Load shape data and convert Vector2 dictionaries back to Vector2
		var shape_data = zone_dict.get("shape_data", {})
		if shape_data.has("points"):
			# Convert point dictionaries to Vector2
			var points = []
			for point_dict in shape_data.points:
				if point_dict is Dictionary:
					points.append(Vector2(point_dict.get("x", 0.0), point_dict.get("y", 0.0)))
				else:
					points.append(point_dict as Vector2)
			shape_data["points"] = points
		
		if shape_data.has("center"):
			var center = shape_data.center
			if center is Dictionary:
				shape_data["center"] = Vector2(center.get("x", 0.0), center.get("y", 0.0))
		
		zone_def.shape_data = shape_data
		zones.append(zone_def)
	
	return zones
