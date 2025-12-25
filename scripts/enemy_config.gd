class_name EnemyConfig
extends Resource
## Centralized enemy configuration with priorities and stats

enum AttackPriority { PLAYER, BOT, TURRET }

@export var enemy_type: Enemy.EnemyType
@export var name: String = ""
@export var max_health: float = 20.0
@export var damage: float = 5.0
@export var armor: float = 0.0
@export var move_speed: float = 60.0
@export var attack_range: float = 30.0
@export var attack_cooldown: float = 1.5
@export var coin_reward: int = 2
@export var size: float = 12.0
@export var color: Color = Color.WHITE
@export var priority_list: Array[AttackPriority] = [AttackPriority.BOT, AttackPriority.PLAYER, AttackPriority.TURRET]

static func get_all_configs() -> Dictionary:
	var configs: Dictionary = {}
	
	# Slime
	var slime = EnemyConfig.new()
	slime.enemy_type = Enemy.EnemyType.SLIME
	slime.name = "Slime"
	slime.max_health = 15.0
	slime.damage = 3.0
	slime.armor = 0.0
	slime.move_speed = 50.0
	slime.attack_range = 30.0
	slime.attack_cooldown = 1.5
	slime.coin_reward = 2
	slime.size = 12.0
	slime.color = Color("#84cc16")
	var slime_priorities: Array[AttackPriority] = [AttackPriority.BOT, AttackPriority.PLAYER, AttackPriority.TURRET]
	slime.priority_list = slime_priorities
	configs[Enemy.EnemyType.SLIME] = slime
	
	# Goblin
	var goblin = EnemyConfig.new()
	goblin.enemy_type = Enemy.EnemyType.GOBLIN
	goblin.name = "Goblin"
	goblin.max_health = 30.0
	goblin.damage = 8.0
	goblin.armor = 1.0
	goblin.move_speed = 80.0
	goblin.attack_range = 30.0
	goblin.attack_cooldown = 1.2
	goblin.coin_reward = 5
	goblin.size = 14.0
	goblin.color = Color("#f97316")
	var goblin_priorities: Array[AttackPriority] = [AttackPriority.BOT, AttackPriority.TURRET, AttackPriority.PLAYER]
	goblin.priority_list = goblin_priorities
	configs[Enemy.EnemyType.GOBLIN] = goblin
	
	# Demon
	var demon = EnemyConfig.new()
	demon.enemy_type = Enemy.EnemyType.DEMON
	demon.name = "Demon"
	demon.max_health = 60.0
	demon.damage = 15.0
	demon.armor = 3.0
	demon.move_speed = 60.0
	demon.attack_range = 35.0
	demon.attack_cooldown = 1.0
	demon.coin_reward = 15
	demon.size = 18.0
	demon.color = Color("#dc2626")
	var demon_priorities: Array[AttackPriority] = [AttackPriority.TURRET, AttackPriority.BOT, AttackPriority.PLAYER]
	demon.priority_list = demon_priorities
	configs[Enemy.EnemyType.DEMON] = demon
	
	# Shadow
	var shadow = EnemyConfig.new()
	shadow.enemy_type = Enemy.EnemyType.SHADOW
	shadow.name = "Shadow"
	shadow.max_health = 100.0
	shadow.damage = 25.0
	shadow.armor = 5.0
	shadow.move_speed = 100.0
	shadow.attack_range = 40.0
	shadow.attack_cooldown = 0.8
	shadow.coin_reward = 40
	shadow.size = 16.0
	shadow.color = Color("#6366f1")
	var shadow_priorities: Array[AttackPriority] = [AttackPriority.TURRET, AttackPriority.PLAYER, AttackPriority.BOT]
	shadow.priority_list = shadow_priorities
	configs[Enemy.EnemyType.SHADOW] = shadow
	
	return configs
