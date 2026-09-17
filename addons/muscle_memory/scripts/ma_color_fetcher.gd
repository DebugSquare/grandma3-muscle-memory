class_name MAColorFetcher
# Composition of multiple attribute fetchers,
# to fetch the color value of a fixture
extends Node
@export var id_handle:MAFixtureIdHandle;
signal received(color: Color)

var color: Color;

var r_fetcher: MAAttributeFetcher
var g_fetcher: MAAttributeFetcher
var b_fetcher: MAAttributeFetcher
var fetchers : Array
func _enter_tree():
	r_fetcher= MAAttributeFetcher.new(id_handle, "ColorRGB_R")
	g_fetcher= MAAttributeFetcher.new(id_handle, "ColorRGB_G")
	b_fetcher= MAAttributeFetcher.new(id_handle, "ColorRGB_B")
	fetchers = [r_fetcher, g_fetcher, b_fetcher]; 



func fetch():
	for f in fetchers:
		f.fetch();
func push():
	MA.push_color(id_handle.fixture_id, color);
func push_color(_color: Color):
	color = _color; 
	MA.push_color(id_handle.fixture_id, color);

func _ready() -> void:
	for f in fetchers:
		add_child(f);
	r_fetcher.received.connect(func(r: float): color.r = r; received.emit(color));
	g_fetcher.received.connect(func(g: float): color.g = g; received.emit(color));
	b_fetcher.received.connect(func(b: float): color.b = b; received.emit(color));

func _init(_id_handle:MAFixtureIdHandle):
	id_handle = _id_handle;
