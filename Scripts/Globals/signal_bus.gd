extends Node

@warning_ignore("unused_signal")
signal start_turn(colour: EnumBus.Colour)

@warning_ignore("unused_signal")
signal enable_white_control(enable: bool)

@warning_ignore("unused_signal")
signal black_move()

@warning_ignore("unused_signal")
signal move_piece(piece_src_tile_index: int, piece_dest_tile_index: int)

@warning_ignore("unused_signal")
signal enable_highlight_tile(enable: bool, tile_index: int)

@warning_ignore("unused_signal")
signal enable_tile_indicators(enable: bool, tiles: Array[Tile])

@warning_ignore("unused_signal")
signal cursor_tile_collision(tile: Tile)
