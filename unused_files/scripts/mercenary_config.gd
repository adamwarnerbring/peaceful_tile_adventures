class_name MercenaryConfig
extends Resource
## Mercenary type configurations

enum MercenaryType { WARRIOR, ARCHER, MAGE, KNIGHT }

@export var mercenary_type: MercenaryType
@export var name: String = ""
@export var max_health: float = 50.0
@export var damage: float = 10.0
@export var move_speed: float = 100.0
@export var attack_range: float = 40.0
@export var attack_cooldown: float = 1.0
@export var price: int = 150
@export var color: Color = Color.WHITE
@export var size: float = 16.0

static func get_all_configs() -> Dictionary:
	var configs: Dictionary = {}
	
	# Warrior - Balanced melee
	var warrior = MercenaryConfig.new()
	warrior.mercenary_type = MercenaryType.WARRIOR
	warrior.name = "Warrior"
	warrior.max_health = 60.0
	warrior.damage = 12.0
	warrior.move_speed = 90.0
	warrior.attack_range = 35.0
	warrior.attack_cooldown = 1.0
	warrior.price = 150
	warrior.color = Color("#3b82f6")
	warrior.size = 16.0
	configs[MercenaryType.WARRIOR] = warrior
	
	# Archer - Ranged
	var archer = MercenaryConfig.new()
	archer.mercenary_type = MercenaryType.ARCHER
	archer.name = "Archer"
	archer.max_health = 40.0
	archer.damage = 10.0
	archer.move_speed = 110.0
	archer.attack_range = 120.0
	archer.attack_cooldown = 1.2
	archer.price = 200
	archer.color = Color("#22c55e")
	archer.size = 15.0
	configs[MercenaryType.ARCHER] = archer
	
	# Mage - Magic damage
	var mage = MercenaryConfig.new()
	mage.mercenary_type = MercenaryType.MAGE
	mage.name = "Mage"
	mage.max_health = 35.0
	mage.damage = 15.0
	mage.move_speed = 80.0
	mage.attack_range = 100.0
	mage.attack_cooldown = 1.5
	mage.price = 250
	mage.color = Color("#a855f7")
	mage.size = 14.0
	configs[MercenaryType.MAGE] = mage
	
	# Knight - Tank
	var knight = MercenaryConfig.new()
	knight.mercenary_type = MercenaryType.KNIGHT
	knight.name = "Knight"
	knight.max_health = 100.0
	knight.damage = 8.0
	knight.move_speed = 70.0
	knight.attack_range = 30.0
	knight.attack_cooldown = 1.2
	knight.price = 300
	knight.color = Color("#fbbf24")
	knight.size = 18.0
	configs[MercenaryType.KNIGHT] = knight
	
	return configs

