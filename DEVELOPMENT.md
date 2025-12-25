# Tile Adventures - Development Documentation

## Project Overview

Tile Adventures is a 2D tile-based merge game built with Godot 4.4. It combines resource collection, base building, tower defense, and idle game mechanics in a mobile-friendly portrait orientation.

**Key Technologies:**
- Godot 4.4
- GDScript
- Node2D-based architecture
- Resource-based configuration system

---

## Project Structure

```
tile_adventures/
├── scenes/              # Godot scene files (.tscn)
│   ├── main.tscn       # Main game scene
│   ├── player.tscn     # Player character
│   ├── base.tscn       # Base structure
│   ├── tile_grid.tscn  # Grid system
│   ├── enemy.tscn      # Enemy entities
│   ├── collector_bot.tscn
│   ├── turret.tscn
│   └── resource_pickup.tscn
│
├── scripts/            # GDScript files
│   ├── main.gd         # Main game controller (orchestrates everything)
│   ├── player.gd       # Player movement, combat, inventory
│   ├── base.gd         # Base logic, merging, health
│   ├── tile_grid.gd    # Grid management, zones, spawning
│   ├── enemy.gd        # Enemy AI, combat
│   ├── collector_bot.gd # Bot AI for resource collection
│   ├── turret.gd       # Turret combat logic
│   ├── resource_pickup.gd
│   │
│   └── Resources/      # Resource classes (data definitions)
│       ├── game_item.gd      # Item tier definitions
│       ├── weapon.gd         # Weapon configurations
│       ├── upgrade.gd        # Player upgrade definitions
│       ├── base_upgrade.gd   # Base upgrade definitions
│       └── enemy_config.gd  # Enemy type configurations
│
├── plan.md             # Game design document
└── project.godot       # Godot project settings
```

---

## Core Architecture

### Main Controller Pattern

**`main.gd`** is the central orchestrator that:
- Manages game state (coins, timers, counts)
- Handles input (touch/mouse)
- Coordinates between systems (player, base, grid, enemies)
- Manages UI updates
- Controls spawning (resources, enemies)
- Handles shop and economy

**Key Pattern:** Most game logic flows through `main.gd`, which delegates to specialized scripts.

### Resource-Based Configuration

Game data is defined using Godot's `Resource` class:

- **`EnemyConfig`**: Enemy stats (health, damage, armor, priorities)
- **`Weapon`**: Weapon properties (damage, range, attack speed)
- **`Upgrade`**: Player upgrade definitions
- **`BaseUpgrade`**: Base upgrade definitions
- **`GameItem`**: Item tier colors and values

**Benefits:**
- Easy to modify game balance without code changes
- Centralized data definitions
- Can be edited in Godot editor

### Scene Hierarchy

```
Main (Node2D)
├── TileGrid (Node2D)
├── Base (Node2D)
├── Player (Node2D)
├── Bots (Node2D) - container for bot instances
├── Enemies (Node2D) - container for enemy instances
├── Turrets (Node2D) - container for turret instances
└── UI (CanvasLayer)
    ├── CoinLabel
    ├── HealthLabel
    ├── BaseHealthLabel
    ├── ShopPanel
    └── StatsPanel
```

---

## Key Systems

### 1. Grid System (`tile_grid.gd`)

**Purpose:** Manages the game world grid, zones, and resource/enemy spawning.

**Key Features:**
- 20x32 cell grid (640x1024 pixels)
- Zone system (Forest, Cave, Crystal, Volcano, Abyss)
- Curved biome boundaries around base
- Resource spawning per zone
- Turret placement tracking
- Zone unlocking system

**Important Constants:**
```gdscript
GRID_SIZE = Vector2i(20, 32)
CELL_SIZE = 32
BASE_CENTER_X = 10
BASE_CENTER_Y = 28
BASE_RADIUS = 4.5
```

**Key Functions:**
- `grid_to_world(cell: Vector2i) -> Vector2` - Convert grid to world position
- `world_to_grid(world: Vector2) -> Vector2i` - Convert world to grid position
- `spawn_resource_in_zone(zone: Zone)` - Spawn resource in specific zone
- `unlock_zone(zone: Zone)` - Unlock a new zone
- `is_zone_unlocked(zone: Zone) -> bool` - Check zone status

### 2. Merge System (`base.gd`)

**Purpose:** Handles resource deposit, storage, and exponential merging.

**How It Works:**
- Resources deposited into tier-specific slots (0-11)
- Each tier has merge requirements (2, 3, 4, or 5 items)
- When requirement met, merges into next tier
- Cascade merging: multiple tiers can merge in sequence

**Key Variables:**
- `slot_contents: Array[int]` - Count of items per slot
- `merge_requirements: Array[int]` - Required count per tier

**Visual Progress:**
- Rectangular progress indicators show collection progress
- Different fill patterns for 2, 3, 4, 5+ item requirements

### 3. Combat System

**Player Combat** (`player.gd`):
- Auto-attacks nearest enemy in weapon range
- Health system with regeneration
- Armor reduces damage
- Respawns at base on death

