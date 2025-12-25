class_name ShapeSelectionButton extends Control

signal shape_selection_button_pressed(chosen_shape: Main.GameShapes)

@export var shapes_icons: Dictionary[Main.GameShapes, Texture2D]

@export var shape: Main.GameShapes

var _active_hover_tween: Tween
var _passive_hover_tween: Tween

@onready var button: Button = %Button
@onready var button_icon: TextureRect = %ButtonIcon
@onready var hover_background_00: TextureRect = %HoverBackground00
@onready var hover_background_01: TextureRect = %HoverBackground01


func _ready() -> void:
	_create_selection_button_for_choice(shape)
	_start_passive_hover_tween_loop()
	hover_background_00.visible = false
	hover_background_01.visible = false

func _create_selection_button_for_choice(selected_shape: Main.GameShapes) -> void:
	button_icon.texture = shapes_icons[selected_shape]
	shape = selected_shape
	

func _on_button_pressed() -> void:
	shape_selection_button_pressed.emit(shape)
	

func _start_passive_hover_tween_loop() -> void:
	_stop_passive_hover_tween_loop()
	
	var hover_pos_offset_y: float = 16.0
	#var coinflip := randi_range(0, 1)
	var starting_pos_offset_y: float = 0.0
	var tween_duration: float = 0.75
	
	#if coinflip == 0:
		#starting_pos_offset_y = -hover_pos_offset_y
	#else:
		#starting_pos_offset_y = hover_pos_offset_y
	
	button_icon.position.y = starting_pos_offset_y
	
	_passive_hover_tween = create_tween()
	_passive_hover_tween.set_loops()
	_passive_hover_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_passive_hover_tween.tween_property(
		button_icon, "position:y", -hover_pos_offset_y, tween_duration
	)
	_passive_hover_tween.tween_property(
		button_icon, "position:y", hover_pos_offset_y, tween_duration
	)

func _stop_passive_hover_tween_loop() -> void:
	if _passive_hover_tween and _passive_hover_tween.is_running():
		_passive_hover_tween.kill()
		button_icon.position = Vector2.ZERO
	

func _start_active_hover_tween() -> void:
	_stop_active_hover_tween()
	
	var tween_duration: float = 0.50
	var half_rotation_degrees: float = 90.0
	var desired_min_scale := (Vector2.ONE * 0.1)
	var desired_max_scale := (Vector2.ONE * 1.75)
	
	hover_background_00.visible = true
	hover_background_01.visible = true
	
	hover_background_00.scale = desired_min_scale
	hover_background_01.scale = desired_max_scale
	
	_active_hover_tween = create_tween()
	_active_hover_tween.set_loops()
	_active_hover_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	
	_active_hover_tween.tween_property(
		hover_background_00, "scale", desired_max_scale, tween_duration
		)
	_active_hover_tween.parallel().tween_property(
		hover_background_01, "scale", desired_min_scale, tween_duration
		)
	_active_hover_tween.parallel().tween_property(
		hover_background_00, "rotation_degrees", half_rotation_degrees, tween_duration
		).as_relative()
	_active_hover_tween.parallel().tween_property(
		hover_background_01, "rotation_degrees", -half_rotation_degrees, tween_duration
		).as_relative()
		
	_active_hover_tween.tween_property(
		hover_background_00, "scale", desired_min_scale, tween_duration
		)
	_active_hover_tween.parallel().tween_property(
		hover_background_01, "scale", desired_max_scale, tween_duration
		)
	_active_hover_tween.parallel().tween_property(
		hover_background_00, "rotation_degrees", half_rotation_degrees, tween_duration
		).as_relative()
	_active_hover_tween.parallel().tween_property(
		hover_background_01, "rotation_degrees", -half_rotation_degrees, tween_duration
		).as_relative()
		

func _stop_active_hover_tween() -> void:
	if _active_hover_tween and _active_hover_tween.is_running():
		_active_hover_tween.kill()
		hover_background_00.visible = false
		hover_background_01.visible = false
		hover_background_00.scale = Vector2.ZERO
		hover_background_01.scale = Vector2.ZERO
		
	


func _on_button_mouse_entered() -> void:
	_stop_passive_hover_tween_loop()
	_start_active_hover_tween()


func _on_button_mouse_exited() -> void:
	_stop_active_hover_tween()
	_start_passive_hover_tween_loop()
