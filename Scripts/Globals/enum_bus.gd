extends Node

enum Colour {
	White, Black
}

enum Type {
	King, Queen, Bishop, Knight, Rook, Pawn
}

enum Dir {
	NorthWest = -9, North = -8, NorthEast = -7, East = 1, 
	SouthEast = 9, South = 8, SouthWest = 7, West = -1, 
	
	KnightTopLeft = -17, KnightTopRight = -15, 
	KnightRightTop = -6, KnightRightBottom = 10, 
	KnightBottomRight = 17, KnightBottomLeft = 15, 
	KnightLeftBottom = 6, KnightLeftTop = -10, 
	
	WhitePawnDoubleStep = -16, BlackPawnDoubleStep = 16
}
