class_name RoundProcessWindow extends Control

signal players_tied_round
signal player_1_won_round
signal player_2_won_round

@export var shapes_textures: Dictionary[Main.GameShapes, Texture2D]

var player_one_shape: Main.GameShapes
var player_two_shape: Main.GameShapes
var altar_intial_pos_y := 360.0

var _initial_pos_tween: Tween

@onready var altar_h_box_container: HBoxContainer = %AltarHBoxContainer
@onready var p_1_shape_texture: TextureRect = %P1ShapeTexture
@onready var p_2_shape_texture: TextureRect = %P2ShapeTexture
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var rich_text_label_result: RichTextLabel = %RichTextLabelResult


func _init() -> void:
	player_one_shape = Main.GameShapes.PAPER
	player_two_shape = Main.GameShapes.SCISSORS

func _ready() -> void:
	_tween_initial_scene()
	await _initial_pos_tween.finished
	_process_round(player_one_shape, player_two_shape)
	#_process_round(Main.GameShapes.ROCK, Main.GameShapes.SCISSORS)
	#_process_round(Main.GameShapes.ROCK, Main.GameShapes.PAPER)
	#_process_round(Main.GameShapes.SCISSORS, Main.GameShapes.SCISSORS)

func _process_round(p1_shape: Main.GameShapes, p2_shape: Main.GameShapes) -> void:
	animation_player.play("process_round_animation")
	await animation_player.animation_finished
	#Tie
	if p1_shape == p2_shape:
		rich_text_label_result.text = "TIE"
		#print("TIE")
		players_tied_round.emit()
		
	#P1 Win
	elif _did_first_player_win(p1_shape, p2_shape):
		rich_text_label_result.text = "P1 WIN"
		#print("P1 WIN")
		player_1_won_round.emit()
	#P2 Win
	else:
		rich_text_label_result.text = "P2 WIN"
		#print("P2 WIN")
		player_2_won_round.emit()
	
	
	

func _did_first_player_win(p1_shape: Main.GameShapes, p2_shape: Main.GameShapes) -> bool:
	var first_player_wins: Dictionary[Main.GameShapes, Main.GameShapes] = {
		Main.GameShapes.ROCK: Main.GameShapes.SCISSORS,
		Main.GameShapes.PAPER: Main.GameShapes.ROCK,
		Main.GameShapes.SCISSORS: Main.GameShapes.PAPER,
	}
	
	#This checks to see if the second player's shape would be the specific shape that the
	#first player's shape would beat. Since ties are checked before this point, this can only mean
	#that it would either be a win or not
	if first_player_wins[p1_shape] == p2_shape:
		return true
	return false

func _tween_initial_scene() -> void:
	var tween_duration := 0.5
	
	altar_h_box_container.position.y = altar_intial_pos_y
	
	_initial_pos_tween = create_tween()
	_initial_pos_tween.tween_property(
		altar_h_box_container, "position:y",
		0.0, tween_duration)

#func _on_animation_player_round_animation_finished() -> void:
	#pass

func _on_animation_player_swap_textures() -> void:
	p_1_shape_texture.texture = shapes_textures[player_one_shape]
	p_2_shape_texture.texture = shapes_textures[player_two_shape]
	
