class_name Weapon
extends Resource
## Weapon data for player attacks

enum WeaponType { SWORD, BOW, STAFF, CANNON }

@export var weapon_type: WeaponType = WeaponType.SWORD
@export var name: String = "Sword"
@export var damage: float = 10.0
@export var attack_range: float = 50.0
@export var attack_speed: float = 1.0  # Seconds between attacks
@export var projectile_speed: float = 0.0  # 0 = melee
@export var aoe_radius: float = 0.0  # 0 = single target
@export var color: Color = Color.WHITE
@export var price: int = 50

static func create_sword() -> Weapon:
	var w = Weapon.new()
	w.weapon_type = WeaponType.SWORD
	w.name = "Sword"
	w.damage = 12.0
	w.attack_range = 45.0
	w.attack_speed = 0.8
	w.projectile_speed = 0.0
	w.aoe_radius = 0.0
	w.color = Color("#94a3b8")
	w.price = 30
	return w

static func create_bow() -> Weapon:
	var w = Weapon.new()
	w.weapon_type = WeaponType.BOW
	w.name = "Bow"
	w.damage = 8.0
	w.attack_range = 120.0
	w.attack_speed = 1.2
	w.projectile_speed = 300.0
	w.aoe_radius = 0.0
	w.color = Color("#a3e635")
	w.price = 60
	return w

static func create_staff() -> Weapon:
	var w = Weapon.new()
	w.weapon_type = WeaponType.STAFF
	w.name = "Magic Staff"
	w.damage = 15.0
	w.attack_range = 100.0
	w.attack_speed = 1.5
	w.projectile_speed = 200.0
	w.aoe_radius = 40.0  # Area damage
	w.color = Color("#c084fc")
	w.price = 150
	return w

static func create_cannon() -> Weapon:
	var w = Weapon.new()
	w.weapon_type = WeaponType.CANNON
	w.name = "Cannon"
	w.damage = 30.0
	w.attack_range = 80.0
	w.attack_speed = 2.5
	w.projectile_speed = 150.0
	w.aoe_radius = 60.0  # Big explosion
	w.color = Color("#f97316")
	w.price = 1000
	return w

static func get_all_weapons() -> Array[Weapon]:
	return [create_sword(), create_bow(), create_staff(), create_cannon()]

