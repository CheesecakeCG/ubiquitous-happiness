extends RigidBody

export var kick_force : float = 500
export var jump_force : float = 100
export var stopping_force : float = 500
export var stopping_turn : float = PI/2

var turn : float = 0 setget _set_turn

var accel : float = 0

func _ready():
#	turn = angular_velocity.y
	pass

func _process(delta: float) -> void:
	if accel > 100:
		$"Mesh/Scene Root/AnimationPlayer".play("run")
	else:
		$"Mesh/Scene Root/AnimationPlayer".stop()

func _input(event: InputEvent) -> void:
	if is_network_master():
		if (Input.is_action_pressed("player_forward")):
			player_forward()
	if event is InputEventMouseMotion && Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rpc("_set_turn", turn - event.relative.x * .16 * .01)
		$Mesh.rotation.y = turn
		$Mesh.rotation.z = turn / 2

func player_forward():
	rpc("_set_accel", kick_force)

sync func _set_turn(t : float):
	if abs(t) < .05:
		t = 0
	if abs(turn - t) < .01:
		t = t - (sign(t) * stopping_force)
	turn = clamp(t, -PI/12, PI/12)

sync func _set_accel(a : float):
	if abs(a) < 50:
		a = 0
	accel = clamp(a, -500, 500)

func _physics_process(delta: float) -> void:
	angular_velocity.y += turn * 40 * delta
	apply_central_impulse(Vector3(0, 0, accel).rotated(transform.basis.y, rotation.y))
	rpc("_set_accel", accel - (sign(accel) * stopping_force * delta))#	rpc("_set_turn", turn - (sign(turn) * stopping_turn * delta))
	angular_velocity.y = clamp(angular_velocity.y, -10, 10)



