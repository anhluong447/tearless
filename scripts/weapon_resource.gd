class_name WeaponData
extends Resource

@export var name: String = "Pistol"
@export var damage: int = 25
@export var fire_rate: float = 0.2
@export var max_ammo: int = 30
@export var reload_time: float = 1.2
@export var is_shotgun: bool = false
@export var pellet_count: int = 5
@export_range(0.0, 0.5) var spread: float = 0.0
@export var shoot_sound: AudioStream
@export var reload_sound: AudioStream
@export var gun_color: Color = Color(1, 0.8, 0, 1)
