extends RigidBody

export var pull_force : float = 30000
export var kick_force : float = 70000
export var jump_force : float = 10000

var turn : float = 0
var kickNext = true

func _ready():
#	turn = angular_velocity.y
	pass

func _input(event: InputEvent) -> void:
	if is_network_master():
		if (Input.is_action_pressed("player_forward")) :
			rpc_unreliable("take_step")
	if event is InputEventMouseMotion && Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		turn -= event.relative.x * .16 * .02
		turn = clamp(turn, -PI/4, PI/4)
		$DirectionIndicator.rotation.y = turn


func _physics_process(delta: float) -> void:

	pass

sync func take_step() -> void:
	if ($Timer.time_left <= 0 && translation.y < .05 && translation.y >= 0):
		print("Can Move")
		var direction = Vector3()
		if !kickNext:
			print("Pull")
			direction += Vector3(0, jump_force, pull_force)
			kickNext = true
		else:
			print("Kick")
			direction += Vector3(0, jump_force, kick_force)
			kickNext = false

		apply_torque_impulse(Vector3(0, turn, 0))

		direction = direction.rotated(transform.basis.y, wrapf(rotation.y, -PI, PI)) # Rotated only likes the least coterminal for some reason.
		apply_central_impulse(direction)

		$Timer.start()
	pass
