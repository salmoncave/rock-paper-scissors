class_name MainMenu extends Control

signal game_started(num_rounds: int)

var _num_rounds: int = 2

@onready var background_texture_rect: TextureRect = %BackgroundTextureRect

func _ready() -> void:
	background_texture_rect.material.set_shader_parameter("shaking", true)

func _on_start_game_button_pressed() -> void:
	background_texture_rect.material.set_shader_parameter("shaking", false)
	
	var modulate_tween := create_tween()
	
	modulate_tween.tween_property(
		self, "modulate", Color(0.0, 0.0, 0.0, 1.0), 0.5
	)
	
	await modulate_tween.finished
	
	game_started.emit(_num_rounds)

func _on_spin_box_value_changed(value: float) -> void:
	_num_rounds = int(value)
	
