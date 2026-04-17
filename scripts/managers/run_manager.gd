extends Node

const WEAPON_ID_PLUNGER: String = "plunger"
const WEAPON_ID_BARE_HANDS: String = "bare_hands"

enum BootMode {
	NONE,
	NEW_RUN,
	CONTINUE_RUN
}

enum LevelPhase {
	FLOOR_1,
	FLOOR_2,
	FLOOR_3,
	ENDLESS
}

# Public Variables
var applied_reward_effects: Array[Dictionary] = []
var current_weapon_id: String = WEAPON_ID_PLUNGER
var boot_mode: BootMode = BootMode.NONE
var pending_save_data: Dictionary = {}
var pending_setup_data: Dictionary = {}

var current_money: float = 0.0
var current_meta: float = 0.0
var is_boss_active: bool = false
var boss_node: BaseEnemy
var is_timer_active: bool = true
var current_run_timer: float = 0.0
var is_active_combat_room: bool = false

var current_level_phase: LevelPhase = LevelPhase.FLOOR_1
var endless_depth: int = 0

var current_level_timer: float = 0.0
var current_level_silver_gained: float = 0.0
var current_level_gold_gained: float = 0.0
var current_level_reward_effects: Array[Dictionary] = []

var total_run_silver_gained: float = 0.0
var total_run_gold_gained: float = 0.0

func _process(delta: float) -> void:
	if is_timer_active:
		current_run_timer += delta
		current_level_timer += delta


func normalize_weapon_id(weapon_id: String) -> String:
	match weapon_id:
		WEAPON_ID_PLUNGER, WEAPON_ID_BARE_HANDS:
			return weapon_id
	return WEAPON_ID_PLUNGER


func can_afford(amount: float) -> bool:
	return current_money >= amount


func try_spend_money(amount: float) -> bool:
	if current_money < amount:
		return false
	
	current_money -= amount
	return true


func set_active_combat_room(enabled: bool) -> void:
	is_active_combat_room = enabled
	is_timer_active = enabled


func get_current_level_room_count() -> int:
	match current_level_phase:
		LevelPhase.FLOOR_1:
			return 15
		LevelPhase.FLOOR_2:
			return 25
		LevelPhase.FLOOR_3:
			return 40
		LevelPhase.ENDLESS:
			return 50 + (5 * endless_depth)

	return 15


func get_current_level_start_difficulty() -> int:
	match current_level_phase:
		LevelPhase.FLOOR_1:
			return 10
		LevelPhase.FLOOR_2:
			return 50
		LevelPhase.FLOOR_3:
			return 75
		LevelPhase.ENDLESS:
			return 100 + (25 * endless_depth)

	return 10


func get_current_boss_pool_id() -> String:
	match current_level_phase:
		LevelPhase.FLOOR_1:
			return "floor_1"
		LevelPhase.FLOOR_2:
			return "floor_2"
		LevelPhase.FLOOR_3:
			return "floor_3"
		LevelPhase.ENDLESS:
			return "endless"

	return "floor_1"


func get_current_level_label() -> String:
	match current_level_phase:
		LevelPhase.FLOOR_1:
			return "Floor 1"
		LevelPhase.FLOOR_2:
			return "Floor 2"
		LevelPhase.FLOOR_3:
			return "Floor 3"
		LevelPhase.ENDLESS:
			return "Endless %d" % (endless_depth + 1)

	return "Floor 1"


func add_silver(amount: float) -> void:
	current_money += amount
	current_level_silver_gained += amount
	total_run_silver_gained += amount


func add_gold(amount: float) -> void:
	current_meta += amount
	current_level_gold_gained += amount
	total_run_gold_gained += amount


func reset_current_level_counters() -> void:
	current_level_timer = 0.0
	current_level_silver_gained = 0.0
	current_level_gold_gained = 0.0
	current_level_reward_effects = []


func advance_to_next_floor() -> void:
	match current_level_phase:
		LevelPhase.FLOOR_1:
			current_level_phase = LevelPhase.FLOOR_2
		LevelPhase.FLOOR_2:
			current_level_phase = LevelPhase.FLOOR_3
		LevelPhase.ENDLESS:
			endless_depth += 1

	reset_current_level_counters()


func enter_endless_mode() -> void:
	current_level_phase = LevelPhase.ENDLESS
	endless_depth = 0
	reset_current_level_counters()


func format_time(total_time: float) -> String:
	var hours: int = int(total_time / 3600.0)
	var minutes: int = int(total_time / 60.0) % 60
	var seconds: int = int(total_time) % 60
	return "%d:%02d:%02d" % [hours, minutes, seconds]


