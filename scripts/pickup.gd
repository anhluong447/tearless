extends Area3D

enum PickupType { HEALTH, AMMO }

@export var pickup_type: PickupType = PickupType.HEALTH
@export var pickup_value: int = 25

@onready var mesh: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	update_visuals()

func _process(delta: float) -> void:
	if mesh:
		mesh.rotate_y(2.0 * delta)

func update_visuals() -> void:
	if not is_inside_tree():
		return
	if mesh:
		var mat := StandardMaterial3D.new()
		if pickup_type == PickupType.HEALTH:
			mat.albedo_color = Color(0.1, 0.8, 0.2, 1) # Green for health
		else:
			mat.albedo_color = Color(0.1, 0.5, 0.9, 1) # Blue for ammo
		mat.emission_enabled = true
		mat.emission = mat.albedo_color
		mat.emission_energy_multiplier = 0.5
		mesh.material_override = mat

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		var applied := false
		if pickup_type == PickupType.HEALTH:
			var health := body.get("health") as int
			var max_health := body.get("max_health") as int
			if health < max_health:
				body.set("health", mini(max_health, health + pickup_value))
				applied = true
		else: # AMMO
			var cur_weapon = body.get("current_weapon")
			if cur_weapon:
				var w_name := cur_weapon.get("name") as String
				var reserves := body.get("ammo_reserves") as Dictionary
				var max_ammo := cur_weapon.get("max_ammo") as int
				reserves[w_name] = reserves.get(w_name, 0) + max_ammo * 2
				applied = true
				
		if applied:
			body.call("update_hud")
			play_pickup_sound()
			queue_free()

func play_pickup_sound() -> void:
	var temp_player := AudioStreamPlayer.new()
	temp_player.stream = preload("res://sound/reload.wav")
	temp_player.volume_db = -5.0
	get_tree().root.add_child(temp_player)
	temp_player.play()
	temp_player.finished.connect(temp_player.queue_free)
