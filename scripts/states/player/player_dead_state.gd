extends StateComponent
class_name PlayerDeadStateComponent

func enter(_previous_state: StateComponent, _data: Dictionary = {}) -> void:
	if parent is Clive:
		parent.begin_death()

		var run_root: RunRoot = parent.get_tree().get_first_node_in_group("run_root") as RunRoot
		if run_root:
			run_root.begin_player_death_sequence(parent)
