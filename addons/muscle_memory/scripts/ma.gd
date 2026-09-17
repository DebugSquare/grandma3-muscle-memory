class_name MA
# Static functions to communicate with MA
static func push_color(fixture_id:int, color:Color):
	# Set color of a fixture
	var command = """Lua "
	local f, s = %d, 0 
	local attrs = {'ColorRGB_R', 'ColorRGB_G', 'ColorRGB_B'} 
	local vals = {%f, %f, %f} 
	for i, attr in ipairs(attrs) do 
		local ui = GetUIChannelIndex(f, GetAttributeIndex(attr)) 
		if ui then SetProgPhaserValue(ui, s, {absolute = vals[i]}) end 
	end
	""" % [fixture_id, color.r*100, color.g*100, color.b*100]
	trim_and_execute(command)

static func push_position(fixture_id:int, position:Vector3):
	# Set (setup-)position of a fixture
	# adjust for z up & y forward
	var command = """Lua "
	local f = GetSubfixture(%d);
	f.POSX = %f;
	f.POSZ = %f;
	f.POSY = %f;
	"
	""" % [fixture_id, position.x,	position.y, -	position.z]	
	trim_and_execute(command)

static func push_scale(fixture_id: int, scale: Vector3):
	# Set (setup-)scale of a fixture
	var command = """Lua "
	local f = GetSubfixture(%d);
	f.SCALEX = %f;
	f.SCALEZ = %f;
	f.SCALEY = %f;
	"
	""" % [fixture_id, scale.x,scale.y, scale.z]
	trim_and_execute(command)

static func trim_and_execute(command:String):
	# Trim out whitespaces before sending over osc
	OSCManager.send_message("/cmd", [command.replace("\n", "").replace("\t", "")] )
