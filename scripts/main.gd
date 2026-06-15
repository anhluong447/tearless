extends Node3D

@onready var nav_region = $NavigationRegion3D

func _ready():
	# Wait one frame for CSG shapes and physics to settle, then bake the navmesh
	await get_tree().physics_frame
	if nav_region:
		nav_region.bake_navigation_mesh()
