extends CharacterBody3D

const ATTACK_RANGE: float = 1.8
const ATTACK_COOLDOWN: float = 1.2
const DAMAGE: int = 20

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Scaled difficulty multipliers (injected by Spawner)
var speed_multiplier: float = 1.0
var health_multiplier: float = 1.0

var speed: float = 2.5
var max_health: int = 50
var health: int = max_health
var dead: bool = false
var time_since_last_attack: float = ATTACK_COOLDOWN

var player: CharacterBody3D = null

# Cached nodes
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var hurt_sound: AudioStreamPlayer3D = $HurtSound
var state_machine: StateMachine = null

# Option 4: Pickups Drop Scene database
var health_pickup_scene: PackedScene = preload("res://scenes/pickup.tscn") # Loaded dynamically in Option 4

func _ready() -> void:
	# Calculate scaled attributes
	speed = 2.5 * speed_multiplier
	max_health = int(50.0 * health_multiplier)
	health = max_health

	# Find player node in group
	player = get_tree().get_first_node_in_group("player") as CharacterBody3D
	if not player:
		player = get_node_or_null("/root/Main/Player") as CharacterBody3D

	# Instantiate StateMachine programmatically
	state_machine = StateMachine.new()
	state_machine.name = "StateMachine"
	add_child(state_machine)

	# Wait for navigation map synchronization
	await get_tree().physics_frame

func take_damage(amount: int) -> void:
	if dead:
		return
	
	health -= amount
	
	# Hurt visual reaction (brief scale offset)
	var visuals := get_node_or_null("Visuals") as Node3D
	if visuals:
		var tween := create_tween()
		tween.tween_property(visuals, "scale", Vector3(0.9, 1.1, 0.9), 0.05)
		tween.tween_property(visuals, "scale", Vector3(1.0, 1.0, 1.0), 0.05)
	
	# Trigger sound
	if hurt_sound and health > 0:
		hurt_sound.play()
		
	if health <= 0 and state_machine:
		state_machine.transition_to("die")

func spawn_drop() -> void:
	# 30% chance to drop item
	if randf() <= 0.3:
		if health_pickup_scene:
			var pickup := health_pickup_scene.instantiate() as Area3D
			
			# Configure drop location
			pickup.global_position = global_position + Vector3(0, 0.5, 0)
			
			# Decide pickup type randomly
			# 0 = Health, 1 = Ammo
			var p_type = randi() % 2
			pickup.set("pickup_type", p_type)
			
			# Spawn in parent level map
			get_parent().add_child(pickup)
