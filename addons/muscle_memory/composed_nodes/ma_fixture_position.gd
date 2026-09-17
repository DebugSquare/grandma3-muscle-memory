class_name MAFixturePosition
# A position fetcher wrapped in a Node3D 
# may be used as parent for colliders and such
extends Node3D
@export var id_handle: MAFixtureIdHandle;
var position_fetcher: MAPositionFetcher;

func _enter_tree() -> void:
	position_fetcher = MAPositionFetcher.new(id_handle);

func _ready() -> void:
	position_fetcher.received.connect(func(p: Vector3): global_position = p);

func fetch():
	position_fetcher.fetch();

func push():
	MA.push_position(id_handle.fixture_id, global_position);

func _init(_id_handle: MAFixtureIdHandle):
	id_handle = _id_handle;
