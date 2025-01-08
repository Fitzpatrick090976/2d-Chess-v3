extends Node

@export var board: Board

func _ready() -> void:
	
	SignalBus.black_move.connect(_on_black_move)

func _on_black_move():
	
	print("_on_black_move")
	# Produce a valid source & destination
