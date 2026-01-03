##[GameController] is the high-level manager for all this minigame's events.
##
##
##
##The main purpose of this class is to handle spawning either the [ShapeSelectionWindow]
##or [RoundProcessWindow]. Normally this would be handled through a finite state machine
##as the windows do not exist concurrently. That approach felt overkill due to the lack of
##scope on this project, but will be the first consideration should the project be expanded. 
class_name GameController extends Control

##Emitted whenever the user wishes to return to the main menu
signal main_menu_requested

@export_group("Packed Scenes")
##[PackedScene] for [ShapeSelectionWindow]
@export var shape_selection_window_packed_scene: PackedScene
##[PackedScene] for [RoundProcessWindow]
@export var round_process_window_packed_scene: PackedScene

##Active [ShapeSelectionWindow] if applicable
var _active_shape_selection_window: ShapeSelectionWindow
##Active [RoundProcessWindow] if applicable
var _active_round_process_window: RoundProcessWindow

##The number of wins required for a match to end, roughly determines the number of rounds
##that will be played.
var _total_wins_needed: int = 2

##The number of seconds a player has to chose their shape
var _round_selection_seconds: float = 15.0

##The results of each round as an [int] array
##0: Tie
##1: P1 Win
##2: P2 Win
var _round_results: Array[int]

##The GameShape chosen by Player 1
var _player_one_shape: Main.GameShapes
##The GameShape chosen by Player 2, this is just random in the current version,
##but this variable can be used to determine the opponent's behavior in a 2-player match
var _player_two_shape: Main.GameShapes

@onready var texture_rect_background: TextureRect = %TextureRectBackground

##Starts the game given the number of rounds
func start_game(num_rounds: int) -> void:
	texture_rect_background.material.set_shader_parameter("shaking", false)
	
	var modulate_tween := create_tween()
	
	modulate_tween.tween_property(
		self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5
	)
	
	await modulate_tween.finished
	
	
	_total_wins_needed = num_rounds
	_spawn_shape_selection_window()

##Spawns in a [ShapeSelectionWindow] and connects its signals
func _spawn_shape_selection_window() -> ShapeSelectionWindow:
	if _active_round_process_window:
		_active_round_process_window.queue_free()
	
	var new_shape_selection_window := shape_selection_window_packed_scene.instantiate() as ShapeSelectionWindow
	add_child(new_shape_selection_window)
	
	new_shape_selection_window.selection_timer.start(_round_selection_seconds)
	
	new_shape_selection_window.confirmed_shape_selection.connect(
		_on_shape_selection_window_confirmed_shape_selection
		)
	new_shape_selection_window.selection_tween_finished.connect(
		_on_shape_selection_window_selection_tween_finished
	)
	
	new_shape_selection_window.quit_to_main_menu_requested.connect(
		_on_quit_to_main_requested
	)
	
	_active_shape_selection_window = new_shape_selection_window
	
	return new_shape_selection_window

##Spawns a [RoundProcessWindow] to allow the player to see the results of a round
##and potentially complete a match
func _spawn_round_process_window() -> RoundProcessWindow:
	if _active_shape_selection_window:
		_active_shape_selection_window.queue_free()
	
	var new_round_process_window := round_process_window_packed_scene.instantiate() as RoundProcessWindow
	
	new_round_process_window.player_one_shape = _player_one_shape
	new_round_process_window.player_two_shape = _player_two_shape
	
	new_round_process_window.round_completed.connect(
		_on_round_process_window_round_completed
	)
	
	new_round_process_window.round_processed.connect(
		_on_round_process_window_round_processed
	)
	
	new_round_process_window.replay_requested.connect(
		_on_round_process_window_replay_requested
	)
	
	new_round_process_window.quit_to_main_requested.connect(
		_on_quit_to_main_requested
	)
	
	add_child(new_round_process_window)
	
	_active_round_process_window = new_round_process_window
	_active_round_process_window.update_win_loss_text(_round_results)
	
	return new_round_process_window
	

##Called after the animation has finished when a player has selected a GameShape
##in the [ShapeSelectionWindow]
func _on_shape_selection_window_selection_tween_finished() -> void:
	_spawn_round_process_window()
	

##Called whenever the player confirms a GameShape, currently also sets the computer's choice
func _on_shape_selection_window_confirmed_shape_selection(confirmed_shape: Main.GameShapes) -> void:
	_player_one_shape = confirmed_shape
	_player_two_shape = (randi_range(0, 2) as Main.GameShapes)
	

##Called whenever a round is processed to store the result and update the win-loss text
func _on_round_process_window_round_processed(result: int) -> void:
	_round_results.append(result)
	_active_round_process_window.update_win_loss_text(_round_results)

##Processed whenever a round has finished, determined if the [RoundProcessWindow] should remain
##on screen to choose replay/quit OR another round is necessary and the [ShapeSelectionWindow]
##needs to be spawned in
func _on_round_process_window_round_completed() -> void:
	var is_match_over: bool = (
		(_round_results.count(1) >= _total_wins_needed) or (_round_results.count(2) >= _total_wins_needed)
	)
	
	if not is_match_over:
		_spawn_shape_selection_window()
	else:
		_active_round_process_window.animate_end_match()

func _on_round_process_window_replay_requested() -> void:
	_reset_game()
	

func _on_quit_to_main_requested() -> void:
	main_menu_requested.emit()
	

func _reset_game():
	_round_results.clear()
	_spawn_shape_selection_window()
	
