class_name Main extends Node

enum GameShapes {
	ROCK,
	PAPER,
	SCISSORS,
}

@export_group("Packed Scenes")
@export var main_menu_packed_scene: PackedScene
@export var game_controller_packed_scene: PackedScene

@onready var canvas_layer: CanvasLayer = %CanvasLayer

func _ready() -> void:
	_spawn_main_menu()

func _spawn_game_controller(num_rounds: int) -> GameController:
	var new_game_controller := game_controller_packed_scene.instantiate() as GameController
	
	canvas_layer.add_child(new_game_controller)
	
	new_game_controller.start_game(num_rounds)
	
	new_game_controller.main_menu_requested.connect(
		_on_game_controller_main_menu_requested
	)
	
	return new_game_controller
	

func _spawn_main_menu() -> MainMenu:
	var new_main_menu := main_menu_packed_scene.instantiate() as MainMenu
	
	canvas_layer.add_child(new_main_menu)
	
	new_main_menu.game_started.connect(
		_on_main_menu_game_started
	)
	
	return new_main_menu
	

func _on_main_menu_game_started(num_rounds: int) -> void:
	_flush_canvas_layer()
	_spawn_game_controller(num_rounds)
	

func _on_game_controller_main_menu_requested() -> void:
	_flush_canvas_layer()
	_spawn_main_menu()
	

func _flush_canvas_layer() -> void:
	for child in canvas_layer.get_children():
		child.queue_free()
