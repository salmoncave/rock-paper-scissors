class_name ShapeSelectionWindow extends Control

signal confirmed_shape_selection(player_id: int, confirmed_shape: Main.GameShapes)
signal selection_tween_finished


var player_id : int = -1

@onready var shape_button_h_box_container: HBoxContainer = %ShapeButtonHBoxContainer
@onready var rich_text_label_title: RichTextLabel = %RichTextLabelTitle
@onready var rich_text_label_timer: RichTextLabel = %RichTextLabelTimer
@onready var confirm_button: Button = %ConfirmButton
@onready var concede_button: Button = %ConcedeButton
@onready var selection_timer: Timer = %SelectionTimer

var selected_shape := Main.GameShapes.ROCK
var round_selection_seconds: float = 15.0

var _has_selected_shape: bool = false

var _selection_buttons: Array[ShapeSelectionButton]
var _active_button: ShapeSelectionButton = null

func _ready() -> void:
	for child in shape_button_h_box_container.get_children():
		if child is ShapeSelectionButton:
			child.shape_selection_button_pressed.connect(_on_shape_selection_button_pressed)
			_selection_buttons.append(child)
		_selection_buttons[0].button_icon.material.set_shader_parameter("shaking", true)

func _physics_process(_delta: float) -> void:
	rich_text_label_timer.text = _get_timer_text(selection_timer.time_left)

func _on_shape_selection_button_pressed(button: ShapeSelectionButton, shape: Main.GameShapes) -> void:
	_deactivate_buttons(_selection_buttons, button)
	button.activate()
	button.active = true
	selected_shape = shape
	_active_button = button
	_has_selected_shape = true
	

func _on_confirm_button_pressed() -> void:
	if _has_selected_shape:
		if not selection_timer.is_stopped():
			selection_timer.stop()
		print("confirmed shape: ", Main.GameShapes.keys()[selected_shape])
		confirmed_shape_selection.emit(player_id, selected_shape)
		#_active_button.deactivate()
		_tween_button_selection(_active_button)
		_active_button.selection_trail_gpu_particles_2d.emitting = true
		confirm_button.disabled = true
		confirm_button.visible = false
		concede_button.disabled = true
		concede_button.visible = false
		for button in _selection_buttons:
			button.button.disabled = true
			button.button.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if button != _active_button:
				_tween_inactive_button(button)
		await selection_tween_finished
		_active_button.selection_trail_gpu_particles_2d.emitting = false
		
	else:
		push_error("NO SELECTED SHAPE")
	

func _deactivate_buttons(array: Array[ShapeSelectionButton], excluded_button: ShapeSelectionButton) -> void:
	for button in array:
		if button != excluded_button and button.active:
			button.active = false
			button.deactivate()
		

func _tween_button_selection(button: ShapeSelectionButton) -> void:
	var button_desired_pos_y := -512.0
	var button_scale := Vector2.ONE * 1.25
	var modulate_duration := 1.0
	var scale_duration := 0.5
	var pos_duration := 1.0
	
	var selection_tween := create_tween()
	
	selection_tween.tween_property(
		rich_text_label_title, "self_modulate", Color(1.0, 0.0, 0.0, 0.0), modulate_duration
	)
	selection_tween.parallel().tween_property(
		rich_text_label_timer, "self_modulate", Color(0.0, 0.0, 0.0, 0.0), modulate_duration
	)
	selection_tween.parallel().tween_property(
		button, "scale", button_scale, scale_duration
	)
	selection_tween.tween_property(
		button, "global_position:y", button_desired_pos_y, pos_duration
		)
	await selection_tween.finished
	selection_tween_finished.emit()
	
	#texture_rect_background.material.set_shader_parameter("shaking", false)
	#var fade_tween := create_tween()
	
	#fade_tween.tween_property(
		#texture_rect_background, "self_modulate", Color(0.0, 0.0, 0.0, 1.0), scale_duration
	#)

func _tween_inactive_button(button: ShapeSelectionButton) -> void:
	var tween_duration := 0.5
	var inactive_button_tween := create_tween()
	button.button_icon.material.set_shader_parameter("shaking", false)
	inactive_button_tween.tween_property(
		button, "modulate", Color(1.0, 0.0, 0.0, 1.0), tween_duration
	)
	inactive_button_tween.tween_property(
		button, "modulate", Color(1.0, 0.0, 0.0, 0.0), tween_duration
	)

func _get_timer_text(time_seconds: float) -> String:
	return str("%.2f" % time_seconds).replace(".", ":")


func _on_selection_timer_timeout() -> void:
	if _has_selected_shape:
		return
	_active_button = _selection_buttons.pick_random()
	_has_selected_shape = true
	selected_shape = _active_button.shape
	_on_confirm_button_pressed()
