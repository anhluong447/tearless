extends Node3D
## Procedurally builds a detailed hotel floor with rooms, corridors, furniture, and lighting.

# Material cache
var mat_carpet: StandardMaterial3D
var mat_corridor_carpet: StandardMaterial3D
var mat_wall: StandardMaterial3D
var mat_wall_accent: StandardMaterial3D
var mat_ceiling: StandardMaterial3D
var mat_wood: StandardMaterial3D
var mat_wood_dark: StandardMaterial3D
var mat_metal: StandardMaterial3D
var mat_bed_sheet: StandardMaterial3D
var mat_bed_pillow: StandardMaterial3D
var mat_glass: StandardMaterial3D
var mat_debris: StandardMaterial3D
var mat_door: StandardMaterial3D
var mat_tile: StandardMaterial3D
var mat_mirror: StandardMaterial3D
var mat_elevator_door: StandardMaterial3D

func _ready() -> void:
	create_materials()
	build_floor()
	build_outer_walls()
	build_corridor()
	build_rooms_north()
	build_rooms_south()
	build_elevator_lobby()
	build_stairwell()
	build_lobby_furniture()
	build_corridor_decor()
	build_lighting()

func create_materials() -> void:
	mat_carpet = _mat(Color(0.18, 0.04, 0.04), 0.95)
	_apply_texture(mat_carpet, "res://textures/carpet.jpg", 1.5)
	
	mat_corridor_carpet = _mat(Color(0.12, 0.08, 0.06), 0.92)
	_apply_texture(mat_corridor_carpet, "res://textures/carpet.jpg", 1.5)
	
	mat_wall = _mat(Color(0.38, 0.35, 0.28), 0.85)
	_apply_texture(mat_wall, "res://textures/wallpaper.jpg", 0.6)
	
	mat_wall_accent = _mat(Color(0.28, 0.22, 0.16), 0.85)
	_apply_texture(mat_wall_accent, "res://textures/wallpaper.jpg", 0.6)
	
	mat_ceiling = _mat(Color(0.1, 0.1, 0.11), 0.9)
	_apply_texture(mat_ceiling, "res://textures/ceiling.jpg", 0.8)
	
	mat_wood = _mat(Color(0.22, 0.14, 0.08), 0.75)
	_apply_texture(mat_wood, "res://textures/wood.jpg", 1.2)
	
	mat_wood_dark = _mat(Color(0.12, 0.07, 0.04), 0.8)
	_apply_texture(mat_wood_dark, "res://textures/wood.jpg", 1.2)
	
	mat_metal = _mat_metallic(Color(0.5, 0.5, 0.5), 0.7, 0.3)
	mat_bed_sheet = _mat(Color(0.7, 0.68, 0.62), 0.8)
	mat_bed_pillow = _mat(Color(0.8, 0.78, 0.75), 0.85)
	mat_glass = _mat_metallic(Color(0.15, 0.35, 0.45), 0.85, 0.15)
	
	mat_debris = _mat(Color(0.14, 0.1, 0.06), 0.9)
	_apply_texture(mat_debris, "res://textures/wood.jpg", 1.0)
	
	mat_door = _mat(Color(0.3, 0.2, 0.12), 0.7)
	_apply_texture(mat_door, "res://textures/wood.jpg", 1.0)
	
	mat_tile = _mat(Color(0.75, 0.73, 0.7), 0.5)
	_apply_texture(mat_tile, "res://textures/tile.jpg", 1.2)
	
	mat_mirror = _mat_metallic(Color(0.8, 0.85, 0.9), 0.95, 0.05)
	mat_elevator_door = _mat_metallic(Color(0.55, 0.48, 0.2), 0.85, 0.25)

func _apply_texture(mat: StandardMaterial3D, path: String, scale: float = 1.0) -> void:
	var abs_path = ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(abs_path):
		var img = Image.load_from_file(abs_path)
		if img:
			var tex = ImageTexture.create_from_image(img)
			mat.albedo_texture = tex
			mat.uv1_triplanar = true
			mat.uv1_scale = Vector3(scale, scale, scale)

func _mat(color: Color, rough: float) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.uv1_triplanar = true
	return m

