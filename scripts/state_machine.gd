class_name StateMachine
extends Node

var current_state: ZombieState
var states: Dictionary = {}
var zombie: CharacterBody3D

func _ready() -> void:
	zombie = get_parent() as CharacterBody3D
	
	# Programmatically register the states from ZombieStates
	var idle: ZombieState = ZombieStates.ZombieIdleState.new()
	idle.name = "idle"
	idle.zombie = zombie
	idle.state_machine = self
	add_child(idle)
	states["idle"] = idle
	
	var chase: ZombieState = ZombieStates.ZombieChaseState.new()
	chase.name = "chase"
	chase.zombie = zombie
	chase.state_machine = self
	add_child(chase)
	states["chase"] = chase
	
	var attack: ZombieState = ZombieStates.ZombieAttackState.new()
	attack.name = "attack"
	attack.zombie = zombie
	attack.state_machine = self
	add_child(attack)
	states["attack"] = attack
	
	var die: ZombieState = ZombieStates.ZombieDieState.new()
	die.name = "die"
	die.zombie = zombie
	die.state_machine = self
	add_child(die)
	states["die"] = die
	
	# Set initial state
	current_state = idle
	current_state.enter()

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func transition_to(state_name: String) -> void:
	var key := state_name.to_lower()
	if states.has(key):
		var new_state: ZombieState = states[key]
		if new_state != current_state:
			if current_state:
				current_state.exit()
			current_state = new_state
			current_state.enter()
