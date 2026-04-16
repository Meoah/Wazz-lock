extends Node

enum BootMode {
	NONE,
	NEW_RUN,
	CONTINUE_RUN
}
const WEAPON_ID_PLUNGER: String = "plunger"
const WEAPON_ID_BARE_HANDS: String = "bare_hands"
const PLAYER_BONUS_DEFAULTS: Dictionary = {
	"max_health": 0.0,
	"max_mana": 0.0,
	"damage": 0.0,
	"defense": 0.0,
	"knockback": 0.0,
	"poise": 0.0,
	"health_regen": 0.0,
	"mana_regen": 0.0,
	"move_speed": 0.0,
}
enum LevelPhase {
	FLOOR_1,
	FLOOR_2,
	FLOOR_3,
	ENDLESS
}

var player_stat_bonuses: Dictionary = PLAYER_BONUS_DEFAULTS.duplicate(true)

var current_weapon_id: String = WEAPON_ID_PLUNGER
var boot_mode: BootMode = BootMode.NONE
var pending_save_data: Dictionary = {}
var pending_setup_data: Dictionary = {}

# Public Variables
var current_money: float = 0.0
var current_meta: float = 0.0
var is_boss_active: bool = false
var boss_node: BaseEnemy
var is_timer_active: bool = true
var current_run_timer: float = 0.0

var current_level_phase: LevelPhase = LevelPhase.FLOOR_1
var endless_depth: int = 0

var current_level_timer: float = 0.0
var current_level_silver_gained: int = 0
var current_level_gold_gained: int = 0

var total_run_silver_gained: int = 0
var total_run_gold_gained: int = 0

func _process(delta: float) -> void:
	if is_timer_active:
		current_run_timer += delta
		current_level_timer += delta


func normalize_weapon_id(weapon_id: String) -> String:
	match weapon_id:
		WEAPON_ID_PLUNGER, WEAPON_ID_BARE_HANDS:
			return weapon_id
	return WEAPON_ID_PLUNGER


func reset_player_stat_bonuses() -> void:
	player_stat_bonuses = PLAYER_BONUS_DEFAULTS.duplicate(true)


func add_player_stat_bonus(stat_id: String, amount: float) -> void:
	player_stat_bonuses[stat_id] = float(player_stat_bonuses.get(stat_id, 0.0)) + amount


func can_afford(amount: float) -> bool:
	return current_money >= amount


func try_spend_money(amount: float) -> bool:
	if current_money < amount:
		return false
	
	current_money -= amount
	return true


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


func add_silver(amount: int) -> void:
	current_money += amount
	current_level_silver_gained += amount
	total_run_silver_gained += amount


func add_gold(amount: int) -> void:
	current_meta += amount
	current_level_gold_gained += amount
	total_run_gold_gained += amount


func reset_current_level_counters() -> void:
	current_level_timer = 0.0
	current_level_silver_gained = 0
	current_level_gold_gained = 0


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
	
	total_run_silver_gained = 0
	total_run_gold_gained = 0
	
	is_timer_active = true
	current_run_timer = 0.0
	current_weapon_id = WEAPON_ID_PLUNGER
	
	reset_player_stat_bonuses()


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


func get_run_bonus_summary_lines() -> Array[String]:
	var lines: Array[String] = []
	
	for stat_id in player_stat_bonuses.keys():
		var amount: float = float(player_stat_bonuses[stat_id])
		if is_zero_approx(amount):
			continue
		
		lines.append("%s: %+0.2f" % [stat_id, amount])
	
	if lines.is_empty():
		lines.append("No bonuses claimed.")
	
	return lines


func build_level_complete_popup_params() -> Dictionary:
	var bonus_lines: Array[String] = get_run_bonus_summary_lines()
	var bonus_text: String = "\n".join(bonus_lines)

	var body: String = "[center][b]%s cleared[/b]\n\nSilver gained this level: %d\nGold gained this level: %d\n\nTime this level: %s\nTime total: %s\n\nBonuses this run:\n%s[/center]" % [
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
	var bonus_lines: Array[String] = get_run_bonus_summary_lines()
	var bonus_text: String = "\n".join(bonus_lines)

	var body: String = "[center][b]Run Failed[/b]\n\nSilver gained this level: %d\nGold gained this run: %d\n\nTime this level: %s\nTime total: %s\n\nBonuses this run:\n%s[/center]" % [
		current_level_silver_gained,
		total_run_gold_gained,
		format_time(current_level_timer),
		format_time(current_run_timer),
		bonus_text
	]

	return {
		"title": "Game Over",
		"body": body,
		"primary_text": "Return to Main Menu"
	}
