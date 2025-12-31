class_name RoundProcessWindow extends Control

const ROUND_COMPLETE_WAIT_SECONDS := 1.0

##0: Tie
##1: Player One Win
##2: Player Two Win
signal round_completed
signal round_processed(result: int)

@export var shapes_textures: Dictionary[Main.GameShapes, Texture2D]

var player_one_shape: Main.GameShapes
var player_two_shape: Main.GameShapes
var altar_intial_pos_y := 360.0

var _game_controller: GameController
var _initial_pos_tween: Tween

@onready var altar_h_box_container: HBoxContainer = %AltarHBoxContainer
@onready var p_1_shape_texture: TextureRect = %P1ShapeTexture
@onready var p_2_shape_texture: TextureRect = %P2ShapeTexture
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var rich_text_label_title: RichTextLabel = %RichTextLabelTitle
@onready var rich_text_label_results: RichTextLabel = %RichTextLabelResults



func _init() -> void:
	player_one_shape = Main.GameShapes.SCISSORS
	player_two_shape = Main.GameShapes.PAPER

func _ready() -> void:
	_update_win_loss_text()
	_tween_initial_scene()
	await _initial_pos_tween.finished
	_process_round(player_one_shape, player_two_shape)
	#_process_round(Main.GameShapes.ROCK, Main.GameShapes.SCISSORS)
	#_process_round(Main.GameShapes.ROCK, Main.GameShapes.PAPER)
	#_process_round(Main.GameShapes.SCISSORS, Main.GameShapes.SCISSORS)

func _process_round(p1_shape: Main.GameShapes, p2_shape: Main.GameShapes) -> void:
	var round_result: int = 0
	var anim_name: String = ''
	var title_text: String = ''
	
	animation_player.play("process_round_animation")
	await animation_player.animation_finished
	
	#Tie
	if p1_shape == p2_shape:
		round_result = 0
		title_text = "TIE"
		anim_name = "tie"
		animation_player.play("tie")
	#P1 Win
	elif _did_first_player_win(p1_shape, p2_shape):
		round_result = 1
		title_text = "YOU WIN"
		anim_name = "p1_win"
	#P2 Win
	else:
		round_result = 2
		title_text = "YOU LOSE"
		anim_name = "p2_win"
	
	#Get results, send them to GameController
	round_processed.emit(round_result)
	#Display Title text
	rich_text_label_title.text = title_text
	#Set text for w/l from within GameController
	_update_win_loss_text()
	#Play anim
	animation_player.play(anim_name)
	#Wait for animation player to declare round finished
	await animation_player.animation_finished
	await get_tree().create_timer(ROUND_COMPLETE_WAIT_SECONDS).timeout
	round_completed.emit()
	


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
	

func _update_win_loss_text() -> void:
	var self_win_count := _game_controller.round_results.count(1)
	var opponent_win_count := _game_controller.round_results.count(2)
	var ties_count := _game_controller.round_results.count(0)
	
	var win_loss_string := (
		str(self_win_count) + " - " + 
		str(opponent_win_count) + " - " +
		str(ties_count)
		)
	print(win_loss_string)
	
	rich_text_label_results.text = win_loss_string
	
