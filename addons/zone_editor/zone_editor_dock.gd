@tool
extends Control
## Visual zone editor dock for drawing zones in the editor

var zone_canvas: Control
var stage_select: OptionButton
var zone_select: OptionButton
var save_btn: Button
var load_btn: Button
var clear_btn: Button
var status_label: Label

const BASE_CELL_SIZE = 32.0  # Base cell size in pixels (matches tile_grid)
const BASE_GRID_SIZE = Vector2i(20, 32)  # Reference grid size
const EDITOR_CELL_SIZE = 16.0  # Cell size in editor (smaller to fit more on screen)
const BASE_RADIUS = 4.5  # Base radius in cells (matches tile_grid)
const ZONE_COLORS = [
	Color("#14532d"),  # FOREST - Green
	Color("#3b0764"),  # CAVE - Purple
	Color("#083344"),  # CRYSTAL - Blue
	Color("#7f1d1d"),  # VOLCANO - Red
	Color("#1a1a2e"),  # ABYSS - Dark
]

var current_stage: String = "Area"
var current_zone: int = 0  # TileGrid.Zone enum value
var current_zone_configs: Array = []  # Array of ZoneConfig.ZoneDef
var drawing_polygon: bool = false
var polygon_points: Array[Vector2] = []
var editor_plugin: EditorPlugin

# For dragging polygon points
var dragging_point: bool = false
var dragged_zone_def: ZoneConfig.ZoneDef = null
var dragged_point_index: int = -1
var current_grid_size: Vector2i = Vector2i(20, 32)

func _ready():
	# Get node references
	zone_canvas = $VBox/ZoneCanvas
	stage_select = $VBox/Toolbar/StageSelect
	zone_select = $VBox/Toolbar/ZoneSelect
	save_btn = $VBox/Toolbar/SaveBtn
	load_btn = $VBox/Toolbar/LoadBtn
	clear_btn = $VBox/Toolbar/ClearBtn
	status_label = $VBox/StatusLabel
	
	# Setup stage selector
	stage_select.add_item("Area")
	stage_select.add_item("River")
	stage_select.add_item("Valley")
	stage_select.add_item("Region")
	stage_select.add_item("Country")
	stage_select.add_item("Continent")
	stage_select.add_item("World")
	stage_select.add_item("Space")
	stage_select.selected = 0
	
	# Setup zone selector
	zone_select.add_item("Forest")
	zone_select.add_item("Cave")
	zone_select.add_item("Crystal")
	zone_select.add_item("Volcano")
	zone_select.add_item("Abyss")
	zone_select.selected = 0
	
	# Connect signals
	stage_select.item_selected.connect(_on_stage_selected)
	zone_select.item_selected.connect(_on_zone_selected)
	save_btn.pressed.connect(_on_save)
	load_btn.pressed.connect(_on_load)
	clear_btn.pressed.connect(_on_clear)
	
	# Setup canvas - needs mouse input for dragging
	zone_canvas.mouse_filter = Control.MOUSE_FILTER_STOP  # Enable mouse input
	zone_canvas.canvas_clicked.connect(_on_canvas_clicked)
	zone_canvas.canvas_mouse_released.connect(_on_canvas_mouse_released)
	zone_canvas.canvas_right_clicked.connect(_on_canvas_right_clicked)
	zone_canvas.set_draw_callback(_draw_canvas)
	
	# Connect mouse events for dragging
	zone_canvas.mouse_entered.connect(_on_canvas_mouse_entered)
	zone_canvas.mouse_exited.connect(_on_canvas_mouse_exited)
	zone_canvas.canvas_mouse_motion.connect(_on_canvas_mouse_motion)
	
	# Start with empty zones and update stage
	_on_stage_selected(0)

func set_editor(plugin: EditorPlugin):
	editor_plugin = plugin

func _on_stage_selected(index: int):
	current_stage = stage_select.get_item_text(index)
	
	# Get grid size for this stage from ProgressionConfig
	var config = ProgressionConfig.get_default_config()
	var stage_config = config.get_stage_config(index)
	current_grid_size = stage_config.get("grid_size", Vector2i(20, 32))
	
	# Update canvas size to match stage grid
	zone_canvas.custom_minimum_size = Vector2(
		current_grid_size.x * EDITOR_CELL_SIZE,
		current_grid_size.y * EDITOR_CELL_SIZE
	)
	
	# Start with empty zones (no defaults)
	current_zone_configs.clear()
	polygon_points.clear()
	drawing_polygon = false
	status_label.text = "Stage: " + current_stage + " (" + str(current_grid_size.x) + "x" + str(current_grid_size.y) + ") - Start drawing zones!"
	_update_canvas()

