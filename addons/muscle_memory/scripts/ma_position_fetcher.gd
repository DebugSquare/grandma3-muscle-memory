class_name MAPositionFetcher
# Fetcher to get the (setup-)position of a fixture
extends MAInteractionBase
@export var id_handle: MAFixtureIdHandle
signal received(position: Vector3)
func emit_position_from_pipes(pipes: String): # change to y up & z backwards
	var split = pipes.split("|");
	var position: Vector3;
	position.x = float(split[0])
	position.y = float(split[2])
	position.z = -float(split[1])
	received.emit(position)
func on_osc_message(_address, _value, _time):
	if not id_handle: return;
	var split = _address.split("/", false)
	if (split[0] == "attribute"  
	and split[1] == str(id_handle.fixture_id) 
	and split[2] == "Position"):
		emit_position_from_pipes(_value)
func fetch():
	var command = """Lua "
	local i = %d;
	local f = GetSubfixture(i);
	Cmd('SendOSC 1 \\'/attribute/'..i..'/Position,s,'
	..f.POSX..'|'..f.POSY..'|'..f.POSZ..'\\'');
	"
	""" % [id_handle.fixture_id]
	MA.trim_and_execute(command)

func _init(_id_handle: MAFixtureIdHandle):
	super();
	id_handle = _id_handle;
