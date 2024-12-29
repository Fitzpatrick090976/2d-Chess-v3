extends ColorRect

class_name Tile

@export var tile_index: int
@export var tile_dark: bool
@export var tile_piece: Piece

# Tile Visual Representation

const TILE_COLOUR_DEFAULT_DARK: Color = Color(0.60, 0.36, 0.23)
const TILE_COLOUR_DEFAULT_LIGHT: Color = Color(0.90, 0.76, 0.63)
const TILE_COLOUR_HIGHLIGHT_DARK: Color = Color(0.60, 0.45, 0.00)
const TILE_COLOUR_HIGHLIGHT_LIGHT: Color = Color(0.90, 0.85, 0.36)

func set_tile_default_colour():
	
	if tile_dark:
		color = TILE_COLOUR_DEFAULT_DARK
	else:
		color = TILE_COLOUR_DEFAULT_LIGHT

func set_tile_highlight_colour():
	
	if tile_dark:
		color = TILE_COLOUR_HIGHLIGHT_DARK
	else:
		color = TILE_COLOUR_HIGHLIGHT_LIGHT
