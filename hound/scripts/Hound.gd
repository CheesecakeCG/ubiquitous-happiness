extends VehicleBody

export var kick_force : float = 600
export var jump_force : float = 100
export var stopping_force : float = 500
export var stopping_turn : float = PI/2


func _ready():
#	turn = angular_velocity.y
	pass

func _process(delta: float) -> void:
	if is_network_master():
		if (Input.is_action_pressed("player_skid")):
			rpc("_brake", kick_force / 25)
		else:
			if (Input.is_action_pressed("player_forward")):
				rpc("_gas", kick_force)
				print("Gas gas gas!")
			else:
				if (Input.is_action_pressed("player_backwards")):
					rpc("_gas", -kick_force)
				else:
					rpc("_brake", kick_force / 2)

	if abs(engine_force) > 100:
		$"Mesh/Scene Root/AnimationPlayer".play("run")
	else:
		$"Mesh/Scene Root/AnimationPlayer".stop()

	var r = rotation
	r.y = 0
	if r.length() > .6:
		rpc("_wipeout")

func _input(event: InputEvent) -> void:
	if is_network_master():
		if event is InputEventMouseMotion && Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			rpc("_steer", steering - event.relative.x * .16 * .005)
#			$Mesh.rotation.y = steering
			$Mesh.rotation.z = -steering / 2
			$DirectionIndicator.rotation.y = steering


sync func _steer(t : float):
	if abs(t) < .005:
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
		$Timer.start()

func _on_Timer_timeout() -> void:
	rotation.x = 0
	rotation.z = 0
	engine_force = 0
	linear_velocity = Vector3()
	angular_velocity = Vector3()
