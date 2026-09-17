class_name MAConnectionFetcher
# Fetcher to check for a connection
extends MAInteractionBase
signal received;
func fetch():
	var command = 'SendOSC 1 "/connected,s,y"'  
	MA.trim_and_execute(command)
func on_osc_message(_address, _value, _time):
	var split = _address.split("/", false)
	if (split[0] == "connected" && _value == 'y'):
		received.emit();
