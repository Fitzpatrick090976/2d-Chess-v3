extends Node2D

class_name Piece

@export var piece_exist: bool
@export var piece_index: int
@export var piece_tile_index: int # i.e. parent's tile index
@export var piece_colour: EnumBus.Colour
@export var piece_type: EnumBus.Type
@export var piece_legal_moves: Array[Tile]

# Piece Visual Representation

@export var sprite: AnimatedSprite2D

func set_piece_sprite():
	
	if not piece_exist:
		return
	
	if piece_colour == EnumBus.Colour.White:
		sprite.animation = "white_pieces"
	elif piece_colour == EnumBus.Colour.Black:
		sprite.animation = "black_pieces"
	
	sprite.frame = piece_type
