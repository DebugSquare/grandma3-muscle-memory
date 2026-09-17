# OSC Manager
# Global autoload that manages osc communication

extends Node

# interface:
signal message_received(address, value, time) 								# Signal that recieives osc messages
func send_message(osc_address : String, args : Array): 						# Function to send osc messages
	if client.is_socket_connected():
		var packet = prepare_message(osc_address, args)
		client.put_packet(packet)






var ip_address: String = "127.0.0.1"
var output_port: int = 9000
var input_port: int = 8000

## Sets the timecode sent in the message_recieved signal to be in unix time (greater precision, less readable)
@export var timecode_as_unix = false

var client = PacketPeerUDP.new()
var server = UDPServer.new()
var peers: Array[PacketPeerUDP] = []

## A dictionary containing all recieved messages.
var incoming_messages := {}


signal peer_connected(peer_ip, peer_port)


func _ready():
	_load_config_settings()
	ProjectSettings.settings_changed.connect(_on_project_settings_changed)
	_setup_osc()
	

func _setup_osc():
	connect_socket(output_port, ip_address)
	server.stop();
	server.listen(input_port, ip_address)


func _load_config_settings() -> void :
	if ProjectSettings.has_setting("plugins/muscle_memory/ip_address"):
		ip_address = ProjectSettings.get_setting("plugins/muscle_memory/ip_address")
		
	if ProjectSettings.has_setting("plugins/muscle_memory/input_port"):
		input_port = ProjectSettings.get_setting("plugins/muscle_memory/input_port")
		
	if ProjectSettings.has_setting("plugins/muscle_memory/output_port"):
		output_port = ProjectSettings.get_setting("plugins/muscle_memory/output_port")

func _on_project_settings_changed() -> void :
	_load_config_settings()
	_setup_osc()

## Connect to an OSC server. Can only send to one OSC server at a time.
func connect_socket( new_port, new_ip):
	close_socket()
	client.connect_to_host(new_ip, new_port)
	
	if not client.is_socket_connected():
		push_error("OSCClient did not successfully connect to host.")

func close_socket():
	if client.is_socket_connected():
		client.close()




func _process(_delta):
	server.poll()
	if server.is_connection_available():
		var peer: PacketPeerUDP = server.take_connection()
		
		#print("Accepted peer: %s:%s" % [peer.get_packet_ip(), peer.get_packet_port()])
		
		peer_connected.emit(peer.get_packet_ip(), peer.get_packet_port())
		# Keep a reference so we can keep contacting the remote peer.
		peers.append(peer)
	elif len(peers) == 0:
		pass
		#push_warning("OSCServer has no incoming connections.")
	parse()


## Parses an OSC packet. This is not intended to be called directly outside of the OSCServer
func parse():
	for peer in peers:
		for l in range(peer.get_available_packet_count()):
			var packet = peer.get_packet()
			
			if packet.get_string_from_ascii() == "#bundle":
				parse_bundle(packet)
			else:
				parse_message(packet)

func parse_message(packet: PackedByteArray):
	#print(packet)
	var comma_index = packet.find(44)
	var address = packet.slice(0, comma_index).get_string_from_ascii()
	var args = packet.slice(comma_index, packet.size())
	var tags = args.get_string_from_ascii()
	var vals = []

	args = args.slice(ceili((tags.length() + 1) / 4.0) * 4, args.size())
	
	for tag in tags.to_ascii_buffer():
		#print(tags)
		match tag:
			44: #,: comma
				pass
			70: #false
				vals.append(false)
			84: #true
				vals.append(true)
			105: #i: int32
				var val = args.slice(0, 4)
				val.reverse()
				vals.append(val.decode_s32(0))
				args = args.slice(4, args.size())
			102: #f: float32
				var val = args.slice(0, 4)
				val.reverse()
				vals.append(val.decode_float(0))
				args = args.slice(4, args.size())
			115: #s: string
				var val = args.get_string_from_ascii()
				vals.append(val)
				args = args.slice(ceili((val.length() + 1) / 4.0) * 4, args.size())
			98:  #b: blob
				vals.append(args)
			
			
	
	incoming_messages[address] = vals
	
	if vals is Array and len(vals) == 1:
		vals = vals[0]
	
	if !timecode_as_unix:
		message_received.emit(address, vals, Time.get_time_string_from_system())
	else:
		message_received.emit(address, vals, Time.get_unix_time_from_system())