func _on_zone_selected(index: int):
	current_zone = index  # Maps to TileGrid.Zone enum
	# Cancel any drawing when switching zones
	polygon_points.clear()
	drawing_polygon = false
	status_label.text = "Selected zone: " + zone_select.get_item_text(index) + " - Click to add polygon points"
	zone_canvas.queue_redraw()

func _update_canvas():
	if zone_canvas:
		zone_canvas.queue_redraw()

func _on_canvas_clicked(pos: Vector2, button: int):
	if button == MOUSE_BUTTON_LEFT:
		_handle_canvas_click(pos)

func _on_canvas_right_clicked(pos: Vector2):
	_handle_canvas_right_click(pos)

func _handle_canvas_click(pos: Vector2):
	var grid_pos = _pixel_to_grid(pos)
	
	# Don't start drawing if we're already dragging (wait for release)
	if dragging_point:
		return
	
	# Check if clicking on an existing polygon point to start dragging
	var clicked_point = _get_point_at_position(grid_pos)
	if clicked_point.zone_def != null and clicked_point.point_index >= 0:
		# Start dragging this point
		dragging_point = true
		dragged_zone_def = clicked_point.zone_def
		dragged_point_index = clicked_point.point_index
		status_label.text = "Dragging point " + str(dragged_point_index) + " - drag to move, release to finish"
		return
	
	# If drawing new polygon, add point
	if drawing_polygon:
		polygon_points.append(grid_pos)
		status_label.text = "Polygon: " + str(polygon_points.size()) + " points. Right-click to finish."
		_update_canvas()
	else:
		# Start new polygon for current zone
		drawing_polygon = true
		polygon_points.clear()
		polygon_points.append(grid_pos)
		status_label.text = "Polygon: 1 point. Add more points, then right-click to finish."
		_update_canvas()

func _on_canvas_mouse_released(pos: Vector2):
	# Finish dragging when mouse button is released
	if dragging_point and dragged_zone_def != null:
		var grid_pos = _pixel_to_grid(pos)
		var points = dragged_zone_def.shape_data.get("points", [])
		if dragged_point_index >= 0 and dragged_point_index < points.size():
			points[dragged_point_index] = grid_pos
			dragged_zone_def.shape_data["points"] = points
			_update_canvas()
		dragging_point = false
		dragged_zone_def = null
		dragged_point_index = -1
		status_label.text = "Finished dragging point"

func _on_canvas_mouse_motion(pos: Vector2):
	# Update dragged point position while dragging
	if dragging_point and dragged_zone_def != null and dragged_point_index >= 0:
		var grid_pos = _pixel_to_grid(pos)
		var points = dragged_zone_def.shape_data.get("points", [])
		if dragged_point_index < points.size():
			points[dragged_point_index] = grid_pos
			dragged_zone_def.shape_data["points"] = points
			_update_canvas()

func _handle_canvas_right_click(pos: Vector2):
	if drawing_polygon and polygon_points.size() >= 3:
		# Finish polygon
		_create_polygon_zone()
		polygon_points.clear()
		drawing_polygon = false
	elif drawing_polygon:
		# Cancel polygon
		polygon_points.clear()
		drawing_polygon = false
		status_label.text = "Cancelled polygon drawing."
		_update_canvas()

func _on_canvas_mouse_entered():
	zone_canvas.mouse_filter = Control.MOUSE_FILTER_STOP

func _on_canvas_mouse_exited():
	# Stop dragging if mouse leaves
	if dragging_point:
		dragging_point = false
		dragged_zone_def = null
		dragged_point_index = -1
	zone_canvas.queue_redraw()

# Check if a grid position is near an existing polygon point (within 1 cell)
func _get_point_at_position(grid_pos: Vector2) -> Dictionary:
	var POINT_SNAP_DISTANCE = 1.0  # Within 1 grid cell
	
	for zone_def in current_zone_configs:
		if zone_def.shape_type == ZoneConfig.ShapeType.POLYGON:
			var points = zone_def.shape_data.get("points", [])
			for i in range(points.size()):
				var point = points[i] as Vector2
				if grid_pos.distance_to(point) <= POINT_SNAP_DISTANCE:
					return {"zone_def": zone_def, "point_index": i}
	
	return {"zone_def": null, "point_index": -1}

func _create_polygon_zone():
	if polygon_points.size() < 3:
		status_label.text = "Error: Polygon needs at least 3 points!"
		return
	
	# Find or create zone def for current zone
	var zone_def = _get_or_create_zone_def(current_zone)
	zone_def.shape_type = ZoneConfig.ShapeType.POLYGON
	zone_def.shape_data = {"points": polygon_points.duplicate()}
	
	status_label.text = "Created polygon zone with " + str(polygon_points.size()) + " points! Click and drag points to edit."
	_update_canvas()

