extends Node

var players = {}
var players_ready = {}


func _ready() -> void:
	pass


func player_ready_up(id:int, choosen_shape: Main.GameShapes ):
	players_ready[id] = choosen_shape
	if players_ready == 2:
		
		pass
	pass
