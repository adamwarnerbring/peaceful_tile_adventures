class_name Upgrade
extends Resource
## Player upgrade definitions

enum UpgradeType { MAX_HEALTH, HEALTH_REGEN, ARMOR, MOVE_SPEED, DAMAGE_BOOST }

@export var upgrade_type: UpgradeType
@export var name: String = ""
@export var description: String = ""
@export var price: int = 50
@export var value: float = 0.0  # Amount to increase
@export var max_level: int = 10
@export var price_multiplier: float = 1.5  # Price increases by this each level

static func get_all_upgrades() -> Array[Upgrade]:
	var upgrades: Array[Upgrade] = []
	
	# Max Health
	var max_hp = Upgrade.new()
	max_hp.upgrade_type = UpgradeType.MAX_HEALTH
	max_hp.name = "Max Health +"
	max_hp.description = "Increases maximum health"
	max_hp.price = 50
	max_hp.value = 25.0
	max_hp.max_level = 20
	upgrades.append(max_hp)
	
	# Health Regen
	var regen = Upgrade.new()
	regen.upgrade_type = UpgradeType.HEALTH_REGEN
	regen.name = "Health Regen"
	regen.description = "Regenerates health over time"
	regen.price = 75
	regen.value = 0.5  # HP per second
	regen.max_level = 15
	upgrades.append(regen)
	
	# Armor
	var armor = Upgrade.new()
	armor.upgrade_type = UpgradeType.ARMOR
	armor.name = "Armor +"
	armor.description = "Reduces incoming damage"
	armor.price = 60
	armor.value = 1.0
	armor.max_level = 15
	upgrades.append(armor)
	
	# Move Speed
	var speed = Upgrade.new()
	speed.upgrade_type = UpgradeType.MOVE_SPEED
	speed.name = "Move Speed +"
	speed.description = "Increases movement speed"
	speed.price = 40
	speed.value = 10.0
	speed.max_level = 10
	upgrades.append(speed)
	
	# Damage Boost
	var damage = Upgrade.new()
	damage.upgrade_type = UpgradeType.DAMAGE_BOOST
	damage.name = "Damage +"
	damage.description = "Increases weapon damage"
	damage.price = 100
	damage.value = 2.0
	damage.max_level = 10
	upgrades.append(damage)
	
	return upgrades

