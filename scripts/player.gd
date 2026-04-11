extends CharacterBody2D

const SPEED         := 220.0
const JUMP_VELOCITY := -520.0
const GRAVITY       := 980.0

# Walk animation: 4 frames at this interval
const WALK_FPS  := 8.0

var spawn_point: Vector2

@onready var _sprite: Sprite2D = $Sprite2D

var _walk_timer := 0.0


func _ready() -> void:
	spawn_point = global_position


func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Horizontal movement
	var direction := Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * SPEED

	move_and_slide()
	_update_sprite(direction, delta)


func _update_sprite(direction: float, delta: float) -> void:
	if direction != 0.0:
		# Face the direction of travel
		_sprite.flip_h = direction < 0.0
		# Advance walk cycle
		_walk_timer += delta
		if _walk_timer >= 1.0 / WALK_FPS:
			_walk_timer = 0.0
			_sprite.frame = (_sprite.frame + 1) % 4
	else:
		# Return to idle frame
		_sprite.frame = 0
		_walk_timer  = 0.0


# Called by the kill zone when the player falls off the map.
func respawn() -> void:
	global_position = spawn_point
	velocity        = Vector2.ZERO