func _mat_metallic(color: Color, metal: float, rough: float) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metal
	m.roughness = rough
	m.uv1_triplanar = true
	return m

func _mat_emissive(color: Color, emission: Color, energy: float) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = emission
	m.emission_energy_multiplier = energy
	return m

func _box(parent: Node3D, nm: String, pos: Vector3, sz: Vector3, mat: StandardMaterial3D, collision: bool = true) -> CSGBox3D:
	var b = CSGBox3D.new()
	b.name = nm
	b.size = sz
	b.transform.origin = pos
	b.material = mat
	b.use_collision = collision
	parent.add_child(b)
	return b

# ── FLOOR & CEILING ──
func build_floor() -> void:
	# Main floor — large hotel floor: 70m x 30m
	_box(self, "Floor", Vector3(0, -0.05, 0), Vector3(70, 0.1, 30), mat_carpet)
	# Corridor carpet stripe
	_box(self, "CorridorCarpet", Vector3(0, 0.001, 0), Vector3(60, 0.01, 3.2), mat_corridor_carpet, false)
	# Ceiling
	_box(self, "Ceiling", Vector3(0, 3.55, 0), Vector3(70, 0.1, 30), mat_ceiling)

# ── OUTER WALLS ──
func build_outer_walls() -> void:
	_box(self, "WallN", Vector3(0, 1.75, -15.1), Vector3(70, 3.5, 0.2), mat_wall)
	_box(self, "WallS", Vector3(0, 1.75, 15.1), Vector3(70, 3.5, 0.2), mat_wall)
	_box(self, "WallW", Vector3(-35.1, 1.75, 0), Vector3(0.2, 3.5, 30.4), mat_wall)
	_box(self, "WallE", Vector3(35.1, 1.75, 0), Vector3(0.2, 3.5, 30.4), mat_wall)

# ── CENTRAL CORRIDOR ──
func build_corridor() -> void:
	# North corridor wall (with gaps for room doors)
	var north_segments = [
		[Vector3(-30, 1.75, -1.6), Vector3(8, 3.5, 0.2)],   # Far west
		[Vector3(-19, 1.75, -1.6), Vector3(6, 3.5, 0.2)],
		[Vector3(-8, 1.75, -1.6), Vector3(8, 3.5, 0.2)],
		[Vector3(4, 1.75, -1.6), Vector3(8, 3.5, 0.2)],
		[Vector3(16, 1.75, -1.6), Vector3(6, 3.5, 0.2)],
		[Vector3(27, 1.75, -1.6), Vector3(8, 3.5, 0.2)],
	]
	for i in range(north_segments.size()):
		_box(self, "CorridorN_%d" % i, north_segments[i][0], north_segments[i][1], mat_wall)
	
	# South corridor wall (with gaps for room doors)
	var south_segments = [
		[Vector3(-30, 1.75, 1.6), Vector3(8, 3.5, 0.2)],
		[Vector3(-19, 1.75, 1.6), Vector3(6, 3.5, 0.2)],
		[Vector3(-8, 1.75, 1.6), Vector3(8, 3.5, 0.2)],
		[Vector3(4, 1.75, 1.6), Vector3(8, 3.5, 0.2)],
		[Vector3(16, 1.75, 1.6), Vector3(6, 3.5, 0.2)],
		[Vector3(27, 1.75, 1.6), Vector3(8, 3.5, 0.2)],
	]
	for i in range(south_segments.size()):
		_box(self, "CorridorS_%d" % i, south_segments[i][0], south_segments[i][1], mat_wall)

