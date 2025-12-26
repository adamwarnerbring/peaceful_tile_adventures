class_name Base
extends Node2D
## Home base area with deposit spots for different resource tiers

signal resource_deposited(tier: int, slot: int)
signal resources_merged(new_tier: int)
signal highest_tier_achieved(tier: int)  # Emitted when a new highest tier is reached

const SLOT_SIZE := 40.0  # Smaller slots to fit more
const SLOTS_PER_ROW := 4
var NUM_SLOTS := 12  # Dynamic based on max_tier (0-11 default)
const SLOT_SPACING := 4.0  # Less spacing
const DEPOSIT_DISTANCE := 35.0

var slot_contents: Array[int] = []
var slot_positions: Array[Vector2] = []

# Merge requirements: tier -> required count
var merge_requirements: Array[int] = []

# Track highest tier achieved (for stage progression)
var max_tier_reached: int = -1

var tier_colors: Array[Color] = [
	Color("#4ade80"), Color("#22d3ee"), Color("#3b82f6"), Color("#a855f7"),
	Color("#f43f5e"), Color("#f97316"), Color("#eab308"), Color("#fafafa"),
	Color("#06b6d4"), Color("#ec4899"), Color("#14b8a6"), Color("#fbbf24"),
]

func _ready() -> void:
	slot_contents.resize(NUM_SLOTS)
	slot_contents.fill(0)
	_init_merge_requirements()
	_calculate_slot_positions()
	queue_redraw()

func _init_merge_requirements() -> void:
	merge_requirements.clear()
	merge_requirements.resize(NUM_SLOTS)
	# Tier 0-1: need 2, Tier 2: need 3, Tier 3: need 4, Tier 4+: need 5
	for i in NUM_SLOTS:
		if i <= 1:
			merge_requirements[i] = 2
		elif i == 2:
			merge_requirements[i] = 3
		elif i == 3:
			merge_requirements[i] = 4
		else:
			merge_requirements[i] = 5

func _calculate_slot_positions() -> void:
	slot_positions.clear()
	var total_width = SLOTS_PER_ROW * SLOT_SIZE + (SLOTS_PER_ROW - 1) * SLOT_SPACING
	var start_x = -total_width / 2 + SLOT_SIZE / 2
	
	var total_rows = ceil(float(NUM_SLOTS) / SLOTS_PER_ROW)
	var total_height = total_rows * SLOT_SIZE + (total_rows - 1) * SLOT_SPACING
	var start_y = -total_height / 2 + SLOT_SIZE / 2
	
	for i in NUM_SLOTS:
		var row = i / SLOTS_PER_ROW
		var col = i % SLOTS_PER_ROW
		var pos = Vector2(
			start_x + col * (SLOT_SIZE + SLOT_SPACING),
			start_y + row * (SLOT_SIZE + SLOT_SPACING)
		)
		slot_positions.append(pos)

func _draw() -> void:
	var total_width = SLOTS_PER_ROW * SLOT_SIZE + (SLOTS_PER_ROW - 1) * SLOT_SPACING + 20
	var total_rows = ceil(float(NUM_SLOTS) / SLOTS_PER_ROW)
	var total_height = total_rows * SLOT_SIZE + (total_rows - 1) * SLOT_SPACING + 20
	var bg_rect = Rect2(-total_width/2, -total_height/2, total_width, total_height)
	
	# Draw base background
	var bg_color = Color("#334155")
	draw_rect(bg_rect, bg_color, false, 4.0)
	draw_rect(bg_rect.grow(-2), Color("#1e293b", 0.95))
	
	# Draw decorative border
	var border_points = PackedVector2Array([
		Vector2(-total_width/2 + 5, -total_height/2),
		Vector2(total_width/2 - 5, -total_height/2),
		Vector2(total_width/2, -total_height/2 + 5),
		Vector2(total_width/2, total_height/2 - 5),
		Vector2(total_width/2 - 5, total_height/2),
		Vector2(-total_width/2 + 5, total_height/2),
		Vector2(-total_width/2, total_height/2 - 5),
		Vector2(-total_width/2, -total_height/2 + 5)
	])
	draw_polyline(border_points + PackedVector2Array([border_points[0]]), Color("#64748b"), 2.0)
	
	for i in NUM_SLOTS:
		var pos = slot_positions[i]
		# Slot rect centered on position
		var slot_rect = Rect2(pos - Vector2(SLOT_SIZE, SLOT_SIZE) / 2, Vector2(SLOT_SIZE, SLOT_SIZE))
		
		var slot_color = tier_colors[i].darkened(0.7)
		draw_rect(slot_rect, slot_color)
		draw_rect(slot_rect, tier_colors[i].darkened(0.3), false, 2.0)
		
		if slot_contents[i] > 0:
			_draw_progress_rectangles(slot_rect, i, slot_contents[i])

