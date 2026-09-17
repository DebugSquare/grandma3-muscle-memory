class_name MASelectionFetcher
# Fetcher to get what fixtures are selected in MA
extends MAInteractionBase
signal received(selection:Array[int])
func fetch():
	var command = """Lua "
	local s= '';
	local i,_,_,_=SelectionFirst();
	while i do;
		s = s .. i .. '|';
		i,_,_,_=SelectionNext(i);
	end;
	Cmd('SendOSC 1 \\'/selection,s,'..s..'\\'');
	"""
	MA.trim_and_execute(command)
func on_osc_message(_address, _value, _time):
	var split = _address.split("/", false)
	if (split[0] == "selection"):
		var val_split = _value.split("|", false);
		var ret: Array[int]= []
		for i in val_split.size():
			ret.append(int(val_split[i]));
		received.emit( ret);
