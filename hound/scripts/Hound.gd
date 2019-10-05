extends VehicleBody

export var kick_force : float = 600
export var jump_force : float = 22
export var stopping_force : float = 500
export var stopping_turn : float = PI/2

var done_mid_lap : bool = false
var start_lap_count : int = 0
var lap_count : int = 0
var lap_time : float = 0

var og_translation : Vector3
var og_rotation : Vector3

onready var speed_label = $"Control/Panel/VBoxContainer/SpeedLabel"

export var max_health : int = 10000
onready var health : int = max_health

signal finished_race

func _ready():
	set_network_master(-1)
	_brake(5000)
	Multiplayer.connect("ready_to_race", self, "_ready_to_race")

	get_tree().get_nodes_in_group("StartLap")[0].connect("body_exited", self, "_start_lap")
	get_tree().get_nodes_in_group("StartLap")[0].connect("body_entered", self, "_end_lap")
	get_tree().get_nodes_in_group("MidLap")[0].connect("body_entered", self, "_mid_lap")

	og_translation = translation
	og_rotation = rotation

	$Control/Panel/VBoxContainer/ProgressBar.max_value = max_health
	$Control/Panel/VBoxContainer/ProgressBar.value = max_health

	$Control.hide()
	$Camera/motion_blur.hide()
	pass

func _ready_to_race():
	print("READY TO RACE!!!" + str(name))
	if is_network_master():
		$Camera.make_current()
		$Control.show()

func _process(delta: float) -> void:
	lap_time += delta
	if is_network_master():
		if (Input.is_action_pressed("player_skid")):
			rpc_unreliable("_brake", kick_force / 10)
		else:
			if (is_on_ground()):
				if (Input.is_action_just_pressed("player_jump")):
	#				TODO: Check if on ground! DONE!
					apply_central_impulse(Vector3(0, jump_force * mass, 0))
				if (Input.is_action_pressed("player_forward")):
					rpc_unreliable("_gas", kick_force)
				else:
					if (Input.is_action_pressed("player_backwards")):
						rpc_unreliable("_gas", -kick_force)
					else:
						rpc_unreliable("_brake", kick_force / 2)
			else:
				$"Mesh/Scene Root/AnimationPlayer".stop()
				apply_central_impulse(Vector3(0, -mass / 2, 0))


	if abs(linear_velocity.length()) > 10:
		if true: #!brake >= 30:
			$"Mesh/Scene Root/AnimationPlayer".play("run")
			$"Mesh/Scene Root/AnimationPlayer".playback_speed = min(linear_velocity.length() * .03, 2)
#			if abs(linear_velocity.length()) > 50:
#				$Camera/motion_blur.show()
#				$Camera/motion_blur.get_surface_material(0).set_shader_param("intensity", lerp(0, 0.08, linear_velocity.length_squared() / (100 * 100)))
#			else:
#				$Camera/motion_blur.hide()
		else:
#			$"Mesh/Scene Root/AnimationPlayer".play("skid")
			pass
	else:
		$"Mesh/Scene Root/AnimationPlayer".stop()

	speed_label.text = String(stepify(linear_velocity.length(), .01)) + " m/s"

	var r = rotation
	r.y = 0
	if r.length() > .5:
		rpc("_wipeout")

func _input(event: InputEvent) -> void:
	if is_network_master():
		if event is InputEventMouseMotion && Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			rpc_unreliable("_steer", steering - event.relative.x * .16 * .005)
			$Mesh.rotation.z = -steering / 2
			$DirectionIndicator.rotation.y = steering


sync func _steer(t : float):
	if abs(t) < .002:
		t = 0
	steering = clamp(t, -.8, .8) # Wheel Radius

sync func _gas(a : float):
	engine_force = a

sync func _brake(a : float):
	engine_force = 0
	brake = a

sync func _wipeout():
	if ($Timer.time_left > 0):
		engine_force = 0
	else:
		rotation.z = 0
#		$"Mesh/Scene Root/Armature/Skeleton".physical_bones_start_simulation()
		$Timer.start()


sync func full_motion_sync(trans : Vector3, rot : Vector3, lin_vel : Vector3, ang_vel : Vector3, eng_f : float, ste : float, bra : float) -> void:
	translation = (trans + translation) / 2
	rotation = (rot + rotation) / 2
	linear_velocity = (lin_vel + linear_velocity) / 2
	angular_velocity = (ang_vel + angular_velocity) / 2
	engine_force = (eng_f + engine_force) / 2
	steering = (ste + steering) / 2
	brake = (bra + brake) / 2

func _on_Timer_timeout() -> void:
	rotation.x = 0
	rotation.z = 0
	engine_force = 0
	linear_velocity = Vector3()
	angular_velocity = Vector3()
#	$"Mesh/Scene Root/Armature/Skeleton".physical_bones_stop_simulation()

func is_on_ground() -> bool:
	return $VehicleWheel3.is_in_contact() and $VehicleWheel4.is_in_contact()

func _on_ResyncTimer_timeout() -> void:
	rpc("full_motion_sync", translation, rotation, linear_velocity, angular_velocity, engine_force, steering, brake)
	$ResyncTimer.start()

func _start_lap(b):
	if (b != self or !Multiplayer.is_racing()):
		return
	start_lap_count += 1
	done_mid_lap = false
	lap_time = 0

func _mid_lap(b):
	if (b != self or !Multiplayer.is_racing()):
		return
	done_mid_lap = true

func _end_lap(b):
	if (b != self or !Multiplayer.is_racing()):
		return
	if (done_mid_lap == false or start_lap_count == 0):
		return
	lap_count += 1
	done_mid_lap = false
	if $Control.is_network_master():
		Multiplayer.get_node("Panel/VBoxContainer/Caption").text = str(lap_count) + "/3 laps"
	if lap_count >= 3:
		Multiplayer.rpc("finished_race", self)

sync func die():
	$Explode.set_as_toplevel(true)
	$Explode.emitting = true
	$Mesh.hide()
	freeze()
	set_network_master(-1, false)

sync func revive():
	$Explode.set_as_toplevel(false)
	$Explode.emitting = false
	$Mesh.show()
	set_network_master($Control.get_network_master(), true)

func freeze():
	linear_velocity = Vector3()
	angular_velocity = Vector3()
	engine_force = 0
	steering = 0
	brake = 0

sync func set_health(hp : int):
	health = hp
	if $Control.is_network_master():
		$Control/Panel/VBoxContainer/ProgressBar.value = health
	if health <= 0:
		die()

func reset():
	revive()
	translation = og_translation
	rotation = og_rotation
	set_health(max_health)
	freeze()
	rpc("full_motion_sync", translation, rotation, linear_velocity, angular_velocity, engine_force, steering, brake)


func _on_Hound_body_entered(body: Node) -> void:
	if (not body.is_in_group("track_surface")):
		rpc("set_health", max(50, health - linear_velocity.length_squared() / 4))