# ── NORTH ROOMS (5 rooms) ──
func build_rooms_north() -> void:
	var room_centers_x = [-26.0, -15.0, -4.0, 9.0, 22.0]
	var room_width = 8.0
	var lamp_mat = _mat_emissive(Color(1,0.9,0.6), Color(1,0.85,0.5), 3.0)
	for i in range(room_centers_x.size()):
		var cx = room_centers_x[i]
		var cz = -8.0
		var rm_name = "Room%d" % (101 + i)
		# Room divider walls (between rooms)
		if i < room_centers_x.size() - 1:
			var wall_x = (room_centers_x[i] + room_centers_x[i + 1]) / 2.0
			_box(self, rm_name + "_DivW", Vector3(wall_x, 1.75, cz), Vector3(0.15, 3.5, 13.6), mat_wall_accent)
		# Furniture: Bed
		_box(self, rm_name + "_BedFrame", Vector3(cx - 1.5, 0.25, cz - 2.5), Vector3(2.4, 0.5, 2.0), mat_wood)
		_box(self, rm_name + "_Sheet", Vector3(cx - 1.5, 0.55, cz - 2.5), Vector3(2.2, 0.08, 1.8), mat_bed_sheet, false)
		_box(self, rm_name + "_Pillow", Vector3(cx - 1.5, 0.62, cz - 3.2), Vector3(1.2, 0.12, 0.4), mat_bed_pillow, false)
		# Headboard
		_box(self, rm_name + "_Headboard", Vector3(cx - 1.5, 0.7, cz - 3.5), Vector3(2.3, 0.8, 0.1), mat_wood_dark, false)
		# Nightstands (both sides)
		_box(self, rm_name + "_NightstandL", Vector3(cx - 2.9, 0.3, cz - 3.2), Vector3(0.5, 0.6, 0.5), mat_wood_dark)
		_box(self, rm_name + "_NightstandR", Vector3(cx - 0.1, 0.3, cz - 3.2), Vector3(0.5, 0.6, 0.5), mat_wood_dark)
		# Bedside lamps
		_box(self, rm_name + "_LampL", Vector3(cx - 2.9, 0.75, cz - 3.2), Vector3(0.15, 0.3, 0.15), lamp_mat, false)
		_box(self, rm_name + "_LampR", Vector3(cx - 0.1, 0.75, cz - 3.2), Vector3(0.15, 0.3, 0.15), lamp_mat, false)
		# Bedside light source
		var bl = OmniLight3D.new()
		bl.name = rm_name + "_BedLight"
		bl.light_color = Color(1.0, 0.85, 0.6)
		bl.light_energy = 1.5
		bl.omni_range = 5.0
		bl.position = Vector3(cx - 0.1, 1.0, cz - 3.2)
		add_child(bl)
		# Dresser + TV
		_box(self, rm_name + "_Dresser", Vector3(cx + 2.0, 0.45, cz + 4.5), Vector3(1.4, 0.9, 0.6), mat_wood)
		var tv_mat = _mat_emissive(Color(0.1, 0.1, 0.15), Color(0.05, 0.3, 0.8), 3.0)
		_box(self, rm_name + "_TV", Vector3(cx + 2.0, 1.1, cz + 4.5), Vector3(0.9, 0.55, 0.08), tv_mat, false)
		# Bathroom partition
		_box(self, rm_name + "_BathWall", Vector3(cx + 2.8, 1.75, cz - 0.5), Vector3(0.12, 3.5, 2.8), mat_tile)
		_box(self, rm_name + "_BathFloor", Vector3(cx + 3.2, 0.01, cz - 1.0), Vector3(1.5, 0.02, 2.5), mat_tile, false)
		# Sink counter
		_box(self, rm_name + "_Sink", Vector3(cx + 3.5, 0.45, cz - 1.5), Vector3(0.8, 0.9, 0.5), mat_tile)
		# Mirror above sink
		_box(self, rm_name + "_Mirror", Vector3(cx + 3.9, 1.5, cz - 1.5), Vector3(0.04, 0.7, 0.5), mat_mirror, false)
		# Desk + chair
		_box(self, rm_name + "_Desk", Vector3(cx - 0.5, 0.38, cz + 2.0), Vector3(1.2, 0.76, 0.6), mat_wood_dark)
		_box(self, rm_name + "_Chair", Vector3(cx - 0.5, 0.25, cz + 3.0), Vector3(0.5, 0.5, 0.5), mat_wood)
		# Baseboard north wall
		_box(self, rm_name + "_BaseN", Vector3(cx, 0.06, cz - 6.9), Vector3(room_width, 0.12, 0.08), mat_wood_dark, false)
		# Door frame
		_box(self, rm_name + "_DoorL", Vector3(cx - 0.55, 1.2, -1.55), Vector3(0.1, 2.4, 0.15), mat_door, false)
		_box(self, rm_name + "_DoorR", Vector3(cx + 0.55, 1.2, -1.55), Vector3(0.1, 2.4, 0.15), mat_door, false)
		_box(self, rm_name + "_DoorTop", Vector3(cx, 2.45, -1.55), Vector3(1.2, 0.1, 0.15), mat_door, false)

