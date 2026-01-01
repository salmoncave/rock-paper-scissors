
class_name RoundProcessWindow extends Control

##The number of seconds that the player waits before the next round. Is used
##to allow the player to see the round results before it goes to the next one.
const ROUND_COMPLETE_WAIT_SECONDS := 1.0

##0: Tie
##1: Player One Win
##2: Player Two Win
signal round_processed(result: int)
##Process whenever a round completely ends
signal round_completed

##Emitted after a match has been completed and the player wishes to play again
signal replay_requested
##Emitted after a match has been completed and the player quits to the main menu
signal quit_to_main_requested

##The GameShapes and their associated [Texture2D]
@export var shapes_textures: Dictionary[Main.GameShapes, Texture2D]

##The GameShape chosen by the first player (Only player in singeplayer)
var player_one_shape: Main.GameShapes
##The GameShape chosen by the second player (Computer, but can be used for multiplayer)
var player_two_shape: Main.GameShapes

@onready var altar_h_box_container: HBoxContainer = %AltarHBoxContainer
@onready var p_1_shape_texture: TextureRect = %P1ShapeTexture
@onready var p_2_shape_texture: TextureRect = %P2ShapeTexture
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var rich_text_label_title: RichTextLabel = %RichTextLabelTitle
@onready var rich_text_label_results: RichTextLabel = %RichTextLabelResults
@onready var replay_button: Button = %ReplayButton
@onready var quit_button: Button = %QuitButton

func _ready() -> void:
	animation_player.play("animate_initial_scene")
	await animation_player.animation_finished
	_process_round(player_one_shape, player_two_shape)
	

##Animates the end of the match from [GameController] after a game has been completed 
func animate_end_match() -> void:
	animation_player.play("fade_in_buttons")
	await animation_player.animation_finished
	replay_button.disabled = false
	quit_button.disabled = false

##Processes a round given both player's GameShapes
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
	#Play anim
	animation_player.play(anim_name)
	#Wait for animation player to declare round finished
	await animation_player.animation_finished
	await get_tree().create_timer(ROUND_COMPLETE_WAIT_SECONDS).timeout
	round_completed.emit()
	

##Determines if the first player has won based on the relationships of each GameShape
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
	

##Called during the animation the displays the rocking motion before
##the shapes are revealed for the round
func _on_animation_player_swap_textures() -> void:
	p_1_shape_texture.texture = shapes_textures[player_one_shape]
	p_2_shape_texture.texture = shapes_textures[player_two_shape]
	

##Updates the win-loss text record with the current round results
func update_win_loss_text(round_results: Array[int]) -> void:
	var self_win_count := round_results.count(1)
	var opponent_win_count := round_results.count(2)
	var ties_count := round_results.count(0)
	
	var win_loss_string := (
		str(self_win_count) + " - " + 
		str(opponent_win_count) + " - " +
		str(ties_count)
		)
	print(win_loss_string)
	
	rich_text_label_results.text = win_loss_string
	

func _on_replay_button_pressed() -> void:
	replay_requested.emit()
	

func _on_quit_button_pressed() -> void:
	quit_to_main_requested.emit()
	