**Enemy Combat** (`enemy.gd`):
- Priority-based targeting (Player > Bot > Turret > Base)
- Distance-based retargeting
- Wanders toward base if no target
- Configurable via `EnemyConfig` resource

**Turret Combat** (`turret.gd`):
- Auto-attacks nearest enemy in range
- Different types: Arrow, Magic, Fire, Lightning
- Has health (can be destroyed)

**Base Combat** (`base.gd`):
- Can be attacked by enemies
- Has health, armor, regeneration
- Game over if health reaches 0
- Optional base weapon (auto-attack upgrade)

### 4. Economy System (`main.gd`)

**Currency:** Coins
- Earned from: resource deposits, merges, enemy kills
- Spent on: zone unlocks, bots, weapons, turrets, upgrades
- Gold capacity: Max coins limit (upgradeable)

**Shop System:**
- Tab-based UI (Zones, Bots, Weapons, Turrets, Upgrades, Base Upgrades)
- All tabs visible, click to switch content
- Auto-refreshes when coins change
- Tooltips show purchase requirements

**Pricing:**
- Dynamic bot prices (increase with each purchase)
- Zone unlock prices (fixed)
- Upgrade prices (exponential scaling)

### 5. Spawning System

**Resource Spawning:**
- Timer-based (every 2.5 seconds)
- Spawns in unlocked zones
- Respects max resources per zone (8)
- Zone determines tier range

**Enemy Spawning:**
- Timer-based (every 4.0 seconds)
- Spawns in unlocked zones
- Minimum distance from player (200px)
- Can spawn off-screen
- Zone determines enemy type

### 6. Bot System (`collector_bot.gd`)

**Purpose:** Automated resource collection

**Behavior:**
- Assigned to specific zone
- Finds resources in zone
- Collects and returns to base
- Deposits automatically
- Has health (can be destroyed by enemies)
- Spawns in front of base

---

## Adding New Features

### Adding a New Zone

1. **Update `tile_grid.gd`:**
   - Add to `Zone` enum
   - Add to `zone_tiers` dictionary
   - Add to `zone_prices` dictionary
   - Update `_setup_zones()` to define boundaries
   - Add to `zone_unlock_order` in `main.gd`

2. **Update `enemy_config.gd`:**
   - Add enemy type for zone (if needed)
   - Update `get_type_for_zone()` function

3. **Update `main.gd`:**
   - Add bot price for zone in `bot_prices`
   - Initialize bot count in `_ready()`

### Adding a New Enemy Type

1. **Update `enemy_config.gd`:**
   - Add to `EnemyType` enum
   - Add config in `get_all_configs()`
   - Set stats (health, damage, armor, etc.)
   - Define attack priorities

2. **Update `enemy.gd`:**
   - Add drawing function `_draw_[type]()`
   - Add case in `_draw()` match statement

3. **Update `tile_grid.gd`:**
   - Update `get_type_for_zone()` if needed

### Adding a New Weapon

1. **Update `weapon.gd`:**
   - Add to `WeaponType` enum
   - Add creation function (e.g., `create_[weapon]()`)
   - Add to `get_all_weapons()` array
   - Set stats (damage, range, cooldown, price)

2. **Update `main.gd`:**
   - Weapon shop automatically picks up new weapons
   - No additional code needed (uses reflection)

### Adding a New Turret Type

1. **Update `turret.gd`:**
   - Add to `TurretType` enum
   - Add stats in `get_stats()` function
   - Add price in `get_price()` function
   - Add name in `get_turret_name()` function

2. **Update `main.gd`:**
   - Add to turret shop population
   - Add to turret counts dictionary

### Adding a New Upgrade

**Player Upgrade:**
1. Update `upgrade.gd`:
   - Add to `UpgradeType` enum
   - Add upgrade definition in `get_all_upgrades()`

2. Update `main.gd`:
   - Add upgrade level tracking
   - Add upgrade application in `_on_buy_upgrade()`

**Base Upgrade:**
1. Update `base_upgrade.gd`:
   - Add to `UpgradeType` enum
   - Add upgrade definition in `get_all_upgrades()`

2. Update `main.gd`:
   - Add upgrade application in `_on_buy_base_upgrade()`
   - Handle new upgrade type in match statement

---

## Common Tasks

### Modifying Game Balance

**Enemy Stats:**
- Edit `enemy_config.gd` → `get_all_configs()`
- Modify health, damage, armor, speed, etc.

**Weapon Stats:**
- Edit `weapon.gd` → individual weapon creation functions
- Modify damage, range, attack_cooldown, price

**Economy:**
- Bot prices: `main.gd` → `bot_prices` dictionary
- Zone prices: `tile_grid.gd` → `zone_prices` dictionary
- Upgrade prices: `upgrade.gd` / `base_upgrade.gd` → `price` and `price_multiplier`

