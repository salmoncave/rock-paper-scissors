##The [ShapeSelectionWindow] is primarily responsible for allowing the player to
##select a GameShape, then communicating that information to the [GameController]
##
##
##
##If this is added to a multiplayer controller, this window should remain client
##side as all the processing can be done from within each player's [GameController].
class_name ShapeSelectionWindow extends Control

##Emitted when the player selects a GameShape, will need to be passed a player id
##if this is added to a multiplayer controller
signal confirmed_shape_selection(confirmed_shape: Main.GameShapes)
#signal confirmed_shape_selection(player_id: int, confirmed_shape: Main.GameShapes)

##Emitted whenever the selection tween finishes, and is used by [GameController]
##to progress to the next round
signal selection_tween_finished

##Container to deterimine GameShapes
@onready var shape_button_h_box_container: HBoxContainer = %ShapeButtonHBoxContainer
##Title [RichTextLabel]
@onready var rich_text_label_title: RichTextLabel = %RichTextLabelTitle
##Timer [RichTextLabel]
@onready var rich_text_label_timer: RichTextLabel = %RichTextLabelTimer
##[Button] used for confirming the player's GameShape
@onready var confirm_button: Button = %ConfirmButton
##[Button] for quitting out of the match by concession
@onready var concede_button: Button = %ConcedeButton
##[Timer] that automatically choses for the player if they take too long
@onready var selection_timer: Timer = %SelectionTimer

##The currently selected GameShape, used to determine the chosen shape
##when the confirm button is pressed
var selected_shape := Main.GameShapes.ROCK

##The number of seconds a player has to select a GameShape, set by [GameController]
var round_selection_seconds: float = 15.0

##Determines whether or not a GameShape has been selected for confirmation
var _has_selected_shape: bool = false

##The buttons assigned to each shape, [ShapeSelectionButton]s are currently set manually
##but they could be done programmatically if enough GameShapes are added
var _selection_buttons: Array[ShapeSelectionButton]

##The active [ShapeSelectionButton]
var _active_button: ShapeSelectionButton = null

func _ready() -> void:
	for child in shape_button_h_box_container.get_children():
		if child is ShapeSelectionButton:
			child.shape_selection_button_pressed.connect(_on_shape_selection_button_pressed)
			_selection_buttons.append(child)
		_selection_buttons[0].button_icon.material.set_shader_parameter("shaking", true)

func _physics_process(_delta: float) -> void:
	if selection_timer.is_stopped():
		return
	
	rich_text_label_timer.text = _get_timer_text(selection_timer.time_left)

##Determines what happens whenever a [ShapeSelectionButton] is pressed, coordinates
##properties and animations.
func _on_shape_selection_button_pressed(button: ShapeSelectionButton, shape: Main.GameShapes) -> void:
	_deactivate_buttons(_selection_buttons, button)
	button.activate()
	button.active = true
	selected_shape = shape
	_active_button = button
	_has_selected_shape = true
	

##Called when [member confirm_button] is pressed
func _on_confirm_button_pressed() -> void:
	if _has_selected_shape:
		if not selection_timer.is_stopped():
			selection_timer.stop()
		print("confirmed shape: ", Main.GameShapes.keys()[selected_shape])
		confirmed_shape_selection.emit(selected_shape)
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
	

##Deactivates other [ShapeSelectionButton] when one is confirmed,
##helps avoid selection when it's not necessary
func _deactivate_buttons(array: Array[ShapeSelectionButton], excluded_button: ShapeSelectionButton) -> void:
	for button in array:
		if button != excluded_button and button.active:
			button.active = false
			button.deactivate()
	

##Tweens a [ShapeSelectionButton] whenever it is confirmed for selection
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
	

##Tweens [ShapeSelectionButton]s that aren't selected whenever another is confirmed for selection
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
	

##Gets the text for the timer, shows seconds and miliseconds
func _get_timer_text(time_seconds: float) -> String:
	return str("%.2f" % time_seconds).replace(".", ":")
	

##Called when [selection_timer] times out, automatically confirms a selection
##if one hasn't already been confirmed
func _on_selection_timer_timeout() -> void:
	if _has_selected_shape:
		return
	_active_button = _selection_buttons.pick_random()
	_has_selected_shape = true
	selected_shape = _active_button.shape
	_on_confirm_button_pressed()
	
