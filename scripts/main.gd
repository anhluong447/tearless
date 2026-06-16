extends Node3D

@onready var nav_region: NavigationRegion3D = $NavigationRegion3D
@onready var spawner: Node3D = $Spawner
var player: CharacterBody3D = null

# Quest variables
var quest_phase: int = 1 # 1: Wave survival, 2: Battery quest, 3: Extraction countdown, 4: Extraction ready
var batteries_collected: int = 0
var extraction_timer: float = 30.0
var bgm_player: AudioStreamPlayer = null
var quest_spawn_timer: float = 0.0

func _ready() -> void:
	# Find player
	player = get_tree().get_first_node_in_group("player") as CharacterBody3D
	if not player:
		player = get_node_or_null("/root/Main/Player") as CharacterBody3D
	
	# Connect spawner signals
	if spawner and player:
		spawner.connect("wave_started", _on_wave_started)
		spawner.connect("wave_completed", _on_wave_completed)
		spawner.connect("countdown_tick", _on_countdown_tick)
	
	# Setup background music
	setup_bgm()
	
	# Spawn explosive barrels
	spawn_barrels()
	
	# Wait a few frames for CSG shapes and physics to settle, then bake the navmesh
	for i in range(5):
		await get_tree().physics_frame
	if nav_region:
		nav_region.bake_navigation_mesh()

func _process(delta: float) -> void:
	if quest_phase == 2:
		quest_spawn_timer += delta
		if quest_spawn_timer >= 6.0:
			quest_spawn_timer = 0.0
			var alive = get_tree().get_nodes_in_group("zombie").size()
			if alive < 5:
				if spawner and spawner.has_method("spawn_zombie"):
					spawner.call("spawn_zombie")
					
	if quest_phase == 3:
		extraction_timer -= delta
		var sec = ceili(extraction_timer)
		if player:
			if sec > 0:
				player.show_wave_alert("HELI ARRIVING IN %d SECONDS!" % sec)
			else:
				# Trigger Phase 4 (Extraction Pad Active)
				quest_phase = 4
				player.show_wave_alert("EXTRACTION LZ ACTIVE! GET TO THE LZ!")
				# Spawn extraction zone at West Stairwell Lobby
				spawn_extraction_pad(Vector3(-15.5, 0.05, 0.0))

func setup_bgm() -> void:
	bgm_player = AudioStreamPlayer.new()
	var stream = load("res://sound/Bouncy Away.mp3")
	if stream:
		if stream is AudioStreamMP3:
			stream.loop = true
		bgm_player.stream = stream
		bgm_player.volume_db = -12.0 # Ambient level
		add_child(bgm_player)
		bgm_player.play()

func _on_wave_started(wave_num: int) -> void:
	if player:
		player.update_wave_number(wave_num)
		player.show_wave_alert("WAVE %d INCOMING!" % wave_num)
		
		# Hide the alert banner after 2 seconds
		await get_tree().create_timer(2.0).timeout
		if is_instance_valid(player):
			player.hide_wave_alert()

func _on_wave_completed(wave_num: int) -> void:
	if player:
		player.show_wave_alert("WAVE %d COMPLETED!" % wave_num)
		
	if wave_num == 3:
		# Enter Phase 2 (Objective Battery Retrieval)
		start_battery_quest_phase()

func _on_countdown_tick(seconds: int) -> void:
	if player:
		if seconds > 0:
			player.show_wave_alert("NEXT WAVE IN %d..." % seconds)
		else:
			player.hide_wave_alert()

func start_battery_quest_phase() -> void:
	quest_phase = 2
	
	# Pause normal wave progression by pausing the spawner physics
	if spawner:
		spawner.set_physics_process(false)
		
	if player:
		player.show_wave_alert("OBJECTIVE: Collect 2 Batteries to Repair Radio!")
		
	# Spawn 2 batteries inside Room 101 and Room 104
	spawn_battery(Vector3(-11.0, 0.5, -5.5))
	spawn_battery(Vector3(11.0, 0.5, 5.5))
	
	# Spawn Radio Transmitter on the Lobby reception desk
	spawn_radio(Vector3(0.0, 1.0, -2.5))

