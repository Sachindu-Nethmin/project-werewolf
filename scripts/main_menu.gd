extends Control

func _ready() -> void:
	$VBox/DayButton.pressed.connect(_on_day_pressed)
	$VBox/NightButton.pressed.connect(_on_night_pressed)
	$VBox/QuitButton.pressed.connect(_on_quit_pressed)

func _on_day_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/level_2.tscn")

func _on_night_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/level_1.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
