extends StaticBody3D

@export var explosion_damage: float = 150.0
@export var explosion_radius: float = 6.0

var exploded: bool = false

func take_damage(_amount: int, _is_headshot: bool = false) -> void:
	if exploded:
		return
	explode()

func explode() -> void:
	exploded = true
	
	# Play explosion sound
	var audio_player = AudioStreamPlayer3D.new()
	audio_player.stream = load("res://sound/splat.wav")
	audio_player.pitch_scale = 0.4
	audio_player.volume_db = 12.0
	audio_player.max_distance = 60.0
	audio_player.bus = "Master"
	get_parent().add_child(audio_player)
	audio_player.global_position = global_position
	audio_player.play()
	
	# Deal damage to zombies in radius
	var all_zombies = get_tree().get_nodes_in_group("zombie")
	for zombie in all_zombies:
		if is_instance_valid(zombie) and not zombie.get("dead"):
			var dist = global_position.distance_to(zombie.global_position)
			if dist <= explosion_radius:
				var damage_falloff = int(explosion_damage * (1.0 - (dist / explosion_radius)))
				if zombie.has_method("take_damage"):
					zombie.take_damage(damage_falloff)
					
	# Deal damage to player in radius
	var player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player) and player.get("health") > 0:
		var dist = global_position.distance_to(player.global_position)
		if dist <= explosion_radius:
			var damage_falloff = int((explosion_damage * 0.4) * (1.0 - (dist / explosion_radius)))
			if player.has_method("take_damage"):
				player.take_damage(damage_falloff)
				
	# Spawn explosion particles
	var spark_scene = load("res://scenes/spark_particles.tscn") as PackedScene
	if spark_scene:
		var inst = spark_scene.instantiate() as CPUParticles3D
		inst.position = global_position + Vector3(0, 0.6, 0)
		inst.amount = 80
		inst.lifetime = 1.2
		inst.scale = Vector3(4.0, 4.0, 4.0)
		get_parent().add_child(inst)
		
	# Clean up audio player
	get_tree().create_timer(3.0).timeout.connect(audio_player.queue_free)
	
	# Remove barrel
	queue_free()