func _get_or_create_zone_def(zone_enum: int) -> ZoneConfig.ZoneDef:
	# Find existing zone def
	for zone_def in current_zone_configs:
		if zone_def.zone_id == zone_enum:
			return zone_def
	
	# Create new zone def
	var zone_def = ZoneConfig.ZoneDef.new()
	zone_def.zone_id = zone_enum
	zone_def.zone_name = zone_select.get_item_text(zone_enum)
	zone_def.zone_colors = [ZONE_COLORS[zone_enum], ZONE_COLORS[zone_enum].lightened(0.2)]
	zone_def.zone_tiers = [0, 1]
	zone_def.base_price = 100
	current_zone_configs.append(zone_def)
	return zone_def

func _pixel_to_grid(pixel: Vector2) -> Vector2:
	# Clamp to grid bounds
	return Vector2(
		clamp(floor(pixel.x / EDITOR_CELL_SIZE), 0, current_grid_size.x - 1),
		clamp(floor(pixel.y / EDITOR_CELL_SIZE), 0, current_grid_size.y - 1)
	)

func _grid_to_pixel(grid: Vector2) -> Vector2:
	return grid * EDITOR_CELL_SIZE

func _draw_canvas(canvas: Control):
	# Draw grid matching current stage grid size
	for x in range(current_grid_size.x + 1):
		var start = Vector2(x * EDITOR_CELL_SIZE, 0)
		var end = Vector2(x * EDITOR_CELL_SIZE, current_grid_size.y * EDITOR_CELL_SIZE)
		canvas.draw_line(start, end, Color(0.3, 0.3, 0.3, 0.5), 1.0)
	
	for y in range(current_grid_size.y + 1):
		var start = Vector2(0, y * EDITOR_CELL_SIZE)
		var end = Vector2(current_grid_size.x * EDITOR_CELL_SIZE, y * EDITOR_CELL_SIZE)
		canvas.draw_line(start, end, Color(0.3, 0.3, 0.3, 0.5), 1.0)
	
	# Draw base center (matches tile_grid calculation: x/2, y*0.875)
	var base_center_x = int(current_grid_size.x / 2.0)
	var base_center_y = int(current_grid_size.y * 0.875)
	var base_center = Vector2(base_center_x, base_center_y)
	var base_pixel = _grid_to_pixel(base_center)
	var base_radius_pixels = BASE_RADIUS * EDITOR_CELL_SIZE
	
	# Draw base area (filled circle)
	canvas.draw_circle(base_pixel, base_radius_pixels, Color("#1e293b", 0.3))
	canvas.draw_circle(base_pixel, base_radius_pixels, Color("#1e293b"), 2.0)
	
	# Draw base center marker
	canvas.draw_circle(base_pixel, 4, Color.WHITE)
	canvas.draw_circle(base_pixel, 3, Color("#1e293b"))
	
	# Draw existing zones (polygons only)
	for zone_def in current_zone_configs:
		_draw_zone(canvas, zone_def)
	
	# Draw current polygon being drawn
	if drawing_polygon and polygon_points.size() > 0:
		var pixel_points = PackedVector2Array()
		for point in polygon_points:
			pixel_points.append(_grid_to_pixel(point))
		
		if pixel_points.size() > 1:
			canvas.draw_polyline(pixel_points, ZONE_COLORS[current_zone], 2.0)
			# Draw line back to first point if 3+ points
			if pixel_points.size() >= 3:
				canvas.draw_line(pixel_points[pixel_points.size() - 1], pixel_points[0], ZONE_COLORS[current_zone], 1.5)
		
		# Draw points
		for point in polygon_points:
			var pixel = _grid_to_pixel(point)
			canvas.draw_circle(pixel, 4, ZONE_COLORS[current_zone])
			canvas.draw_circle(pixel, 2, Color.WHITE)
	
	# Draw all polygon points for editing (with hover indication)
	for zone_def in current_zone_configs:
		if zone_def.shape_type == ZoneConfig.ShapeType.POLYGON:
			var points = zone_def.shape_data.get("points", [])
			var zone_color = ZONE_COLORS[zone_def.zone_id] if zone_def.zone_id < ZONE_COLORS.size() else Color.WHITE
			
			for i in range(points.size()):
				var point = points[i] as Vector2
				var pixel = _grid_to_pixel(point)
				var is_dragging = (dragged_zone_def == zone_def and dragged_point_index == i)
				var point_size = 5 if is_dragging else 3
				canvas.draw_circle(pixel, point_size, zone_color)
				canvas.draw_circle(pixel, point_size - 1, Color.WHITE)
	
	# Draw border to show canvas bounds
	canvas.draw_rect(Rect2(0, 0, canvas.size.x, canvas.size.y), Color(0.5, 0.5, 0.5), false, 1.0)

