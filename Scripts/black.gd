extends Node

@export var board: Board

func _ready() -> void:
	
	SignalBus.black_move.connect(_on_black_move)

func _on_black_move():
	
	# Produce a valid source & destination
	
	var black_pieces: Array[Piece] = []
	
	for board_tile: Tile in board.get_children():
		
		if not board_tile.tile_piece.piece_exist:
			continue
		
		if board_tile.tile_piece.piece_colour != EnumBus.Colour.Black:
			continue
		
		if board_tile.tile_piece.piece_legal_moves == []:
			continue
		
		black_pieces.append(board_tile.tile_piece)
	
	var selected_piece: Piece = black_pieces.pick_random()
	var selected_move: Tile = selected_piece.piece_legal_moves.pick_random()
	
	SignalBus.move_piece.emit(selected_piece.piece_tile_index, selected_move.tile_index, EnumBus.Colour.Black)
