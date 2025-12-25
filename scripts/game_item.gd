class_name GameItem
extends Resource
## Represents an item type with merge tier progression

@export var id: String = ""
@export var display_name: String = ""
@export var tier: int = 0
@export var color: Color = Color.WHITE
@export var value: int = 1  # Resource value = 2^tier

static func create(item_id: String, name: String, item_tier: int, item_color: Color) -> GameItem:
	var item = GameItem.new()
	item.id = item_id
	item.display_name = name
	item.tier = item_tier
	item.color = item_color
	item.value = int(pow(2, item_tier))
	return item
