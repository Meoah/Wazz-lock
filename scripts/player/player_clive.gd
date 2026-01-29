extends CharacterBody2D
class_name Clive

var manager : PlayerManager

@export var move_speed : float = 200.0
var move_direction : Vector2 = Vector2.ZERO
var initial_scale : Vector2 = Vector2.ZERO

var move_inputs : Dictionary ={
	"ui_up" : false,
	"ui_down" : false,
	"ui_left" : false,
	"ui_right" : false
}
var roll_input : bool = false
var attack_input : bool = false

func _ready() -> void:
	manager = PlayerManager.new()
	initial_scale = scale
	

func _physics_process(delta) -> void:
	manager.physics_update(delta, move_direction, roll_input, attack_input)
	
	if manager.is_allow_movement():
		velocity = move_direction * move_speed
		if move_direction.x < 0:
			flip_h(true)
		elif move_direction.x > 0:
			flip_h(false)
	else:
		velocity = Vector2.ZERO
		
	move_and_slide()

func flip_h(negative : bool = false) -> void:
	if negative:
		scale.y = -1 * initial_scale.y
		rotation_degrees = 180.0
	else:
		scale.y = initial_scale.y
		rotation_degrees = 0.0

func _input(event : InputEvent) -> void:
	var direction : bool = false
	
	## Main input reader
	for each in move_inputs.keys():
		if event.is_action(each):
			move_inputs[each] = event.is_pressed()
			direction = true
	if event.is_action_pressed("ui_dodge"):
		roll_input = true
	elif event.is_action_released("ui_dodge"):
		roll_input = false
	if event.is_action_pressed("ui_select"):
		attack_input = true
	elif event.is_action_released("ui_select"):
		attack_input = false
	
	## Updates direction only if corresponding keys are pressed 
	if direction:
		_update_move_dir()
		
func _update_move_dir() -> void:
	var x : int = int(move_inputs["ui_right"]) - int(move_inputs["ui_left"])
	var y : int = int(move_inputs["ui_down"]) - int(move_inputs["ui_up"])
	move_direction = Vector2(x,y)
	
	if move_direction != Vector2.ZERO:
		move_direction = move_direction.normalized()
