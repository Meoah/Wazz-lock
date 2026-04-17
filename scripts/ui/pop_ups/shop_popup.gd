extends BasePopup
class_name ShopPopup

const COST_COLOR_DEFAULT: String = "#FFFFFF"
const COST_COLOR_CANNOT_AFFORD: String = "#D05050"
const COST_COLOR_PURCHASED: String = "#65C96B"

@export var _label_title: Label
@export var _card_a: RewardCard
@export var _card_b: RewardCard
@export var _card_c: RewardCard
@export var _cost_a: RichTextLabel
@export var _cost_b: RichTextLabel
@export var _cost_c: RichTextLabel
@export var _button_back: Button

var _shop_state: Dictionary = {}
var _offers: Array = []


func _on_init() -> void:
	type = POPUP_TYPE.SHOP
	flags = POPUP_FLAG.WILL_PAUSE


func _on_set_params() -> void:
	_shop_state = params.get("shop_state", {})
	_offers = _shop_state.get("offers", [])

	if is_node_ready():
		_refresh_ui()


func _on_ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_card_a.selected.connect(_on_card_selected.bind(_card_a, 0))
	_card_b.selected.connect(_on_card_selected.bind(_card_b, 1))
	_card_c.selected.connect(_on_card_selected.bind(_card_c, 2))
	_button_back.pressed.connect(_on_pressed_back)

	_refresh_ui()


func _refresh_ui() -> void:
	_label_title.text = "Shop"

	_refresh_offer_slot(0, _card_a, _cost_a)
	_refresh_offer_slot(1, _card_b, _cost_b)
	_refresh_offer_slot(2, _card_c, _cost_c)


func _refresh_offer_slot(index: int, card_control: RewardCard, cost_label: RichTextLabel) -> void:
	if index >= _offers.size():
		card_control.set_card(null)
		cost_label.text = ""
		return

	var offer: Dictionary = _offers[index]
	var card: RewardCardData = RewardLibrary.find_card_by_id(str(offer.get("card_id", "")))
	var cost: float = float(offer.get("cost", 0.0))
	var purchased: bool = bool(offer.get("purchased", false))

	card_control.set_card(card)

	if !card:
		cost_label.text = ""
		return

	if purchased:
		cost_label.text = "[color=%s]Purchased[/color]" % COST_COLOR_PURCHASED
		card_control.modulate = Color(0.6, 0.6, 0.6, 1.0)
		return

	if RunManager.can_afford(cost):
		cost_label.text = "[color=%s]%.2f Silver[/color]" % [COST_COLOR_DEFAULT, cost]
		card_control.modulate = Color.WHITE
		return

	cost_label.text = "[color=%s]%.2f Silver[/color]" % [COST_COLOR_CANNOT_AFFORD, cost]
	card_control.modulate = Color(0.75, 0.75, 0.75, 1.0)


func _on_card_selected(_card: RewardCardData, card_control: RewardCard, index: int) -> void:
	if index < 0 or index >= _offers.size():
		return

	var offer: Dictionary = _offers[index]
	if bool(offer.get("purchased", false)):
		return

	var cost: float = float(offer.get("cost", 0.0))
	if !RunManager.try_spend_money(cost):
		return

	var card: RewardCardData = RewardLibrary.find_card_by_id(str(offer.get("card_id", "")))
	if !card:
		return

	var player: Clive = get_tree().get_first_node_in_group("player") as Clive
	if player:
		RewardLibrary.apply_card_to_player(card, player, true)

	var room: Room = get_tree().get_first_node_in_group("current_room") as Room
	if room:
		room.mark_shop_offer_purchased(index)

	_offers[index]["purchased"] = true
	_refresh_ui()


func _on_pressed_back() -> void:
	GameManager.popup_queue.dismiss_popup()
