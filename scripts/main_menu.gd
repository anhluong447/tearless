extends Control

const GameSettings = preload("res://scripts/settings.gd")


@onready var main_panel: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/MainPanel
@onready var settings_panel: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/SettingsPanel

@onready var sens_slider: HSlider = $CenterContainer/PanelContainer/MarginContainer/SettingsPanel/SensContainer/SensSlider
@onready var sens_val_label: Label = $CenterContainer/PanelContainer/MarginContainer/SettingsPanel/SensContainer/ValueLabel

@onready var vol_slider: HSlider = $CenterContainer/PanelContainer/MarginContainer/SettingsPanel/VolContainer/VolSlider
@onready var vol_val_label: Label = $CenterContainer/PanelContainer/MarginContainer/SettingsPanel/VolContainer/ValueLabel

@onready var fullscreen_checkbox: CheckButton = $CenterContainer/PanelContainer/MarginContainer/SettingsPanel/FullscreenContainer/FullscreenCheckbox

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	main_panel.show()
	settings_panel.hide()
	
	# Load current settings into UI
	sens_slider.value = GameSettings.mouse_sensitivity
	sens_val_label.text = "%.2f" % GameSettings.mouse_sensitivity
	
	vol_slider.value = GameSettings.audio_volume
	vol_val_label.text = "%d%%" % (GameSettings.audio_volume * 100)
	
	fullscreen_checkbox.button_pressed = GameSettings.is_fullscreen
	
	# Connect signals
	sens_slider.value_changed.connect(_on_sens_changed)
	vol_slider.value_changed.connect(_on_vol_changed)
	fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)

# --- Main Panel Actions ---
func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_settings_button_pressed() -> void:
	main_panel.hide()
	settings_panel.show()

func _on_exit_button_pressed() -> void:
	get_tree().quit()

# --- Settings Actions ---
func _on_back_button_pressed() -> void:
	settings_panel.hide()
	main_panel.show()

func _on_sens_changed(value: float) -> void:
	GameSettings.mouse_sensitivity = value
	sens_val_label.text = "%.2f" % value

func _on_vol_changed(value: float) -> void:
	GameSettings.audio_volume = value
	vol_val_label.text = "%d%%" % (value * 100)
	# Set main audio bus volume
	var db = linear_to_db(value)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)

func _on_fullscreen_toggled(pressed: bool) -> void:
	GameSettings.is_fullscreen = pressed
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
