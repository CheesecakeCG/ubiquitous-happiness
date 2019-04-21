extends RigidBody

export var pull_force : float = 500
export var kick_force : float = 800
export var jump_force : float = 100

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
		turn -= event.relative.x * .16 * .01
#		turn = clamp(turn, -.3, .3)
#		turn = clamp(turn, -PI/2, PI/2)
		turn = wrapf(turn, -2*PI, 2*PI)
#		$Mesh/DirectionIndicator.rotation.y = turn
		$Mesh.rotation.y = turn
		$Mesh.rotation.z = wrapf(-turn, -PI/12, PI/12)
#		$DirectionIndicator.translation = Vector3(-turn, 0, -2.2)

func _physics_process(delta: float) -> void:

	pass

sync func run(force : Vector3):
	pass

sync func take_step() -> void:
	if (translation.y < .1 && translation.y >= 0):
		print("Can Move")
		var direction = Vector3()
		if !kickNext:
			print("Pull")
			direction += Vector3(0, 0, pull_force)
			kickNext = true
		else:
			print("Kick")
			direction += Vector3(0, 0, kick_force)
			kickNext = false

#		apply_torque_impulse(Vector3(0, turn, 0).rotated(transform.basis.y, wrapf(rotation.y, -PI, PI)))
#		angular_velocity += Vector3(0, turn, 0)
#		turn = 0
#		angular_velocity = angular_velocity/4

#		var t = Vector3(turn, 0, -2.2)
#		turn += rotation.y

		turn =+ rotation.y
#		direction = direction.rotated(transform.basis.y, wrapf(rotation.y + turn, -PI, PI)) # Rotated only likes the least coterminal for some reason.
		direction = direction.rotated(transform.basis.y, turn) # Rotated only likes the least coterminal for some reason.

		apply_central_impulse(direction)
		print(direction)


		$Timer.start()
	pass
