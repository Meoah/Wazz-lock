extends CharacterBody2D
class_name Clive

# Manager
var manager : PlayerManager
# Animation
@export var animation_player : AnimationPlayer
@export var body_root : Node2D
@export var hands : AnimatedSprite2D
@export var aim_arrow : Sprite2D
@export var collision_box : CollisionShape2D
@export var hurt_box : Area2D
@export var health_bar : ProgressBar
# Movement
const BASE_SPEED : float = 200.0
var move_speed : float = 200.0
var move_direction : Vector2 = Vector2.ZERO
# Input
var input_flags : int = 0
enum INPUT_FLAG{
	MOVE_UP		= 1 << 0,
	MOVE_DOWN	= 1 << 1,
	MOVE_LEFT	= 1 << 2,
	MOVE_RIGHT	= 1 << 3,
	DODGE		= 1 << 4,
	PRIMARY		= 1 << 5,
	SECONDARY	= 1 << 6
}
# Tweens
var flash_tween : Tween
var invuln_tween : Tween
# Cooldowns
var roll_cooldown : float = 0.0
var attack_cooldown : float = 0.0
var invuln_cooldown : float = 0.0
# Status Flags
var status_flags : int = 0
enum STATUS_FLAG{
	INVULN		= 1 << 0,
	ROLLING		= 1 << 1,
	ATTACKING	= 1 << 2
}

func _ready() -> void:
	manager = PlayerManager.new()
	
	# Connects signals
	#SignalBus.connect("state_player_hurt", _player_hurt)
	SignalBus.connect("state_player_dead", _player_dead)
	SignalBus.connect("state_player_rolling", _attempt_roll)
	SignalBus.connect("state_player_attacking", _attempt_attack)
	
func _process(delta: float) -> void:
	if manager.get_current_state() is PlayerDeadState : return
	
	_update_timers(delta)
	_update_status()
	_update_aim()
	_update_state()
	
	# Handles which animation to play depending on state.
	if manager.get_current_state() is PlayerWalkingState: _play_walking()
	if manager.get_current_state() is PlayerIdleState: _play_idle()


func _physics_process(_delta : float) -> void:
	_movement_handler()

func _input(event : InputEvent) -> void:
	## Main input reader
	if event.is_action_pressed("move_left"):		_set_input_flag(INPUT_FLAG.MOVE_LEFT, true)
	if event.is_action_released("move_left"):		_set_input_flag(INPUT_FLAG.MOVE_LEFT, false)
	if event.is_action_pressed("move_right"):		_set_input_flag(INPUT_FLAG.MOVE_RIGHT, true)
	if event.is_action_released("move_right"):		_set_input_flag(INPUT_FLAG.MOVE_RIGHT, false)
	if event.is_action_pressed("move_up"):			_set_input_flag(INPUT_FLAG.MOVE_UP, true)
	if event.is_action_released("move_up"):			_set_input_flag(INPUT_FLAG.MOVE_UP, false)
	if event.is_action_pressed("move_down"):		_set_input_flag(INPUT_FLAG.MOVE_DOWN, true)
	if event.is_action_released("move_down"):		_set_input_flag(INPUT_FLAG.MOVE_DOWN, false)
	if event.is_action_pressed("move_dodge"):		_set_input_flag(INPUT_FLAG.DODGE, true)
	if event.is_action_released("move_dodge"):		_set_input_flag(INPUT_FLAG.DODGE, false)
	if event.is_action_pressed("move_primary"):		_set_input_flag(INPUT_FLAG.PRIMARY, true)
	if event.is_action_released("move_primary"):	_set_input_flag(INPUT_FLAG.PRIMARY, false)
	if event.is_action_pressed("move_secondary"):	_set_input_flag(INPUT_FLAG.SECONDARY, true)
	if event.is_action_released("move_secondary"):	_set_input_flag(INPUT_FLAG.SECONDARY, false)
	
	## Updates
	_update_move_direction()

func _notification(what: int) -> void:
	# Resets movement flags to 0 if window loses focus.
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT : input_flags = 0
	_update_move_direction()

# Handles all timers.
func _update_timers(delta : float) -> void:
	roll_cooldown -= delta
	attack_cooldown -= delta
	invuln_cooldown -= delta

# Handles most statuses.
func _update_status() -> void:
	if invuln_cooldown > 0 : _set_status_flag(STATUS_FLAG.INVULN, true)
	if invuln_cooldown <= 0 : _set_status_flag(STATUS_FLAG.INVULN, false)
	
	# Status handlers.
	_health_handler()
	_invuln_handler()

