extends Area3D

enum ItemType { BATTERY, RADIO, EXTRACTION_PAD }

@export var item_type: ItemType = ItemType.BATTERY

var player_in_range: bool = false
var player_node: CharacterBody3D = null
var main_script: Node = null

var prompt_label: Label = null

func _ready() -> void:
	prompt_label = _find_prompt_label(self)
	if prompt_label:
		prompt_label.hide()
		
	main_script = get_node_or_null("/root/Main")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _find_prompt_label(node: Node) -> Label:
	if node is Label and node.name == "PromptLabel":
		return node
	for child in node.get_children():
		var found = _find_prompt_label(child)
		if found:
			return found
	return null

func _process(_delta: float) -> void:
	if player_in_range:
		if item_type == ItemType.BATTERY:
			if Input.is_key_pressed(KEY_E):
				pick_up_battery()
		elif item_type == ItemType.RADIO:
			var collected = main_script.get("batteries_collected") if main_script else 0
			if collected >= 2:
				if prompt_label:
					prompt_label.text = "[E] Repair Radio Transmitter"
				if Input.is_key_pressed(KEY_E):
					repair_radio()
			else:
				if prompt_label:
					prompt_label.text = "Radio Offline: Find 2 Batteries (%d/2)" % collected

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		player_node = body
		
		if item_type == ItemType.BATTERY:
			if prompt_label:
				prompt_label.text = "[E] Take Battery"
				prompt_label.show()
		elif item_type == ItemType.RADIO:
			var collected = main_script.get("batteries_collected") if main_script else 0
			if prompt_label:
				if collected >= 2:
					prompt_label.text = "[E] Repair Radio Transmitter"
				else:
					prompt_label.text = "Radio Offline: Find 2 Batteries (%d/2)" % collected
				prompt_label.show()
		elif item_type == ItemType.EXTRACTION_PAD:
			trigger_victory()

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		player_node = null
		if prompt_label:
			prompt_label.hide()

func pick_up_battery() -> void:
	if main_script and main_script.has_method("collect_battery"):
		main_script.call("collect_battery")
	if prompt_label:
		prompt_label.hide()
	
	if player_node and player_node.reload_sound:
		player_node.reload_sound.play()
		
	queue_free()

func repair_radio() -> void:
	if main_script and main_script.has_method("start_extraction_phase"):
		main_script.call("start_extraction_phase")
	if prompt_label:
		prompt_label.hide()
	queue_free()

func trigger_victory() -> void:
	if main_script and main_script.has_method("show_victory"):
		main_script.call("show_victory")
