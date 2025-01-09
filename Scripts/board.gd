extends GridContainer

class_name Board

const BOARD_TILE_COUNT: int = 64
const BOARD_TILE_PIECE_OFFSET: Vector2 = Vector2(32, 32)

# Initial Game Setup

@export var board_piece_setup: String

func _ready() -> void:
	
	SignalBus.start_turn.connect(_on_start_turn)
	SignalBus.move_piece.connect(_on_move_piece)
	SignalBus.enable_highlight_tile.connect(_on_enable_highlight_tile)
	SignalBus.enable_tile_indicators.connect(_on_enable_tile_indicators)
	
	var board_parsed_result: Array[Tile] = parse_board_piece_setup()
	
	for board_tile_index: int in range(BOARD_TILE_COUNT):
		var board_tile: Tile = board_parsed_result[board_tile_index]
		add_child(board_tile)
		board_tile.set_collider()
		board_tile.set_tile_default_colour()
		board_tile.tile_virgin = true
		
	
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
		
		var board_tile_children: Array = board_tile.get_children()
		if not board_tile_children.has(board_tile.tile_piece): # Check if "first time" (has child been added yet?)
			break
		var board_tile_piece_index: int = board_tile_children.find(board_tile.tile_piece)
		board_tile_children[board_tile_piece_index].queue_free()

func instance_board_tile_piece_sprites():
	
	for board_tile: Tile in get_children():
		
		var prev_board_tile_piece: Piece = board_tile.tile_piece
		var new_board_tile_piece = copy_prev_board_tile_piece_properties(prev_board_tile_piece)
		prev_board_tile_piece.queue_free()
		board_tile.tile_piece = new_board_tile_piece
		board_tile.add_child(new_board_tile_piece)
		
		new_board_tile_piece.set_piece_sprite()
		new_board_tile_piece.set_collision_area()
		new_board_tile_piece.global_position = board_tile.get_global_rect().position + BOARD_TILE_PIECE_OFFSET

func copy_prev_board_tile_piece_properties(prev_board_tile_piece: Piece):
	
	var new_board_tile_piece = PIECE.instantiate()
	
	new_board_tile_piece.piece_exist = prev_board_tile_piece.piece_exist
	new_board_tile_piece.piece_index = prev_board_tile_piece.piece_index
	new_board_tile_piece.piece_tile_index = prev_board_tile_piece.piece_tile_index
	new_board_tile_piece.piece_colour = prev_board_tile_piece.piece_colour
	new_board_tile_piece.piece_type = prev_board_tile_piece.piece_type
	new_board_tile_piece.piece_legal_moves = prev_board_tile_piece.piece_legal_moves
	
	return new_board_tile_piece

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
					
					EnumBus.Dir.KingCastlingQueenside, EnumBus.Dir.KingCastlingKingside, 
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
				piece_dirs = [
					EnumBus.Dir.KnightTopLeft, EnumBus.Dir.KnightTopRight, 
					EnumBus.Dir.KnightRightTop, EnumBus.Dir.KnightRightBottom, 
					EnumBus.Dir.KnightBottomRight, EnumBus.Dir.KnightBottomLeft, 
					EnumBus.Dir.KnightLeftBottom, EnumBus.Dir.KnightLeftTop, 
				]
			
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
						EnumBus.Dir.NorthWest, EnumBus.Dir.NorthEast, # Capture
						EnumBus.Dir.WhitePawnDoubleStep
					]
				elif colour == EnumBus.Colour.Black:
					piece_dirs = [
						EnumBus.Dir.South, # Normal
						EnumBus.Dir.SouthWest, EnumBus.Dir.SouthEast, # Capture
						EnumBus.Dir.BlackPawnDoubleStep
					]
		
		# For each available direction, determine moves
		for dir: EnumBus.Dir in piece_dirs:
			
			generate_legal_moves_for_direction(repeat, dir, board_tile.tile_index, board_tile_piece.piece_type, colour, board_tile_piece)

