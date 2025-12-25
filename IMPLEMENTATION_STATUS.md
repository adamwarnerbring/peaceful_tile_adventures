# Implementation Status

## ✅ Completed Features

### 1. Gold Display Format
- **Status:** ✅ Complete
- **Location:** `scripts/main.gd` → `_update_ui()`
- **Change:** Gold now shows as "🪙 current / max" format

### 2. Turret Placement Restrictions
- **Status:** ✅ Complete
- **Location:** 
  - `scripts/main.gd` → `_try_place_turret()` - Prevents base placement
  - `scripts/tile_grid.gd` → `_draw_turret_placement_indicators()` - Visual indicators
- **Features:**
  - Red tint for base area (invalid)
  - Orange tint for occupied cells
  - Green tint for valid placement
  - Indicators show when `is_placing_turret = true`

### 3. Config File System
- **Status:** ✅ Complete
- **Location:** `scripts/game_config.gd`
- **Features:**
  - Centralized game settings
  - Player respawn time (configurable)
  - Spawn intervals
  - Map scaling settings
  - All major constants moved to config

### 4. Player Respawn Timer
- **Status:** ✅ Complete
- **Location:** `scripts/main.gd` → `_process_player_respawn()`
- **Features:**
  - Configurable respawn delay (default 5 seconds)
  - Player invisible during respawn
  - Timer-based system

### 5. Ranged Enemies
- **Status:** ✅ Complete
- **Location:** 
  - `scripts/enemy_config.gd` - Added `is_ranged`, `projectile_speed`
  - `scripts/enemy.gd` - Added `ARCHER_GOBLIN`, `MAGE_DEMON` types
- **Features:**
  - Archer Goblin (Crystal/Volcano zones)
  - Mage Demon (Volcano/Abyss zones)
  - Ranged attacks with projectiles
  - Visual differentiation

### 6. Weapon Projectiles
- **Status:** ✅ Complete
- **Location:** 
  - `scripts/projectile.gd` - New projectile system
  - `scripts/main.gd` → `_create_weapon_projectile()`
- **Features:**
  - Visual projectiles for player attacks
  - Color-coded by weapon
  - Hitscan-style targeting

### 7. Single-Target Attacks
- **Status:** ✅ Complete
- **Location:**
  - `scripts/main.gd` → `_player_attack()` - Removed AoE
  - `scripts/turret.gd` → `_attack()` - Single target only
- **Features:**
  - Weapons attack one enemy at a time
  - Turrets attack one enemy at a time
  - Projectile visuals for feedback

### 8. Enemy Drops
- **Status:** ✅ Complete
- **Location:** `scripts/main.gd` → `_spawn_enemy_drops()`
- **Features:**
  - Drop chance based on zone danger level (30-80%)
  - Drops resource pickups (tier 0-2)
  - Spawns at enemy death location

## 🚧 In Progress / Skeleton Code

### 9. Mercenaries System
- **Status:** 🚧 Skeleton Created
- **Location:** `scripts/mercenary.gd`
- **What's Done:**
  - Mercenary class with behavior types
  - Behavior enum (GUARD_BOTS, GUARD_PLAYER, HUNT_ENEMIES, PATROL_ZONE)
  - Basic structure and drawing
- **What's Needed:**
  - Shop menu integration
  - Behavior implementation
  - Spawning system
  - Integration with main game loop

### 10. Map Scaling & Castle Upgrades
- **Status:** 🚧 Skeleton Created
- **Location:** `scripts/game_config.gd` - Map scaling constants
- **What's Done:**
  - Config constants for map expansion
  - Grid size per upgrade defined
- **What's Needed:**
  - Castle upgrades shop menu (separate from base upgrades)
  - Map expansion logic
  - Grid resizing system
  - Zoom/camera adjustments
  - Infinite progression system

## 📝 Implementation Notes

### Projectile System
- Projectiles are created programmatically (no scene file needed)
- Both player and enemy projectiles use same system
- Projectiles auto-cleanup on hit or target loss

### Ranged Enemies
- Spawn in later zones (Crystal, Volcano, Abyss)
- Use projectiles instead of melee
- Longer attack range than melee enemies

### Config System
- All major game settings in `game_config.gd`
- Easy to adjust balance without code changes
- Can be extended for difficulty levels

### Turret Placement
- Visual feedback system in place
- Can be extended for other placement restrictions
- Indicators update in real-time

## 🔧 Next Steps

1. **Mercenaries:**
   - Add shop menu tab
   - Implement behavior logic
   - Add spawning system
   - Integrate with combat system

2. **Map Scaling:**
   - Create Castle Upgrades shop tab
   - Implement grid expansion
   - Add camera zoom system
   - Create progression milestones

3. **Polish:**
   - Add projectile scene files (optional, for better visuals)
   - Add sound effects for projectiles
   - Balance enemy spawn rates
   - Add more mercenary types

## 🐛 Known Issues

- Turret attack function had leftover AoE code (should be fixed)
- Projectile scene is created programmatically (could use .tscn file)
- Mercenary behaviors are stubs (need implementation)
- Map scaling not yet implemented (config ready)

## 📚 Files Modified

- `scripts/main.gd` - Main game controller updates
- `scripts/tile_grid.gd` - Turret placement indicators
- `scripts/enemy.gd` - Ranged enemy support
- `scripts/enemy_config.gd` - Ranged enemy configs
- `scripts/turret.gd` - Single-target attacks
- `scripts/player.gd` - (No changes, but uses new projectile system)
- `scripts/game_config.gd` - NEW: Config system
- `scripts/projectile.gd` - NEW: Projectile system
- `scripts/mercenary.gd` - NEW: Mercenary skeleton