func collect_battery() -> void:
	batteries_collected += 1
	if player:
		player.set("batteries_carried", player.get("batteries_carried") + 1)
		player.show_wave_alert("Battery Collected! (%d/2)" % batteries_collected)
		await get_tree().create_timer(2.0).timeout
		if is_instance_valid(player) and quest_phase == 2:
			player.show_wave_alert("Return both batteries to the Radio at the center Plaza!")

func start_extraction_phase() -> void:
	quest_phase = 3
	extraction_timer = 30.0
	
	# Reactivate spawner and turn it into a final chaotic wave spawner
	if spawner:
		spawner.set_physics_process(true)
		spawner.set("current_wave", 4)
		spawner.set("zombies_to_spawn_total", 999) # Endless rush
		spawner.set("zombies_spawned_so_far", 0)
		spawner.set("current_spawn_cooldown", 1.0) # Spawn every 1s
		spawner.set("spawn_timer", 0.0)

func spawn_battery(pos: Vector3) -> void:
	var root_node = Area3D.new()
	root_node.collision_layer = 8
	root_node.collision_mask = 2
	root_node.global_position = pos
	
	root_node.set_script(load("res://scripts/quest_item.gd"))
	root_node.set("item_type", 0) # BATTERY
	
	var shape3d = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(2, 2, 2)
	shape3d.shape = box_shape
	root_node.add_child(shape3d)
	
	# Yellow glowing mesh
	var mesh = CSGBox3D.new()
	mesh.size = Vector3(0.4, 0.6, 0.4)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0.9, 0)
	mat.emission_enabled = true
	mat.emission = Color(1, 0.9, 0)
	mat.emission_energy_multiplier = 3.0
	mesh.material = mat
	root_node.add_child(mesh)
	
	var canvas = CanvasLayer.new()
	var label = Label.new()
	label.name = "PromptLabel"
	label.anchors_preset = 7
	label.grow_horizontal = 2
	label.grow_vertical = 0
	label.text = "[E] Take Battery"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set("theme_override_font_sizes/font_size", 20)
	label.set("theme_override_colors/font_color", Color(1, 0.9, 0))
	label.set("theme_override_colors/font_outline_color", Color(0, 0, 0))
	label.set("theme_override_constants/outline_size", 4)
	label.offset_left = -150
	label.offset_right = 150
	label.offset_top = -120
	label.offset_bottom = -90
	
	canvas.add_child(label)
	root_node.add_child(canvas)
	
	add_child(root_node)
	root_node.add_to_group("batteries")

func spawn_radio(pos: Vector3) -> void:
	var root_node = Area3D.new()
	root_node.collision_layer = 8
	root_node.collision_mask = 2
	root_node.global_position = pos
	
	root_node.set_script(load("res://scripts/quest_item.gd"))
	root_node.set("item_type", 1) # RADIO
	
	var shape3d = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(2.5, 2, 2.5)
	shape3d.shape = box_shape
	root_node.add_child(shape3d)
	
	# Pedestal
	var mesh = CSGBox3D.new()
	mesh.size = Vector3(0.5, 1.2, 0.5)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.25, 0.3)
	mesh.material = mat
	root_node.add_child(mesh)
	
	# Red blinking screen/antenna
	var antenna = CSGCylinder3D.new()
	antenna.radius = 0.05
	antenna.height = 0.6
	antenna.position = Vector3(0, 0.9, 0)
	var ant_mat = StandardMaterial3D.new()
	ant_mat.albedo_color = Color(1, 0, 0)
	ant_mat.emission_enabled = true
	ant_mat.emission = Color(1, 0, 0)
	ant_mat.emission_energy_multiplier = 2.0
	antenna.material = ant_mat
	root_node.add_child(antenna)
	
	var canvas = CanvasLayer.new()
	var label = Label.new()
	label.name = "PromptLabel"
	label.anchors_preset = 7
	label.grow_horizontal = 2
	label.grow_vertical = 0
	label.text = "Radio Offline: Find 2 Batteries"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set("theme_override_font_sizes/font_size", 20)
	label.set("theme_override_colors/font_color", Color(1, 0.2, 0.2))
	label.set("theme_override_colors/font_outline_color", Color(0, 0, 0))
	label.set("theme_override_constants/outline_size", 4)
	label.offset_left = -250
	label.offset_right = 250
	label.offset_top = -120
	label.offset_bottom = -90
	
	canvas.add_child(label)
	root_node.add_child(canvas)
	
	add_child(root_node)
	root_node.add_to_group("radio")

