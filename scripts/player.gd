extends CharacterBody3D

const GameSettings = preload("res://scripts/settings.gd")


const SPEED: float = 5.0
const JUMP_VELOCITY: float = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Camera sensitivity and nodes
@export var sensitivity: float = 0.003
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var raycast: RayCast3D = $Head/Camera3D/RayCast3D
@onready var muzzle_flash: MeshInstance3D = $Head/Camera3D/Gun/MuzzleFlash
@onready var gun_mesh: MeshInstance3D = $Head/Camera3D/Gun

# Weapon resource database
@export var weapons: Array[WeaponData] = []
var current_weapon_idx: int = 0
var current_weapon: WeaponData = null

# Particle effects
@export var spark_particles: PackedScene = preload("res://scenes/spark_particles.tscn")
@export var blood_particles: PackedScene = preload("res://scenes/blood_particles.tscn")

# Ammo tracking (per weapon name)
var weapon_clip_ammo: Dictionary = {} # { "Pistol": 30, "Shotgun": 6 }
var ammo_reserves: Dictionary = {}    # { "Pistol": 90, "Shotgun": 24 }

# Timing and reload states
var time_since_last_shot: float = 0.0
var is_reloading: bool = false
var reload_timer: float = 0.0

# ADS variables
const HIP_POSITION := Vector3(0.2, -0.2, -0.4)
const DEFAULT_FOV := 75.0
var ads_speed: float = 12.0
var is_ads: bool = false

# Gameplay variables
var max_health: int = 100
var health: int = max_health
var score: int = 0
var speed_multiplier: float = 1.0
var damage_multiplier: float = 1.0

# UI nodes
@onready var health_label: Label = $HUD/Layout/BottomHUD/HealthPanel/Margin/VBox/HealthLabel
@onready var health_bar: ProgressBar = $HUD/Layout/BottomHUD/HealthPanel/Margin/VBox/HealthBar
@onready var ammo_label: Label = $HUD/Layout/BottomHUD/AmmoPanel/Margin/AmmoLabel
@onready var score_label: Label = $HUD/Layout/TopHUD/ScorePanel/Margin/ScoreLabel
@onready var wave_label: Label = $HUD/Layout/TopHUD/WavePanel/Margin/WaveLabel
@onready var wave_alert: Label = $HUD/Layout/WaveAlert
@onready var game_over_screen: CenterContainer = $HUD/GameOverScreen
@onready var crosshair: Control = $HUD/Crosshair
@onready var objective_marker: PanelContainer = $HUD/Layout/ObjectiveMarker
@onready var objective_marker_label: Label = $HUD/Layout/ObjectiveMarker/Margin/Label

# Throwables inventory
var molotovs_carried: int = 3

# Sound players
@onready var shoot_sound: AudioStreamPlayer = $ShootSound
@onready var reload_sound: AudioStreamPlayer = $ReloadSound
@onready var hurt_sound: AudioStreamPlayer = $HurtSound

func _enter_tree() -> void:
	setup_inputs()

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	game_over_screen.hide()
	setup_weapons()
	
	# Apply mouse sensitivity from GameSettings
	sensitivity = GameSettings.mouse_sensitivity * 0.01

	# Connect Game Over screen buttons
	var restart_btn = $HUD/GameOverScreen/PanelContainer/Margin/VBox/RestartButton as Button
	var menu_btn = $HUD/GameOverScreen/PanelContainer/Margin/VBox/MenuButton as Button
	if restart_btn:
		restart_btn.pressed.connect(restart_game)
	if menu_btn:
		menu_btn.pressed.connect(_on_menu_button_pressed)

func setup_inputs() -> void:
	var actions: Dictionary = {
		"move_forward": KEY_W,
		"move_backward": KEY_S,
		"move_left": KEY_A,
		"move_right": KEY_D,
		"jump": KEY_SPACE,
		"shoot": MOUSE_BUTTON_LEFT,
		"ads": MOUSE_BUTTON_RIGHT,
		"reload": KEY_R,
		"ui_cancel": KEY_ESCAPE,
		"swap_next": MOUSE_BUTTON_WHEEL_DOWN,
		"swap_prev": MOUSE_BUTTON_WHEEL_UP,
		"weapon_1": KEY_1,
		"weapon_2": KEY_2
	}
	
	for action in actions:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var key = actions[action]
			var event: InputEvent
			if key == MOUSE_BUTTON_LEFT or key == MOUSE_BUTTON_RIGHT or key == MOUSE_BUTTON_WHEEL_DOWN or key == MOUSE_BUTTON_WHEEL_UP:
				var m_event := InputEventMouseButton.new()
				m_event.button_index = key
				event = m_event
			else:
				var k_event := InputEventKey.new()
				k_event.physical_keycode = key
				event = k_event
			InputMap.action_add_event(action, event)

