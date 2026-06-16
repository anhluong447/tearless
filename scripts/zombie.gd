extends CharacterBody3D

enum ZombieType { NORMAL, RUNNER, TANK, BOMBER }

const ATTACK_RANGE: float = 1.8
const ATTACK_COOLDOWN: float = 1.2
const DAMAGE: int = 20

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Scaled difficulty multipliers (injected by Spawner)
var speed_multiplier: float = 1.0
var health_multiplier: float = 1.0

@export var zombie_type: ZombieType = ZombieType.NORMAL

var speed: float = 2.5
var max_health: int = 50
var health: int = max_health
var dead: bool = false
var time_since_last_attack: float = ATTACK_COOLDOWN

var player: CharacterBody3D = null

# Persistent stagger and audio timers
var stagger_timer: float = 0.0
var moan_sound: AudioStreamPlayer3D = null
var moan_timer: float = 0.0

# Cached nodes
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var hurt_sound: AudioStreamPlayer3D = $HurtSound
var state_machine: StateMachine = null

# Option 4: Pickups Drop Scene database
var health_pickup_scene: PackedScene = preload("res://scenes/pickup.tscn")

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player") as CharacterBody3D
	if not player:
		player = get_node_or_null("/root/Main/Player") as CharacterBody3D

	configure_zombie_type()
	
	# Instantiate 3D growl audio player
	moan_sound = AudioStreamPlayer3D.new()
	moan_sound.stream = load("res://sound/splat.wav")
	moan_sound.volume_db = -8.0
	moan_sound.max_distance = 25.0
	add_child(moan_sound)
	moan_timer = randf_range(3.0, 10.0)

	# Instantiate StateMachine programmatically
	state_machine = StateMachine.new()
	state_machine.name = "StateMachine"
	add_child(state_machine)

	# Wait for navigation map synchronization
	await get_tree().physics_frame

func configure_zombie_type() -> void:
	var body_mesh = $Visuals/BodyMesh as MeshInstance3D
	var mat = StandardMaterial3D.new()
	
	match zombie_type:
		ZombieType.NORMAL:
			speed = 2.5 * speed_multiplier
			max_health = int(50.0 * health_multiplier)
			mat.albedo_color = Color(0.18, 0.54, 0.28, 1) # Green
			
		ZombieType.RUNNER:
			speed = 4.5 * speed_multiplier
			max_health = int(30.0 * health_multiplier)
			mat.albedo_color = Color(0.85, 0.4, 0.1, 1) # Orange
			var left_eye = $Visuals/LeftEye as MeshInstance3D
			var right_eye = $Visuals/RightEye as MeshInstance3D
			var eye_mat = StandardMaterial3D.new()
			eye_mat.albedo_color = Color(1.0, 1.0, 0.0, 1)
			eye_mat.emission_enabled = true
			eye_mat.emission = Color(1.0, 1.0, 0.0, 1)
			left_eye.material_override = eye_mat
			right_eye.material_override = eye_mat
			
		ZombieType.TANK:
			speed = 1.6 * speed_multiplier
			max_health = int(160.0 * health_multiplier)
			mat.albedo_color = Color(0.5, 0.05, 0.05, 1) # Dark red
			$Visuals.scale = Vector3(1.5, 1.5, 1.5)
			$CollisionShape3D.scale = Vector3(1.5, 1.0, 1.5)
			
		ZombieType.BOMBER:
			speed = 2.8 * speed_multiplier
			max_health = int(40.0 * health_multiplier)
			mat.albedo_color = Color(0.9, 0.8, 0.1, 1) # Yellow
			mat.emission_enabled = true
			mat.emission = Color(0.4, 0.3, 0.0, 1)
			mat.emission_energy_multiplier = 1.5
			
	if body_mesh:
		body_mesh.material_override = mat
	health = max_health