func generate_legal_moves_for_direction(repeat: bool, dir: EnumBus.Dir, src_tile_index: int, type: EnumBus.Type, colour: EnumBus.Colour, piece: Piece):
	
	# Check if we're standing on edge tile
	if check_if_on_edge_tile(src_tile_index, type) == true:
		# Check if we intend to move in a direction that is not allowed
		if check_if_dir_forbidden(dir, src_tile_index, type) == true:
			return
	
	var dest_tile_index: int = src_tile_index + dir
	if dest_tile_index not in range(BOARD_TILE_COUNT):
		return # Prevent the "double step problem"
	var board_matrix: Array = get_children()
	var src_tile: Tile = board_matrix[src_tile_index]
	var dest_tile: Tile = board_matrix[dest_tile_index]
	
	# King castling
	if type == EnumBus.Type.King:
		
		var castling_dirs: Array[EnumBus.Dir] = [
			EnumBus.Dir.KingCastlingQueenside, EnumBus.Dir.KingCastlingKingside
		]
		
		if dir in castling_dirs:
			
			if check_if_castling_is_legal(dir, src_tile_index, colour):
				piece.piece_legal_moves.append(dest_tile)
				return
			else:
				return
	
	# Check if we're a pawn
	if type == EnumBus.Type.Pawn:
		# Double step
		var double_steps: Array[EnumBus.Dir] = [EnumBus.Dir.WhitePawnDoubleStep, EnumBus.Dir.BlackPawnDoubleStep]
		
		if dir in double_steps:
			
			if not src_tile.tile_virgin:
				return
			
			if dest_tile.tile_piece.piece_exist:
				return
			
			var starting_rank: Array
			if colour == EnumBus.Colour.White:
				starting_rank = range(48, 56)
			elif colour == EnumBus.Colour.Black:
				starting_rank = range(8, 24)
			
			if src_tile_index not in starting_rank:
				return
			
			piece.piece_legal_moves.append(dest_tile)
			return
		
		# Piece capture
		var capture_dirs: Array[EnumBus.Dir] = [
			EnumBus.Dir.NorthWest, EnumBus.Dir.NorthEast, 
			EnumBus.Dir.SouthWest, EnumBus.Dir.SouthEast, 
		]
		
		if dir in capture_dirs:
			
			if not dest_tile.tile_piece.piece_exist:
				return 
			# Check if piece colour is opposite colour's
			var target_piece: Piece = dest_tile.tile_piece
			
			if target_piece.piece_colour == colour:
				# It's our own piece, cannot capture -- direction invalid
				return
			elif target_piece.piece_colour != colour:
				# We can capture this piece
				piece.piece_legal_moves.append(dest_tile)
				return
		
		# Normal move
		
			# Check if dest is occupied by another piece
		
		if dest_tile.tile_piece.piece_exist == true:
			return
		elif dest_tile.tile_piece.piece_exist == false:
			piece.piece_legal_moves.append(dest_tile)
			return
	
	# Check if dest is occupied by another piece
	if dest_tile.tile_piece.piece_exist == true:
		var other_piece: Piece = dest_tile.tile_piece
		# Check if other piece is my colour
		if other_piece.piece_colour == colour:
			# Can't move here -- end of this direction, stop searching
			return
		elif other_piece.piece_colour != colour:
			# You may move here & capture the piece -- end of this direction, stop searching
			piece.piece_legal_moves.append(dest_tile)
			return
		
	elif dest_tile.tile_piece.piece_exist == false:
		# You may move here, as the space is empty
		piece.piece_legal_moves.append(dest_tile)
	
	# Check if piece is "repeat", i.e. should we continue searching
	if repeat:
		generate_legal_moves_for_direction(repeat, dir, dest_tile_index, type, colour, piece)
	elif not repeat:
		return

