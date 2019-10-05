extends Node

onready var ip_input = $Control/HBoxContainer/IPInput
export var port = 30001

signal ready_to_race

var player_list = []

func _ready() -> void:
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")



func _on_HostButton_pressed() -> void:
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(port, 6)
	get_tree().set_network_peer(peer)
	Utils.pause()
	player_list.append(1)
	match_clients_to_players()

func _on_JoinButton_pressed() -> void:
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(ip_input.text, port)
	get_tree().set_network_peer(peer)
	Utils.pause()

func _on_LineEdit_text_entered() -> void:
	_on_JoinButton_pressed()

func allow_players_to_join():
	pass

func _connected_ok():
	rpc("register_player", get_tree().get_network_unique_id())

remote func register_player(id):
	player_list.append(id)
	# If I'm the server, let the new guy know about existing players.
	if get_tree().is_network_server():
		# Send the info of existing players
		for peer_id in player_list:
			rpc_id(id, "register_player", peer_id)

	rpc("match_clients_to_players")


sync func match_clients_to_players():
	for i in range(player_list.size()):
		if not get_tree().get_root().get_node("Root/Players").has_node(str(player_list[i])):
			get_tree().get_nodes_in_group("unclaimed")[0].name = str(player_list[i])
			get_tree().get_nodes_in_group("unclaimed")[0].set_network_master(player_list[i])
			get_tree().get_nodes_in_group("unclaimed")[0].show()
			get_tree().get_nodes_in_group("unclaimed")[0].remove_from_group("unclaimed")
	emit_signal("ready_to_race")
	$AnimationTree["parameters/playback"].travel("Practice")

func _process(delta: float) -> void:

	match ($AnimationTree["parameters/playback"].get_current_node()):
		"Practice", "WinnerCeremony":
			$Panel/VBoxContainer/Time.text = String(stepify($AnimationPlayer.current_animation_length - $AnimationPlayer.current_animation_position, .1)) + "s"
		"Race":
			# TODO: Remove ineffiecient hack
			for p in get_tree().get_nodes_in_group("hound"):
				if p.is_network_master():
					$Panel/VBoxContainer/Time.text = "Lap Time: " + String(stepify(p.lap_time, .001)) + "s"

func _on_AnimTimer_timeout() -> void:
	$AnimTimer.start()
	if get_tree().is_network_server():
		rpc("sync_anim_player", $AnimationTree["parameters/playback"])

sync func sync_anim_player(a : AnimationNodeStateMachinePlayback):
	$AnimationTree["parameters/playback"] = a

sync func is_racing() -> bool:
	if $AnimationTree["parameters/playback"].get_current_node() == "Race":
		return true
	return false

sync func finished_race(h):
	$AnimationTree["parameters/playback"].travel("WinnerCeremony")
	if h.is_network_master():
		$Panel/VBoxContainer/Caption.text = "YOU WON!"
	else:
		$Panel/VBoxContainer/Caption.text = "Someone else won..."

sync func start_race():
	for p in get_tree().get_nodes_in_group("hound"):
		p.reset()