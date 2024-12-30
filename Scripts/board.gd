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
	
	if colour == EnumBus.Colour.White:
		SignalBus.enable_white_control.emit(true)
	elif colour == EnumBus.Colour.Black:
		SignalBus.enable_white_control.emit(false)
		SignalBus.black_move.emit()

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
		
		# We know this is a piece that we own
		board_tile_piece.piece_legal_moves = [] # Init legal moves
		# Determine piece type
		var repeat: bool # "Does the piece move more than once in the same direction?"
		var piece_dirs: Array[EnumBus.Dir]
		match board_tile_piece.piece_type:
			
			EnumBus.Type.King:
				repeat = false
				piece_dirs = [
					EnumBus.Dir.NorthWest, EnumBus.Dir.North, EnumBus.Dir.NorthEast, EnumBus.Dir.East, 
					EnumBus.Dir.SouthEast, EnumBus.Dir.South, EnumBus.Dir.SouthWest, EnumBus.Dir.West, 
				]
			
			EnumBus.Type.Queen:
				repeat = true
				piece_dirs = [
					EnumBus.Dir.NorthWest, EnumBus.Dir.North, EnumBus.Dir.NorthEast, EnumBus.Dir.East, 
					EnumBus.Dir.SouthEast, EnumBus.Dir.South, EnumBus.Dir.SouthWest, EnumBus.Dir.West, 
				]
			
			EnumBus.Type.Bishop:
				repeat = true
				piece_dirs = [
					EnumBus.Dir.NorthWest, EnumBus.Dir.NorthEast, 
					EnumBus.Dir.SouthEast, EnumBus.Dir.SouthWest, 
				]
			
			EnumBus.Type.Knight:
				repeat = false
			
			EnumBus.Type.Rook:
				repeat = true
				piece_dirs = [
					EnumBus.Dir.North, EnumBus.Dir.East, 
					EnumBus.Dir.South, EnumBus.Dir.West, 
				]
			
			EnumBus.Type.Pawn:
				repeat = false
				if colour == EnumBus.Colour.White:
					piece_dirs = [
						EnumBus.Dir.North, # Normal
						EnumBus.Dir.NorthWest, EnumBus.Dir.NorthEast # Capture
					]
				elif colour == EnumBus.Colour.Black:
					piece_dirs = [
						EnumBus.Dir.South, # Normal
						EnumBus.Dir.SouthWest, EnumBus.Dir.SouthEast # Capture
					]
		
		# For each available direction, determine moves
		for dir: EnumBus.Dir in piece_dirs:
			
			generate_legal_moves_for_direction(repeat, dir, board_tile.tile_index, board_tile_piece.piece_type, colour)

func generate_legal_moves_for_direction(repeat: bool, dir: EnumBus.Dir, src_tile_index: int, type: EnumBus.Type, colour: EnumBus.Colour):
	
	# Check if we're standing on edge tile
	if check_if_on_edge_tile(src_tile_index, type) == true:
		# Check if we intend to move in a direction that is not allowed
		if check_if_dir_forbidden(dir, src_tile_index, type) == true:
			return
	
	var dest_tile_index: int = src_tile_index + dir
	var board_matrix: Array = get_children()
	var src_tile: Tile = board_matrix[src_tile_index]
	var dest_tile: Tile = board_matrix[dest_tile_index]
	
	# Check if we're a pawn
	if type == EnumBus.Type.Pawn:
		# TODO
		pass
	
	# Check if dest is occupied by another piece
	if dest_tile.tile_piece.piece_exist == true:
		var other_piece: Piece = dest_tile.tile_piece
		# Check if other piece is my colour
		if other_piece.piece_colour == colour:
			# Can't move here -- end of this direction, stop searching
			return
		elif other_piece.piece_colour != colour:
			# You may move here & capture the piece -- end of this direction, stop searching
			dest_tile.tile_piece.piece_legal_moves.append(dest_tile)
			return
		
	elif dest_tile.tile_piece.piece_exist == false:
		# You may move here, as the space is empty
		dest_tile.tile_piece.piece_legal_moves.append(dest_tile)
	
	# Check if piece is "repeat", i.e. should we continue searching
	if repeat:
		generate_legal_moves_for_direction(repeat, dir, dest_tile_index, type, colour)
	elif not repeat:
		return

