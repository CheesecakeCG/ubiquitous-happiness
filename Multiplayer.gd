extends Node

onready var ip_input = $Control/HBoxContainer/IPInput
export var port = 30001

func _ready() -> void:
	pass

func _on_HostButton_pressed() -> void:
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(port, 6)
	get_tree().set_network_peer(peer)
	Utils.pause()


func _on_JoinButton_pressed() -> void:
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(ip_input.text, port)
	get_tree().set_network_peer(peer)
	Utils.pause()


func _on_LineEdit_text_entered() -> void:
	_on_JoinButton_pressed()

