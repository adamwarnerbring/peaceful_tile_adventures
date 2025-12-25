class_name ResourcePickup
extends Node2D
## A resource that can be picked up by the player

signal picked_up(tier: int)

@export var tier: int = 0

var bob_offset := 0.0
var base_y: float

const ITEM_SIZE := 24.0

func _ready() -> void:
	base_y = position.y
	bob_offset = randf() * TAU  # Random start phase
	queue_redraw()
	_spawn_animation()

func _process(delta: float) -> void:
	bob_offset += delta * 3.0
	position.y = base_y + sin(bob_offset) * 3.0

func _draw() -> void:
	var color = _get_tier_color(tier)
	
	# Draw gem shape
	var points = PackedVector2Array([
		Vector2(0, -ITEM_SIZE/2),
		Vector2(ITEM_SIZE/2, 0),
		Vector2(0, ITEM_SIZE/2),
		Vector2(-ITEM_SIZE/2, 0)
	])
	draw_polygon(points, [color])
	draw_polyline(points + PackedVector2Array([points[0]]), Color.WHITE, 2.0)
	
	# Draw tier number
	# (Label would need a child node, using simple indicator instead)

func collect() -> int:
	picked_up.emit(tier)
	# Collect animation
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector2.ZERO, 0.15)
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	tw.chain().tween_callback(queue_free)
	return tier

func _spawn_animation() -> void:
	scale = Vector2.ZERO
	modulate.a = 0.0
	var tw = create_tween()
	tw.set_parallel(true)
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "scale", Vector2.ONE, 0.3)
	tw.tween_property(self, "modulate:a", 1.0, 0.2)

func _get_tier_color(t: int) -> Color:
	var colors: Array[Color] = [
		Color("#4ade80"), Color("#22d3ee"), Color("#3b82f6"), Color("#a855f7"),
		Color("#f43f5e"), Color("#f97316"), Color("#eab308"), Color("#fafafa"),
	]
	return colors[mini(t, colors.size() - 1)]