func setup_weapons() -> void:
	if weapons.size() > 0:
		for w in weapons:
			if not weapon_clip_ammo.has(w.name):
				weapon_clip_ammo[w.name] = w.max_ammo
			if not ammo_reserves.has(w.name):
				# Starting reserve is 3 full magazines
				ammo_reserves[w.name] = w.max_ammo * 3
		
		current_weapon = weapons[current_weapon_idx]
		update_weapon_visuals()
	update_hud()

func update_weapon_visuals() -> void:
	if not current_weapon:
		return
		
	# Assign sound streams from resource
	if shoot_sound:
		shoot_sound.stream = current_weapon.shoot_sound
	if reload_sound:
		reload_sound.stream = current_weapon.reload_sound
		
	# Apply weapon mesh material color override
	if gun_mesh:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = current_weapon.gun_color
		mat.emission_enabled = true
		mat.emission = current_weapon.gun_color
		mat.emission_energy_multiplier = 0.5
		gun_mesh.material_override = mat

func _unhandled_input(event: InputEvent) -> void:
	# Handle Molotov quick throw
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_G:
			if health > 0 and molotovs_carried > 0:
				throw_molotov()

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * sensitivity)
		head.rotate_x(-event.relative.y * sensitivity)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

func _physics_process(delta: float) -> void:
	# Check exit mouse capture
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if health <= 0:
		return

	# Handle ADS (Aim Down Sights)
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		is_ads = Input.is_action_pressed("ads")
	else:
		is_ads = false

	var target_fov := DEFAULT_FOV
	var target_pos := HIP_POSITION

	if is_ads and current_weapon:
		target_fov = DEFAULT_FOV * current_weapon.ads_fov_multiplier
		target_pos = current_weapon.ads_position

	camera.fov = lerp(camera.fov, target_fov, ads_speed * delta)
	if gun_mesh:
		gun_mesh.position = lerp(gun_mesh.position, target_pos, ads_speed * delta)


	# Handle shooting/reload timers
	time_since_last_shot += delta
	if is_reloading:
		reload_timer -= delta
		if reload_timer <= 0.0:
			finish_reload()

	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Handle shooting
	if Input.is_action_pressed("shoot") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		shoot()

	# Handle reload
	if Input.is_action_just_pressed("reload") and current_weapon:
		var clip = weapon_clip_ammo.get(current_weapon.name, 0)
		if clip < current_weapon.max_ammo and not is_reloading:
			start_reload()

	# Handle weapon swap input
	if not is_reloading:
		if Input.is_action_just_pressed("swap_next"):
			swap_weapon(1)
		elif Input.is_action_just_pressed("swap_prev"):
			swap_weapon(-1)
		elif Input.is_action_just_pressed("weapon_1") and weapons.size() > 0:
			select_weapon(0)
		elif Input.is_action_just_pressed("weapon_2") and weapons.size() > 1:
			select_weapon(1)

	# Get input direction and handle movement/deceleration
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var current_speed = SPEED * speed_multiplier
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, current_speed)
		velocity.z = move_toward(velocity.z, 0.0, current_speed)

	move_and_slide()
	update_objective_marker()

func select_weapon(idx: int) -> void:
	if idx == current_weapon_idx or idx >= weapons.size() or is_reloading:
		return
	current_weapon_idx = idx
	current_weapon = weapons[current_weapon_idx]
	update_weapon_visuals()
	update_hud()

func swap_weapon(direction: int) -> void:
	if weapons.size() <= 1 or is_reloading:
		return
	current_weapon_idx = (current_weapon_idx + direction + weapons.size()) % weapons.size()
	current_weapon = weapons[current_weapon_idx]
	update_weapon_visuals()
	update_hud()