func _draw_progress_rectangles(slot_rect: Rect2, tier: int, count: int) -> void:
	var required = merge_requirements[tier]
	# Ensure fill rect stays within slot bounds
	var margin = 3.0
	var fill_rect = Rect2(
		slot_rect.position + Vector2(margin, margin),
		slot_rect.size - Vector2(margin * 2, margin * 2)
	)
	var color = tier_colors[tier]
	
	# Draw background
	draw_rect(fill_rect, color.darkened(0.3))
	
	# Draw filled rectangles based on count - all within fill_rect bounds
	if required == 2:
		# Split in half
		var half_width = fill_rect.size.x / 2
		if count >= 1:
			var left_rect = Rect2(fill_rect.position, Vector2(half_width, fill_rect.size.y))
			draw_rect(left_rect, color)
		if count >= 2:
			var right_rect = Rect2(fill_rect.position + Vector2(half_width, 0), Vector2(half_width, fill_rect.size.y))
			draw_rect(right_rect, color)
	elif required == 3:
		# Split in thirds
		var third_width = fill_rect.size.x / 3
		for i in range(mini(count, 3)):
			var rect = Rect2(fill_rect.position + Vector2(i * third_width, 0), Vector2(third_width, fill_rect.size.y))
			draw_rect(rect, color)
	elif required == 4:
		# Split in quarters (2x2 grid)
		var quarter_width = fill_rect.size.x / 2
		var quarter_height = fill_rect.size.y / 2
		for i in range(mini(count, 4)):
			var row = i / 2
			var col = i % 2
			var rect = Rect2(
				fill_rect.position + Vector2(col * quarter_width, row * quarter_height),
				Vector2(quarter_width, quarter_height)
			)
			draw_rect(rect, color)
	else:  # 5+
		# Split in 5 (2 rows: 3 top, 2 bottom)
		var cell_width = fill_rect.size.x / 3
		var cell_height = fill_rect.size.y / 2
		for i in range(mini(count, 5)):
			var row = 0 if i < 3 else 1
			var col = i if i < 3 else (i - 3)
			if row == 1 and col >= 2:
				col = 0  # Bottom row only has 2 cells
			var rect = Rect2(
				fill_rect.position + Vector2(col * cell_width, row * cell_height),
				Vector2(cell_width, cell_height)
			)
			draw_rect(rect, color)

func get_slot_world_position(slot_index: int) -> Vector2:
	if slot_index < 0 or slot_index >= slot_positions.size():
		return global_position
	return global_position + slot_positions[slot_index]

func get_nearest_slot(world_pos: Vector2) -> int:
	var nearest = -1
	var nearest_dist = INF
	
	for i in NUM_SLOTS:
		var slot_world = global_position + slot_positions[i]
		var dist = world_pos.distance_to(slot_world)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = i
	
	if nearest_dist <= DEPOSIT_DISTANCE:
		return nearest
	return -1

func can_deposit_at_slot(slot_index: int, tier: int) -> bool:
	return slot_index == tier

func get_merge_requirement(tier: int) -> int:
	if tier < 0 or tier >= merge_requirements.size():
		return 2
	return merge_requirements[tier]

func deposit(tier: int, slot_index: int) -> bool:
	if slot_index != tier:
		return false
	
	slot_contents[slot_index] += 1
	resource_deposited.emit(tier, slot_index)
	
	# Track highest tier achieved (even before merging)
	if tier > max_tier_reached:
		max_tier_reached = tier
		highest_tier_achieved.emit(tier)
	
	# Cascade merge with variable requirements
	_cascade_merge(slot_index)
	
	queue_redraw()
	return true

func _cascade_merge(starting_tier: int) -> void:
	var current_tier = starting_tier
	
	while current_tier < NUM_SLOTS:
		var required = merge_requirements[current_tier]
		if slot_contents[current_tier] >= required:
			# Merge required amount into 1 of next tier
			slot_contents[current_tier] -= required
			
			var new_tier = current_tier + 1
			if new_tier < NUM_SLOTS:
				slot_contents[new_tier] += 1
				resources_merged.emit(new_tier)
				
				# Track highest tier achieved
				if new_tier > max_tier_reached:
					max_tier_reached = new_tier
					highest_tier_achieved.emit(new_tier)
				
				current_tier = new_tier
			else:
				# Max tier exceeded
				resources_merged.emit(new_tier)
				
				# Track highest tier achieved
				if new_tier > max_tier_reached:
					max_tier_reached = new_tier
					highest_tier_achieved.emit(new_tier)
				
				break
		else:
			break

func get_total_value() -> int:
	var total = 0
	for i in NUM_SLOTS:
		total += slot_contents[i] * int(pow(2, i))
	return total

func get_base_bounds() -> Rect2:
	var total_width = SLOTS_PER_ROW * SLOT_SIZE + (SLOTS_PER_ROW - 1) * SLOT_SPACING + 20
	var total_rows = ceil(float(NUM_SLOTS) / SLOTS_PER_ROW)
	var total_height = total_rows * SLOT_SIZE + (total_rows - 1) * SLOT_SPACING + 20
	return Rect2(global_position + Vector2(-total_width/2, -total_height/2), Vector2(total_width, total_height))

func get_highest_tier_achieved() -> int:
	return max_tier_reached

func reset_base() -> void:
	# Reset all slots to empty
	slot_contents.fill(0)
	max_tier_reached = -1
	queue_redraw()

# Set number of slots based on max tier (max_tier + 1, since tiers are 0-indexed)
func set_num_slots(max_tier: int) -> void:
	NUM_SLOTS = max_tier + 1
	slot_contents.resize(NUM_SLOTS)
	slot_contents.fill(0)
	_init_merge_requirements()
	_calculate_slot_positions()
	
	# Extend tier colors if needed
	while tier_colors.size() < NUM_SLOTS:
		tier_colors.append(Color("#ffffff"))  # Default white for missing colors
	
	queue_redraw()
