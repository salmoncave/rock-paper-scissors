class_name GameController extends Node

@export var shape_selection_window_packed_scene: PackedScene
@export var round_process_window_packed_scene: PackedScene

@onready var canvas_layer: CanvasLayer = %CanvasLayer

var _active_shape_selection_window: ShapeSelectionWindow
var _active_round_process_window: RoundProcessWindow

var _player_one_shape: Main.GameShapes
var _player_two_shape: Main.GameShapes

func _ready() -> void:
	_spawn_shape_selection_window()
	

func _spawn_shape_selection_window() -> ShapeSelectionWindow:
	var new_shape_selection_window := shape_selection_window_packed_scene.instantiate() as ShapeSelectionWindow
	canvas_layer.add_child(new_shape_selection_window)
	
	new_shape_selection_window.confirmed_shape_selection.connect(
		_on_shape_selection_window_confirmed_shape_selection
		)
	new_shape_selection_window.selection_tween_finished.connect(
		_on_shape_selection_window_selection_tween_finished
	)
	
	_active_shape_selection_window = new_shape_selection_window
	
	return new_shape_selection_window

func _spawn_round_process_window() -> RoundProcessWindow:
	var new_round_process_window := round_process_window_packed_scene.instantiate() as RoundProcessWindow
	canvas_layer.add_child(new_round_process_window)
	
	_active_round_process_window = new_round_process_window
	_active_round_process_window.player_one_shape = _player_one_shape
	_active_round_process_window.player_two_shape = _player_two_shape
	
	return new_round_process_window

func _on_shape_selection_window_selection_tween_finished() -> void:
	_active_shape_selection_window.queue_free()
	_spawn_round_process_window()

func _on_shape_selection_window_confirmed_shape_selection(player_id: int, confirmed_shape: Main.GameShapes) -> void:
	if player_id == 0:
		_player_one_shape = confirmed_shape
		_player_two_shape = (randi_range(0, 2) as Main.GameShapes)
	
