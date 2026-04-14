extends Area2D
class_name HurtBoxComponent

signal hit_received(hit_data)

@export var receiver: Node
@export var faction: StringName = &"neutral"
@export var hurtable: bool = true

func receive_hit(hit_data: HitData) -> bool:
	if !hurtable: return false
	
	if receiver == null:
		push_warning("HurtBoxComponent has no receiver.")
		return false
	
	if receiver.has_method("can_receive_hit"):
		if not receiver.can_receive_hit(hit_data):
			return false
	
	if receiver.has_method("receive_hit"):
		var accepted: bool = receiver.receive_hit(hit_data)
		if accepted: hit_received.emit(hit_data)
		return accepted
	
	push_warning("Receiver does not implement receive_hit(hit_data).")
	return false