func spawn_extraction_pad(pos: Vector3) -> void:
	var root_node = Area3D.new()
	root_node.collision_layer = 8
	root_node.collision_mask = 2
	root_node.global_position = pos
	
	root_node.set_script(load("res://scripts/quest_item.gd"))
	root_node.set("item_type", 2) # EXTRACTION_PAD
	
	var shape3d = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(4.0, 2.0, 4.0)
	shape3d.shape = box_shape
	root_node.add_child(shape3d)
	
	var mesh = CSGCylinder3D.new()
	mesh.radius = 2.0
	mesh.height = 0.05
	mesh.position = Vector3(0, 0.025, 0)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0, 1, 0.2, 0.5)
	mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0, 1, 0.2, 1)
	mat.emission_energy_multiplier = 4.0
	mesh.material = mat
	root_node.add_child(mesh)
	
	# Empty prompt label node so _ready does not fail to find it
	var canvas = CanvasLayer.new()
	var label = Label.new()
	label.name = "PromptLabel"
	canvas.add_child(label)
	root_node.add_child(canvas)
	
	add_child(root_node)
	root_node.add_to_group("extraction_pad")

func show_victory() -> void:
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	var canvas = CanvasLayer.new()
	canvas.process_mode = PROCESS_MODE_ALWAYS
	
	var center = CenterContainer.new()
	center.anchors_preset = 15
	center.grow_horizontal = 2
	center.grow_vertical = 2
	
	var panel = PanelContainer.new()
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.15, 0.05, 0.95)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(0, 1.0, 0.2, 1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	panel.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.set("theme_override_constants/margin_left", 40)
	margin.set("theme_override_constants/margin_top", 30)
	margin.set("theme_override_constants/margin_right", 40)
	margin.set("theme_override_constants/margin_bottom", 30)
	
	var vbox = VBoxContainer.new()
	vbox.set("theme_override_constants/separation", 15)
	
	var title = Label.new()
	title.text = "MISSION ACCOMPLISHED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set("theme_override_font_sizes/font_size", 28)
	title.set("theme_override_colors/font_color", Color(0, 1.0, 0.2))
	
	var desc = Label.new()
	desc.text = "You successfully repaired the radio\nand escaped the zombie infested city!\n\nFinal Score: %d" % (player.score if player else 0)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var btn = Button.new()
	btn.text = "Play Again"
	btn.pressed.connect(_on_restart_pressed)
	
	vbox.add_child(title)
	vbox.add_child(desc)
	vbox.add_child(btn)
	margin.add_child(vbox)
	panel.add_child(margin)
	center.add_child(panel)
	canvas.add_child(center)
	add_child(canvas)

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func spawn_barrels() -> void:
	var barrel_scene = load("res://scenes/explosive_barrel.tscn") as PackedScene
	if not barrel_scene:
		return
		
	var barrel_positions := [
		Vector3(-4.0, 0.0, 0.0),
		Vector3(4.0, 0.0, 0.0),
		Vector3(-7.0, 0.0, -4.5),
		Vector3(7.0, 0.0, 4.5)
	]
	
	for pos in barrel_positions:
		var barrel = barrel_scene.instantiate() as Node3D
		add_child(barrel)
		barrel.global_position = pos

func get_current_objective_targets() -> Array:
	var list = []
	if quest_phase == 2:
		var p = get_tree().get_first_node_in_group("player")
		var batteries_carried = p.get("batteries_carried") if p else 0
		if batteries_carried < 2:
			for bat in get_tree().get_nodes_in_group("batteries"):
				if is_instance_valid(bat):
					list.append({"node": bat, "label": "◆ Battery"})
		else:
			for rad in get_tree().get_nodes_in_group("radio"):
				if is_instance_valid(rad):
					list.append({"node": rad, "label": "▲ Transmitter"})
	elif quest_phase == 4:
		for pad in get_tree().get_nodes_in_group("extraction_pad"):
			if is_instance_valid(pad):
				list.append({"node": pad, "label": "★ Escape LZ"})
	return list
