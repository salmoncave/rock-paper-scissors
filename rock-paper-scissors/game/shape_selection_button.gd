class_name ShapeSelectionButton extends Control

signal shape_selection_button_pressed(chosen_shape: Main.GameShapes)

@export var shapes_icons: Dictionary[Main.GameShapes, Texture2D]

var shape: Main.GameShapes

var _active_hover_tween: Tween
var _passive_hover_tween: Tween

@onready var button: Button = %Button
@onready var button_icon: TextureRect = %ButtonIcon
@onready var hover_background_00: TextureRect = %HoverBackground00
@onready var hover_background_01: TextureRect = %HoverBackground01


func _ready() -> void:
	_create_selection_button_for_choice(Main.GameShapes.PAPER)
	_start_passive_hover_tween_loop()

func _create_selection_button_for_choice(selected_shape: Main.GameShapes) -> void:
	button_icon.texture = shapes_icons[selected_shape]
	shape = selected_shape
	

func _on_button_pressed() -> void:
	shape_selection_button_pressed.emit(shape)
	

func _start_passive_hover_tween_loop() -> void:
	if _passive_hover_tween and _passive_hover_tween.is_running():
		_passive_hover_tween.kill()
	
	var hover_pos_offset_y: float = 16.0
	var tween_duration: float = 0.75
	
	button_icon.position.y = hover_pos_offset_y
	
	_passive_hover_tween = create_tween()
	_passive_hover_tween.set_loops()
	_passive_hover_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_passive_hover_tween.tween_property(
		button_icon, "position:y", -hover_pos_offset_y, tween_duration
	)
	_passive_hover_tween.tween_property(
		button_icon, "position:y", hover_pos_offset_y, tween_duration
	)

func _stop_passive_hover_tween_lopp() -> void:
	pass
	

func _start_active_hover_tween() -> void:
	pass
	

func _stop_active_hover_tween() -> void:
	pass
	
