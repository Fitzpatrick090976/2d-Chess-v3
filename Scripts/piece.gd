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
	
	visible = true
	
	if not piece_exist:
		visible = false
		return
	
	if piece_colour == EnumBus.Colour.White:
		sprite.animation = "white_pieces"
	elif piece_colour == EnumBus.Colour.Black:
		sprite.animation = "black_pieces"
	
	sprite.frame = piece_type

# Piece User Input Interaction

	# Cursor Collision

@export var collision_area: Area2D

var cursor_colliding: bool = false
var piece_draggable: bool = false

func set_collision_area() -> void:
	
	if not piece_exist:
		return
	
	collision_area.mouse_entered.connect(_on_mouse_entered)
	collision_area.mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	
	cursor_colliding = true

func _on_mouse_exited():
	
	cursor_colliding = false

	# Input Reaction

func _input(event: InputEvent) -> void:
	
	if not white_control:
		return
	
	if event is InputEventMouseMotion:
		return
	
	if not piece_exist:
		return
	
	if not cursor_colliding:
		return
	
	if piece_colour != EnumBus.Colour.White:
		return
	
	# We know that this is a piece that we own
	if event.is_action_pressed("left_click"):
		
		# Highlight the tile upon which I'm standing
		SignalBus.enable_highlight_tile.emit(true, piece_tile_index)
		
		# Enable "move indicators"
		SignalBus.enable_tile_indicators.emit(true, piece_legal_moves)
		
		piece_draggable = true
		z_index = 200
	
	elif event.is_action_released("left_click"):
		
		# Disable highlight & indicators
		SignalBus.enable_highlight_tile.emit(false, piece_tile_index)
		SignalBus.enable_tile_indicators.emit(false, piece_legal_moves)
		
		piece_draggable = false
		z_index = 50
		
		if piece_last_cursor_tile_collision in piece_legal_moves:
			SignalBus.move_piece.emit(piece_tile_index, piece_last_cursor_tile_collision.tile_index, EnumBus.Colour.White)
		else:
			SignalBus.start_turn.emit(EnumBus.Colour.White)
		

func _physics_process(delta: float) -> void:
	if piece_draggable:
		global_position = get_global_mouse_position()

# Cursor Tile Collision

var piece_last_cursor_tile_collision: Tile

func _ready() -> void:
	
	SignalBus.cursor_tile_collision.connect(_on_cursor_tile_collision)
	SignalBus.enable_white_control.connect(_on_enable_white_control)

func _on_cursor_tile_collision(tile: Tile):
	
	if not piece_draggable:
		return
	
	piece_last_cursor_tile_collision = tile

var white_control: bool = false

func _on_enable_white_control(enable: bool):
	
	white_control = enable
