@tool
extends Control
## Custom canvas control for drawing zones

signal canvas_clicked(pos: Vector2, button: int)
signal canvas_mouse_released(pos: Vector2)
signal canvas_right_clicked(pos: Vector2)
signal canvas_mouse_motion(pos: Vector2)

var draw_callback: Callable

func set_draw_callback(callback: Callable):
	draw_callback = callback
	queue_redraw()

func _draw():
	if draw_callback.is_valid():
		draw_callback.call(self)

func _gui_input(event: InputEvent):
	if event is InputEventMouseMotion:
		var mouse_pos = get_local_mouse_position()
		canvas_mouse_motion.emit(mouse_pos)
		queue_redraw()
	elif event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		var mouse_pos = get_local_mouse_position()
		
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				canvas_clicked.emit(mouse_pos, MOUSE_BUTTON_LEFT)
			else:
				# Mouse button released
				canvas_mouse_released.emit(mouse_pos)
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			canvas_right_clicked.emit(mouse_pos)

