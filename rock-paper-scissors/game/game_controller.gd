class_name GameController extends Node

@export var shape_selection_window_packed_scene: PackedScene
@export var round_process_window_packed_scene: PackedScene
@export var total_wins_needed :int=2 
 

var player_id : int = -1
var players_ready = {}
var second_caller : int = -1

var current_wins = 0 


var _active_shape_selection_window: ShapeSelectionWindow
var _active_round_process_window: RoundProcessWindow

var _player_one_shape: Main.GameShapes 
var _player_two_shape: Main.GameShapes


@onready var canvas_layer: CanvasLayer = %CanvasLayer

func _ready() -> void:
	_spawn_shape_selection_window()
	

func _spawn_shape_selection_window() -> ShapeSelectionWindow:
	var new_shape_selection_window := shape_selection_window_packed_scene.instantiate() as ShapeSelectionWindow
	new_shape_selection_window.player_id = player_id
	canvas_layer.add_child(new_shape_selection_window)
	
	new_shape_selection_window.confirmed_shape_selection.connect(
		_on_shape_selection_window_confirmed_shape_selection
		)
	new_shape_selection_window.selection_tween_finished.connect(
		_on_shape_selection_window_selection_tween_finished
	)
	
	_active_shape_selection_window = new_shape_selection_window
	
	return new_shape_selection_window


@rpc("any_peer", "call_local")
func _spawn_round_process_window() -> RoundProcessWindow:
	_active_shape_selection_window.queue_free()
	var new_round_process_window := round_process_window_packed_scene.instantiate() as RoundProcessWindow
	new_round_process_window.player_one_shape = _player_one_shape
	new_round_process_window.player_two_shape = _player_two_shape
	# take the signal and reset while making the chagnes
	#new_round_process_window
	
	canvas_layer.add_child(new_round_process_window)
	_active_round_process_window = new_round_process_window
	
	
	
	
	return new_round_process_window

func _on_shape_selection_window_selection_tween_finished() -> void:
	if player_id == -1:
		print("Queue free")
		#_active_shape_selection_window.queue_free()
		_spawn_round_process_window()
	else:
		#after both player are ready send out an rpc call
		#possiably needs a gate?
		if players_ready.size() == 2 and second_caller == player_id:
			print("ID: ", player_id, "| Calling rpc")
			_spawn_round_process_window.rpc()

#Player confirmed a shape
func _on_shape_selection_window_confirmed_shape_selection(confirmed_player_id: int, confirmed_shape: Main.GameShapes) -> void:
	if confirmed_player_id == -1:
		_player_one_shape = confirmed_shape
		_player_two_shape = (randi_range(0, 2) as Main.GameShapes)
	else:
		multiplayer_ready_up.rpc(confirmed_player_id,confirmed_shape)


#lets both sides that are connect on what was selected
@rpc("any_peer", "call_local")
func multiplayer_ready_up(id:int, choosen_shape: Main.GameShapes):
	players_ready[id] = choosen_shape
	if id == player_id:
		_player_one_shape = choosen_shape
	else:
		_player_two_shape = choosen_shape
	
	print("ID: ", player_id , " players that are ready :" ,players_ready)
	print("ID: ", player_id ," | ", _player_one_shape, _player_two_shape )
	if players_ready.size()==2:
		second_caller = id


func result(winner_id:int):
	if player_id == winner_id:
		
		
	

func reset_game():
	players_ready = {}
	second_caller = -1
