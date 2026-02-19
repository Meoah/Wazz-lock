extends CharacterBody2D
class_name Clive

# Manager
var manager : PlayerManager
# Animation
@export var animation_player : AnimationPlayer
@export var body_root : Node2D
# Movement
const BASE_SPEED : float = 200.0
var move_speed : float = 200.0
var move_direction : Vector2 = Vector2.ZERO
var initial_scale : Vector2 = Vector2.ZERO
var is_rolling : bool = false
# Input
var input_flags : int = 0
var input_lock : bool = false
# Flash
var flash_tween : Tween

func _ready() -> void:
	manager = PlayerManager.new()
	initial_scale = scale # Required for _flip_h()
	
	# Connects signals
	SignalBus.connect("signal_player_rolling", _attempt_roll)
	
func _process(_delta: float) -> void:
	# Handles which animation to play depending on state.
	if manager.get_current_state() is PlayerWalkingState: _play_walking()
	if manager.get_current_state() is PlayerIdleState: _play_idle()

func _physics_process(delta) -> void:
	# Sends data to manager for state transitions.
	if !is_rolling:
		manager.physics_update(delta, input_flags)
	
	# Movement handler
	var adjusted_move_speed = move_speed
	if manager.get_current_state() is PlayerRollingState:
		adjusted_move_speed *= 2.0
		velocity = move_direction * adjusted_move_speed
	if manager.is_allow_movement():
		velocity = move_direction * adjusted_move_speed
		if move_direction.x < 0:
			_flip_h(true)
		elif move_direction.x > 0:
			_flip_h(false)
		
	move_and_slide()

# Flips the entire node visuaully on the h axis. It has to be like this
#	as negatives are converted back to positive each update tick.
func _flip_h(negative : bool = false) -> void:
	if negative:
		scale.y = -1 * initial_scale.y
		rotation_degrees = 180.0
	else:
		scale.y = initial_scale.y
		rotation_degrees = 0.0

func _input(event : InputEvent) -> void:
	## Main input reader
	if event.is_action_pressed("move_left"):		_set_flag(PlayerManager.InputFlags.MOVE_LEFT, true)
	if event.is_action_released("move_left"):		_set_flag(PlayerManager.InputFlags.MOVE_LEFT, false)
	if event.is_action_pressed("move_right"):		_set_flag(PlayerManager.InputFlags.MOVE_RIGHT, true)
	if event.is_action_released("move_right"):		_set_flag(PlayerManager.InputFlags.MOVE_RIGHT, false)
	if event.is_action_pressed("move_up"):			_set_flag(PlayerManager.InputFlags.MOVE_UP, true)
	if event.is_action_released("move_up"):			_set_flag(PlayerManager.InputFlags.MOVE_UP, false)
	if event.is_action_pressed("move_down"):		_set_flag(PlayerManager.InputFlags.MOVE_DOWN, true)
	if event.is_action_released("move_down"):		_set_flag(PlayerManager.InputFlags.MOVE_DOWN, false)
	if event.is_action_pressed("move_dodge"):		_set_flag(PlayerManager.InputFlags.DODGE, true)
	if event.is_action_released("move_dodge"):		_set_flag(PlayerManager.InputFlags.DODGE, false)
	if event.is_action_pressed("move_primary"):		_set_flag(PlayerManager.InputFlags.PRIMARY, true)
	if event.is_action_released("move_primary"):	_set_flag(PlayerManager.InputFlags.PRIMARY, false)
	if event.is_action_pressed("move_secondary"):	_set_flag(PlayerManager.InputFlags.SECONDARY, true)
	if event.is_action_released("move_secondary"):	_set_flag(PlayerManager.InputFlags.SECONDARY, false)
	
	## Updates
	_update_move_dir()

func _notification(what: int) -> void:
	# Resets movement flags to 0 if window loses focus.
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT : input_flags = 0
	_update_move_dir()

# Changes move direction according to input_flags
func _update_move_dir() -> void:
	# Don't read input if input_lock is true.
	if input_lock : return
	
	var x : int = int((input_flags & PlayerManager.InputFlags.MOVE_RIGHT) != 0) \
		   - int((input_flags & PlayerManager.InputFlags.MOVE_LEFT) != 0)
	var y : int = int((input_flags & PlayerManager.InputFlags.MOVE_DOWN) != 0) \
		   - int((input_flags & PlayerManager.InputFlags.MOVE_UP) != 0)
	move_direction = Vector2(x,y)
	
	if move_direction != Vector2.ZERO:
		move_direction = move_direction.normalized()

# Sets flag on or off
func _set_flag(flag : int, enabled : bool) -> void:
	if enabled : input_flags |= flag
	else : input_flags &= ~flag

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
const ROLL_FLASH_COLOR : Color = Color(0x41bbf3ff)
const ROLL_FLASH_FADE_IN : float = 0.3
const ROLL_FLASH_FADE_OUT : float = 0.08
# Attempts to start the roll.
func _attempt_roll() -> void:
	if is_rolling : return
	input_lock = true
	is_rolling = true
	_roll()

# Actual roll logic. Played once.
# TODO Might need to consider animation cancel handling.
func _roll() -> void:
	# Saves current animation and freezes it.
	#var previous_animation := animation_player.current_animation
	#var previous_position := animation_player.current_animation_position
	animation_player.pause()
	await _preroll_glow()
	animation_player.speed_scale = 1.0
	animation_player.play("rolling")
	await animation_player.animation_finished
	_postroll()

# Freeze frames and activates the flash.
func _preroll_glow() -> void:
	# Resets the flash if it's currently in use.
	body_root.modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	# Resets tween, then plays the flash tween.
	_kill_flash_tween()
	flash_tween = create_tween()
	flash_tween.tween_property(body_root, "modulate", ROLL_FLASH_COLOR, ROLL_FLASH_FADE_IN)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	
	# Wait for ROLL_HOLD_FRAMES amount of frames.
	for frame in ROLL_HOLD_FRAMES:
		await get_tree().process_frame

# Tweens the glow back to 0 and sets state back to idle.
func _postroll() -> void:
	# Signal that the roll is done and finishes the roll.
	SignalBus.rolling_complete.emit()
	await get_tree().process_frame
	is_rolling = false
	input_lock = false
	
	# Resets tween, then plays the flash tween.
	_kill_flash_tween()
	flash_tween = create_tween()
	flash_tween.tween_property(body_root, "modulate", Color(1.0, 1.0, 1.0, 1.0), ROLL_FLASH_FADE_OUT)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

# Kills the flash_tween.
func _kill_flash_tween():
	if flash_tween and flash_tween.is_running():
		flash_tween.kill()
	flash_tween = null

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name != "RESET":
		animation_player.play(&"RESET")
		animation_player.seek(0.0, true)
