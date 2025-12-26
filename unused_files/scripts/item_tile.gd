class_name ItemTile
extends Node2D
## Visual representation of an item on the grid

@export var tier: int = 0
@export var color: Color = Color.WHITE
@export var display_name: String = "Item"

@onready var sprite: ColorRect
@onready var label: Label
@onready var tween: Tween

const ITEM_SIZE := 56

func _ready() -> void:
	_create_visuals()
	refresh_visuals()
	_spawn_animation()

func _create_visuals() -> void:
	# Create colored square
	sprite = ColorRect.new()
	sprite.size = Vector2(ITEM_SIZE, ITEM_SIZE)
	sprite.position = -sprite.size / 2
	add_child(sprite)
	
	# Create tier label
	label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = Vector2(ITEM_SIZE, ITEM_SIZE)
	label.position = -label.size / 2
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color.BLACK)
	add_child(label)

func refresh_visuals() -> void:
	if sprite:
		sprite.color = color
	if label:
		label.text = str(tier)
	_merge_animation()

func _spawn_animation() -> void:
	scale = Vector2.ZERO
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "scale", Vector2.ONE, 0.25)

func _merge_animation() -> void:
	if not is_inside_tree():
		return
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_ELASTIC)
	tw.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	tw.tween_property(self, "scale", Vector2.ONE, 0.2)