# Handles health. Triggers death if health < 0.
func _health_handler() -> void:
	health_bar.max_value = SystemData.player_max_health
	health_bar.value = SystemData.player_current_health
	
	if SystemData.player_current_health < 0.0 : manager.request_dead()

## Invuln Procedure
const INVULN_FLASH_MIN_ALPHA : float = 0.25
const INVULN_FLASH_HALF_PERIOD : float = 0.06
var was_invuln : bool = false
# Determines effects while invuln.
func _invuln_handler() -> void:
	# Only run the handler if it detects a change in invuln status.
	var invuln_now := (status_flags & STATUS_FLAG.INVULN) != 0
	if invuln_now == was_invuln : return
	was_invuln = invuln_now
	
	if invuln_now : _start_invuln_flash()
	else : _stop_invuln_flash()

# Starts the invuln flash.
func _start_invuln_flash() -> void:
	# Resets
	_stop_invuln_flash()
	
	# Starts the loop of alpha flashing.
	invuln_tween = create_tween()
	invuln_tween.set_loops()
	invuln_tween.tween_property(body_root, "modulate:a", INVULN_FLASH_MIN_ALPHA, INVULN_FLASH_HALF_PERIOD)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	invuln_tween.tween_property(body_root, "modulate:a", 1.0, INVULN_FLASH_HALF_PERIOD)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

# Stops the flashing and resets.
func _stop_invuln_flash() -> void:
	_kill_invuln_tween()
	body_root.modulate.a = 1.0

# Kills the invuln_tween.
func _kill_invuln_tween() -> void:
	if invuln_tween and invuln_tween.is_running():
		invuln_tween.kill()
	invuln_tween = null

# Main state handler
func _update_state() -> void:
	# Movement flags
	var movement_flags : int = INPUT_FLAG.MOVE_UP | INPUT_FLAG.MOVE_DOWN | INPUT_FLAG.MOVE_LEFT | INPUT_FLAG.MOVE_RIGHT
	
	## Interrupts
	if manager.get_current_state() is PlayerDeadState : return
	if manager.get_current_state() is PlayerHurtState : return
	
	## Transitions by priority (roll > attack > movement)
	#TODO Primary/secondary attack
	if input_flags & INPUT_FLAG.DODGE && roll_cooldown < 0 : manager.request_rolling()
	elif input_flags & INPUT_FLAG.PRIMARY && attack_cooldown < 0 : manager.request_attacking()
	elif input_flags & movement_flags != 0 : manager.request_walking()
	else : manager.request_idle()

# Flips the entire node visuaully on the h axis. It has to be like this
#	as negatives are converted back to positive each update tick.
func _flip_h(negative : bool = false) -> void:
	if negative:
		body_root.scale.y = -1.0
		body_root.rotation_degrees = 180.0
	else:
		body_root.scale.y = 1.0
		body_root.rotation_degrees = 0.0

# Changes move direction according to input_flags
func _update_move_direction() -> void:
	# Don't read input if rolling.
	if status_flags & STATUS_FLAG.ROLLING : return
	
	var x : int = int((input_flags & INPUT_FLAG.MOVE_RIGHT) != 0) \
		   - int((input_flags & INPUT_FLAG.MOVE_LEFT) != 0)
	var y : int = int((input_flags & INPUT_FLAG.MOVE_DOWN) != 0) \
		   - int((input_flags & INPUT_FLAG.MOVE_UP) != 0)
	move_direction = Vector2(x,y)
	
	if move_direction != Vector2.ZERO:
		move_direction = move_direction.normalized()

# Checks if movement is allowed.
func _movement_handler() -> void:
	# If there are movement adjustments, do them here.
	var adjusted_move_speed = move_speed
	
	# Rolling state, disallows movement adjustment when rolling.
	if manager.get_current_state() is PlayerRollingState:
		adjusted_move_speed *= 2.0
		velocity = move_direction * adjusted_move_speed
	
	# If state allows movement, do so.
	if manager.is_allow_movement():
		velocity = move_direction * adjusted_move_speed
		# Flips horizontally if player faces left.
		# TODO mouse aiming may alter this logic.
		if move_direction.x < 0 : _flip_h(true)
		elif move_direction.x > 0 : _flip_h(false)
	
	move_and_slide()

# Sets input flag on or off
func _set_input_flag(flag : int, enabled : bool) -> void:
	if enabled : input_flags |= flag
	else : input_flags &= ~flag
	
# Sets status flag on or off
func _set_status_flag(flag : int, enabled : bool) -> void:
	if enabled : status_flags |= flag
	else : status_flags &= ~flag

