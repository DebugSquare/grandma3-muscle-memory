@tool
extends EditorPlugin
const AUTOLOAD_NAME = "OSCManager"
const AUTOLOAD_PATH = "res://addons/muscle_memory/scripts/osc_manager.gd"
const PATH_IP = "plugins/muscle_memory/ip_address"
const PATH_IN_PORT = "plugins/muscle_memory/input_port"
const PATH_OUT_PORT = "plugins/muscle_memory/output_port"


func _enter_tree() -> void:
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)
	_init_setting(PATH_IP, "127.0.0.1", TYPE_STRING)
	_init_setting(PATH_OUT_PORT, 9000, TYPE_INT)
	_init_setting(PATH_IN_PORT, 8000, TYPE_INT)
	ProjectSettings.save()
func _exit_tree() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)


func _init_setting(path: String, default_value: Variant, type: int) -> void:
	if not ProjectSettings.has_setting(path):
		ProjectSettings.set_setting(path, default_value)
		
	var property_info = {
		"name": path,
		"type": type
	}
	ProjectSettings.add_property_info(property_info)
