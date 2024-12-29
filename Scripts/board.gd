extends GridContainer

const BOARD_TILE_COUNT: int = 64
const BOARD_TILE_PIECE_OFFSET: Vector2 = Vector2(32, 32)

# Initial Game Setup

@export var board_piece_setup: String

func _ready() -> void:
	
	SignalBus.start_turn.connect(_on_start_turn)
	
	var board_parsed_result: Array[Tile] = parse_board_piece_setup()
	
	for board_tile_index: int in range(BOARD_TILE_COUNT):
		var board_tile: Tile = board_parsed_result[board_tile_index]
		add_child(board_tile)
		board_tile.set_tile_default_colour()
		
	
	SignalBus.start_turn.emit.call_deferred(EnumBus.Colour.White)

# Start Turn

func _on_start_turn(colour: EnumBus.Colour):
	
	delete_board_tile_piece_sprites()
	
	instance_board_tile_piece_sprites()
	
	calculate_board_tile_piece_legal_moves(colour)

func delete_board_tile_piece_sprites():
	
	for board_tile: Tile in get_children():
		for board_tile_piece: Piece in board_tile.get_children():
			board_tile_piece.queue_free()

func instance_board_tile_piece_sprites():
	
	for board_tile: Tile in get_children():
		var board_tile_piece: Piece = board_tile.tile_piece
		add_child(board_tile_piece)
		board_tile_piece.set_piece_sprite()
		board_tile_piece.global_position = board_tile.get_global_rect().position + BOARD_TILE_PIECE_OFFSET

func calculate_board_tile_piece_legal_moves(colour: EnumBus.Colour):
	
	# For each piece on board, determine legal moves & give piece this data
	var board_matrix: Array = get_children()
	for board_tile: Tile in board_matrix:
		
		var board_tile_piece: Piece = board_tile.tile_piece
		
		if board_tile_piece.piece_exist == false:
			continue
		
		if board_tile_piece.piece_colour != colour:
			continue

# Parse Piece Setup

const TILE = preload("res://Scenes/tile.tscn")
const PIECE = preload("res://Scenes/piece.tscn")

func parse_board_piece_setup():
	
	var board_parsed_result: Array[Tile] = []
	var board_white_pieces: Array = ["K", "Q", "B", "N", "R", "P"]
	var board_black_pieces: Array = ["k", "q", "b", "n", "r", "p"]
	var board_piece_setup_delimiter: String = "/"
	
	var board_piece_setup_count: int = 0
	var board_piece_index: int = 0
	var board_tile_dark: bool = false
	
	for board_piece_setup_char: String in board_piece_setup:
		
		if board_piece_setup_char == board_piece_setup_delimiter:
			
			if board_tile_dark == true:
				board_tile_dark = false
			elif board_tile_dark == false:
				board_tile_dark = true
			
			continue
		
		if int(board_piece_setup_char) != 0: # Fill with empty space
			
			for count: int in range(int(board_piece_setup_char)):
				
				var board_tile: Tile = TILE.instantiate()
				board_tile.tile_index = board_piece_setup_count
				board_tile.tile_dark = board_tile_dark
				board_tile.tile_piece = Piece.new()
				board_tile.tile_piece.piece_exist = false
				board_parsed_result.append(board_tile)
				
				board_piece_setup_count += 1
				
				if board_tile_dark == true:
					board_tile_dark = false
				elif board_tile_dark == false:
					board_tile_dark = true
			
			continue
		
		# We know that it must contain a piece
		var board_tile: Tile = TILE.instantiate()
		board_tile.tile_index = board_piece_setup_count
		board_tile.tile_dark = board_tile_dark
		board_tile.tile_piece = PIECE.instantiate()
		board_tile.tile_piece.piece_exist = true
		board_tile.tile_piece.piece_index = board_piece_index
		board_tile.tile_piece.piece_tile_index = board_piece_setup_count
		
		if board_piece_setup_char in board_white_pieces:
			
			board_tile.tile_piece.piece_colour = EnumBus.Colour.White
			
			var board_white_pieces_size: int = board_white_pieces.size()
			for count: int in range(board_white_pieces_size):
				
				if board_piece_setup_char == board_white_pieces[count]:
					
					board_tile.tile_piece.piece_type = count
					break
		
		elif board_piece_setup_char in board_black_pieces:
			
			board_tile.tile_piece.piece_colour = EnumBus.Colour.Black
			
			var board_black_pieces_size: int = board_black_pieces.size()
			for count: int in range(board_black_pieces_size):
				
				if board_piece_setup_char == board_black_pieces[count]:
					
					board_tile.tile_piece.piece_type = count
					break
		
		board_parsed_result.append(board_tile)
		board_piece_setup_count += 1
		board_piece_index += 1
		
		if board_tile_dark == true:
			board_tile_dark = false
		elif board_tile_dark == false:
			board_tile_dark = true
	
	return board_parsed_result