# ── SOUTH ROOMS (5 rooms) ──
func build_rooms_south() -> void:
	var room_centers_x = [-26.0, -15.0, -4.0, 9.0, 22.0]
	for i in range(room_centers_x.size()):
		var cx = room_centers_x[i]
		var cz = 8.0
		var rm_name = "RoomS%d" % (106 + i)
		if i < room_centers_x.size() - 1:
			var wall_x = (room_centers_x[i] + room_centers_x[i + 1]) / 2.0
			_box(self, rm_name + "_DivW", Vector3(wall_x, 1.75, cz), Vector3(0.15, 3.5, 13), mat_wall_accent)
		_box(self, rm_name + "_BedFrame", Vector3(cx + 1.5, 0.25, cz + 2.5), Vector3(2.4, 0.5, 2.0), mat_wood)
		_box(self, rm_name + "_Sheet", Vector3(cx + 1.5, 0.55, cz + 2.5), Vector3(2.2, 0.08, 1.8), mat_bed_sheet, false)
		_box(self, rm_name + "_Pillow", Vector3(cx + 1.5, 0.62, cz + 3.2), Vector3(1.2, 0.12, 0.4), mat_bed_pillow, false)
		_box(self, rm_name + "_Nightstand", Vector3(cx - 0.2, 0.3, cz + 3.2), Vector3(0.5, 0.6, 0.5), mat_wood_dark)
		_box(self, rm_name + "_Dresser", Vector3(cx - 2.0, 0.45, cz + 4.0), Vector3(1.2, 0.9, 0.6), mat_wood)
		var tv_mat = _mat_emissive(Color(0.1, 0.1, 0.15), Color(0.05, 0.3, 0.8), 2.0)
		_box(self, rm_name + "_TV", Vector3(cx - 2.0, 1.1, cz + 4.0), Vector3(0.8, 0.5, 0.1), tv_mat, false)
		_box(self, rm_name + "_BathWall", Vector3(cx - 2.8, 1.75, cz - 0.5), Vector3(0.12, 3.5, 3.5), mat_tile)
		_box(self, rm_name + "_BathFloor", Vector3(cx - 3.2, 0.01, cz - 0.5), Vector3(1.5, 0.02, 3.5), mat_tile, false)
		_box(self, rm_name + "_Mirror", Vector3(cx - 3.85, 1.6, cz - 0.5), Vector3(0.04, 0.8, 0.5), mat_mirror, false)
		_box(self, rm_name + "_Desk", Vector3(cx + 0.5, 0.38, cz - 1.5), Vector3(1.2, 0.76, 0.6), mat_wood_dark)

# ── ELEVATOR LOBBY (east end) ──
func build_elevator_lobby() -> void:
	# End wall partition
	_box(self, "ElevatorPartition", Vector3(31, 1.75, 0), Vector3(0.2, 3.5, 30), mat_wall_accent)
	# Elevator doors (2 elevators)
	_box(self, "ElevDoor1", Vector3(34.9, 1.1, -3), Vector3(0.3, 2.2, 1.6), mat_elevator_door)
	_box(self, "ElevDoor2", Vector3(34.9, 1.1, 3), Vector3(0.3, 2.2, 1.6), mat_elevator_door)
	# Blocked with debris
	_box(self, "ElevDebris1", Vector3(33, 0.5, -3), Vector3(1.5, 1.0, 1.8), mat_debris)
	_box(self, "ElevDebris2", Vector3(33.5, 0.35, 2), Vector3(1.0, 0.7, 1.5), mat_debris)
	_box(self, "ElevDebris3", Vector3(32, 0.7, 0), Vector3(2.0, 1.4, 1.0), mat_debris)
	# Waiting bench
	_box(self, "ElevBench", Vector3(31.5, 0.25, -6), Vector3(2.0, 0.5, 0.7), mat_wood)