# Plays default animation with a scaling speed depending on adjusted speed.
func _play_walking() -> void:
	var speed_ratio = velocity.length() / BASE_SPEED
	if animation_player.current_animation != "default":
		animation_player.play("default")
	animation_player.speed_scale = lerp(1.0, 4.0, speed_ratio)

# Plays default animation at normal speed.
func _play_idle() -> void:
	if animation_player.current_animation != "default":
		animation_player.play("default")
	animation_player.speed_scale = 1.0

## Rolling Procedure
const ROLL_HOLD_FRAMES : int = 15 # How long the preroll is in frames before rolling.
const ROLL_FLASH_COLOR : Color = Color(0.255, 0.733, 0.953)
# Attempts to start the roll.
func _attempt_roll() -> void:
	if status_flags & STATUS_FLAG.ROLLING : return
	_set_status_flag(STATUS_FLAG.ROLLING, true)
	_roll()

# Actual roll logic. Played once.
# TODO Might need to consider animation cancel handling.
func _roll() -> void:
	# Freezes current animation and triggers flash.
	animation_player.pause()
	await _preroll_flash()
	
	# Play actual rolling animation.
	animation_player.speed_scale = 1.0
	animation_player.play("rolling")
	
	# Cleanup
	await animation_player.animation_finished
	_postroll()

# Freeze frames and activates the flash.
func _preroll_flash() -> void:
	# Resets the flash if it's currently in use.
	body_root.modulate = Color(1.0, 1.0, 1.0)
	
	# Resets tween, then plays the flash tween.
	_flash_color(ROLL_FLASH_COLOR, 0.3)
	
	# Wait for ROLL_HOLD_FRAMES amount of frames.
	for frame in ROLL_HOLD_FRAMES:
		await get_tree().process_frame

# Tweens the glow back to 0 and sets state back to idle.
func _postroll() -> void:
	# Cooldown and flag.
	roll_cooldown = 0.56
	_set_status_flag(STATUS_FLAG.ROLLING, false)
	
	# Resets tween, then replays the flash tween to reset back to normal colors.
	_flash_color(Color(1.0, 1.0, 1.0), 0.3)

# Flash handler.
func _flash_color(target_color : Color, time : float) -> void:
	# Reset
	_kill_flash_tween()
	flash_tween = create_tween()
	
	# Preserves current alpha, then flash the target color.
	target_color.a = body_root.modulate.a
	flash_tween.tween_property(body_root, "modulate", target_color, time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

# Kills the flash_tween.
func _kill_flash_tween():
	if flash_tween and flash_tween.is_running():
		flash_tween.kill()
	flash_tween = null

## Attacking Procedure
# Finds appropriate attack.
func _attempt_attack() -> void:
	# TODO actually have different attacks. For now he just punch
	_set_status_flag(STATUS_FLAG.ATTACKING, true)
	
	var adjusted_attack_speed = 1.0
	_use_aim()
	animation_player.speed_scale = adjusted_attack_speed
	_punch()
	
	await animation_player.animation_finished
	_use_aim(true)
	_set_status_flag(STATUS_FLAG.ATTACKING, false)

# Do a punch.
func _punch() -> void:
	animation_player.play("attacking")
	_adjust_attack_cooldown(1.0)

# Handles cooldowns.
func _adjust_attack_cooldown(base : float) -> void :
	# TODO allow adjustments
	attack_cooldown = base

## Aiming Procedure
# Uses the current arrow rotation for where the hands should aim at.
func _use_aim(reset : bool = false) -> void:
	if reset : hands.rotation = 0.0
	elif body_root.scale.y < 0 : hands.rotation = -aim_arrow.rotation - PI / 2.0
	else : hands.rotation = aim_arrow.rotation - PI / 2.0

# Finds appropriate aiming type.
func _update_aim() -> void:
	# TODO other aim options
	match SystemData.aim_mode:
		SystemData.AIMING_MODE.DEFAULT : _keyboard_aim(false)

# Uses the last directional input to determine aim.
func _keyboard_aim(_assist : bool = false) -> void:
	if move_direction == Vector2.ZERO : return
	var target : float = move_direction.angle() + PI / 2.0
	aim_arrow.rotation = target
	
	# TODO add aim assist
	# if assist : _aim_assist()

func _player_dead() -> void:
	manager.request_dead()
	animation_player.speed_scale = 1.0
	animation_player.play("dead")

# Forces a reset every time an animation is finished unless dead.
func _on_animation_player_animation_finished(anim_name : StringName) -> void:
	if (anim_name != "RESET") && (anim_name != "dead"):
		manager.request_reset()
		animation_player.play("RESET")
		animation_player.seek(0.0, true)
