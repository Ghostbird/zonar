extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func set_id(id):
	$HBoxContainer/id.text = id
	
func set_username(username):
	$HBoxContainer/username.text = username
