extends Node3D

@export var zombie_scene: PackedScene = preload("res://scenes/zombie.tscn")
@export var spawn_cooldown = 3.0
@export var max_zombies = 15

var time_since_last_spawn = 0.0
var spawn_points = []

func _ready():
	# Gather spawn points from children (e.g. Marker3D nodes)
	for child in get_children():
		if child is Node3D:
			spawn_points.append(child)
	
	# Fallback if no child nodes are defined
	if spawn_points.is_empty():
		spawn_points.append(self)

func _physics_process(delta):
	time_since_last_spawn += delta
	if time_since_last_spawn >= spawn_cooldown:
		time_since_last_spawn = 0.0
		
		# Get count of currently active zombies
		var active_zombies = get_tree().get_nodes_in_group("zombie")
		if active_zombies.size() < max_zombies:
			spawn_zombie()

func spawn_zombie():
	if spawn_points.is_empty() or not zombie_scene:
		return
		
	# Pick a random spawn point
	var spawn_point = spawn_points[randi() % spawn_points.size()]
	var zombie = zombie_scene.instantiate()
	
	# Place zombie at spawn point position
	zombie.global_position = spawn_point.global_position
	
	# Spawn into parent map scene
	get_parent().add_child(zombie)
