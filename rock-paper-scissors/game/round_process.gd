class_name RoundProcess extends Control

signal players_tied_round
signal player_1_won_round
signal player_2_won_round

func _ready() -> void:
	_process_round(Main.GameShapes.ROCK, Main.GameShapes.SCISSORS)
	_process_round(Main.GameShapes.ROCK, Main.GameShapes.PAPER)
	_process_round(Main.GameShapes.SCISSORS, Main.GameShapes.SCISSORS)

func _process_round(p1_shape: Main.GameShapes, p2_shape: Main.GameShapes) -> void:
	#Tie
	if p1_shape == p2_shape:
		print("TIE")
		players_tied_round.emit()
	#P1 Win
	elif _did_first_player_win(p1_shape, p2_shape):
		print("P1 WIN")
		player_1_won_round.emit()
	#P2 Win
	else:
		print("P2 WIN")
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
