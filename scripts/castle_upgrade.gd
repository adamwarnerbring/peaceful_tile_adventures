class_name CastleUpgrade
extends Resource
## Castle upgrade definitions for map expansion and base improvements

enum UpgradeType { 
	MAP_EXPANSION_LEVEL_1,
	MAP_EXPANSION_LEVEL_2,
	MAP_EXPANSION_LEVEL_3,
	MAP_EXPANSION_LEVEL_4,
	MAP_EXPANSION_LEVEL_5,
	BASE_EXPANSION,
	STORAGE_EXPANSION,
	COLLECTION_EFFICIENCY,
	GOLD_CAPACITY
}

@export var upgrade_type: UpgradeType
@export var name: String = ""
@export var description: String = ""
@export var price: int = 1000
@export var value: float = 0.0
@export var is_one_time: bool = true  # Most castle upgrades are one-time

static func get_all_upgrades() -> Array[CastleUpgrade]:
	var upgrades: Array[CastleUpgrade] = []
	
	# Map Expansion Upgrades
	var level1 = CastleUpgrade.new()
	level1.upgrade_type = UpgradeType.MAP_EXPANSION_LEVEL_1
	level1.name = "Reveal the Valley"
	level1.description = "Unlocks Level 1 map - reveals 4x larger area"
	level1.price = 1000
	level1.value = 1.0  # Level index
	level1.is_one_time = true
	upgrades.append(level1)
	
	var level2 = CastleUpgrade.new()
	level2.upgrade_type = UpgradeType.MAP_EXPANSION_LEVEL_2
	level2.name = "Reveal the Region"
	level2.description = "Unlocks Level 2 map - reveals 16x larger area"
	level2.price = 5000
	level2.value = 2.0
	level2.is_one_time = true
	upgrades.append(level2)
	
	var level3 = CastleUpgrade.new()
	level3.upgrade_type = UpgradeType.MAP_EXPANSION_LEVEL_3
	level3.name = "Reveal the Continent"
	level3.description = "Unlocks Level 3 map - reveals 64x larger area"
	level3.price = 25000
	level3.value = 3.0
	level3.is_one_time = true
	upgrades.append(level3)
	
	var level4 = CastleUpgrade.new()
	level4.upgrade_type = UpgradeType.MAP_EXPANSION_LEVEL_4
	level4.name = "Reveal the World"
	level4.description = "Unlocks Level 4 map - reveals 256x larger area"
	level4.price = 125000
	level4.value = 4.0
	level4.is_one_time = true
	upgrades.append(level4)
	
	var level5 = CastleUpgrade.new()
	level5.upgrade_type = UpgradeType.MAP_EXPANSION_LEVEL_5
	level5.name = "Reveal the Realm"
	level5.description = "Unlocks Level 5 map - reveals 1024x larger area"
	level5.price = 625000
	level5.value = 5.0
	level5.is_one_time = true
	upgrades.append(level5)
	
	# Base Expansion
	var base_expansion = CastleUpgrade.new()
	base_expansion.upgrade_type = UpgradeType.BASE_EXPANSION
	base_expansion.name = "Base Expansion"
	base_expansion.description = "Increases base size and visual appearance"
	base_expansion.price = 500
	base_expansion.value = 1.0
	base_expansion.is_one_time = false
	upgrades.append(base_expansion)
	
	# Storage Expansion (moved from BaseUpgrade)
	var storage = CastleUpgrade.new()
	storage.upgrade_type = UpgradeType.STORAGE_EXPANSION
	storage.name = "Storage Expansion"
	storage.description = "Adds more resource slots to the base"
	storage.price = 300
	storage.value = 1.0
	storage.is_one_time = false
	upgrades.append(storage)
	
	# Collection Efficiency
	var efficiency = CastleUpgrade.new()
	efficiency.upgrade_type = UpgradeType.COLLECTION_EFFICIENCY
	efficiency.name = "Collection Efficiency"
	efficiency.description = "Improves bot performance across all levels"
	efficiency.price = 200
	efficiency.value = 0.1
	efficiency.is_one_time = false
	upgrades.append(efficiency)
	
	# Gold Storage Capacity (from BaseUpgrade)
	var gold_cap = CastleUpgrade.new()
	gold_cap.upgrade_type = UpgradeType.GOLD_CAPACITY
	gold_cap.name = "Gold Storage +"
	gold_cap.description = "Increases max gold capacity"
	gold_cap.price = 80
	gold_cap.value = 500.0  # Additional capacity
	gold_cap.is_one_time = false
	upgrades.append(gold_cap)
	
	return upgrades

static func get_map_expansion_upgrades() -> Array[CastleUpgrade]:
	var all = get_all_upgrades()
	var map_upgrades: Array[CastleUpgrade] = []
	for upgrade in all:
		if upgrade.upgrade_type >= UpgradeType.MAP_EXPANSION_LEVEL_1 and upgrade.upgrade_type <= UpgradeType.MAP_EXPANSION_LEVEL_5:
			map_upgrades.append(upgrade)
	return map_upgrades

static func get_base_upgrades() -> Array[CastleUpgrade]:
	var all = get_all_upgrades()
	var base_upgrades: Array[CastleUpgrade] = []
	for upgrade in all:
		# All non-map-expansion upgrades are base/castle upgrades
		if upgrade.upgrade_type >= UpgradeType.BASE_EXPANSION:
			base_upgrades.append(upgrade)
	return base_upgrades

