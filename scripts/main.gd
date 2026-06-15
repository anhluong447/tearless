extends Node3D

@onready var nav_region: NavigationRegion3D = $NavigationRegion3D
@onready var spawner: Node3D = $Spawner
var player: CharacterBody3D = null

func _ready() -> void:
	# Find player
	player = get_tree().get_first_node_in_group("player") as CharacterBody3D
	
	# Connect spawner signals to player HUD
	if spawner and player:
		spawner.connect("wave_started", _on_wave_started)
		spawner.connect("wave_completed", _on_wave_completed)
		spawner.connect("countdown_tick", _on_countdown_tick)
	
	# Wait a few frames for CSG shapes and physics to settle, then bake the navmesh
	for i in range(5):
		await get_tree().physics_frame
	if nav_region:
		nav_region.bake_navigation_mesh()

func _on_wave_started(wave_num: int) -> void:
	if player:
		player.update_wave_number(wave_num)
		player.show_wave_alert("WAVE %d INCOMING!" % wave_num)
		
		# Hide the alert banner after 2 seconds
		await get_tree().create_timer(2.0).timeout
		# Make sure player is still in tree/valid before hiding
		if is_instance_valid(player):
			player.hide_wave_alert()

func _on_wave_completed(wave_num: int) -> void:
	if player:
		player.show_wave_alert("WAVE %d COMPLETED!" % wave_num)

func _on_countdown_tick(seconds: int) -> void:
	if player:
		if seconds > 0:
			player.show_wave_alert("NEXT WAVE IN %d..." % seconds)
		else:
			player.hide_wave_alert()
