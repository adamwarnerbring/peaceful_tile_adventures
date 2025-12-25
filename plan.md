Tile game with Godot 4.4

Features:
- Tile based game
- 2D top-down view
- Base building / idle / tower defense hybrid
- Collect resources
- Exponential growth (combine 2 of the same object to get a new object, scales as 2^n)

Gameplay:
- Playable character moves around the tile grid
- Touch/click to move character to destination
- Resources spawn in different zones
- Player picks up resources and deposits at base
- Cascade merging: multiple tiers can chain-merge

Zones (Unlockable):
- Forest (green) - FREE, spawns tier 0-1, slimes
- Cave (purple) - 100 coins, spawns tier 1-2, goblins
- Crystal Mine (cyan) - 500 coins, spawns tier 2-3, demons
- Volcano (red) - 2000 coins, spawns tier 3-4, demons
- Abyss (indigo) - 8000 coins, spawns tier 4-5, shadows
- Base Area (bottom) - safe zone, deposit slots

Combat:
- Enemies spawn in unlocked zones
- Enemy types: Slime, Goblin, Demon, Shadow
- Enemies attack player and bots
- Player has health, respawns at base on death
- Bots have health, destroyed on death

Weapons (Player):
- Sword: Melee, fast, single target
- Bow: Ranged, moderate speed, single target
- Magic Staff: Ranged, AoE damage
- Cannon: Slow, high damage, large AoE

Turrets (Placeable):
- Arrow Tower: Fast, long range, single target
- Magic Tower: Medium range, small AoE
- Fire Tower: Short range, high damage, large AoE
- Lightning Tower: Very fast, very long range

Economy:
- Coins from depositing (2^tier)
- Coins from merging (2× bonus)
- Coins from killing enemies
- Buy zone unlocks, bots, weapons, turrets

Mobile:
- Portrait orientation (700x1200)
- Touch controls
- Tap-to-move, tap-to-place turrets
