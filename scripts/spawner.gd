extends Node3D

signal wave_started(wave_num: int)
signal wave_completed(wave_num: int)
signal countdown_tick(seconds: int)

@export var zombie_scene: PackedScene = preload("res://scenes/zombie.tscn")

var spawn_points: Array[Node3D] = []

var current_wave: int = 0
var zombies_to_spawn_total: int = 0
var zombies_spawned_so_far: int = 0
var zombies_alive: int = 0

var is_in_downtime: bool = false
var downtime_timer: float = 0.0
var last_reported_countdown: int = -1

var spawn_timer: float = 0.0
var current_spawn_cooldown: float = 3.0

const DOWNTIME_DURATION: float = 5.0

func _ready() -> void:
	# Gather spawn points from children (e.g. Marker3D nodes)
	for child in get_children():
		if child is Node3D:
			spawn_points.append(child)
	
	# Fallback if no child nodes are defined
	if spawn_points.is_empty():
		spawn_points.append(self)
		
	# Start downtime before Wave 1
	start_downtime()

func _physics_process(delta: float) -> void:
	if is_in_downtime:
		downtime_timer -= delta
		var current_seconds := ceili(downtime_timer)
		if current_seconds != last_reported_countdown and current_seconds >= 0:
			last_reported_countdown = current_seconds
			countdown_tick.emit(current_seconds)
			
		if downtime_timer <= 0.0:
			start_next_wave()
	else:
		if zombies_spawned_so_far < zombies_to_spawn_total:
			spawn_timer += delta
			if spawn_timer >= current_spawn_cooldown:
				spawn_timer = 0.0
				spawn_zombie()
		
		# Check if wave is completed
		if zombies_spawned_so_far >= zombies_to_spawn_total and zombies_alive <= 0:
			complete_wave()

func start_downtime() -> void:
	is_in_downtime = true
	downtime_timer = DOWNTIME_DURATION
	last_reported_countdown = -1

func start_next_wave() -> void:
	is_in_downtime = false
	current_wave += 1
	
	# Calculate difficulty stats for the wave
	zombies_to_spawn_total = 5 + current_wave * 3
	zombies_spawned_so_far = 0
	zombies_alive = 0
	current_spawn_cooldown = maxf(0.6, 3.0 - current_wave * 0.25)
	spawn_timer = current_spawn_cooldown # Spawn the first zombie immediately
	
	wave_started.emit(current_wave)

func complete_wave() -> void:
	wave_completed.emit(current_wave)
	start_downtime()

func spawn_zombie() -> void:
	if spawn_points.is_empty() or not zombie_scene:
		return
		
	var spawn_point := spawn_points[randi() % spawn_points.size()]
	var zombie := zombie_scene.instantiate() as CharacterBody3D
	
	# Configure zombie stats based on wave difficulty
	var speed_mult := 1.0 + (current_wave - 1) * 0.08
	var health_mult := 1.0 + (current_wave - 1) * 0.12
	
	zombie.set("speed_multiplier", speed_mult)
	zombie.set("health_multiplier", health_mult)
	
	zombie.global_position = spawn_point.global_position
	
	# Connect to track alive count
	zombie.tree_exited.connect(_on_zombie_freed)
	
	zombies_spawned_so_far += 1
	zombies_alive += 1
	
	get_parent().add_child(zombie)

func _on_zombie_freed() -> void:
	zombies_alive -= 1
