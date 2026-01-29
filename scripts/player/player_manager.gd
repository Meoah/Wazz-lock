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

func _ready() -> void:
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
