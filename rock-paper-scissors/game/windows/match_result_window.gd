class_name MatchResultWindow extends Control

var _has_won: bool = false
var _win_loss_text: String = ''

@onready var rich_text_label_title: RichTextLabel = %RichTextLabelTitle
@onready var rich_text_label_results: RichTextLabel = %RichTextLabelResults

@onready var replay_button: Button = %ReplayButton
@onready var quit_button: Button = %QuitButton

func _ready() -> void:
	rich_text_label_results.text = _win_loss_text
	if _has_won:
		rich_text_label_title.text = "YOU WIN"
	else:
		rich_text_label_title.text = "YOU LOSE"

func set_match_results_window(results: Array[int]) -> void:
	var _round_results := results.duplicate()
	#Don't actually need to know how many (num rounds to win),
	#can just check if they have more wins that opponent
	_has_won = _round_results.count(1) > _round_results.count(2)
	
	var self_win_count := _round_results.count(1)
	var opponent_win_count := _round_results.count(2)
	var ties_count := _round_results.count(0)
	
	var win_loss_string := (
		str(self_win_count) + " - " + 
		str(opponent_win_count) + " - " +
		str(ties_count)
		)
	
	_win_loss_text = win_loss_string
	
