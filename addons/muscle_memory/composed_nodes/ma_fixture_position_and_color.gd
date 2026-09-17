class_name MAFixturePositionAndColor
# A composition of a color and position fetcher represented as CSGBox3D
extends CSGBox3D
@export var id_handle: MAFixtureIdHandle;
var position_fetcher: MAPositionFetcher;
var color_fetcher: MAColorFetcher;
var fetchers: Array
func _enter_tree() -> void:
	position_fetcher= MAPositionFetcher.new(id_handle);
	color_fetcher= MAColorFetcher.new(id_handle);
	fetchers  = [position_fetcher, color_fetcher]

var color: Color:
	set(val):
		(material as StandardMaterial3D).albedo_color = val
	get():
		return (material as StandardMaterial3D).albedo_color;

func _ready() -> void:
	for f in fetchers:
		add_child(f);
	material = StandardMaterial3D.new();
	position_fetcher.received.connect(func(p: Vector3): global_position = p);
	color_fetcher.received.connect(func(c: Color): color = c);

func fetch():
	for f in fetchers:
		f.fetch();

func push():
	MA.push_position(id_handle.fixture_id, global_position);
	MA.push_color(id_handle.fixture_id, color);

func _init(_id_handle : MAFixtureIdHandle = null) -> void:
	id_handle = _id_handle;
