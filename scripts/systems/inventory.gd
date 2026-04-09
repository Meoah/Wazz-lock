extends Node
class_name InventoryComponent

# TODO Item Database
const HEALTH_POTION: String = "Health Potion"

var current_inventory: Dictionary = {
	HEALTH_POTION : 3
}

func request_use_item(item: String, quantity: int = 1) -> bool:
	if !current_inventory.has(item): return false
	
	var item_count: int = current_inventory.get(item, 0)
	if item_count < quantity: return false
	
	item_count -= quantity
	current_inventory.set(item, item_count)
	
	return true
