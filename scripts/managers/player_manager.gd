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
var reset_state : PlayerResetState

func _init() -> void:
	_setup_state_machine()

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
			PlayerHurtState.STATE_NAME,
			PlayerDeadState.STATE_NAME,
			PlayerResetState.STATE_NAME],
		PlayerAttackingState.STATE_NAME : [
			PlayerRollingState.STATE_NAME,
			PlayerHurtState.STATE_NAME,
			PlayerDeadState.STATE_NAME,
			PlayerResetState.STATE_NAME],
		PlayerHurtState.STATE_NAME : [
			PlayerResetState.STATE_NAME,
			PlayerDeadState.STATE_NAME],
		PlayerDeadState.STATE_NAME : [
			PlayerResetState.STATE_NAME],
		PlayerResetState.STATE_NAME: [
			PlayerIdleState.STATE_NAME,
			PlayerWalkingState.STATE_NAME,
			PlayerAttackingState.STATE_NAME]
	}
	
	state_machine = StateMachine.new("player_state", transitions)
	
	idle_state = PlayerIdleState.new(state_machine)
	walking_state = PlayerWalkingState.new(state_machine)
	rolling_state = PlayerRollingState.new(state_machine)
	attacking_state = PlayerAttackingState.new(state_machine)
	hurt_state = PlayerHurtState.new(state_machine)
	dead_state = PlayerDeadState.new(state_machine)
	reset_state = PlayerResetState.new(state_machine)
	
	state_machine.transition_to(idle_state)

func get_current_state() -> State:
	return state_machine.current_state
	
func is_allow_movement() -> bool:
	return state_machine.current_state.allows_movement()

## Requests by other systems. Returns false if invalid transition
func request_idle() -> bool : return state_machine.transition_to(idle_state) == OK
func request_walking() -> bool : return state_machine.transition_to(walking_state) == OK
func request_rolling() -> bool : return state_machine.transition_to(rolling_state) == OK
func request_attacking() -> bool : return state_machine.transition_to(attacking_state) == OK
func request_hurt() -> bool : return state_machine.transition_to(hurt_state) == OK
func request_dead() -> bool : return state_machine.transition_to(dead_state) == OK
func request_reset() -> bool : return state_machine.transition_to(reset_state) == OK