# ── STAIRWELL (west end) ──
func build_stairwell() -> void:
	_box(self, "StairPartition", Vector3(-31, 1.75, 0), Vector3(0.2, 3.5, 30), mat_wall_accent)
	# Stairwell door frame
	_box(self, "StairDoorL", Vector3(-34.5, 1.75, -0.7), Vector3(0.6, 3.5, 0.2), mat_door)
	_box(self, "StairDoorR", Vector3(-34.5, 1.75, 0.7), Vector3(0.6, 3.5, 0.2), mat_door)
	# Blocked staircase
	_box(self, "StairBlock1", Vector3(-33, 0.6, 0), Vector3(2.5, 1.2, 2.0), mat_debris)
	_box(self, "StairBlock2", Vector3(-33.5, 1.2, -1), Vector3(1.5, 0.6, 1.0), mat_debris)
	# Overturned vending machine
	_box(self, "VendingMachine", Vector3(-33, 0.45, 4), Vector3(1.0, 0.9, 2.0), mat_metal)

# ── LOBBY FURNITURE (center area) ──
func build_lobby_furniture() -> void:
	# Reception counter (L-shaped)
	_box(self, "ReceptionFront", Vector3(0, 0.55, -3.5), Vector3(4.0, 1.1, 0.6), mat_wood_dark)
	_box(self, "ReceptionSide", Vector3(-1.8, 0.55, -5.0), Vector3(0.6, 1.1, 3.5), mat_wood_dark)
	# Counter top
	_box(self, "ReceptionTop", Vector3(0, 1.15, -3.5), Vector3(4.2, 0.06, 0.7), mat_wood, false)
	# Seating area
	_box(self, "Sofa1", Vector3(3, 0.3, -5), Vector3(2.5, 0.6, 1.0), mat_bed_sheet)
	_box(self, "Sofa1Back", Vector3(3, 0.7, -5.4), Vector3(2.5, 0.4, 0.2), mat_bed_sheet, false)
	_box(self, "CoffeeTable", Vector3(3, 0.22, -3.5), Vector3(1.5, 0.44, 0.8), mat_wood)

# ── CORRIDOR DECORATIONS ──
func build_corridor_decor() -> void:
	# Wall paintings along corridor (north side)
	var painting_positions_x = [-22.0, -10.0, 2.0, 14.0, 25.0]
	for i in range(painting_positions_x.size()):
		var colors = [Color(0.6, 0.2, 0.15), Color(0.15, 0.3, 0.5), Color(0.4, 0.35, 0.15), Color(0.2, 0.45, 0.2), Color(0.5, 0.15, 0.35)]
		var pm = _mat(colors[i], 0.6)
		_box(self, "PaintingN_%d" % i, Vector3(painting_positions_x[i], 1.8, -1.5), Vector3(1.2, 0.8, 0.04), pm, false)
	# South side paintings
	for i in range(painting_positions_x.size()):
		var colors = [Color(0.3, 0.15, 0.5), Color(0.5, 0.4, 0.1), Color(0.1, 0.4, 0.4), Color(0.55, 0.2, 0.1), Color(0.2, 0.2, 0.5)]
		var pm = _mat(colors[i], 0.6)
		_box(self, "PaintingS_%d" % i, Vector3(painting_positions_x[i], 1.8, 1.5), Vector3(1.2, 0.8, 0.04), pm, false)
	# Potted plants (dark green boxes as placeholder)
	var plant_mat = _mat(Color(0.1, 0.3, 0.08), 0.85)
	var pot_mat = _mat(Color(0.4, 0.2, 0.1), 0.8)
	var plant_x = [-28.0, -12.0, 6.0, 18.0, 28.0]
	for i in range(plant_x.size()):
		_box(self, "Pot_%d" % i, Vector3(plant_x[i], 0.2, -1.3), Vector3(0.4, 0.4, 0.4), pot_mat)
		_box(self, "Plant_%d" % i, Vector3(plant_x[i], 0.6, -1.3), Vector3(0.5, 0.5, 0.5), plant_mat, false)
	# Room number signs (emissive gold)
	var sign_mat = _mat_emissive(Color(0.6, 0.5, 0.2), Color(0.6, 0.5, 0.2), 1.5)
	var room_x_n = [-26.0, -15.0, -4.0, 9.0, 22.0]
	for i in range(room_x_n.size()):
		_box(self, "SignN_%d" % i, Vector3(room_x_n[i], 2.3, -1.55), Vector3(0.5, 0.2, 0.04), sign_mat, false)
		_box(self, "SignS_%d" % i, Vector3(room_x_n[i], 2.3, 1.55), Vector3(0.5, 0.2, 0.04), sign_mat, false)

