extends Control

var player: CharacterBody3D = null

# Crosshair custom properties
@export var line_width: float = 2.0
@export var line_length: float = 8.0
@export var base_offset: float = 6.0
@export var crosshair_color: Color = Color(0.0, 1.0, 0.8, 0.8) # Sleek neon cyan

var current_spread: float = 0.0
var shoot_kick: float = 0.0

func _ready() -> void:
	player = get_parent().get_parent() as CharacterBody3D
	
	# Center anchor
	set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)

func _process(delta: float) -> void:
	if not is_instance_valid(player) or player.health <= 0:
		visible = false
		return
	visible = true
	
	# Calculate spread factor based on player movement
	var vel_factor: float = player.velocity.length() / player.SPEED
	if not player.is_on_floor():
		vel_factor += 1.0 # Extra spread when jumping/falling
	
	# If player is in ADS, reduce base offset and movement influence
	var base: float = base_offset
	if player.get("is_ads"):
		base = 1.0
		vel_factor *= 0.1
		
	# Decay shot kick
	shoot_kick = move_toward(shoot_kick, 0.0, delta * 40.0)
	
	# Target spread
	var target_spread: float = base + vel_factor * 12.0 + shoot_kick
	
	# Smoothly interpolate current spread
	current_spread = lerp(current_spread, target_spread, 20.0 * delta)
	
	# Force redraw
	queue_redraw()

func _draw() -> void:
	# Draw 4 lines around the center
	# Left
	draw_line(Vector2(-current_spread - line_length, 0), Vector2(-current_spread, 0), crosshair_color, line_width)
	# Right
	draw_line(Vector2(current_spread, 0), Vector2(current_spread + line_length, 0), crosshair_color, line_width)
	# Top
	draw_line(Vector2(0, -current_spread - line_length), Vector2(0, -current_spread), crosshair_color, line_width)
	# Bottom
	draw_line(Vector2(0, current_spread), Vector2(0, current_spread + line_length), crosshair_color, line_width)