func check_if_on_edge_tile(src_tile_index: int, type: EnumBus.Type):
	
	if type == EnumBus.Type.Knight:
		var knight_edge_tiles: Array = [
			
		]
		
		# TODO
		
		for knight_edge_tiles_range in knight_edge_tiles:
			if src_tile_index in knight_edge_tiles_range:
				return true
	
	elif type != EnumBus.Type.Knight:
		var normal_edge_tiles: Array = [ # Array of ranges containing "edge tiles"
			# Singleton tiles, i.e. corners
			range(0, 1), range(7, 8), range(63, 64), range(56, 57), 
			
			# Other edge tiles, i.e. columns and rows
			range(1, 7), range(7, 64, 8), range(57, 63), range(0, 57, 8)
		]
		
		for normal_edge_tiles_range in normal_edge_tiles:
			if src_tile_index in normal_edge_tiles_range:
				return true
	
	return false

func check_if_dir_forbidden(dir: EnumBus.Dir, src_tile_index: int, type: EnumBus.Type):
	
	if type == EnumBus.Type.Knight:
		var knight_edge_tiles: Array = [
			
		]
		
		# TODO
	
	elif type != EnumBus.Type.Knight:
		var normal_edge_tiles: Array = [ # Array of ranges containing "edge tiles"
			# Singleton tiles, i.e. corners
			range(0, 1), range(7, 8), range(63, 64), range(56, 57), 
			
			# Other edge tiles, i.e. columns and rows
			range(1, 7), range(7, 64, 8), range(57, 63), range(0, 57, 8)
		]
		
		# "What range are we in?"
		var my_range: Array[int]
		for normal_edge_tiles_range in normal_edge_tiles:
			if src_tile_index in normal_edge_tiles_range:
				my_range = normal_edge_tiles_range
		
		# We can now determine with range if direction is forbidden
		var normal_edge_tiles_forbidden_dirs: Dictionary = {
			# From top-left to top-right to bottom-right to bottom-left:
			# Each key is a range of index representing "edge tile"
			# Value for each key is array of directions to ignore
			
			# Singleton tiles, i.e. corners
			str(range(0, 1)): [ # Top-left singleton
				EnumBus.Dir.North, EnumBus.Dir.West, 
				EnumBus.Dir.NorthWest, EnumBus.Dir.NorthEast, EnumBus.Dir.SouthWest
				],
			str(range(7, 8)): [ # Top-right singleton
				EnumBus.Dir.North, EnumBus.Dir.East, 
				EnumBus.Dir.NorthWest, EnumBus.Dir.NorthEast, EnumBus.Dir.SouthEast
			],
			str(range(63, 64)): [ # Bottom-right singleton
				EnumBus.Dir.East, EnumBus.Dir.South,
				EnumBus.Dir.NorthEast, EnumBus.Dir.SouthEast, EnumBus.Dir.SouthWest
			],
			str(range(56, 57)): [ # Bottom-left singleton
				EnumBus.Dir.South, EnumBus.Dir.West, 
				EnumBus.Dir.SouthEast, EnumBus.Dir.SouthWest, EnumBus.Dir.NorthWest
			],
			
			# Other edge tiles, i.e. columns and rows
			str(range(1, 7)): [ # Top row
				EnumBus.Dir.North, 
				EnumBus.Dir.NorthWest, EnumBus.Dir.NorthEast
			],
			str(range(7, 64, 8)): [ # Right column
				EnumBus.Dir.South, 
				EnumBus.Dir.NorthEast, EnumBus.Dir.SouthEast
			],
			str(range(57, 63)): [ # Bottom row
				EnumBus.Dir.East, 
				EnumBus.Dir.SouthEast, EnumBus.Dir.SouthWest
			],
			str(range(0, 57, 8)): [ # Left column
				EnumBus.Dir.West, 
				EnumBus.Dir.SouthWest, EnumBus.Dir.NorthWest
			],
		}
		
		# Check if the direction that we intend to move in is forbidden
		for forbidden_dir: EnumBus.Dir in normal_edge_tiles_forbidden_dirs[str(my_range)]:
			if forbidden_dir == dir:
				return true
	
	return false

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
