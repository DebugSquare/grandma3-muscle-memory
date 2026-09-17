class_name MAFixtureIdHandle
# Handle that wraps the fixture id, will error if not set
extends Resource
@export var fixture_id: int;

func _init(_fixture_id: int = 1):
	fixture_id = _fixture_id;
	
