@tool
extends EditorPlugin


func _enter_tree() -> void:
	if !Engine.has_singleton("Innovations"):
		add_autoload_singleton("Innovations", "res://addons/Neat/NEAT_code/innovations.gd")
	if !Engine.has_singleton("Params"):
		add_autoload_singleton("Params", "res://addons/Neat/NEAT_code/params.gd")
	if !Engine.has_singleton("Utils"):
		add_autoload_singleton("Utils", "res://addons/Neat/NEAT_code/utils.gd")


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass
