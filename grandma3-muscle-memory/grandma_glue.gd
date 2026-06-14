class_name GrandMAGlue


class MAInteractionBase extends Node:
	func _init():
		GrandMAConnectionManager.osc_server.message_received.connect(on_osc_message)
	func trim_and_execute(command:String):
		GrandMAConnectionManager.osc_client.send_message("/cmd", [command.replace("\n", "").replace("\t", "")] )
	func on_osc_message(_address, _value, _time):
		pass

class ConnectionChecker extends MAInteractionBase:
	signal connection_recieved;
	func query_connection():
		var command = 'SendOSC 1 "/connected,s,y"'  
		trim_and_execute(command)
	func on_osc_message(_address, _value, _time):
		var split = _address.split("/", false)
		if (split[0] == "connected" && _value == 'y'):
			connection_recieved.emit();
			
class FixtureSelection extends MAInteractionBase:
	signal selection_recieved(selection:Array[int])
	func query_selections():
		var command = """Lua "
		local s= '';
		local i,_,_,_=SelectionFirst();
		while i do;
			s = s .. i .. '|';
			i,_,_,_=SelectionNext(i);
		end;
		Cmd('SendOSC 1 \\'/selection,s,'..s..'\\'');
		"""
		trim_and_execute(command)
	func on_osc_message(_address, _value, _time):
		var split = _address.split("/", false)
		if (split[0] == "selection"):
			selection_recieved.emit( _value.split("|", false));

class FixtureBase extends MAInteractionBase:
	var fixture_id:int
	var position: Vector3
	func _init(_fixture_id: int):
		fixture_id = _fixture_id;
		super();
	func set_position_from_pipes(pipes: String): # change to y up here
		var split = pipes.split("|");
		position.x = float(split[0])
		position.y = float(split[2])
		position.z = float(split[1])
	func on_osc_message(_address, _value, _time):
		var split = _address.split("/", false)
		if (split[0] == "attribute"  
		and split[1] == str(fixture_id) 
		and split[2] == "Position"):
			set_position_from_pipes(_value)
	func ask_attribute(attribute:String):
		var command = """Lua "
		local f, a = %d, '%s';
		local ai = GetAttributeIndex(a);
		local ui = GetUIChannelIndex(f, ai);
		local cf = GetChannelFunction(ui, ai);
		local v = GetProgPhaserValue(ui, 0).absolute / 100;
		local phys = v * (math.abs(cf.PHYSICALFROM) + math.abs(cf.PHYSICALTO)) + cf.PHYSICALFROM;
		Cmd('SendOSC 1 \\'/attribute/'..f..'/'..a..',f,'..phys..'\\'');
		"
		""" % [fixture_id, attribute]
		trim_and_execute(command)
	func ask_position():
		var command = """Lua "
		local i = %d;
		local f = GetSubfixture(i);
		Cmd('SendOSC 1 \\'/attribute/'..i..'/Position,s,'
		..f.POSX..'|'..f.POSY..'|'..f.POSZ..'\\'');
		"
		""" % [fixture_id]
		trim_and_execute(command)

class TargetFixture extends FixtureBase:
	var color: Color
	var selection: FixtureSelection
	func _init(_fixture_id: int):
		super(_fixture_id);
		selection = FixtureSelection.new();
	func send_color_osc():
		trim_and_execute(
			"""
			Store Group 99 /Overwrite;
			clear;
			Fixture %d;
			Attribute "ColorRGB_R" At %f;
			Attribute "ColorRGB_G" At %f;
			Attribute "ColorRGB_B" At %f;
			clear;
			Group 99;
			"""% [fixture_id, color.r*100, color.g*100, color.b*100]
		)
	func set_position_via_osc(): # adjust for z up
		var command = """Lua "
		local f = GetSubfixture(%d);
		f.POSX = %f;
		f.POSZ = %f;
		f.POSY = %f;
		"
		""" % [fixture_id, position.x,position.y, position.z]
		trim_and_execute(command)
	func set_scale_via_osc(scale: Vector3):
		var command = """Lua "
		local f = GetSubfixture(%d);
		f.SCALEX = %f;
		f.SCALEZ = %f;
		f.SCALEY = %f;
		"
		""" % [fixture_id, scale.x,scale.y, scale.z]
		trim_and_execute(command)

class TargetPartFixture extends TargetFixture:
	pass

class LightFixture extends FixtureBase:
	var pan: float
	var tilt: float
	var dimmer: float
	var color: Color;
	var _pan_offset: float = -540;
	var _opening_angle := 10.0;
	func ask_relevant_attributes():
		ask_position()
		ask_attribute("Pan")
		ask_attribute("Tilt")
		ask_attribute("Dimmer")
		ask_attribute("ColorRGB_R")
		ask_attribute("ColorRGB_G")
		ask_attribute("ColorRGB_B")
	func on_osc_message(_address, _value, _time):
		super(_address, _value, _time);
		var split = _address.split("/", false)
		if (split[0] == "attribute"  
		and split[1] == str(fixture_id)):
			if split[2] == "Pan":
				pan = _value + _pan_offset
			if split[2] == "Tilt":
				tilt = _value;
			if split[2] == "Dimmer":
				dimmer = _value;
			if split[2] == "ColorRGB_R": 	
				color.r = _value
			if split[2] == "ColorRGB_G":
				color.g = _value
			if split[2] == "ColorRGB_B":
				color.b = _value
	func set_debug_cube_axis(axis):
		var q = Quaternion(Vector3.DOWN, axis.normalized())
		GrandMAConnectionManager.debug_cube.quaternion = q
	
	func check_point_in_cone(point: Vector3):
		var axis = Vector3.DOWN
		axis = axis.rotated(Vector3.LEFT, deg_to_rad(tilt))
		axis = axis.rotated(Vector3.UP, deg_to_rad(pan))
		var cone_origin = position
		var dir_to_point = (point - cone_origin).normalized()
		var cone_direction = axis.normalized()
		var angle_to_point = cone_direction.angle_to(dir_to_point)
		var is_inside = angle_to_point <= deg_to_rad(_opening_angle)
		set_debug_cube_axis(axis);
		# --- DEBUG PRINTS ---
		#print("--- Cone Check ---")
		#print("Cone Origin: ", cone_origin)
		#print("Target Point: ", point)
		#print("Cone Axis (Normalized): ", cone_direction)
		#print("Direction to Point: ", dir_to_point)
		#print("Angle (Degrees): ", rad_to_deg(angle_to_point))
		#print("Is Inside: ", is_inside)
		#print("------------------")
		return is_inside;
	func are_colors_similar(c1: Color, c2: Color, threshold: float = 0.4) -> bool:
		var vec1 = Vector3(c1.r, c1.g, c1.b)
		var vec2 = Vector3(c2.r, c2.g, c2.b)
		return vec1.distance_to(vec2) < threshold
	func check_lit(target: TargetFixture):
		return check_point_in_cone(target.position) and dimmer >= 0.2 and are_colors_similar(color, target.color)
