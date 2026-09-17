class_name MaFixtureConeCollider
# composition of various fetchers to get a colored, positioned, angled cone
# that should be equivalent to the light cone in MA
# wrap in Area3D and such2
extends CollisionShape3D;
@export var id_handle: MAFixtureIdHandle;
@export var cone_opening_angle:float = 10.0;
@export var cone_height: float = 10.0;
@export var cone_detail: int = 10;

var position_fetcher: MAPositionFetcher;
var pan_fetcher: MAAttributeFetcher;
var tilt_fetcher: MAAttributeFetcher;
var color_fetcher: MAColorFetcher;
var fetchers: Array
func _enter_tree() -> void:
	position_fetcher= MAPositionFetcher.new(id_handle);
	pan_fetcher= MAAttributeFetcher.new(id_handle, "Pan");
	tilt_fetcher= MAAttributeFetcher.new(id_handle, "Tilt");
	color_fetcher= MAColorFetcher.new(id_handle);
	fetchers = [position_fetcher, pan_fetcher, tilt_fetcher,color_fetcher]

var color: Color;
var pan: float = 0.0;
var tilt: float = 0.0;
const PAN_OFFSET: float = -540;



func _ready() -> void:
	for f in fetchers:
		add_child(f)
	position_fetcher.received.connect(func(_position: Vector3): global_position = _position);
	pan_fetcher.received.connect(func(_pan:float ): pan = _pan + PAN_OFFSET; update_cone_angle())
	tilt_fetcher.received.connect(func(_tilt:float ): tilt = _tilt; update_cone_angle())
	color_fetcher.received.connect(func(_color:Color):color = _color;debug_color = _color);
	setup_cone();

func fetch():
	for f in fetchers:
		f.fetch();

func update_cone_angle():
	var axis = Vector3.DOWN
	axis = axis.rotated(Vector3.LEFT, deg_to_rad(-tilt)) # adjust for z backwards
	axis = axis.rotated(Vector3.UP, deg_to_rad(pan))
	var q = Quaternion(Vector3.DOWN, axis.normalized())
	quaternion = q


func setup_cone():
	
	var points: Array[Vector3] = []
	points.append(Vector3.ZERO)
	var radius: float = cone_height * tan(deg_to_rad(cone_opening_angle / 2.0))
	for i in range(cone_detail):
		var angle: float = (i * 2.0 * PI) / cone_detail
		var x: float = cos(angle) * radius
		var z: float = sin(angle) * radius
		points.append(Vector3(x, -cone_height, z))
	var _shape = ConvexPolygonShape3D.new();
	_shape.points = points
	shape = _shape;
	
func _init(_id_handle : MAFixtureIdHandle = null) -> void:
	id_handle = _id_handle;
