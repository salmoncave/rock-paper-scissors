extends Control

#@export var Address = "127.0.0.1"
const PORT = 8910
var peer

@onready var player_name: LineEdit = %PlayerName
@onready var address: LineEdit = %Address


#note on debugging, adding a breakpoint allows you to check each session 
# that you started at the bottom. reccomend using this as you are able to

func _ready() -> void:
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	if "--server" in OS.get_cmdline_args():
		_host_game()
		

func _host_game():
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT,2)
	if error:
		print("Can't Host: ",error)
		return
	#We can use different compresses. It helps by giving more bandwidth and can be optimize based on the game
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER) 
	multiplayer.multiplayer_peer = peer
	print("Waiting for friends")

#Gets called on the sever and client
func peer_connected(id):
	print("player connected " + str(id))

#Gets called on the sever and client
func peer_disconnected(id):
	print("player disconnected " + str(id))
	var removed = GameManager.players.erase(id)
	var players = get_tree().get_nodes_in_group("player")
	for i in players:
		if i.name == str(id):
			i.queue_free()
	if removed:
		print("player removed from game manager  " + str(id))

#Called ONLY from the clients
# This function is how you send client data to server data
func connected_to_server():
	print("Connected to the Server!")
	#can be sent on peer connected to double check infomation or 
	# just in connected to sever so that only the new player needs to update
	# the server
	send_player_infomation.rpc_id(1,player_name.text, multiplayer.get_unique_id())

func connection_failed():
	print("Couldn't Connect to server")

#Call every machine exact the local machine
@rpc("any_peer")
func send_player_infomation(name,id):
	#if this is a unquie name/ hasn't been put in the global script add it
	if !GameManager.players.has(id):
		GameManager.players[id]={
			"name" : name, 
			"id" : id , 
			"score" : 0
		}
	# Tells the server/host to go through every player in the server list
	# and update everyone on the server of the new person who has join. 
	if multiplayer.is_server():
		for i in GameManager.players:
			send_player_infomation.rpc(GameManager.players[i].name, i)

#This is an rpc, force every machien to call this 
@rpc("any_peer","call_local")
func start_game():
	var scene = load("res://scene/levels/lvl_multiplayer_game.tscn").instantiate()
	get_tree().root.add_child(scene)
	self.hide()
	
#we want to start hosting and since we are a player, we want to send out data
func _on_host_pressed() -> void:
	_host_game()
	send_player_infomation(player_name.text, multiplayer.get_unique_id())
	upnp_setup()

func _on_join_pressed() -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_client(address.text,PORT)
	#theses compresses have to be the same as on_host
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER) 
	multiplayer.set_multiplayer_peer(peer)

#RPC functions aforce a function to run on everyones machine that is connected.
func _on_start_game_pressed() -> void:
	#rpc is everyone, rpc_id is select people
	start_game.rpc()

#This sets up the UPNP which goes through your Universal Plug and Play
func upnp_setup():
	var upnp = UPNP.new()
	var discover_result = upnp.discover()
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, "UPNP Discover Failed %s" % discover_result)
	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), "UPNP Invalid Gateway!")
	var map_result = upnp.add_port_mapping(PORT)
	assert(map_result == UPNP.UPNP_RESULT_SUCCESS, "UPNP Port Mapping Failed! Error %s" % map_result)
	
	print("Success! Join Address: %s ", upnp.query_external_address())
	
