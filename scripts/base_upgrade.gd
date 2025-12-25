class_name BaseUpgrade
extends Resource
## Base upgrade definitions

enum UpgradeType { MAX_HEALTH, HEALTH_REGEN, ARMOR, REPAIR, GOLD_CAPACITY, BASE_WEAPON }

@export var upgrade_type: UpgradeType
@export var name: String = ""
@export var description: String = ""
@export var price: int = 100
@export var value: float = 0.0
@export var max_level: int = 10
@export var price_multiplier: float = 1.5
@export var is_one_time: bool = false  # For repairs and one-time purchases

static func get_all_upgrades() -> Array[BaseUpgrade]:
	var upgrades: Array[BaseUpgrade] = []
	
	# Max Health
	var max_hp = BaseUpgrade.new()
	max_hp.upgrade_type = UpgradeType.MAX_HEALTH
	max_hp.name = "Base Health +"
	max_hp.description = "Increases base maximum health"
	max_hp.price = 150
	max_hp.value = 100.0
	max_hp.max_level = 15
	upgrades.append(max_hp)
	
	# Health Regen
	var regen = BaseUpgrade.new()
	regen.upgrade_type = UpgradeType.HEALTH_REGEN
	regen.name = "Base Regen"
	regen.description = "Base regenerates health over time"
	regen.price = 200
	regen.value = 1.0  # HP per second
	regen.max_level = 10
	upgrades.append(regen)
	
	# Armor
	var armor = BaseUpgrade.new()
	armor.upgrade_type = UpgradeType.ARMOR
	armor.name = "Base Armor +"
	armor.description = "Reduces damage to base"
	armor.price = 120
	armor.value = 2.0
	armor.max_level = 12
	upgrades.append(armor)
	
	# Repair (one-time)
	var repair = BaseUpgrade.new()
	repair.upgrade_type = UpgradeType.REPAIR
	repair.name = "Repair Base"
	repair.description = "Instantly repair 200 HP"
	repair.price = 100
	repair.value = 200.0
	repair.max_level = 999  # Unlimited uses
	repair.is_one_time = true
	upgrades.append(repair)
	
	# Gold Storage Capacity
	var gold_cap = BaseUpgrade.new()
	gold_cap.upgrade_type = UpgradeType.GOLD_CAPACITY
	gold_cap.name = "Gold Storage +"
	gold_cap.description = "Increases max gold capacity"
	gold_cap.price = 80
	gold_cap.value = 500.0  # Additional capacity
	gold_cap.max_level = 20
	upgrades.append(gold_cap)
	
	# Base Weapon (auto-attack)
	var base_weapon = BaseUpgrade.new()
	base_weapon.upgrade_type = UpgradeType.BASE_WEAPON
	base_weapon.name = "Base Turret"
	base_weapon.description = "Base auto-attacks nearby enemies"
	base_weapon.price = 300
	base_weapon.value = 1.0  # Damage per shot
	base_weapon.max_level = 5
	upgrades.append(base_weapon)
	
	return upgrades
