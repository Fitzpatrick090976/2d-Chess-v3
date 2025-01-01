extends Node

signal start_turn(colour: EnumBus.Colour)

signal enable_white_control(enable: bool)

signal black_move()

signal move_piece(piece_src_tile: Tile, piece_dest_tile: Tile)

signal enable_highlight_tile(enable: bool, tile_index: int)

signal enable_tile_indicators(enable: bool, tiles: Array[Tile])
