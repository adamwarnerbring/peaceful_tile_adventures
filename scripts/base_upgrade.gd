class_name BaseUpgrade
extends Resource
## Base upgrade definitions for peaceful gameplay

enum UpgradeType { GOLD_CAPACITY, COLLECTION_SPEED, STORAGE_EXPANSION }

@export var upgrade_type: UpgradeType
@export var name: String = ""
@export var description: String = ""
@export var price: int = 100
@export var value: float = 0.0
@export var max_level: int = 10
@export var price_multiplier: float = 1.5
@export var is_one_time: bool = false

static func get_all_upgrades() -> Array[BaseUpgrade]:
	var upgrades: Array[BaseUpgrade] = []
	
	# Gold Storage Capacity
	var gold_cap = BaseUpgrade.new()
	gold_cap.upgrade_type = UpgradeType.GOLD_CAPACITY
	gold_cap.name = "Gold Storage +"
	gold_cap.description = "Increases max gold capacity"
	gold_cap.price = 80
	gold_cap.value = 500.0  # Additional capacity
	gold_cap.max_level = 20
	upgrades.append(gold_cap)
	
	# Collection Speed
	var collection_speed = BaseUpgrade.new()
	collection_speed.upgrade_type = UpgradeType.COLLECTION_SPEED
	collection_speed.name = "Collection Speed +"
	collection_speed.description = "Increases bot collection speed"
	collection_speed.price = 150
	collection_speed.value = 0.1  # Speed multiplier increase
	collection_speed.max_level = 10
	upgrades.append(collection_speed)
	
	# Storage Expansion (future: could expand base slots)
	var storage = BaseUpgrade.new()
	storage.upgrade_type = UpgradeType.STORAGE_EXPANSION
	storage.name = "Storage Expansion"
	storage.description = "Expands base storage capacity"
	storage.price = 300
	storage.value = 1.0
	storage.max_level = 5
	upgrades.append(storage)
	
	return upgrades