func reset_runtime_state() -> void:
	current_money = 0.0
	
	current_level_phase = LevelPhase.FLOOR_1
	endless_depth = 0
	reset_current_level_counters()
	
	total_run_silver_gained = 0.0
	total_run_gold_gained = 0.0
	
	is_active_combat_room = false
	is_timer_active = false
	current_run_timer = 0.0
	current_weapon_id = WEAPON_ID_PLUNGER
	
	reset_applied_reward_effects()


func queue_new_run(setup_data: Dictionary = {}) -> void:
	reset_runtime_state()
	boot_mode = BootMode.NEW_RUN
	pending_save_data = {}
	pending_setup_data = setup_data.duplicate(true)
	current_weapon_id = normalize_weapon_id(str(setup_data.get("weapon_id", WEAPON_ID_PLUNGER)))
	current_meta = SaveManager.get_current_slot_total_gold()


func queue_continue_run(save_data: Dictionary) -> void:
	reset_runtime_state()
	boot_mode = BootMode.CONTINUE_RUN
	pending_save_data = save_data.duplicate(true)
	pending_setup_data = {}

	var saved_state: Dictionary = save_data.get("state", {})
	current_weapon_id = normalize_weapon_id(str(saved_state.get("weapon_id", WEAPON_ID_PLUNGER)))


func consume_boot_payload() -> Dictionary:
	var payload := {
		"boot_mode": boot_mode,
		"save_data": pending_save_data.duplicate(true),
		"setup_data": pending_setup_data.duplicate(true),
	}

	boot_mode = BootMode.NONE
	pending_save_data = {}
	pending_setup_data = {}

	return payload


func get_current_level_bonus_summary_lines() -> Array[String]:
	var lines: Array[String] = RewardLibrary.build_effect_summary_lines(current_level_reward_effects)

	if lines.is_empty():
		lines.append("No bonuses claimed.")

	return lines


func reset_applied_reward_effects() -> void:
	applied_reward_effects = []


func record_reward_effect_snapshot(snapshot: Dictionary) -> void:
	var _snapshot: Dictionary = snapshot.duplicate(true)
	applied_reward_effects.append(_snapshot)
	current_level_reward_effects.append(_snapshot.duplicate(true))


func build_level_complete_popup_params() -> Dictionary:
	var bonus_lines: Array[String] = get_current_level_bonus_summary_lines()
	var bonus_text: String = "\n".join(bonus_lines)

	var body: String = "[center][b]%s cleared[/b]\n\nSilver gained this level: %.2f\nGold gained this level: %.2f\n\nTime this level: %s\nTime total: %s\n\nBonuses this level:\n%s[/center]" % [
		get_current_level_label(),
		current_level_silver_gained,
		current_level_gold_gained,
		format_time(current_level_timer),
		format_time(current_run_timer),
		bonus_text
	]
	
	match current_level_phase:
		LevelPhase.FLOOR_1, LevelPhase.FLOOR_2:
			return {
				"title": "Level Complete",
				"body": body,
				"primary_text": "Continue",
				"primary_action": "continue_floor",
				"secondary_text": "",
				"secondary_action": ""
			}
		
		LevelPhase.FLOOR_3:
			return {
				"title": "Congratulations",
				"body": body + "\n\n[center]You completed the run.[/center]",
				"primary_text": "Enter Endless",
				"primary_action": "enter_endless",
				"secondary_text": "Return to Main Menu",
				"secondary_action": "return_to_main_menu"
			}
		
		LevelPhase.ENDLESS:
			return {
				"title": "Endless Cleared",
				"body": body,
				"primary_text": "Continue Onward",
				"primary_action": "continue_endless",
				"secondary_text": "Return to Main Menu",
				"secondary_action": "return_to_main_menu"
			}
	
	return {
		"title": "Level Complete",
		"body": body,
		"primary_text": "Continue",
		"primary_action": "continue_floor",
		"secondary_text": "",
		"secondary_action": ""
	}


func build_game_over_popup_params() -> Dictionary:

	var body: String = "[center][b]Run Failed[/b]\n\nGold gained this run: %.2f\n\nTime this level: %s\nTime total: %s[/center]" % [
		total_run_gold_gained,
		format_time(current_level_timer),
		format_time(current_run_timer),
	]

	return {
		"title": "Game Over",
		"body": body,
		"primary_text": "Return to Main Menu"
	}
