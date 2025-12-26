class_name WaveConfig
extends Resource
## Configuration for wave-based enemy spawning

# Wave enemy set: Dictionary mapping round -> Array of enemy types with weights
# Format: {round: [{type: EnemyType, weight: float, count: int}, ...]}
static func get_wave_enemies(round: int) -> Array:
	# Returns array of enemy spawns: [{type: Enemy.EnemyType, count: int}, ...]
	var wave_enemies: Array = []
	
	# Early waves: mostly slimes
	if round <= 2:
		wave_enemies.append({"type": Enemy.EnemyType.SLIME, "count": 3 + round})
	
	# Waves 3-5: slimes and goblins
	elif round <= 5:
		wave_enemies.append({"type": Enemy.EnemyType.SLIME, "count": 2 + round})
		wave_enemies.append({"type": Enemy.EnemyType.GOBLIN, "count": round - 2})
	
	# Waves 6-8: goblins and demons
	elif round <= 8:
		wave_enemies.append({"type": Enemy.EnemyType.GOBLIN, "count": 3 + round})
		wave_enemies.append({"type": Enemy.EnemyType.DEMON, "count": round - 4})
	
	# Waves 9-12: demons, shadows, and archers
	elif round <= 12:
		wave_enemies.append({"type": Enemy.EnemyType.DEMON, "count": 2 + round})
		wave_enemies.append({"type": Enemy.EnemyType.SHADOW, "count": round - 6})
		wave_enemies.append({"type": Enemy.EnemyType.ARCHER_GOBLIN, "count": max(1, round - 8)})
	
	# Waves 13+: all enemy types
	else:
		var base_count = round - 10
		wave_enemies.append({"type": Enemy.EnemyType.SLIME, "count": max(1, base_count / 3)})
		wave_enemies.append({"type": Enemy.EnemyType.GOBLIN, "count": base_count})
		wave_enemies.append({"type": Enemy.EnemyType.DEMON, "count": base_count + 2})
		wave_enemies.append({"type": Enemy.EnemyType.SHADOW, "count": max(1, base_count / 2)})
		wave_enemies.append({"type": Enemy.EnemyType.ARCHER_GOBLIN, "count": max(1, base_count / 2)})
		wave_enemies.append({"type": Enemy.EnemyType.MAGE_DEMON, "count": max(1, (round - 12) / 2)})
	
	return wave_enemies