func check_if_castling_is_legal(dir: EnumBus.Dir, src_tile_index: int, colour: EnumBus.Colour):
	
	var correct_king_castling_position_tile_index: int
	if colour == EnumBus.Colour.White:
		correct_king_castling_position_tile_index = 60
	elif colour == EnumBus.Colour.Black:
		correct_king_castling_position_tile_index = 4
	
	# The king must be on the right tile
	if src_tile_index != correct_king_castling_position_tile_index:
		return false
	
	var board_matrix: Array = get_children()
	var king_tile: Tile = board_matrix[src_tile_index]
	
	# The king must not have previously moved
	if not king_tile.tile_virgin:
		return false
	
	var rook_tile_index: int
	match dir:
		EnumBus.Dir.KingCastlingQueenside:
			rook_tile_index = src_tile_index + (EnumBus.Dir.West * 4)
		EnumBus.Dir.KingCastlingKingside:
			rook_tile_index = src_tile_index + (EnumBus.Dir.East * 3)
	var rook_tile: Tile = board_matrix[rook_tile_index]
	
	# The rook must not have previously moved
	if not rook_tile.tile_virgin:
		return false
	
	var vacant_tile_index_range: Array
	match dir:
		EnumBus.Dir.KingCastlingQueenside:
			vacant_tile_index_range = range(rook_tile_index + 1, src_tile_index)
		EnumBus.Dir.KingCastlingKingside:
			vacant_tile_index_range = range(src_tile_index + 1, rook_tile_index)
	
	# Each tile between the rook and the king must be vacant
	for tile_index in vacant_tile_index_range:
		var vacant_tile: Tile = board_matrix[tile_index]
		if vacant_tile.tile_piece.piece_exist:
			return false
	
	return true

