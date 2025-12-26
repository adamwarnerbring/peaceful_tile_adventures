class_name Projectile
extends Node2D
## Projectile for ranged attacks

signal hit_target(projectile: Projectile, target: Node2D)

var speed: float = 200.0
var damage: float = 10.0
var target: Node2D = null
var source: Node2D = null  # Who fired this
var color: Color = Color.WHITE

func _ready() -> void:
	queue_redraw()

func _process(delta: float) -> void:
	if not target or not is_instance_valid(target):
		queue_free()
		return
	
	var direction = (target.position - position).normalized()
	position += direction * speed * delta
	
	# Check if hit target
	var dist = position.distance_to(target.position)
	if dist < 10.0:
		# Store target and self before freeing
		var hit_target_node = target
		hit_target.emit(self, hit_target_node)
		set_process(false)  # Stop processing to prevent multiple hits
		call_deferred("queue_free")  # Defer freeing to ensure signal is processed
		return  # Don't continue processing after hit
	
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 4, color)
	draw_circle(Vector2.ZERO, 4, Color.WHITE, false, 1.0)