**Spawn Rates:**
- Resource spawn: `main.gd` → `SPAWN_INTERVAL` constant
- Enemy spawn: `main.gd` → `ENEMY_SPAWN_INTERVAL` constant

### Changing Grid Size

1. Update `tile_grid.gd`:
   - Modify `GRID_SIZE` constant
   - Adjust `BASE_CENTER_X`, `BASE_CENTER_Y` if needed

2. Update `main.gd`:
   - Grid positioning will auto-adjust
   - May need to adjust `BASE_RADIUS` in `tile_grid.gd`

### Modifying UI

**Shop:**
- Tab buttons: `main.gd` → `_create_tabs()`
- Tab content: `main.gd` → `_populate_*_tab()` functions
- Tooltips: `main.gd` → `_get_*_tooltip()` functions

**Labels:**
- Top UI: `main.gd` → `_update_ui()`
- Stats panel: `main.gd` → `_populate_stats_tab()`

**Scene Structure:**
- Edit `scenes/main.tscn` in Godot editor
- UI nodes are under `UI` CanvasLayer

### Debugging Tips

**Check Game State:**
- Coins: `main.gd` → `coins` variable
- Player health: `player.health` / `player.max_health`
- Base health: `base.health` / `base.max_health`
- Zone status: `tile_grid.unlocked_zones`

**Common Issues:**
- **Enemies not spawning:** Check zone unlock status
- **Resources not merging:** Check `merge_requirements` in `base.gd`
- **Shop not updating:** Check `_check_shop_refresh()` in `main.gd`
- **UI not showing:** Check node paths in `@onready` variables

---

## Code Patterns

### Signal Usage

**Common Signals:**
- `base.health_changed` → Updates UI
- `base.resources_merged` → Awards coins
- `player.died` → Handles respawn
- `enemy.died` → Awards coins, removes from scene
- `tile_grid.zone_unlocked` → Refreshes shop

**Pattern:**
```gdscript
# In source script
signal my_signal(value: int)

# Emit signal
my_signal.emit(42)

# In main.gd
source.my_signal.connect(_on_my_signal)

func _on_my_signal(value: int) -> void:
    # Handle signal
```

### Resource Creation Pattern

```gdscript
# In resource script
static func create_my_resource() -> MyResource:
    var resource = MyResource.new()
    resource.property = value
    return resource

# Usage
var my_resource = MyResource.create_my_resource()
```

### Spawning Pattern

```gdscript
# 1. Load scene
var scene = preload("res://scenes/my_entity.tscn")

# 2. Instantiate
var instance = scene.instantiate()

# 3. Configure
instance.property = value

# 4. Position
instance.position = world_position

# 5. Connect signals
instance.signal_name.connect(_on_signal)

# 6. Add to scene tree
container.add_child(instance)
```

---

## File Responsibilities

| File | Primary Responsibility |
|------|----------------------|
| `main.gd` | Game orchestration, input, economy, spawning |
| `player.gd` | Player movement, combat, inventory |
| `base.gd` | Base logic, merging, health |
| `tile_grid.gd` | Grid management, zones, spawning locations |
| `enemy.gd` | Enemy AI, combat, targeting |
| `collector_bot.gd` | Bot AI, resource collection |
| `turret.gd` | Turret combat logic |
| `enemy_config.gd` | Enemy type definitions |
| `weapon.gd` | Weapon definitions |
| `upgrade.gd` | Player upgrade definitions |
| `base_upgrade.gd` | Base upgrade definitions |
| `game_item.gd` | Item tier definitions |

---

## Best Practices

1. **Keep `main.gd` focused:** It's already large - delegate to other scripts when possible

2. **Use Resources for data:** Don't hardcode stats - use Resource classes

3. **Signal-based communication:** Use signals for cross-system communication

4. **Grid coordinates:** Always use `grid_to_world()` / `world_to_grid()` for conversions

5. **Zone checks:** Always check `is_zone_unlocked()` before zone-specific operations

6. **Health updates:** Always emit `health_changed` signal when health changes

7. **UI updates:** Use `_update_ui()` for consistent UI refresh

8. **Shop refresh:** Call `_refresh_shop()` after purchases to update buttons

---

## Testing Checklist

When adding new features, test:
- [ ] Works on mobile (touch controls)
- [ ] Shop updates correctly
- [ ] Coins are awarded/spent correctly
- [ ] Health bars update
- [ ] Enemies spawn correctly
- [ ] Resources merge correctly
- [ ] Zone unlocking works
- [ ] Game over condition works
- [ ] Stats menu shows correct data

---

## Future Improvements

Potential areas for expansion:
- Save/load system
- More enemy types
- More zones
- Boss enemies
- Achievements
- Daily challenges
- Prestige system
- More turret types
- Base building/expansion
- Multiplayer (co-op)

---

## Getting Help

- **Godot Documentation:** https://docs.godotengine.org/
- **GDScript Reference:** https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/
- **Project Issues:** Check git issues or create new ones

---

**Last Updated:** 2024
**Godot Version:** 4.4
**Project Status:** Active Development