func shoot() -> void:
	if not current_weapon:
		return
	if is_reloading:
		if current_weapon.is_shell_reload:
			# Cancel reloading immediately so player can shoot loaded shells
			is_reloading = false
		else:
			return
	if time_since_last_shot < current_weapon.fire_rate:
		return
		
	var clip_ammo: int = weapon_clip_ammo.get(current_weapon.name, 0)
	if clip_ammo <= 0:
		start_reload()
		return
		
	time_since_last_shot = 0.0
	weapon_clip_ammo[current_weapon.name] = clip_ammo - 1
	update_hud()
	
	if crosshair:
		var kick_amt = 15.0 if current_weapon.is_shotgun else 8.0
		crosshair.set("shoot_kick", crosshair.get("shoot_kick") + kick_amt)
	
	if shoot_sound:
		shoot_sound.play()
	show_muzzle_flash()
	
	# Raycast shoot logic
	if current_weapon.is_shotgun:
		for i in range(current_weapon.pellet_count):
			fire_single_ray(current_weapon.spread, current_weapon.damage)
	else:
		fire_single_ray(0.0, current_weapon.damage)

func fire_single_ray(spread_factor: float, damage_val: int) -> void:
	var space_state = get_world_3d().direct_space_state
	if not space_state:
		return
		
	var start_point = camera.global_position
	var dir = -camera.global_transform.basis.z
	if spread_factor > 0.0:
		dir += camera.global_transform.basis.x * randf_range(-spread_factor, spread_factor)
		dir += camera.global_transform.basis.y * randf_range(-spread_factor, spread_factor)
	dir = dir.normalized()
	
	var end_point = start_point + dir * 100.0
	var query = PhysicsRayQueryParameters3D.create(start_point, end_point)
	query.collision_mask = 5 # Environment (1) and Zombie (4)
	query.exclude = [self.get_rid()]
	
	var result = space_state.intersect_ray(query)
	var hit_point = end_point
	
	if not result.is_empty():
		var collider = result.collider
		var point = result.position
		var normal = result.normal
		hit_point = point
		
		# Check headshot
		var is_head = false
		if collider and collider.has_method("is_headshot"):
			is_head = collider.is_headshot(point.y)
			
		var final_damage = int(damage_val * damage_multiplier)
		if is_head:
			final_damage *= 2
			
		if collider and collider.has_method("take_damage"):
			collider.take_damage(final_damage, is_head)
			spawn_impact_particles(blood_particles, point, normal, is_head)
		else:
			spawn_impact_particles(spark_particles, point, normal)
			
	# Spawn visual bullet tracer
	if muzzle_flash:
		spawn_tracer(muzzle_flash.global_position, hit_point)

func spawn_impact_particles(scene: PackedScene, point: Vector3, normal: Vector3, is_critical: bool = false) -> void:
	if not scene:
		return
	var inst = scene.instantiate() as CPUParticles3D
	
	# Position and orient the node before adding to the tree to avoid ready() origin emission
	inst.position = point
	if normal.is_equal_approx(Vector3.UP):
		inst.look_at_from_position(point, point + Vector3.UP, Vector3.FORWARD)
	elif normal.is_equal_approx(Vector3.DOWN):
		inst.look_at_from_position(point, point + Vector3.DOWN, Vector3.FORWARD)
	else:
		inst.look_at_from_position(point, point + normal, Vector3.UP)
		
	if is_critical:
		inst.scale = Vector3(2.2, 2.2, 2.2)
		inst.amount = 30
		
	get_parent().add_child(inst)

func start_reload() -> void:
	if not current_weapon or is_reloading:
		return
	var reserve: int = ammo_reserves.get(current_weapon.name, 0)
	var clip: int = weapon_clip_ammo.get(current_weapon.name, 0)
	if reserve <= 0 or clip >= current_weapon.max_ammo:
		return
		
	is_reloading = true
	reload_timer = current_weapon.reload_time
	if reload_sound:
		reload_sound.play()
	update_hud()

func finish_reload() -> void:
	var weapon_name = current_weapon.name
	var current_clip: int = weapon_clip_ammo.get(weapon_name, 0)
	var reserve: int = ammo_reserves.get(weapon_name, 0)
	
	if current_weapon.is_shell_reload:
		if reserve > 0 and current_clip < current_weapon.max_ammo:
			weapon_clip_ammo[weapon_name] = current_clip + 1
			ammo_reserves[weapon_name] = reserve - 1
			update_hud()
			
			# If still not full, continue reloading next shell
			if weapon_clip_ammo[weapon_name] < current_weapon.max_ammo and ammo_reserves[weapon_name] > 0:
				reload_timer = current_weapon.reload_time
				if reload_sound:
					reload_sound.play()
			else:
				is_reloading = false
		else:
			is_reloading = false
	else:
		is_reloading = false
		var needed: int = current_weapon.max_ammo - current_clip
		var to_load: int = mini(needed, reserve)
		
		weapon_clip_ammo[weapon_name] = current_clip + to_load
		ammo_reserves[weapon_name] = reserve - to_load
		update_hud()

