extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Camera sensitivity and nodes
@export var sensitivity = 0.003
@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var raycast = $Head/Camera3D/RayCast3D
@onready var muzzle_flash = $Head/Camera3D/MuzzleFlash

# Gameplay variables
var max_health = 100
var health = max_health
var max_ammo = 30
var ammo = max_ammo
var score = 0

# UI nodes
@onready var health_label = $HUD/MarginContainer/VBoxContainer/HealthLabel
@onready var ammo_label = $HUD/MarginContainer/VBoxContainer/AmmoLabel
@onready var score_label = $HUD/MarginContainer/VBoxContainer/ScoreLabel
@onready var game_over_screen = $HUD/GameOverScreen

# Sound players
@onready var shoot_sound = $ShootSound
@onready var reload_sound = $ReloadSound
@onready var hurt_sound = $HurtSound

func _enter_tree():
	setup_inputs()

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	update_hud()
	game_over_screen.hide()

func setup_inputs():
	var actions = {
		"move_forward": KEY_W,
		"move_backward": KEY_S,
		"move_left": KEY_A,
		"move_right": KEY_D,
		"jump": KEY_SPACE,
		"shoot": MOUSE_BUTTON_LEFT,
		"reload": KEY_R,
		"ui_cancel": KEY_ESCAPE
	}
	
	for action in actions:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var key = actions[action]
			var event
			if key == MOUSE_BUTTON_LEFT:
				event = InputEventMouseButton.new()
				event.button_index = key
			else:
				event = InputEventKey.new()
				event.physical_keycode = key
			InputMap.action_add_event(action, event)

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * sensitivity)
		head.rotate_x(-event.relative.y * sensitivity)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

func _physics_process(delta):
	# Check exit mouse capture
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if health <= 0:
		if Input.is_action_just_pressed("shoot"):
			restart_game()
		return

	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Handle shooting
	if Input.is_action_just_pressed("shoot") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		shoot()

	# Handle reload
	if Input.is_action_just_pressed("reload") and ammo < max_ammo:
		reload()

	# Get input direction and handle movement/deceleration
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func shoot():
	if ammo <= 0:
		# Auto reload when shooting with empty gun
		reload()
		return
	
	ammo -= 1
	update_hud()
	
	# Play shooting sound
	if shoot_sound:
		shoot_sound.play()
	
	# Show muzzle flash (visual effect)
	show_muzzle_flash()
	
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider and collider.has_method("take_damage"):
			collider.take_damage(25) # Deal 25 damage per shot

func reload():
	ammo = max_ammo
	update_hud()
	if reload_sound:
		reload_sound.play()

func show_muzzle_flash():
	muzzle_flash.visible = true
	await get_tree().create_timer(0.05).timeout
	muzzle_flash.visible = false

func take_damage(amount):
	if health <= 0:
		return
	health -= amount
	update_hud()
	if hurt_sound:
		hurt_sound.play()
	if health <= 0:
		die()

func add_score(amount):
	score += amount
	update_hud()

func update_hud():
	if health_label:
		health_label.text = "HP: %d" % health
	if ammo_label:
		ammo_label.text = "AMMO: %d/%d" % [ammo, max_ammo]
	if score_label:
		score_label.text = "SCORE: %d" % score

func die():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	game_over_screen.show()

func restart_game():
	get_tree().reload_current_scene()