# ── LIGHTING ──
func build_lighting() -> void:
	# Corridor fluorescent lights every 6m (much denser)
	var tube_mat = _mat_emissive(Color(0.95, 0.95, 1.0), Color(0.9, 0.9, 1.0), 3.0)
	var cx_lights = [-28.0, -22.0, -16.0, -10.0, -4.0, 2.0, 8.0, 14.0, 20.0, 26.0]
	for i in range(cx_lights.size()):
		var tube = MeshInstance3D.new()
		tube.name = "Tube_%d" % i
		var bm = BoxMesh.new()
		bm.size = Vector3(1.4, 0.06, 0.06)
		tube.mesh = bm
		tube.material_override = tube_mat
		tube.position = Vector3(cx_lights[i], 3.4, 0)
		add_child(tube)
		var energy = 2.5 if i % 3 != 2 else 0.6  # 1 in 3 is flickering/dim
		var omni = OmniLight3D.new()
		omni.name = "CL_%d" % i
		omni.light_color = Color(0.85, 0.88, 1.0)
		omni.light_energy = energy
		omni.omni_range = 8.0
		omni.shadow_enabled = true
		omni.position = Vector3(cx_lights[i], 3.2, 0)
		add_child(omni)
	# Emergency red at elevator
	var em = OmniLight3D.new()
	em.name = "EmRed"
	em.light_color = Color(1, 0.03, 0.03)
	em.light_energy = 3.5
	em.omni_range = 9.0
	em.shadow_enabled = true
	em.position = Vector3(33, 2.8, 0)
	add_child(em)
	var esm = _mat_emissive(Color(0.9, 0.05, 0.05), Color(0.9, 0.05, 0.05), 6.0)
	_box(self, "ExitSign", Vector3(31, 2.8, 0), Vector3(0.6, 0.25, 0.06), esm, false)
	# Stairwell green
	var sl = OmniLight3D.new()
	sl.name = "StairGreen"
	sl.light_color = Color(0.1, 0.8, 0.15)
	sl.light_energy = 2.0
	sl.omni_range = 7.0
	sl.shadow_enabled = true
	sl.position = Vector3(-33, 2.8, 0)
	add_child(sl)
	# ALL rooms get ceiling lights now
	var all_rooms_n = [-26.0, -15.0, -4.0, 9.0, 22.0]
	for x in all_rooms_n:
		var rl = OmniLight3D.new()
		rl.name = "RLN_%d" % int(x)
		rl.light_color = Color(1.0, 0.88, 0.65)
		rl.light_energy = 1.8
		rl.omni_range = 7.0
		rl.shadow_enabled = true
		rl.position = Vector3(x, 2.8, -8)
		add_child(rl)
	var all_rooms_s = [-26.0, -15.0, -4.0, 9.0, 22.0]
	for x in all_rooms_s:
		var rl = OmniLight3D.new()
		rl.name = "RLS_%d" % int(x)
		rl.light_color = Color(1.0, 0.88, 0.65)
		rl.light_energy = 1.8
		rl.omni_range = 7.0
		rl.shadow_enabled = true
		rl.position = Vector3(x, 2.8, 8)
		add_child(rl)
	# Lobby chandelier
	var lb = OmniLight3D.new()
	lb.name = "LobbyMain"
	lb.light_color = Color(1.0, 0.82, 0.55)
	lb.light_energy = 3.5
	lb.omni_range = 14.0
	lb.shadow_enabled = true
	lb.position = Vector3(0, 3.0, -4)
	add_child(lb)
	# Elevator lobby light
	var elb = OmniLight3D.new()
	elb.name = "ElevLobby"
	elb.light_color = Color(0.9, 0.7, 0.5)
	elb.light_energy = 2.0
	elb.omni_range = 8.0
	elb.position = Vector3(33, 2.8, -5)
	add_child(elb)
