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

func _process(delta: float) -> void:
	if is_timer_active: current_run_timer += delta


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


func reset_runtime_state() -> void:
	current_money = 0.0
	current_meta = 0.0
	is_boss_active = false
	boss_node = null
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
