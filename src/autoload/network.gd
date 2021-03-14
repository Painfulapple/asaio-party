extends Node

const port = 6969

var server = false

var peer

puppet var clients = []

puppet var names = {}

puppet var colors = {}

var myID = 0

puppet var myName = ""

var myColor: Color

puppet var speed: int = 200

func host():
	#mapGenerator.generateMapCoords(Vector2(512, 300), 0, 10000, 150, PI / 40, 5, 1)
	server = true
	clients = []
	#peer = WebSocketServer.new()
	#peer.listen(port, PoolStringArray(), true)
	#get_tree().set_network_peer(peer)
	peer = NetworkedMultiplayerENet.new()
	peer.create_server(port, 100)
	get_tree().network_peer = peer
# warning-ignore:return_value_discarded
	get_tree().change_scene_to(load("res://assets/main/main.tscn"))
	myID = 1
	clients.append(1)
	names[1] = myName
	colors[1] = myColor
	print("Server started")

func client(ip):
	server = false
	clients = []
	#peer = WebSocketClient.new()
	#var url = "" + str(ip) + ":" + str(port) # You use "ws://" at the beginning of the address for WebSocket connections
	#var error = peer.connect_to_url(url, PoolStringArray(), true)
	#get_tree().set_network_peer(peer)
	peer = NetworkedMultiplayerENet.new()
	peer.create_client(ip, port)
	get_tree().network_peer = peer
	set_network_master(1)
	print("connecting to " + ip)

puppet func sendName(id):
	if not server:
		rpc("addName", id, myName)

remote func addName(id, playerName):
#	if server:
#		var currentName = generatePlayerName(playerName, 0)
#		if currentName != playerName:
#			rset_id(id, "myName", currentName)
	names[id] = playerName
	print(names)
	updateClientData()

remote func addColor(id, color):
	print("adding color of player ", id, ", ", color)
	if not server:
		return
	colors[id] = color
	updateClientData()

#func generatePlayerName(oldName, addon):
#	if server:
#		var newName = ""
#		if addon != 0:
#			newName = oldName + str(addon)
#		else:
#			newName = oldName
#		if names.values().has(newName):
#			return generatePlayerName(oldName, addon + 1)
#		else:
#			print("sending new name: " + newName)
#			return newName

func updateClientData():
	if server:
		rset("clients", clients)
		rset("names", names)
		rset("colors", colors)
		#mapGenerator.syncCoordsAngles()

func _connected_ok():
	myID = get_tree().get_network_unique_id()
	if not server:
# warning-ignore:return_value_discarded
		get_tree().change_scene_to(load("res://assets/main/main.tscn"))
		rpc("addName", myID, myName)
		rpc("addColor", myID, myColor)
		print("connected to server")

func _player_connected(id):
	print("player connected: " + str(id))
	if server:
		clients.append(id)
		#rset_id(id, "myID", id)
		#rpc_id(id, "sendName", id)
		updateClientData()
	
func _player_disconnected(id):
	print("player disconnected: " + str(id))
	if server:
		clients.erase(id)
		names.erase(id)
		updateClientData()

func _server_disconnected():
# warning-ignore:return_value_discarded
	get_tree().change_scene_to(load("res://assets/ui/main_menu/main_menu.tscn"))

func get_peers():
	return clients

func get_player_name(id: int) -> String:
	if not names.has(id):
		return "null"
	return names[id]

func get_my_name() -> String:
	return get_player_name(myID)

func get_color(id: int) -> Color:
	if not colors.has(id):
		return Color(1, 1, 1)
	return colors[id]

func get_my_color() -> Color:
	return get_color(myID)

func get_my_id() -> int:
	return myID

func _ready():
	randomize()
	# make it so when the game is paused, this script still runs
	pause_mode = PAUSE_MODE_PROCESS
# warning-ignore:return_value_discarded
	get_tree().connect("network_peer_connected", self, "_player_connected")
# warning-ignore:return_value_discarded
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
# warning-ignore:return_value_discarded
	get_tree().connect("connected_to_server", self, "_connected_ok")
# warning-ignore:return_value_discarded
	get_tree().connect("connection_failed", self, "_connected_fail")
# warning-ignore:return_value_discarded
	get_tree().connect("server_disconnected", self, "_server_disconnected")

#func _process(delta):
#	if peer != null:
#		if server:
#			if peer.is_listening():
#				peer.poll()
#		elif (peer.get_connection_status() == NetworkedMultiplayerPeer.CONNECTION_CONNECTED || peer.get_connection_status() == NetworkedMultiplayerPeer.CONNECTION_CONNECTING):
#			peer.poll()
