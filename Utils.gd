extends Node

onready var pause_menu = $"/root/Multiplayer/Control"

func _ready():
	pause_menu.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	pause()

func go_fullscreen():
#	print("Toggling Fullscreen")
	OS.window_fullscreen = !OS.window_fullscreen

func force_exit():
#	print("Exiting")
	get_tree().quit()

func pause():
#	print("Toggle Pausing")
	if (get_tree().paused):
		get_tree().paused = false
		pause_menu.visible = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		get_tree().paused = true
		pause_menu.visible = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func reload_game():
	Input.action_release("reload_game")
	get_tree().reload_current_scene()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().paused = false

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("go_fullscreen"):
		go_fullscreen()
	if Input.is_action_pressed("force_exit"):
		force_exit()
	if Input.is_action_pressed("pause"):
		pause()
	if Input.is_action_pressed("reload_game"):
		reload_game()

