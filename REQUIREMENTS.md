# Peaceful Tile Adventure - Requirements

## Core Gameplay
- Purely peaceful game - no combat, enemies, weapons, towers, or mercenaries
- Focus on collecting items, upgrading the base, and gaining access to new areas
- Resource collection and merging system
- Base upgrades that improve collection efficiency and storage

## Stage-Based Progression System

### Overview
The game uses a **stage-based progression** system where players progress through increasingly difficult stages. Each stage is a complete reset with a new base, revealing more of the map. Players can only advance to the next stage after achieving the most rare item (highest tier resource) of the current stage.

### Stage Progression
Stages progress in the following order:
1. **Area** (Stage 0) - Starting stage
2. **River** (Stage 1)
3. **Valley** (Stage 2)
4. **Region** (Stage 3)
5. **Country** (Stage 4)
6. **Continent** (Stage 5)
7. **World** (Stage 6)
8. **Space** (Stage 7) - Final stage

### Stage Requirements
- **Upgrade Condition**: Player must obtain the **highest tier resource** (most rare item) of the current stage before upgrading
- **Maximum Tier Per Stage**: Configurable per stage (e.g., Area: tier 11, River: tier 11, but harder to achieve)
- **Difficulty Scaling**: Each stage gets progressively harder (customizable via config)
  - Higher merge requirements
  - Higher resource costs
  - Slower spawn rates (optional)
  - Larger map sizes (optional)

### World Reset System
When upgrading to the next stage:
- **Complete Reset**: All items, resources, bots, and coins are reset to zero
- **Map Changes**: New map is generated (completely fresh world)
- **Base Reset**: Base returns to starting state (all slots empty, starting configuration unique to each stage)
- **Zone Reset**: All zones lock except BASE and FOREST (starting zones)
- **No Zoom**: Map does not zoom out - it's a fresh world at the same scale
- **New Base**: Player gets a new base in the new world
- **Progress Tracking**: Stage number is tracked and persisted

### Base Positioning
- The base should ALWAYS be centered on the screen
- Base position is fixed at the center of the map
- No scaling/zooming needed since each stage is a fresh reset

## Map and World System

### Map Generation
- Each stage generates a completely new map
- Map size can increase per stage (configurable)
- Zone layout is regenerated for each stage
- Starting zones (BASE and FOREST) are always unlocked

### Zone Unlocking
- Zones must be unlocked sequentially within each stage
- Zone prices scale with stage difficulty
- All zones reset when progressing to next stage

## Shop System
- **Zones Tab**: Shows zones for current stage that can be unlocked
  - Zones must be unlocked in order
  - Prices scale with stage difficulty
  
- **Bots Tab**: Purchase collector bots for unlocked zones
  - Bot prices scale with stage difficulty

- **Stage Upgrade Tab**: 
  - Shows "Upgrade to [Next Stage Name]" button
  - Only enabled when player has achieved the highest tier resource
  - Requires the highest tier resource to be present in base (tracked)
  - Shows current progress toward upgrade requirement

## Technical Requirements
- Stage progression tracking (current stage, highest tier achieved)
- Save/load system for stage progression
- Complete world reset functionality
- Configurable stage settings (difficulty, map size, tier requirements)
- Stage-specific resource spawning and merging rules

## Progression Flow
1. Start in Stage 0 (Area) with initial zones (BASE, FOREST unlocked)
2. Collect resources, unlock zones, merge items
3. Progress through tiers 0 → 11
4. Once tier 11 (highest tier) is achieved, "Upgrade Stage" button becomes available
5. Player chooses to upgrade (optional - can stay in current stage)
6. Complete reset: new map, new base, all progress reset
7. Begin Stage 1 (River) with increased difficulty
8. Repeat process for each stage

## Key Principles
- **Reset on Upgrade**: Complete fresh start when upgrading stages
- **Achievement Gated**: Must achieve highest tier before upgrading
- **Difficulty Scaling**: Each stage is progressively harder (configurable)
- **No Preservation**: Old items/world don't carry over (clean slate)
- **Simple Progression**: Clear goal: reach highest tier → upgrade → repeat