func check_if_on_edge_tile(src_tile_index: int, type: EnumBus.Type):
	
	if type == EnumBus.Type.Knight:
		var knight_top_left_range = range(0, 24)
		knight_top_left_range.append_array(range(0, 57, 8))
		
		var knight_top_right_range = range(0, 24)
		knight_top_right_range.append_array(range(7, 64, 8))
		
		var knight_right_top_range =  range(7, 64, 8)
		knight_right_top_range.append_array(range(6, 63, 8))
		knight_right_top_range.append_array(range(0, 8))
		
		var knight_right_bottom_range = range(7, 64, 8)
		knight_right_bottom_range.append_array(range(6, 63, 8))
		knight_right_bottom_range.append_array(range(56, 64))
		
		var knight_bottom_right_range = range(48, 64)
		knight_bottom_right_range.append_array(range(7, 64, 8))
		
		var knight_bottom_left_range = range(48, 64)
		knight_bottom_left_range.append_array(range(0, 57, 8))
		
		var knight_left_bottom_range = range(0, 57, 8)
		knight_left_bottom_range.append_array(range(1, 58, 8))
		knight_left_bottom_range.append_array(range(57, 63))
		
		var knight_left_top_range = range(0, 57, 8)
		knight_left_top_range.append_array(range(1, 58, 8))
		knight_left_top_range.append_array(range(1, 7))
		
		var knight_edge_tiles: Array = [
			knight_top_left_range, knight_top_right_range, 
			knight_right_top_range, knight_right_bottom_range, 
			knight_bottom_right_range, knight_bottom_left_range, 
			knight_left_bottom_range, knight_left_top_range, 
		]
		
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
		var knight_top_left_range = range(0, 16)
		knight_top_left_range.append_array(range(0, 57, 8))
		
		var knight_top_right_range = range(0, 16)
		knight_top_right_range.append_array(range(7, 64, 8))
		
		var knight_right_top_range =  range(7, 64, 8)
		knight_right_top_range.append_array(range(6, 63, 8))
		knight_right_top_range.append_array(range(0, 8))
		
		var knight_right_bottom_range = range(7, 64, 8)
		knight_right_bottom_range.append_array(range(6, 63, 8))
		knight_right_bottom_range.append_array(range(56, 64))
		
		var knight_bottom_right_range = range(48, 64)
		knight_bottom_right_range.append_array(range(7, 64, 8))
		
		var knight_bottom_left_range = range(48, 64)
		knight_bottom_left_range.append_array(range(0, 57, 8))
		
		var knight_left_bottom_range = range(0, 57, 8)
		knight_left_bottom_range.append_array(range(1, 58, 8))
		knight_left_bottom_range.append_array(range(57, 63))
		
		var knight_left_top_range = range(0, 57, 8)
		knight_left_top_range.append_array(range(1, 58, 8))
		knight_left_top_range.append_array(range(1, 7))
		
		var knight_edge_tiles: Array = [
			knight_top_left_range, knight_top_right_range, 
			knight_right_top_range, knight_right_bottom_range, 
			knight_bottom_right_range, knight_bottom_left_range, 
			knight_left_bottom_range, knight_left_top_range, 
		]
		
		var knight_edge_tiles_forbidden_dirs: Dictionary = {
			str(knight_top_left_range): EnumBus.Dir.KnightTopLeft, 
			str(knight_top_right_range): EnumBus.Dir.KnightTopRight, 
			str(knight_right_top_range): EnumBus.Dir.KnightRightTop, 
			str(knight_right_bottom_range): EnumBus.Dir.KnightRightBottom, 
			str(knight_bottom_right_range): EnumBus.Dir.KnightBottomRight, 
			str(knight_bottom_left_range): EnumBus.Dir.KnightBottomLeft, 
			str(knight_left_bottom_range): EnumBus.Dir.KnightLeftBottom, 
			str(knight_left_top_range): EnumBus.Dir.KnightLeftTop, 
		}
		
		var my_forbidden_dirs: Array[EnumBus.Dir] = []
		for knight_edge_tiles_range in knight_edge_tiles:
			if src_tile_index in knight_edge_tiles_range:
				my_forbidden_dirs.append(knight_edge_tiles_forbidden_dirs[str(knight_edge_tiles_range)])
		
		# Check if the direction that we intend to move in is forbidden
		if dir in my_forbidden_dirs:
			return true
	
	elif type != EnumBus.Type.Knight:
		var normal_edge_tiles: Array = [ # Array of ranges containing "edge tiles"
			# Singleton tiles, i.e. corners
			range(0, 1), range(7, 8), range(63, 64), range(56, 57), 
			
			# Other edge tiles, i.e. columns and rows
			range(1, 7), range(7, 64, 8), range(57, 63), range(0, 57, 8)
		]
		
		# "What range are we in?"
		var my_range: Array
		for normal_edge_tiles_range in normal_edge_tiles:
			if src_tile_index in normal_edge_tiles_range:
				my_range = normal_edge_tiles_range
				break
		
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
				EnumBus.Dir.East, 
				EnumBus.Dir.NorthEast, EnumBus.Dir.SouthEast
			],
			str(range(57, 63)): [ # Bottom row
				EnumBus.Dir.South, 
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

# Piece Movement

var prev_src_tile: Tile
var prev_dest_tile: Tile

func _on_move_piece(piece_src_tile_index: int, piece_dest_tile_index: int, colour: EnumBus.Colour):
	
	var board_matrix: Array = get_children()
	var src_tile: Tile = board_matrix[piece_src_tile_index]
	var dest_tile: Tile = board_matrix[piece_dest_tile_index]
	
	# Castling
	
	if check_if_move_is_castling(src_tile, dest_tile):
		
		# Determine the position & destination of the rook
		var rook_src_tile_index: int
		var rook_dest_tile_index: int
		var dir: EnumBus.Dir = dest_tile.tile_index - src_tile.tile_index
		match dir:
			EnumBus.Dir.KingCastlingQueenside:
				rook_src_tile_index = src_tile.tile_index + (EnumBus.Dir.West * 4)
				rook_dest_tile_index = src_tile.tile_index + (EnumBus.Dir.West * 1)
			EnumBus.Dir.KingCastlingKingside:
				rook_src_tile_index = src_tile.tile_index + (EnumBus.Dir.East * 3)
				rook_dest_tile_index = src_tile.tile_index + (EnumBus.Dir.East * 1)
		
		var rook_src_tile: Tile = board_matrix[rook_src_tile_index]
		var rook_dest_tile: Tile = board_matrix[rook_dest_tile_index]
		
		# Update dest to reflect movement
		rook_dest_tile.tile_virgin = false
		rook_dest_tile.tile_piece = rook_src_tile.tile_piece
		rook_dest_tile.tile_piece.piece_tile_index = rook_dest_tile.tile_index
		
		# Update src, i.e. clear the tile
		rook_src_tile.tile_virgin = false
		rook_src_tile.tile_piece.queue_free()
		rook_src_tile.tile_piece = PIECE.instantiate()
		rook_src_tile.tile_piece.piece_exist = false
	
	# Capture piece
	if dest_tile.tile_piece.piece_exist:
		# Remove the sprite, i.e. free it
		var dest_tile_children: Array = dest_tile.get_children()
		var dest_tile_piece_index: int = dest_tile_children.find(dest_tile.tile_piece)
		dest_tile_children[dest_tile_piece_index].queue_free()
	
	# Update dest to reflect movement
	dest_tile.tile_virgin = false
	dest_tile.tile_piece = src_tile.tile_piece # Piece's movement
	dest_tile.tile_piece.piece_tile_index = dest_tile.tile_index # Update piece's internal knowledge of location, i.e. the tile it's standing on
	
	# Update src, i.e. clear the tile
	src_tile.tile_virgin = false
	src_tile.tile_piece.queue_free() # Reset the piece
	src_tile.tile_piece = PIECE.instantiate()
	src_tile.tile_piece.piece_exist = false
	
	# Highlight src, dest & disable prev
	
	SignalBus.enable_highlight_tile.emit(true, src_tile.tile_index)
	SignalBus.enable_highlight_tile.emit(true, dest_tile.tile_index)
	
	if prev_src_tile != null:
		SignalBus.enable_highlight_tile.emit(false, prev_src_tile.tile_index)
	if prev_dest_tile != null:
		SignalBus.enable_highlight_tile.emit(false, prev_dest_tile.tile_index)
	
	prev_src_tile = src_tile
	prev_dest_tile = dest_tile
	
	if colour == EnumBus.Colour.White:
		SignalBus.start_turn.emit(EnumBus.Colour.Black)
	elif colour == EnumBus.Colour.Black:
		SignalBus.start_turn.emit(EnumBus.Colour.White)

	# Castling

func check_if_move_is_castling(src_tile: Tile, dest_tile: Tile):
	
	# Check if piece is a king
	if src_tile.tile_piece.piece_type != EnumBus.Type.King:
		return false
	
	var dir: EnumBus.Dir = dest_tile.tile_index - src_tile.tile_index
	var castling_dirs: Array[EnumBus.Dir] = [
		EnumBus.Dir.KingCastlingQueenside, EnumBus.Dir.KingCastlingKingside
	]
	
	# Check if king is castling
	if dir not in castling_dirs:
		return false
	
	return true

# Board Tile Visual Management

	# Highlight Tile

func _on_enable_highlight_tile(enable: bool, tile_index: int):
	
	var board_matrix: Array = get_children()
	var board_tile_target: Tile = board_matrix[tile_index]
	
	if enable:
		board_tile_target.set_tile_highlight_colour()
	
	elif not enable:
		board_tile_target.set_tile_default_colour()

	# Display Indicator

func _on_enable_tile_indicators(enable: bool, tiles: Array[Tile]):
	
	for tile: Tile in tiles:
		
		tile.display_tile_indicators(enable)
