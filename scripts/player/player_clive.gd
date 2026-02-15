extends CharacterBody2D
class_name Clive

# Manager
var manager : PlayerManager
# Node exports
@export var sprite : AnimatedSprite2D
# Movement
@export var move_speed : float = 200.0
var move_direction : Vector2 = Vector2.ZERO
var initial_scale : Vector2 = Vector2.ZERO
# Input
var input_flags : int = 0

func _ready() -> void:
	manager = PlayerManager.new()
	initial_scale = scale
	
func _process(_delta: float) -> void:
	# TODO Should this stay in this script or to the manager?
	if manager.get_current_state() == manager.walking_state:
		sprite.sprite_frames.set_animation_speed("idle", 16.0)
	if manager.get_current_state() == manager.idle_state:
		sprite.sprite_frames.set_animation_speed("idle", 4.0)

func _physics_process(delta) -> void:
	manager.physics_update(delta, input_flags)
	
	if manager.is_allow_movement():
		velocity = move_direction * move_speed
		if move_direction.x < 0:
			flip_h(true)
		elif move_direction.x > 0:
			flip_h(false)
	else:
		velocity = Vector2.ZERO
		
	move_and_slide()

# Flips the entire node visuaully on the h axis. It has to be like this
#	as negatives are converted back to positive each update tick.
func flip_h(negative : bool = false) -> void:
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
