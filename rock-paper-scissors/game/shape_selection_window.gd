class_name ShapeSelectionWindow extends Control

signal confirmed_shape_selection(confirmed_shape: Main.GameShapes)

@onready var shape_button_h_box_container: HBoxContainer = %ShapeButtonHBoxContainer

var selected_shape := Main.GameShapes.ROCK
var _has_selected_shape: bool = false

var _selection_buttons: Array[ShapeSelectionButton]

func _ready() -> void:
	for child in shape_button_h_box_container.get_children():
		if child is ShapeSelectionButton:
			child.shape_selection_button_pressed.connect(_on_shape_selection_button_pressed)
			_selection_buttons.append(child)
	

func _on_shape_selection_button_pressed(button: ShapeSelectionButton, shape: Main.GameShapes) -> void:
	_deactivate_buttons(_selection_buttons, button)
	button.active = true
	selected_shape = shape
	_has_selected_shape = true
	

func _on_confirm_button_pressed() -> void:
	if _has_selected_shape:
		print("confirmed shape: ", Main.GameShapes.keys()[selected_shape])
		confirmed_shape_selection.emit(selected_shape)
	else:
		push_error("NO SELECTED SHAPE")
	

func _deactivate_buttons(array: Array[ShapeSelectionButton], excluded_button: ShapeSelectionButton) -> void:
	for button in array:
		if button != excluded_button and button.active:
			button.active = false
			button.deactivate()
		
