class_name MAAttributeFetcher
# Fetcher to get any attribute of a fixture
# Use "List Attribute" to see a list of the avialable attributes in MA
extends MAInteractionBase
@export var id_handle:MAFixtureIdHandle;
@export var attribute: String;
signal received(value)
func fetch():
	var command = """Lua "
	local f, a = %d, '%s';
	local ai = GetAttributeIndex(a);
	local ui = GetUIChannelIndex(f, ai);
	local cf = GetChannelFunction(ui, ai);
	local v = GetProgPhaserValue(ui, 0).absolute / 100;
	local phys = v * (math.abs(cf.PHYSICALFROM) + math.abs(cf.PHYSICALTO)) + cf.PHYSICALFROM;
	Cmd('SendOSC 1 \\'/attribute/'..f..'/'..a..',f,'..phys..'\\'');
	"
	""" % [id_handle.fixture_id, attribute]
	MA.trim_and_execute(command)
func on_osc_message(_address, _value, _time):
	if not id_handle: return;
	var split = _address.split("/", false)
	if (split[0] == "attribute"  
	and split[1] == str(id_handle.fixture_id)):
		if split[2] == attribute:
			received.emit(_value)

func _init(_id_handle:MAFixtureIdHandle,_attribute: String):
	super();
	id_handle = _id_handle;
	attribute = _attribute;
