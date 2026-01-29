class_name PlayerManager
extends RefCounted

var state_machine : StateMachine

# States
var idle_state : PlayerIdleState
var walking_state : PlayerWalkingState
var rolling_state : PlayerRollingState
var attacking_state : PlayerAttackingState
var hurt_state : PlayerHurtState
var dead_state : PlayerDeadState

# Status Flags
enum STATUS_FLAG{
	INVULN = 1
}

func _init() -> void:
	_setup_state_machine()

func _setup_state_machine() -> void:
	var transitions : Dictionary = {
		PlayerIdleState.STATE_NAME : [PlayerWalkingState.STATE_NAME, PlayerRollingState.STATE_NAME, PlayerAttackingState.STATE_NAME, PlayerHurtState.STATE_NAME, PlayerDeadState.STATE_NAME],
		PlayerWalkingState.STATE_NAME : [PlayerIdleState.STATE_NAME, PlayerRollingState.STATE_NAME, PlayerAttackingState.STATE_NAME, PlayerHurtState.STATE_NAME, PlayerDeadState.STATE_NAME],
		PlayerRollingState.STATE_NAME : [PlayerIdleState.STATE_NAME, PlayerWalkingState.STATE_NAME,  PlayerHurtState.STATE_NAME, PlayerDeadState.STATE_NAME],
		PlayerAttackingState.STATE_NAME : [PlayerIdleState.STATE_NAME, PlayerWalkingState.STATE_NAME,  PlayerHurtState.STATE_NAME, PlayerDeadState.STATE_NAME],
		PlayerHurtState.STATE_NAME : [PlayerIdleState.STATE_NAME, PlayerDeadState.STATE_NAME],
		PlayerDeadState.STATE_NAME : [PlayerIdleState.STATE_NAME]
	}
	
	state_machine = StateMachine.new("player_state", transitions)
	
	idle_state = PlayerIdleState.new(state_machine)
	walking_state = PlayerWalkingState.new(state_machine)
	rolling_state = PlayerRollingState.new(state_machine)
	attacking_state = PlayerAttackingState.new(state_machine)
	hurt_state = PlayerHurtState.new(state_machine)
	dead_state = PlayerDeadState.new(state_machine)
	
	state_machine.transition_to(idle_state)

func get_current_state() -> State:
	return state_machine.current_state
	
func is_allow_movement() -> bool:
	return state_machine.current_state.allows_movement()

func physics_update(delta : float, move_direction : Vector2, req_roll : bool, req_attack : bool) -> void:
	## TODO Interrupts (hurt/dead)
	
	## Transitions by priority (roll > attack > movement)
	if req_roll:
		state_machine.transition_to(rolling_state)
	elif req_attack:
		state_machine.transition_to(attacking_state)
	else:
		if move_direction != Vector2.ZERO:
			state_machine.transition_to(walking_state)
		else:
			state_machine.transition_to(idle_state)
			
	## Runs current state behavior
	state_machine.current_state.physics_update(delta, move_direction)
