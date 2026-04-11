extends Node2D

# ─── Tile type constants ──────────────────────────────────────────────────────
const EMPTY   := 0
const GRASS   := 1   # green surface cap + dirt body (walkable top)
const DIRT    := 2   # dirt body only      (underground fill)
const STONE   := 3   # stone surface cap + stone body
const ROCK    := 4   # solid stone body    (deep underground)
const BEDROCK := 5   # impenetrable base layer
const FUNGUS  := 6   # fungus-top platform (atmospheric mid-level)
const GLOW    := 7   # glowing platform    (high / special)

# ─── World geometry ───────────────────────────────────────────────────────────
const TILE_SIZE := 128   # px per tile

# 22 cols × 13 rows  →  2816 × 1664 px world
# Reading guide:
#   Rows  0-1   : open sky
#   Rows  2-3   : high glow platforms
#   Rows  4-5   : mid fungus platforms
#   Rows  6-7   : low grass platforms
#   Row   8     : ground surface (GRASS)
#   Rows  9-10  : sub-surface    (DIRT)
#   Row  11     : deep stone     (ROCK)
#   Row  12     : bedrock        (BEDROCK)
const LEVEL: Array = [
#    0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21
	[ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ], # 0
	[ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ], # 1
	[ 0, 0, 7, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 7, 0, 0 ], # 2  glow
	[ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ], # 3
	[ 0, 0, 0, 0, 0, 6, 6, 6, 0, 0, 0, 0, 6, 6, 6, 0, 0, 0, 0, 0, 0, 0 ], # 4  fungus
	[ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ], # 5
	[ 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0 ], # 6  grass plat
	[ 0, 0, 2, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 2, 0, 0, 0, 0 ], # 7  dirt body
	[ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ], # 8  ground surface
	[ 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2 ], # 9  sub-surface
	[ 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2 ], # 10 deeper dirt
	[ 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4 ], # 11 deep stone
	[ 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5 ], # 12 bedrock
]

# ─── Texture map ──────────────────────────────────────────────────────────────
const TEX_BASE := "res://asset/terrain/generated/"

const TEX_PATHS := {
	GRASS:   TEX_BASE + "grass_surface.png",
	DIRT:    TEX_BASE + "dirt_body.png",
	STONE:   TEX_BASE + "stone_surface.png",
	ROCK:    TEX_BASE + "stone_body.png",
	BEDROCK: TEX_BASE + "bedrock.png",
	FUNGUS:  TEX_BASE + "fungus_surface.png",
	GLOW:    TEX_BASE + "glow_surface.png",
}

# Brightness multiplier per tile type (Z-depth cue for 2.5D)
const MODULATE := {
	GRASS:   Color(1.00, 1.00, 1.00, 1),
	DIRT:    Color(0.88, 0.84, 0.80, 1),
	STONE:   Color(0.95, 0.95, 1.00, 1),
	ROCK:    Color(0.72, 0.72, 0.76, 1),
	BEDROCK: Color(0.55, 0.55, 0.58, 1),
	FUNGUS:  Color(1.00, 0.95, 0.90, 1),
	GLOW:    Color(1.00, 1.00, 1.00, 1),
}

# ─── State ────────────────────────────────────────────────────────────────────
var _tex: Dictionary = {}


# ─── Lifecycle ────────────────────────────────────────────────────────────────
func _ready() -> void:
	for tile_type in TEX_PATHS:
		_tex[tile_type] = load(TEX_PATHS[tile_type])

	var kill_zone: Area2D = $KillZone
	kill_zone.body_entered.connect(_on_kill_zone_body_entered)

	_build_level()


# ─── Level builder ────────────────────────────────────────────────────────────
func _build_level() -> void:
	for row in LEVEL.size():
		for col in LEVEL[row].size():
			var tile_type: int = LEVEL[row][col]
			if tile_type == EMPTY:
				continue
			_spawn_tile(col, row, tile_type)


func _spawn_tile(col: int, row: int, tile_type: int) -> void:
	var body := StaticBody2D.new()
	body.position = Vector2(
		col * TILE_SIZE + TILE_SIZE * 0.5,
		row * TILE_SIZE + TILE_SIZE * 0.5
	)

	var sprite := Sprite2D.new()
	sprite.texture  = _tex[tile_type]
	sprite.modulate = MODULATE.get(tile_type, Color.WHITE)
	body.add_child(sprite)

	var col_shape := CollisionShape2D.new()
	var rect      := RectangleShape2D.new()
	rect.size      = Vector2(TILE_SIZE, TILE_SIZE)
	col_shape.shape = rect
	body.add_child(col_shape)

	add_child(body)


func _on_kill_zone_body_entered(body: Node2D) -> void:
	if body.has_method("respawn"):
		body.respawn()
