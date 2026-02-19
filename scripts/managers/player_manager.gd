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

# Flags
enum InputFlags{
	MOVE_UP		= 1 << 0,
	MOVE_DOWN	= 1 << 1,
	MOVE_LEFT	= 1 << 2,
	MOVE_RIGHT	= 1 << 3,
	DODGE		= 1 << 4,
	PRIMARY		= 1 << 5,
	SECONDARY	= 1 << 6
}
enum STATUS_FLAG{
	INVULN = 1
}

func _init() -> void:
	_setup_state_machine()
	SignalBus.connect("rolling_complete", request_idle)

func _setup_state_machine() -> void:
	var transitions : Dictionary = {
		PlayerIdleState.STATE_NAME : [
			PlayerWalkingState.STATE_NAME,
			PlayerRollingState.STATE_NAME,
			PlayerAttackingState.STATE_NAME,
			PlayerHurtState.STATE_NAME,
			PlayerDeadState.STATE_NAME],
		PlayerWalkingState.STATE_NAME : [
			PlayerIdleState.STATE_NAME,
			PlayerRollingState.STATE_NAME,
			PlayerAttackingState.STATE_NAME,
			PlayerHurtState.STATE_NAME,
			PlayerDeadState.STATE_NAME],
		PlayerRollingState.STATE_NAME : [
			PlayerIdleState.STATE_NAME,
			PlayerWalkingState.STATE_NAME,
			PlayerHurtState.STATE_NAME,
			PlayerDeadState.STATE_NAME],
		PlayerAttackingState.STATE_NAME : [
			PlayerIdleState.STATE_NAME,
			PlayerWalkingState.STATE_NAME,
			PlayerHurtState.STATE_NAME,
			PlayerDeadState.STATE_NAME],
		PlayerHurtState.STATE_NAME : [
			PlayerIdleState.STATE_NAME,
			PlayerDeadState.STATE_NAME],
		PlayerDeadState.STATE_NAME : [
			PlayerIdleState.STATE_NAME]
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

func physics_update(delta : float, input_flags : int) -> void:
	# Movement flags
	var movement_flags : int = InputFlags.MOVE_UP | InputFlags.MOVE_DOWN | InputFlags.MOVE_LEFT | InputFlags.MOVE_RIGHT
	
	## TODO Interrupts (hurt/dead)
	
	## Transitions by priority (roll > attack > movement)
	if input_flags & InputFlags.DODGE :
		state_machine.transition_to(rolling_state)
	elif input_flags & InputFlags.PRIMARY:
		state_machine.transition_to(attacking_state)
	else:
		if input_flags & movement_flags != 0:
			state_machine.transition_to(walking_state)
		else:
			state_machine.transition_to(idle_state)
			
	## Runs current state behavior
	# TODO is this required?
	state_machine.current_state.physics_update(delta, input_flags)

## Requests by other systems. Returns false if invalid transition
func request_idle() -> bool : return state_machine.transition_to(idle_state) == OK
	
