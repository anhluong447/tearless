# zombie_states.gd
# Concrete state implementations for Zombie FSM

class_name ZombieStates
extends Node

# ==========================================
# IDLE STATE
# ==========================================
class ZombieIdleState extends ZombieState:
	func physics_update(_delta: float) -> void:
		if zombie.dead:
			state_machine.transition_to("die")
			return
		if zombie.player and zombie.player.health > 0:
			state_machine.transition_to("chase")

# ==========================================
# CHASE STATE
# ==========================================
class ZombieChaseState extends ZombieState:
	func physics_update(delta: float) -> void:
		if zombie.dead:
			state_machine.transition_to("die")
			return
		if not zombie.player or zombie.player.health <= 0:
			state_machine.transition_to("idle")
			return

		# Apply gravity
		if not zombie.is_on_floor():
			zombie.velocity.y -= zombie.gravity * delta

		zombie.nav_agent.target_position = zombie.player.global_position
		
		var next_pos: Vector3 = zombie.nav_agent.get_next_path_position()
		var new_velocity: Vector3 = Vector3.ZERO
		
		if not zombie.nav_agent.is_navigation_finished():
			new_velocity = (next_pos - zombie.global_position).normalized() * zombie.speed

		# Rotate to face player
		var look_dir: Vector2 = Vector2(new_velocity.x, new_velocity.z)
		if look_dir.length() > 0.1:
			zombie.rotation.y = lerp_angle(zombie.rotation.y, atan2(-new_velocity.x, -new_velocity.z), 10.0 * delta)

		zombie.velocity.x = new_velocity.x
		zombie.velocity.z = new_velocity.z
		
		# Runner leap jump
		if zombie.zombie_type == zombie.ZombieType.RUNNER and zombie.is_on_floor():
			var dist: float = zombie.global_position.distance_to(zombie.player.global_position)
			if dist <= 5.0 and dist > zombie.ATTACK_RANGE and randf() < 0.02:
				var jump_dir = (zombie.player.global_position - zombie.global_position).normalized()
				zombie.velocity.x = jump_dir.x * zombie.speed * 1.5
				zombie.velocity.y = 4.0
				zombie.velocity.z = jump_dir.z * zombie.speed * 1.5
		
		# Check attack range
		var dist: float = zombie.global_position.distance_to(zombie.player.global_position)
		if dist <= zombie.ATTACK_RANGE:
			state_machine.transition_to("attack")
			return

		zombie.move_and_slide()
		zombie.try_step_up()

# ==========================================
# ATTACK STATE
# ==========================================
class ZombieAttackState extends ZombieState:
	var detonate_timer: float = 0.5
	var started_detonation: bool = false

	func enter() -> void:
		if zombie.zombie_type == zombie.ZombieType.BOMBER:
			started_detonation = true
			detonate_timer = 0.5

	func physics_update(delta: float) -> void:
		if zombie.dead:
			state_machine.transition_to("die")
			return
		if not zombie.player or zombie.player.health <= 0:
			state_machine.transition_to("idle")
			return

		if zombie.zombie_type == zombie.ZombieType.BOMBER and started_detonation:
			detonate_timer -= delta
			
			var visuals: Node3D = zombie.get_node_or_null("Visuals") as Node3D
			if visuals:
				var pulse = (int(Engine.get_physics_frames() / 3) % 2) == 0
				visuals.scale = Vector3(1.2, 1.2, 1.2) if pulse else Vector3(0.9, 0.9, 0.9)
				
			if detonate_timer <= 0.0:
				zombie.detonate()
			return

		# Apply gravity
		if not zombie.is_on_floor():
			zombie.velocity.y -= zombie.gravity * delta

		zombie.time_since_last_attack += delta

		# Face player
		var diff: Vector3 = zombie.player.global_position - zombie.global_position
		zombie.rotation.y = atan2(-diff.x, -diff.z)

		var dist: float = zombie.global_position.distance_to(zombie.player.global_position)
		if dist > zombie.ATTACK_RANGE:
			state_machine.transition_to("chase")
			return

		if zombie.time_since_last_attack >= zombie.ATTACK_COOLDOWN:
			zombie.time_since_last_attack = 0.0
			
			var final_damage = zombie.DAMAGE
			if zombie.zombie_type == zombie.ZombieType.TANK:
				final_damage = zombie.DAMAGE * 2
				
			zombie.player.take_damage(final_damage)
			
			# Lunge animation (squash/stretch)
			var visuals: Node3D = zombie.get_node_or_null("Visuals") as Node3D
			if visuals:
				var tween: Tween = zombie.create_tween()
				tween.tween_property(visuals, "scale", visuals.scale * 1.2, 0.1)
				tween.tween_property(visuals, "scale", visuals.scale, 0.2)

		# Decelerate when attacking
		zombie.velocity.x = move_toward(zombie.velocity.x, 0.0, zombie.speed)
		zombie.velocity.z = move_toward(zombie.velocity.z, 0.0, zombie.speed)
		zombie.move_and_slide()
		zombie.try_step_up()

# ==========================================
# DIE STATE
# ==========================================
class ZombieDieState extends ZombieState:
	func enter() -> void:
		zombie.dead = true
		zombie.collision_layer = 0
		zombie.collision_mask = 0
		
		# Award points
		if zombie.player and zombie.player.has_method("add_score"):
			var pts = 10
			if zombie.zombie_type == zombie.ZombieType.BOMBER:
				pts = 15
			elif zombie.zombie_type == zombie.ZombieType.TANK:
				pts = 30
			zombie.player.add_score(pts)
			
		var visuals: Node3D = zombie.get_node_or_null("Visuals") as Node3D
		if zombie.zombie_type == zombie.ZombieType.BOMBER and (visuals == null or not visuals.visible):
			# Already detonating, do not run die sequence
			return
			
		# Play death splat
		if zombie.hurt_sound:
			zombie.hurt_sound.pitch_scale = 0.7
			zombie.hurt_sound.play()
			
		# Squash and sink death visual
		if visuals:
			var tween: Tween = zombie.create_tween()
			tween.set_parallel(true)
			tween.tween_property(visuals, "scale", Vector3(1.5, 0.05, 1.5), 0.2)
			tween.tween_property(visuals, "position", Vector3(0, 0.05, 0), 0.2)
			await tween.finished
			
		# Chance to drop item pickup (Option 4)
		if zombie.has_method("spawn_drop"):
			zombie.spawn_drop()
			
		# Wait and queue free
		await zombie.get_tree().create_timer(1.5).timeout
		zombie.queue_free()
