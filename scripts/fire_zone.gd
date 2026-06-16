extends Area3D

var fire_damage: int = 15
var damage_interval: float = 0.4
var lifetime: float = 6.0

var damage_timer: float = 0.0

func _ready() -> void:
	# Configure area masks
	collision_layer = 0
	collision_mask = 4 # Detect zombies
	
	# Create Cylinder Collision Shape (radius 3.0m, height 0.5m)
	var shape_owner = CollisionShape3D.new()
	var cylinder_shape = CylinderShape3D.new()
	cylinder_shape.radius = 3.0
	cylinder_shape.height = 0.5
	shape_owner.shape = cylinder_shape
	shape_owner.position = Vector3(0, 0.25, 0)
	add_child(shape_owner)
	
	# Spawn visual fire particles
	var fire_particles = CPUParticles3D.new()
	fire_particles.amount = 50
	fire_particles.lifetime = 0.8
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.12, 0.12, 0.12)
	fire_particles.mesh = box_mesh
	
	# Color gradient for fire
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.3, 0.0) # Flame orange
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.2, 0.0)
	mat.emission_energy_multiplier = 4.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fire_particles.material_override = mat
	
	# Fire particle emission properties
	fire_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	fire_particles.emission_sphere_radius = 2.8
	fire_particles.direction = Vector3.UP
	fire_particles.spread = 15.0
	fire_particles.gravity = Vector3(0, 4.0, 0)
	fire_particles.initial_velocity_min = 1.0
	fire_particles.initial_velocity_max = 2.5
	
	add_child(fire_particles)
	fire_particles.emitting = true
	
	# Play dynamic flame igniting burst sound
	var audio_player = AudioStreamPlayer3D.new()
	audio_player.stream = load("res://sound/splat.wav")
	audio_player.pitch_scale = 0.6
	audio_player.volume_db = 6.0
	audio_player.max_distance = 45.0
	add_child(audio_player)
	audio_player.play()
	
	# Free itself after lifetime
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	damage_timer += delta
	if damage_timer >= damage_interval:
		damage_timer = 0.0
		apply_fire_damage()

func apply_fire_damage() -> void:
	var bodies = get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("zombie") and body.has_method("take_damage") and not body.get("dead"):
			body.take_damage(fire_damage)