func show_muzzle_flash() -> void:
	muzzle_flash.visible = true
	var light = muzzle_flash.get_node_or_null("MuzzleLight") as OmniLight3D
	var particles = muzzle_flash.get_node_or_null("MuzzleParticles") as CPUParticles3D
	if light:
		light.visible = true
	if particles:
		particles.restart()
		particles.emitting = true
	await get_tree().create_timer(0.05).timeout
	muzzle_flash.visible = false
	if light:
		light.visible = false


func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health -= amount
	update_hud()
	if hurt_sound:
		hurt_sound.play()
	if health <= 0:
		die()

func add_score(amount: int) -> void:
	score += amount
	update_hud()

func update_hud() -> void:
	if health_label:
		health_label.text = "HP: %d" % health
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health
	if ammo_label:
		if current_weapon:
			var clip: int = weapon_clip_ammo.get(current_weapon.name, 0)
			var reserve: int = ammo_reserves.get(current_weapon.name, 0)
			if is_reloading:
				ammo_label.text = "%s - Reloading...\nMolotovs: %d" % [current_weapon.name, molotovs_carried]
			else:
				ammo_label.text = "%s - %d/%d\nMolotovs: %d" % [current_weapon.name, clip, reserve, molotovs_carried]
		else:
			ammo_label.text = "--/--\nMolotovs: %d" % molotovs_carried
	if score_label:
		score_label.text = "SCORE: %d" % score

func die() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	game_over_screen.show()

func restart_game() -> void:
	get_tree().reload_current_scene()

func _on_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func update_wave_number(wave_num: int) -> void:
	if wave_label:
		wave_label.text = "WAVE: %d" % wave_num

func show_wave_alert(message: String) -> void:
	if wave_alert:
		wave_alert.text = message
		wave_alert.show()

func hide_wave_alert() -> void:
	if wave_alert:
		wave_alert.text = ""
		wave_alert.hide()

func spawn_tracer(start: Vector3, end: Vector3) -> void:
	var tracer := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(0.015, 0.015, 1.0)
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.75, 0.1, 0.8)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.75, 0.1, 1.0)
	mat.emission_energy_multiplier = 4.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	tracer.mesh = box_mesh
	tracer.material_override = mat
	
	get_parent().add_child(tracer)
	
	var dir = end - start
	var dist = dir.length()
	tracer.position = start + dir * 0.5
	tracer.scale.z = dist
	
	if dist > 0.01:
		tracer.look_at(end, Vector3.UP)
		
	var tween = create_tween()
	tween.tween_property(tracer, "scale:x", 0.0, 0.12)
	tween.parallel().tween_property(tracer, "scale:y", 0.0, 0.12)
	tween.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.12)
	tween.tween_callback(tracer.queue_free)

func throw_molotov() -> void:
	var molotov_scene = load("res://scenes/molotov_projectile.tscn") as PackedScene
	if molotov_scene:
		molotovs_carried -= 1
		update_hud()
		
		var molotov = molotov_scene.instantiate() as RigidBody3D
		molotov.position = camera.global_position + (-camera.global_transform.basis.z * 0.5)
		get_parent().add_child(molotov)
		
		var throw_dir = -camera.global_transform.basis.z
		throw_dir.y += 0.2
		throw_dir = throw_dir.normalized()
		
		molotov.linear_velocity = throw_dir * 15.0

func update_objective_marker() -> void:
	if not objective_marker or not objective_marker_label:
		return
		
	var main_node = get_parent()
	if not main_node or not main_node.has_method("get_current_objective_targets"):
		objective_marker.hide()
		return
		
	var targets: Array = main_node.call("get_current_objective_targets")
	if targets.is_empty():
		objective_marker.hide()
		return
		
	var closest_target: Vector3 = Vector3.ZERO
	var min_dist: float = 999999.0
	var label_text := ""
	
	for item in targets:
		if is_instance_valid(item.node):
			var dist = global_position.distance_to(item.node.global_position)
			if dist < min_dist:
				min_dist = dist
				closest_target = item.node.global_position
				label_text = item.label
				
	if min_dist > 99990.0:
		objective_marker.hide()
		return
		
	if camera.is_position_behind(closest_target):
		objective_marker.hide()
		return
		
	var screen_pos = camera.unproject_position(closest_target)
	objective_marker.show()
	objective_marker.position = screen_pos - objective_marker.size * 0.5
	objective_marker_label.text = "%s\n[%dm]" % [label_text, int(min_dist)]
