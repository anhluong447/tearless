extends CharacterBody3D

const SPEED = 2.5
const JUMP_VELOCITY = 4.5
const ATTACK_RANGE = 1.8
const ATTACK_COOLDOWN = 1.2
const DAMAGE = 20

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var max_health = 50
var health = max_health
var dead = false
var time_since_last_attack = ATTACK_COOLDOWN

var player = null
@onready var nav_agent = $NavigationAgent3D
@onready var hurt_sound = $HurtSound

func _ready():
	# Find player by group, with absolute path as fallback
	player = get_tree().get_first_node_in_group("player")
	if not player:
		player = get_node_or_null("/root/Main/Player")
	
	# Wait for navigation map to synchronize
	await get_tree().physics_frame

func _physics_process(delta):
	time_since_last_attack += delta

	if dead:
		return

	if not is_on_floor():
		velocity.y -= gravity * delta

	if not player or player.health <= 0:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		move_and_slide()
		return

	# Update navigation target position
	nav_agent.target_position = player.global_position
	
	if nav_agent.is_navigation_finished():
		return

	var next_pos = nav_agent.get_next_path_position()
	var new_velocity = (next_pos - global_position).normalized() * SPEED

	# Rotate to face the moving direction (towards player)
	var look_dir = Vector2(new_velocity.x, new_velocity.z)
	if look_dir.length() > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(-new_velocity.x, -new_velocity.z), 10.0 * delta)

	velocity.x = new_velocity.x
	velocity.z = new_velocity.z

	# Check and perform attack
	var dist = global_position.distance_to(player.global_position)
	if dist <= ATTACK_RANGE:
		attack_player()

	move_and_slide()

func attack_player():
	if time_since_last_attack >= ATTACK_COOLDOWN:
		time_since_last_attack = 0.0
		player.take_damage(DAMAGE)
		
		# Lunge attack visual animation (squash/stretch)
		var tween = create_tween()
		tween.tween_property($Visuals, "scale", Vector3(1.2, 0.8, 1.2), 0.1)
		tween.tween_property($Visuals, "scale", Vector3(1.0, 1.0, 1.0), 0.2)

func take_damage(amount):
	if dead:
		return
	
	health -= amount
	if hurt_sound:
		hurt_sound.play()
	
	# Visual hit reaction flash/squash
	var tween = create_tween()
	tween.tween_property($Visuals, "scale", Vector3(0.9, 1.1, 0.9), 0.05)
	tween.tween_property($Visuals, "scale", Vector3(1.0, 1.0, 1.0), 0.05)
	
	if health <= 0:
		die()

func die():
	dead = true
	collision_layer = 0
	collision_mask = 0
	
	if hurt_sound:
		hurt_sound.pitch_scale = 0.7
		hurt_sound.play()
	
	if player and player.has_method("add_score"):
		player.add_score(10)
	
	# Death animation: squash flat and sink into ground
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property($Visuals, "scale", Vector3(1.5, 0.05, 1.5), 0.2)
	tween.tween_property($Visuals, "position", Vector3(0, 0.05, 0), 0.2)
	await tween.finished
	
	# Wait 1.5 seconds, then free the memory
	await get_tree().create_timer(1.5).timeout
	queue_free()