func _draw_zone(canvas: Control, zone_def: ZoneConfig.ZoneDef):
	if zone_def.shape_type != ZoneConfig.ShapeType.POLYGON:
		return  # Only draw polygons
	
	var color = ZONE_COLORS[zone_def.zone_id] if zone_def.zone_id < ZONE_COLORS.size() else Color.WHITE
	var points = zone_def.shape_data.get("points", [])
	if points.size() >= 3:
		var pixel_points = PackedVector2Array()
		for point in points:
			pixel_points.append(_grid_to_pixel(point as Vector2))
		# Draw filled polygon
		canvas.draw_colored_polygon(pixel_points, color * Color(1, 1, 1, 0.3))
		# Draw polygon outline
		canvas.draw_polyline(pixel_points + PackedVector2Array([pixel_points[0]]), color, 2.0)

func _on_save():
	var file_path = "res://zone_configs/" + current_stage.to_lower() + "_zones.json"
	
	# Create directory if it doesn't exist (only works in editor)
	if Engine.is_editor_hint():
		var dir = DirAccess.open("res://")
		if dir:
			if not dir.dir_exists("zone_configs"):
				dir.make_dir("zone_configs")
	
	# Convert zone configs to dictionary
	var save_data = {
		"stage": current_stage,
		"zones": []
	}
	
	for zone_def in current_zone_configs:
		# Only save polygon zones
		if zone_def.shape_type != ZoneConfig.ShapeType.POLYGON:
			continue
			
		# Convert shape_data, handling Vector2 objects in points array
		var shape_data_dict = {}
		var points = zone_def.shape_data.get("points", [])
		var converted_points = []
		for point in points:
			if point is Vector2:
				converted_points.append({"x": point.x, "y": point.y})
			elif point is Dictionary:
				converted_points.append(point)
			else:
				# Handle case where point might already be a dict
				converted_points.append({"x": float(point.get("x", 0)), "y": float(point.get("y", 0))})
		shape_data_dict["points"] = converted_points
		
		var zone_dict = {
			"zone_id": zone_def.zone_id,
			"zone_name": zone_def.zone_name,
			"zone_colors": [zone_def.zone_colors[0].to_html(), zone_def.zone_colors[1].to_html()] if zone_def.zone_colors.size() >= 2 else [],
			"zone_tiers": zone_def.zone_tiers,
			"base_price": zone_def.base_price,
			"shape_type": ZoneConfig.ShapeType.POLYGON,  # Always POLYGON
			"shape_data": shape_data_dict
		}
		save_data.zones.append(zone_dict)
	
	# Save to file (only works in editor)
	if not Engine.is_editor_hint():
		status_label.text = "Error: Can only save in editor!"
		return
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		status_label.text = "Saved zones to: " + file_path
		# Note: File system will auto-refresh, no manual refresh needed
	else:
		status_label.text = "Error: Could not save file! Check file path: " + file_path

func _on_load():
	var file_path = "res://zone_configs/" + current_stage.to_lower() + "_zones.json"
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		status_label.text = "No saved zones found for " + current_stage
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		status_label.text = "Error parsing JSON: " + str(error)
		return
	
	var save_data = json.data as Dictionary
	current_zone_configs.clear()
	
	for zone_dict in save_data.get("zones", []):
		var zone_def = ZoneConfig.ZoneDef.new()
		zone_def.zone_id = zone_dict.get("zone_id", 0)
		zone_def.zone_name = zone_dict.get("zone_name", "")
		var color_strings = zone_dict.get("zone_colors", [])
		if color_strings.size() >= 2:
			zone_def.zone_colors = [Color(color_strings[0]), Color(color_strings[1])]
		zone_def.zone_tiers = zone_dict.get("zone_tiers", [])
		zone_def.base_price = zone_dict.get("base_price", 100)
		zone_def.shape_type = ZoneConfig.ShapeType.POLYGON  # Always POLYGON
		
		# Convert points from dictionaries to Vector2
		var shape_data_dict = zone_dict.get("shape_data", {})
		var points_array = shape_data_dict.get("points", [])
		var points_vector2 = []
		for point_data in points_array:
			if point_data is Dictionary:
				points_vector2.append(Vector2(float(point_data.get("x", 0)), float(point_data.get("y", 0))))
			elif point_data is Vector2:
				points_vector2.append(point_data)
		zone_def.shape_data = {"points": points_vector2}
		
		current_zone_configs.append(zone_def)
	
	status_label.text = "Loaded " + str(current_zone_configs.size()) + " zones from " + file_path
	_update_canvas()

func _on_clear():
	current_zone_configs.clear()
	polygon_points.clear()
	drawing_polygon = false
	status_label.text = "Cleared all zones. Start drawing new zones."
	_update_canvas()

# Drawing is handled by zone_canvas._draw() via draw_callback

