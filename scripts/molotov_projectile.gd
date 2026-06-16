extends RigidBody3D

func _ready() -> void:
	# Configure RigidBody physics and collision detection
	contact_monitor = true
	max_contacts_reported = 1
	collision_layer = 0
	collision_mask = 5 # Environment (1) and Zombies (4)
	
	# Create sphere collision shape
	var shape_owner = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 0.15
	shape_owner.shape = sphere_shape
	add_child(shape_owner)
	
	# Create visual mesh (a small cylinder/bottle)
	var mesh_inst = MeshInstance3D.new()
	var cyl_mesh = CylinderMesh.new()
	cyl_mesh.radius = 0.06
	cyl_mesh.height = 0.25
	mesh_inst.mesh = cyl_mesh
	
	# Reddish-brown bottle material
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.25, 0.1)
	mesh_inst.material_override = mat
	add_child(mesh_inst)
	
	# Create trail particles (fire tail)
	var trail = CPUParticles3D.new()
	trail.amount = 15
	trail.lifetime = 0.3
	var trail_mesh = BoxMesh.new()
	trail_mesh.size = Vector3(0.06, 0.06, 0.06)
	trail.mesh = trail_mesh
	
	# Glow material for fire tail
	var trail_mat := StandardMaterial3D.new()
	trail_mat.albedo_color = Color(1.0, 0.4, 0.0)
	trail_mat.emission_enabled = true
	trail_mat.emission = Color(1.0, 0.3, 0.0)
	trail_mat.emission_energy_multiplier = 3.0
	trail_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	trail.material_override = trail_mat
	
	trail.direction = Vector3.UP
	trail.spread = 180.0
	trail.gravity = Vector3(0, 0, 0)
	trail.initial_velocity_min = 0.5
	trail.initial_velocity_max = 1.0
	
	add_child(trail)
	trail.emitting = true
	
	# Connect collision signal
	body_entered.connect(_on_body_entered)
	
	# Safety timeout of 10 seconds to avoid orphaned physics objects
	get_tree().create_timer(10.0).timeout.connect(queue_free)

func _on_body_entered(_body: Node) -> void:
	explode()

func explode() -> void:
	# Spawn fire zone
	var fire_scene = load("res://scenes/fire_zone.tscn") as PackedScene
	if fire_scene:
		var zone = fire_scene.instantiate() as Node3D
		zone.position = global_position
		get_parent().add_child(zone)
		
	queue_free()