func _physics_process(delta: float) -> void:
	if dead:
		return
		
	# Update stagger timer
	if stagger_timer > 0.0:
		stagger_timer -= delta
		
	# Update ambient growls
	moan_timer -= delta
	if moan_timer <= 0.0:
		moan_timer = randf_range(8.0, 16.0)
		if moan_sound:
			moan_sound.pitch_scale = randf_range(0.35, 0.55)
			moan_sound.play()

func is_headshot(hit_global_y: float) -> bool:
	var relative_y = hit_global_y - global_position.y
	# Standard height is 2.0. We scale the head threshold (1.35) by the node's scale.y
	var threshold = 1.35 * scale.y
	return relative_y >= threshold

func apply_stagger(damage_val: int, is_head: bool) -> void:
	if is_head:
		stagger_timer = 0.6
	elif damage_val >= 15:
		stagger_timer = 0.35

func take_damage(amount: int, is_head: bool = false) -> void:
	if dead:
		return
	
	health -= amount
	apply_stagger(amount, is_head)
	
	# Hurt visual reaction (brief scale offset)
	var visuals := get_node_or_null("Visuals") as Node3D
	if visuals and health > 0:
		var tween := create_tween()
		tween.tween_property(visuals, "scale", visuals.scale * 0.9, 0.05)
		tween.tween_property(visuals, "scale", visuals.scale, 0.05)
	
	# Trigger sound
	if hurt_sound and health > 0:
		hurt_sound.pitch_scale = randf_range(1.4, 1.6) if is_head else randf_range(0.9, 1.1)
		hurt_sound.play()
		
	if health <= 0:
		if zombie_type == ZombieType.BOMBER:
			detonate()
		elif state_machine:
			state_machine.transition_to("die")

func detonate() -> void:
	if dead:
		return
	dead = true
	collision_layer = 0
	collision_mask = 0
	
	# Play splat sound at low pitch (explosion-like)
	if hurt_sound:
		hurt_sound.pitch_scale = 0.5
		hurt_sound.volume_db = 10.0
		hurt_sound.play()
		
	# Deal area damage to player
	if player and player.health > 0:
		var dist = global_position.distance_to(player.global_position)
		if dist <= 5.0:
			var dmg = int(lerp(70.0, 15.0, dist / 5.0))
			player.take_damage(dmg)
			
	# Deal area damage to other zombies
	var all_zombies = get_tree().get_nodes_in_group("zombie")
	for z in all_zombies:
		if z != self and z.has_method("take_damage") and not z.dead:
			var dist = global_position.distance_to(z.global_position)
			if dist <= 5.0:
				var dmg = int(lerp(120.0, 20.0, dist / 5.0))
				z.take_damage(dmg)

	# Spawn visual explosion particles
	var spark_scene = load("res://scenes/spark_particles.tscn") as PackedScene
	if spark_scene:
		var inst = spark_scene.instantiate() as CPUParticles3D
		inst.position = global_position + Vector3(0, 1, 0)
		inst.amount = 40
		inst.lifetime = 0.8
		inst.scale = Vector3(2.5, 2.5, 2.5)
		get_parent().add_child(inst)
		
		
	var visuals: Node3D = get_node_or_null("Visuals") as Node3D
	if visuals:
		visuals.hide()
		
	await get_tree().create_timer(1.0).timeout
	queue_free()

func spawn_drop() -> void:
	if randf() <= 0.3:
		if health_pickup_scene:
			var pickup := health_pickup_scene.instantiate() as Area3D
			pickup.global_position = global_position + Vector3(0, 0.5, 0)
			
			var p_type = randi() % 2
			pickup.set("pickup_type", p_type)
			get_parent().add_child(pickup)

func try_step_up() -> void:
	if not is_on_wall():
		return
	var horiz_vel = Vector3(velocity.x, 0, velocity.z)
	if horiz_vel.length_squared() < 0.01:
		return
		
	var step_height = 0.35
	var forward_motion = horiz_vel.normalized() * 0.15
	
	# Test if we can move up and forward
	var up_transform = global_transform
	up_transform.origin += Vector3(0, step_height, 0)
	
	if not test_move(up_transform, forward_motion):
		global_position.y += step_height
		global_position += forward_motion

