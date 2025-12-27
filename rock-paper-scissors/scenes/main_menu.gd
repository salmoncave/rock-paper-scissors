extends Control

@export var game_scene: PackedScene 


#@export var Address = "127.0.0.1"
const PORT = 8910
var peer : ENetMultiplayerPeer
var currently_hosting : bool = false
var currently_joining: bool = false

#on ready variables so that we can just grab the data, could be switching to exported 
@onready var host: Button = %Host
@onready var join: Button = %Join
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
		

func _host_game() -> bool:
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT,2)
	if error:
		print("Can't Host: ",error)
		return false
	#We can use different compresses. It helps by giving more bandwidth and can be optimize based on the game
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER) 
	multiplayer.multiplayer_peer = peer
	print("Waiting for friends")
	return true

#Gets called on the sever and client
func peer_connected(id):
	print("player connected " + str(id))
	start_game.rpc()

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
	

#Called ONLY from the clients(non host)
# This function is how you send client data to server data
func connected_to_server():
	if !player_name.text:
		print("No name :(")
		return
	
	print("Connected to the Server!")
	##if GameManager.players.keys().size() > 2:
	#	discon
	#can be sent on peer connected to double check infomation or 
	# just in connected to sever so that only the new player needs to update
	# the server
	#1 is the host
	send_player_infomation.rpc_id(1,player_name.text, multiplayer.get_unique_id())

func connection_failed():
	print("Couldn't Connect to server")

#Always any peer Call every machine exact the local machine
@rpc("any_peer")
func send_player_infomation(given_name,id) -> void:
	#if this is a unquie name/ hasn't been put in the global script add it
	#better checking for given name could be important 
	if !GameManager.players.has(id):
		GameManager.players[id]={
			"name" : given_name, 
			"id" : id, 
			"score" : 0
		}
	# Tells the server/host to go through every player in the server list
	# and update everyone on the server of the new person who has join. 
	if multiplayer.is_server():
		for i in GameManager.players:
			send_player_infomation.rpc(GameManager.players[i].name, i)


#This is an rpc function which, force every machine to call this 
@rpc("any_peer","call_local")
func start_game():
	#if GameManager.players.size() == 2:
	var scene = game_scene.instantiate()
	get_tree().root.add_child(scene)
	self.hide()
	
#we want to start hosting and since we are a player, we want to send out data
func _on_host_pressed() -> void:
	#If we have succesfully started hosting we want to not allow for clicking this multiple time
	# and have a cancel out
	if currently_hosting:
		cancel_hosting()
		return
	
	#empty string
	if !player_name.text :
		#add some UI to tell we need player name
		return
	
	var is_hosting :bool= _host_game()
	if !is_hosting:
		return 
	send_player_infomation(player_name.text, multiplayer.get_unique_id())
	var is_upnp :bool= upnp_setup()
	if !is_upnp:
		return
	succesfull_host()


func _on_join_pressed() -> void:
	if currently_joining:
		cancel_join()
		return
		
	if !player_name.text or !address.text:
		return
	peer = ENetMultiplayerPeer.new()
	#Gets the address.text from the menu, 
	#add cleaning to the text, could add more configs so it is not direct ip address later.
	var err = peer.create_client(address.text,PORT)
	if err != 0:
		print("Error joining: %s" % err)
		return
	#theses compresses have to be the same as on_host
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER) 
	multiplayer.set_multiplayer_peer(peer)
	sucessful_join()
	

#RPC functions aforce a function to run on everyones machine that is connected.
func _on_start_game_pressed() -> void:
	#rpc is everyone, rpc_id is select people
	start_game.rpc()

#This sets up the UPNP which goes through your Universal Plug and Play
func upnp_setup() -> bool:
	var upnp = UPNP.new()
	var discover_result = upnp.discover()
	var success : bool = true
	if discover_result != UPNP.UPNP_RESULT_SUCCESS:
		success = false
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, "UPNP Discover Failed %s" % discover_result)
	if not(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway()):
		success = false
	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), "UPNP Invalid Gateway!")
	var map_result = upnp.add_port_mapping(PORT)
	if map_result != UPNP.UPNP_RESULT_SUCCESS:
		success = false
	assert(map_result == UPNP.UPNP_RESULT_SUCCESS, "UPNP Port Mapping Failed! Error %s" % map_result)
	if success:
		print("Success! Join Address: ", upnp.query_external_address())
	else:
		print("Failed! Did not Join Address")
	address.text = upnp.query_external_address()
	return success


#Just turn off buttons and change text 
#BORING UI STUFF
func succesfull_host():
	#buttons
	currently_hosting = true
	join.disabled = true
	#text
	player_name.editable = false
	address.editable = false
	host.text = "Cancel"

func sucessful_join():
	#buttons
	currently_joining = true
	host.disabled = true
	#text
	player_name.editable = false
	address.editable = false
	join.text = "Cancel"

func cancel_hosting():
	#buttons
	currently_hosting = false
	join.disabled = false
	#text
	player_name.editable = true
	address.editable = true
	host.text = "host"
	#Closes the peer conection so we do not repeat 
	peer.close()

func cancel_join():
	#buttons
	currently_joining = false
	host.disabled = false
	#text
	player_name.editable = true
	address.editable = true
	join.text = "join"
	#Closes the peer conection so we do not repeat 
	peer.close()
