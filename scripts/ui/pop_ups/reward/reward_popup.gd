extends BasePopup
class_name RewardPopup

@export var _label_title: Label
@export var _card_a: RewardCard
@export var _card_b: RewardCard
@export var _card_c: RewardCard
@export var _button_reroll: Button
@export var _button_skip: Button

var _room_difficulty: int = 100
var _reward_pool_id: String = "standard"
var _choice_count: int = 3
var _reroll_count: int = 0
var _current_cards: Array[RewardCardData] = []

func _on_init() -> void:
	type = POPUP_TYPE.REWARD
	flags = POPUP_FLAG.WILL_PAUSE


func _on_set_params() -> void:
	_room_difficulty = int(params.get("room_difficulty", 100))
	_reward_pool_id = str(params.get("reward_pool_id", "standard"))
	_choice_count = int(params.get("choice_count", 3))

	if is_node_ready():
		_refresh_cards()


func _on_ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_label_title.text = "Choose a Reward"

	_card_a.selected.connect(_on_card_selected)
	_card_b.selected.connect(_on_card_selected)
	_card_c.selected.connect(_on_card_selected)

	_button_reroll.pressed.connect(_on_pressed_reroll)
	_button_skip.pressed.connect(_on_pressed_skip)

	_refresh_cards()


func _refresh_cards() -> void:
	_current_cards = RewardLibrary.generate_choices(_reward_pool_id, _room_difficulty, _choice_count)

	_card_a.set_card(_current_cards[0] if _current_cards.size() > 0 else null)
	_card_b.set_card(_current_cards[1] if _current_cards.size() > 1 else null)
	_card_c.set_card(_current_cards[2] if _current_cards.size() > 2 else null)

	_refresh_reroll_button()


func _refresh_reroll_button() -> void:
	var cost: int = RewardLibrary.get_reroll_cost(_reroll_count)
	_button_reroll.text = "Reroll (%d Silver)" % cost
	_button_reroll.disabled = !RunManager.can_afford(cost)


func _on_card_selected(card: RewardCardData) -> void:
	var run_root: RunRoot = get_tree().get_first_node_in_group("run_root") as RunRoot
	if run_root:
		run_root.apply_reward_card_choice(card)

	GameManager.dismiss_popup()


func _on_pressed_reroll() -> void:
	var cost: int = RewardLibrary.get_reroll_cost(_reroll_count)
	if !RunManager.try_spend_money(cost):
		return

	_reroll_count += 1
	_refresh_cards()


func _on_pressed_skip() -> void:
	var run_root: RunRoot = get_tree().get_first_node_in_group("run_root") as RunRoot
	if run_root:
		run_root.apply_reward_skip()

	GameManager.dismiss_popup()
