extends Control

# Base sizes matching the .tscn authored values
const BASE_TITLE_HALF_W: float = 300.0
const BASE_TITLE_BAR_H: float = 6.0
const BASE_VBOX_HALF_W: float = 140.0
const BASE_BUTTON_W: float = 280.0
const BASE_BUTTON_H: float = 56.0
const BASE_VBOX_SEP: float = 18.0

# Base font sizes from .tscn
const BASE_FONT_TITLE: int = 52
const BASE_FONT_SUBTITLE: int = 18
const BASE_FONT_MODE: int = 14
const BASE_FONT_BUTTON: int = 22
const BASE_FONT_VERSION: int = 12

@onready var title_container: VBoxContainer = $TitleContainer
@onready var title_bar: ColorRect = $TitleContainer/TitleBar
@onready var title_bar_bot: ColorRect = $TitleContainer/TitleBarBottom
@onready var title_label: Label = $TitleContainer/TitleLabel
@onready var subtitle_label: Label = $TitleContainer/SubtitleLabel
@onready var vbox: VBoxContainer = $VBox
@onready var mode_label: Label = $VBox/ModeLabel
@onready var day_button: Button = $VBox/DayButton
@onready var night_button: Button = $VBox/NightButton
@onready var room_code_input: LineEdit = $VBox/RoomCodeInput
@onready var status_label: Label = $VBox/StatusLabel
@onready var host_button: Button = $VBox/HostButton
@onready var join_button: Button = $VBox/JoinButton
@onready var quit_button: Button = $VBox/QuitButton
@onready var version_label: Label = $VersionLabel


func _ready() -> void:
	day_button.pressed.connect(_on_day_pressed)
	night_button.pressed.connect(_on_night_pressed)
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	MultiplayerManager.room_code_ready.connect(_on_room_code_ready)
	MultiplayerManager.connection_failed.connect(_on_connection_failed)
	MultiplayerManager.connected_to_game.connect(_on_connected_to_game, CONNECT_ONE_SHOT)

	ResponsiveUI.scale_changed.connect(_apply_layout)
	_apply_layout(ResponsiveUI.scale_factor)


func _apply_layout(sf: float) -> void:
	var half_title_w: float = BASE_TITLE_HALF_W * sf
	var half_vbox_w: float = BASE_VBOX_HALF_W * sf
	var button_w: float = BASE_BUTTON_W * sf
	var button_h: float = BASE_BUTTON_H * sf
	var title_bar_h: float = BASE_TITLE_BAR_H * sf

	# TitleContainer: re-apply offsets to maintain centered anchor
	title_container.offset_left = -half_title_w
	title_container.offset_right = half_title_w

	# Title bars width
	title_bar.custom_minimum_size = Vector2(half_title_w * 2.0, title_bar_h)
	title_bar_bot.custom_minimum_size = Vector2(half_title_w * 2.0, title_bar_h)

	# VBox: re-apply offsets
	vbox.offset_left = -half_vbox_w
	vbox.offset_right = half_vbox_w
	vbox.add_theme_constant_override("separation", int(BASE_VBOX_SEP * sf))

	# Button sizes
	for btn in [day_button, night_button, host_button, join_button, quit_button]:
		btn.custom_minimum_size = Vector2(button_w, button_h)

	room_code_input.custom_minimum_size = Vector2(button_w, button_h * 0.7)
	status_label.custom_minimum_size = Vector2(button_w, button_h * 0.5)

	# Font sizes
	title_label.add_theme_font_size_override("font_size", int(BASE_FONT_TITLE * sf))
	subtitle_label.add_theme_font_size_override("font_size", int(BASE_FONT_SUBTITLE * sf))
	mode_label.add_theme_font_size_override("font_size", int(BASE_FONT_MODE * sf))
	for btn in [day_button, night_button, host_button, join_button, quit_button]:
		btn.add_theme_font_size_override("font_size", int(BASE_FONT_BUTTON * sf))
	room_code_input.add_theme_font_size_override("font_size", int(BASE_FONT_MODE * sf))
	status_label.add_theme_font_size_override("font_size", int(BASE_FONT_MODE * sf))
	version_label.add_theme_font_size_override("font_size", int(BASE_FONT_VERSION * sf))


func _on_day_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/level_2.tscn")


func _on_night_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/level_1.tscn")


func _on_host_pressed() -> void:
	host_button.disabled = true
	join_button.disabled = true
	status_label.text = "Creating room..."
	MultiplayerManager.host_game()


func _on_join_pressed() -> void:
	var code := room_code_input.text.strip_edges().to_upper()
	if code.length() < 4:
		status_label.text = "Room code too short"
		return
	host_button.disabled = true
	join_button.disabled = true
	status_label.text = "Connecting..."
	MultiplayerManager.join_game(code)


func _on_room_code_ready(code: String) -> void:
	status_label.text = "Room Code: " + code
	room_code_input.visible = false
	get_tree().change_scene_to_file("res://scenes/level_1.tscn")


func _on_connected_to_game() -> void:
	get_tree().change_scene_to_file("res://scenes/level_1.tscn")


func _on_connection_failed(reason: String) -> void:
	status_label.text = "Failed: " + reason
	host_button.disabled = false
	join_button.disabled = false


func _on_quit_pressed() -> void:
	get_tree().quit()
