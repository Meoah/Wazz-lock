extends Resource
class_name AttackChain

@export var stages: Array[AttackStage] = []

func get_stage(stage_id: StringName) -> AttackStage:
	for stage in stages:
		if stage and stage.stage_id == stage_id:
			return stage
	return null
