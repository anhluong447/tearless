extends Area3D

@onready var shop_ui: PanelContainer = $CanvasLayer/ShopUI
@onready var prompt_label: Label = $CanvasLayer/PromptLabel

# Upgrade costs
const AMMO_COST = 150
const HEALTH_COST = 500
const SPEED_COST = 600
const DAMAGE_COST = 800
const MOLOTOV_COST = 200

var player_near: bool = false
var player_node: CharacterBody3D = null

func _ready() -> void:
	# Keep processing when tree is paused
	process_mode = PROCESS_MODE_ALWAYS
	shop_ui.hide()
	prompt_label.hide()
	
	# Connect Area3D signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Dynamically insert MolotovButton in the VBoxContainer
	var vbox = $CanvasLayer/ShopUI/MarginContainer/VBoxContainer
	if vbox:
		var molotov_btn := Button.new()
		molotov_btn.name = "MolotovButton"
		molotov_btn.set("theme_override_font_sizes/font_size", 16)
		var close_btn = vbox.get_node_or_null("CloseButton")
		if close_btn:
			vbox.add_child(molotov_btn)
			vbox.move_child(molotov_btn, close_btn.get_index())
		else:
			vbox.add_child(molotov_btn)
		molotov_btn.pressed.connect(_on_molotov_button_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if player_near and event.is_action_pressed("reload"): # We will map reload or interactive key. Let's use reload key or add "interact" key. Let's use E key for interaction.
		# Wait, let's map a custom action "interact" or check if KEY_E is pressed.
		pass

func _process(_delta: float) -> void:
	if player_near and not shop_ui.visible:
		if Input.is_key_pressed(KEY_E):
			open_shop()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_near = true
		player_node = body as CharacterBody3D
		prompt_label.text = "[E] Open City Shop"
		prompt_label.show()

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_near = false
		player_node = null
		prompt_label.hide()
		close_shop()

func open_shop() -> void:
	if not player_node:
		return
	shop_ui.show()
	prompt_label.hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	update_buttons()

func close_shop() -> void:
	shop_ui.hide()
	if player_near:
		prompt_label.show()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().paused = false

func update_buttons() -> void:
	if not player_node:
		return
		
	var score = player_node.score
	$CanvasLayer/ShopUI/MarginContainer/VBoxContainer/AmmoButton.text = "Refill Ammo (%d pts) - [Current score: %d]" % [AMMO_COST, score]
	$CanvasLayer/ShopUI/MarginContainer/VBoxContainer/HealthButton.text = "Max HP +25 (%d pts)" % HEALTH_COST
	$CanvasLayer/ShopUI/MarginContainer/VBoxContainer/SpeedButton.text = "Move Speed +15%% (%d pts)" % SPEED_COST
	$CanvasLayer/ShopUI/MarginContainer/VBoxContainer/DamageButton.text = "Bullet Damage +20%% (%d pts)" % DAMAGE_COST
	
	var mol_btn = $CanvasLayer/ShopUI/MarginContainer/VBoxContainer.get_node_or_null("MolotovButton") as Button
	if mol_btn:
		var mol_count = player_node.get("molotovs_carried")
		if mol_count >= 5:
			mol_btn.text = "Buy Molotov (MAX 5/5)"
			mol_btn.disabled = true
		else:
			mol_btn.text = "Buy Molotov (%d pts) [Current: %d/5]" % [MOLOTOV_COST, mol_count]
			mol_btn.disabled = player_node.score < MOLOTOV_COST

func _on_ammo_button_pressed() -> void:
	if player_node and player_node.score >= AMMO_COST:
		player_node.score -= AMMO_COST
		# Refill all weapons' reserves
		for w_name in player_node.ammo_reserves.keys():
			var w_data = null
			for w in player_node.weapons:
				if w.name == w_name:
					w_data = w
					break
			if w_data:
				player_node.ammo_reserves[w_name] = w_data.max_ammo * 3
		player_node.update_hud()
		update_buttons()

func _on_health_button_pressed() -> void:
	if player_node and player_node.score >= HEALTH_COST:
		player_node.score -= HEALTH_COST
		player_node.max_health += 25
		player_node.health += 25
		player_node.update_hud()
		update_buttons()

func _on_speed_button_pressed() -> void:
	if player_node and player_node.score >= SPEED_COST:
		player_node.score -= SPEED_COST
		player_node.speed_multiplier *= 1.15
		player_node.update_hud()
		update_buttons()

func _on_damage_button_pressed() -> void:
	if player_node and player_node.score >= DAMAGE_COST:
		player_node.score -= DAMAGE_COST
		player_node.damage_multiplier *= 1.20
		player_node.update_hud()
		update_buttons()

func _on_close_button_pressed() -> void:
	close_shop()

func _on_molotov_button_pressed() -> void:
	if player_node and player_node.score >= MOLOTOV_COST:
		var mol_count = player_node.get("molotovs_carried")
		if mol_count < 5:
			player_node.score -= MOLOTOV_COST
			player_node.set("molotovs_carried", mol_count + 1)
			player_node.update_hud()
			update_buttons()
