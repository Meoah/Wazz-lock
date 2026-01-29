extends Control

@export var button_play : Button
@export var button_options : Button
@export var button_quit : Button

func _ready() -> void:
	# Disables the quit button entirely if it's on web since that just crashes the game if clicked.
	if OS.has_feature("web"):
		button_quit.visible = false
		
	#TODO audio
	#TODO save file

func _on_play_pressed():
	# TODO THIS NEEDS TO BE CHANGED FROM DEBUG SCENE
	GameManager.start_debug_room()
