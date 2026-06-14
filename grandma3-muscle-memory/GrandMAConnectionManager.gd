extends Node
class_name GrandMAConnectionManager

static var osc_client
static var osc_server
static var debug_cube: MeshInstance3D

@export var _osc_client: Node
@export var _osc_server: Node
@export var _debug_cube: MeshInstance3D

func _enter_tree() -> void:
	osc_client = _osc_client
	osc_server = _osc_server
	debug_cube = _debug_cube
