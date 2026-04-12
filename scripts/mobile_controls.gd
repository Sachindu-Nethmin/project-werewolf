extends Control

@export var joystick_base_size: float = 100.0
@export var joystick_handle_size: float = 50.0
@export var button_size: float = 100.0
@export var padding: float = 20.0

@onready var joystick_base = $JoystickBase
@onready var joystick_handle = $JoystickBase/JoystickHandle
@onready var jump_button = $JumpButton

var _joystick_touch_id: int = -1
var _jump_touch_id: int = -1
var _joystick_center: Vector2
var _joystick_max_distance: float
var _mouse_pressed := false


func _ready() -> void:
	# Position controls relative to viewport
	var viewport_size = get_viewport_rect().size

	# Joystick: bottom-right corner
	joystick_base.position = Vector2(
		viewport_size.x - joystick_base_size - padding,
		viewport_size.y - joystick_base_size - padding
	)

	# Jump button: bottom-left corner
	jump_button.position = Vector2(
		padding,
		viewport_size.y - button_size - padding
	)

	_joystick_center = joystick_base.global_position + joystick_base.size / 2
	_joystick_max_distance = joystick_base_size / 2


func _input(event: InputEvent) -> void:
	# Handle touch input
	if event is InputEventScreenTouch:
		if event.pressed:
			_on_touch_pressed(event.position, event.get_index())
		else:
			_on_touch_released(event.get_index())
	elif event is InputEventScreenDrag:
		_on_touch_dragged(event)

	# Handle mouse input (for Godot editor play simulation)
	elif event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_touch_pressed(event.position, 0)
			_mouse_pressed = true
		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_touch_released(0)
			_mouse_pressed = false
	elif event is InputEventMouseMotion and _mouse_pressed:
		_on_touch_dragged(event)


func _on_touch_pressed(position: Vector2, touch_id: int) -> void:
	var joystick_rect = joystick_base.get_global_rect()
	var jump_rect = jump_button.get_global_rect()

	# Check if touch is on joystick
	if joystick_rect.has_point(position):
		_joystick_touch_id = touch_id
		_update_joystick(position)
	# Check if touch is on jump button
	elif jump_rect.has_point(position):
		_jump_touch_id = touch_id
		jump_button.modulate = Color.GRAY
		Input.action_press("ui_accept")


func _on_touch_released(touch_id: int) -> void:
	# Reset joystick
	if _joystick_touch_id == touch_id:
		_joystick_touch_id = -1
		joystick_handle.position = Vector2.ZERO
		Input.action_release("ui_left")
		Input.action_release("ui_right")

	# Reset jump button
	if _jump_touch_id == touch_id:
		_jump_touch_id = -1
		jump_button.modulate = Color.WHITE
		Input.action_release("ui_accept")


func _on_touch_dragged(event: InputEvent) -> void:
	var pos = event.position if event is InputEventScreenDrag else (event as InputEventMouseMotion).position

	if _joystick_touch_id == (event.get_index() if event is InputEventScreenDrag else 0):
		_update_joystick(pos)


func _update_joystick(touch_position: Vector2) -> void:
	var joystick_rect = joystick_base.get_global_rect()
	_joystick_center = joystick_rect.get_center()

	# Calculate vector from center to touch
	var touch_offset = touch_position - _joystick_center
	var distance = touch_offset.length()

	# Clamp to max distance
	if distance > _joystick_max_distance:
		touch_offset = touch_offset.normalized() * _joystick_max_distance
		distance = _joystick_max_distance

	# Update handle position (relative to base)
	var handle_local_pos = touch_offset
	joystick_handle.position = handle_local_pos

	# Determine input based on direction
	_update_movement_input(touch_offset)


func _update_movement_input(offset: Vector2) -> void:
	# Use a deadzone to avoid drift
	var deadzone = 10.0

	if offset.x < -deadzone:
		Input.action_press("ui_left")
		Input.action_release("ui_right")
	elif offset.x > deadzone:
		Input.action_press("ui_right")
		Input.action_release("ui_left")
	else:
		Input.action_release("ui_left")
		Input.action_release("ui_right")