#Handle and parse incoming bundles
func parse_bundle(packet: PackedByteArray):
	
	
	packet = packet.slice(7)
	var mess_num = []
	var bund_ind = 0
	var messages = []
	
	# Find beginning of messages in bundle
	for i in range(packet.size()/4.0):
		var bund_arr = PackedByteArray([32,0,0,0])
		var testo = ""
		if packet.slice(i*4, i*4+4) == PackedByteArray([1, 0, 0, 0]):
			mess_num.append(i*4)
			bund_ind + 1
			
		elif packet[i*4+1] == 47 and packet[i*4 - 2] <= 0 and packet.slice(i*4 - 4, i*4) != PackedByteArray([1, 0, 0, 0]):
			mess_num.append(i*4-4)
		
		
		pass
	
	# Add messages to an array
	for i in range(len(mess_num)):
		
		if i  < len(mess_num) - 1:
			messages.append(packet.slice(mess_num[i]+4, mess_num[i+1]+1))
		else:
			var pack = packet.slice(mess_num[i]+4)
			
			messages.append(pack)
			
			
		
	
	
	# Iterate and parse the messages
	for bund_packet in messages:
		
		bund_packet.remove_at(0)
		bund_packet.insert(0,0)
		#print(bund_packet)
		var comma_index = bund_packet.find(44)
		var address = bund_packet.slice(1, comma_index).get_string_from_ascii()
		var args = bund_packet.slice(comma_index, packet.size())
		var tags = args.get_string_from_ascii()
		var vals = []
		
		
		args = args.slice(ceili((tags.length() + 1) / 4.0) * 4, args.size())
		
		for tag in tags.to_ascii_buffer():
			#print(tags)
			match tag:
				44: #,: comma
					pass
				70: #false
					vals.append(false)
					args = args.slice(4, args.size())
				84: #true
					vals.append(true)
					args = args.slice(4, args.size())
				105: #i: int32
					var val = args.slice(0, 4)
					val.reverse()
					vals.append(val.decode_s32(0))
					args = args.slice(4, args.size())
				102: #f: float32
					var val = args.slice(0, 4)
					val.reverse()
					vals.append(val.decode_float(0))
					args = args.slice(4, args.size())
				115: #s: string
					var val = args.get_string_from_ascii()
					vals.append(val)
					args = args.slice(ceili((val.length() + 1) / 4.0) * 4, args.size())
				98:  #b: blob
					vals.append(args)
				
				
		print(address, " ", vals)
		incoming_messages[address] = vals
		
		if !timecode_as_unix:
			message_received.emit(address, vals, Time.get_time_string_from_system())
		else:
			message_received.emit(address, vals, Time.get_unix_time_from_system())

## Send an OSC message over UDP.
func prepare_message(osc_address : String, args : Array):
	var packet = PackedByteArray()
	
	packet.append_array(osc_address.to_ascii_buffer())
	
	packet.append(0)
	while fmod(packet.size(), 4):
		packet.append(0)
	
	packet.append(44)
	for arg in args:
		match typeof(arg):
			TYPE_BOOL:
				if arg:
					packet.append(84)
				else:
					packet.append(70)
			TYPE_INT:
				packet.append(105)
			TYPE_FLOAT:
				packet.append(102)
			TYPE_STRING:
				packet.append(115)
			TYPE_PACKED_BYTE_ARRAY:
				packet.append(98)
	
	packet.append(0)
	while fmod(packet.size(), 4):
		packet.append(0)
	
	for arg in args:
		var pack = PackedByteArray()
		match typeof(arg):
			TYPE_BOOL:
				if arg:
					pack.append_array([1])
					pack.reverse()
				else:
					pack.append_array([0])
					pack.reverse()
			TYPE_INT:
				pack.append_array([0, 0, 0, 0])
				pack.encode_s32(0, arg)
				pack.reverse()
			TYPE_FLOAT:
				pack.append_array([0, 0, 0, 0])
				pack.encode_float(0, arg)
				pack.reverse()
			TYPE_STRING:
				pack.append_array(arg.to_ascii_buffer())
				pack.append(0)
				while fmod(pack.size(), 4):
					pack.append(0)
			TYPE_PACKED_BYTE_ARRAY:
				pack.append_array(arg)
				while fmod(pack.size(), 4):
					pack.append(0)
		packet.append_array(pack)
	
	return packet
