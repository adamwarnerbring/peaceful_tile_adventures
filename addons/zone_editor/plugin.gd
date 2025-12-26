@tool
extends EditorPlugin

var zone_editor_dock: Control

func _enter_tree():
	# Create and add the dock
	zone_editor_dock = preload("res://addons/zone_editor/zone_editor_dock.tscn").instantiate()
	add_control_to_dock(DOCK_SLOT_LEFT_UL, zone_editor_dock)
	
	# Make sure the dock script has access to editor
	if zone_editor_dock.has_method("set_editor"):
		zone_editor_dock.set_editor(self)
	elif zone_editor_dock.has("editor_plugin"):
		zone_editor_dock.editor_plugin = self

func _exit_tree():
	# Clean up - remove dock and free
	# Note: EditorPlugin automatically removes controls when plugin is disabled
	if zone_editor_dock and is_instance_valid(zone_editor_dock):
		zone_editor_dock.queue_free()
	zone_editor_dock = null

