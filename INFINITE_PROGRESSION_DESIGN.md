# Stage-Based Progression System - Design Document

## Overview
Transform the game into a stage-based progression system where players progress through increasingly difficult stages. Each stage is a complete reset with a new base and fresh world. Players can only advance to the next stage after achieving the most rare item (highest tier resource) of the current stage.

## Core Concept: Stage Progression with Complete Reset

### The Vision
- **Stage 0 (Area)**: Starting stage - small map, basic resources
- **Stage 1 (River)**: New world, slightly larger map, increased difficulty
- **Stage 2 (Valley)**: Larger map, higher difficulty
- **Stage 3 (Region)**: Even larger map, more challenging
- **Stage 4 (Country)**: Significant map size increase
- **Stage 5 (Continent)**: Massive map, very challenging
- **Stage 6 (World)**: Huge map, extreme difficulty
- **Stage 7 (Space)**: Maximum stage - largest map, highest difficulty

Each stage is a **complete reset** - new map, new base, fresh start. The challenge is to reach the highest tier resource to unlock the next stage.

## System Architecture

### 1. Stage System

#### Stage Structure
```
Stage 0 (Area):
  - Grid: 20x32 cells (base size)
  - Max tier: 11 (highest tier)
  - Difficulty multiplier: 1.0x
  - Zone prices: base prices
  - Bot prices: base prices
  
Stage 1 (River):
  - Grid: 24x38 cells (slightly larger)
  - Max tier: 11 (same max, harder to achieve)
  - Difficulty multiplier: 1.5x
  - Zone prices: 1.5x base
  - Bot prices: 1.5x base
  
Stage 2 (Valley):
  - Grid: 28x44 cells
  - Max tier: 11
  - Difficulty multiplier: 2.0x
  - Zone prices: 2.0x base
  - Bot prices: 2.0x base
  
... and so on
```

#### Stage Names
- Stage 0: **Area**
- Stage 1: **River**
- Stage 2: **Valley**
- Stage 3: **Region**
- Stage 4: **Country**
- Stage 5: **Continent**
- Stage 6: **World**
- Stage 7: **Space**

### 2. Upgrade Requirement System

#### Highest Tier Achievement
- **Requirement**: Player must have achieved tier 11 (or configurable max tier) in the base
- **Tracking**: System tracks the highest tier that has been created/merged in the current stage
- **Verification**: Base must have tier 11 item (even if later merged away, the achievement is tracked)
- **Upgrade Button**: Only enabled when requirement is met

#### Achievement Tracking
- Track highest tier achieved per stage
- Persist achievement status (save/load)
- Visual indicator showing progress toward upgrade requirement
- Show "Upgrade Available" notification when requirement met

### 3. World Reset System

#### Complete Reset on Stage Upgrade
When player upgrades to next stage:
- **All Resources**: Removed (no carryover)
- **All Items**: Base slots reset to empty
- **All Bots**: Removed
- **All Coins**: Reset to starting amount
- **All Zones**: Reset (only BASE and FOREST unlocked)
- **Map**: Completely regenerated with new layout
- **Base**: Reset to starting configuration
- **Stage Number**: Incremented and saved

#### Reset Process
1. Player clicks "Upgrade Stage" button
2. Confirmation dialog (optional but recommended)
3. Save current stage progress (achievements, etc.)
4. Clear all game state (resources, bots, base, etc.)
5. Load next stage configuration
6. Generate new map
7. Initialize fresh base
8. Reset player position
9. Show stage transition animation/effect

### 4. Difficulty Scaling

#### Configurable Parameters Per Stage
- **Max Tier**: Highest tier required (typically 11, but configurable)
- **Difficulty Multiplier**: Affects prices, merge requirements, spawn rates
- **Map Size**: Grid size for the stage (can increase per stage)
- **Zone Price Multiplier**: How much zone unlocks cost
- **Bot Price Multiplier**: How much bots cost
- **Merge Requirements**: Can increase merge counts for higher tiers
- **Resource Spawn Rate**: Can slow down spawns
- **Resource Spawn Tier Range**: Can adjust which tiers spawn

#### Scaling Examples
```
Stage 0 (Area):
  - Difficulty: 1.0x
  - Zone prices: 100, 500, 2000, 8000
  - Bot prices: 50, 200, 600, 1500, 4000
  
Stage 1 (River):
  - Difficulty: 1.5x
  - Zone prices: 150, 750, 3000, 12000
  - Bot prices: 75, 300, 900, 2250, 6000
  
Stage 2 (Valley):
  - Difficulty: 2.0x
  - Zone prices: 200, 1000, 4000, 16000
  - Bot prices: 100, 400, 1200, 3000, 8000
```

### 5. UI/UX Changes

#### Shop Structure
```
Shop Menu:
├── Zones Tab
│   └── Zone unlocks for current stage
├── Bots Tab
│   └── Bot purchases for current stage
└── Stage Upgrade Tab (NEW)
    ├── Current Stage: [Stage Name]
    ├── Highest Tier Achieved: T[0-11]
    ├── Upgrade Requirement: T11
    └── "Upgrade to [Next Stage]" button
        └── Enabled only when T11 achieved
```

#### Stage Indicator
- Display current stage name in UI
- Show progress toward upgrade (highest tier achieved / required tier)
- Visual indicator when upgrade is available

#### Upgrade Button
- Only visible/enabled when requirement met
- Shows next stage name
- Confirmation dialog before upgrading
- Celebration effect when upgrading

### 6. Technical Implementation Strategy

#### Phase 1: Foundation
1. **Create Stage Config System**
   - `ProgressionConfig` resource class
   - Stage definitions with all parameters
   - Configurable difficulty settings

2. **Stage Tracking System**
   - Track current stage number
   - Track highest tier achieved per stage
   - Save/load stage progress

3. **Upgrade Requirement Check**
   - Monitor base for tier 11 achievement
   - Set flag when requirement met
   - Enable upgrade button

#### Phase 2: Reset System
1. **Complete Reset Functionality**
   - Clear all resources
   - Remove all bots
   - Reset base slots
   - Reset zones
   - Reset coins

2. **Map Regeneration**
   - Generate new map for next stage
   - Use stage-specific grid size
   - Initialize zones with stage settings

3. **Stage Transition**
   - Save current progress
   - Load next stage config
   - Apply difficulty multipliers
   - Initialize fresh world

#### Phase 3: Difficulty Scaling
1. **Apply Stage Difficulty**
   - Scale zone prices
   - Scale bot prices
   - Adjust merge requirements (optional)
   - Adjust spawn rates (optional)

2. **Dynamic Pricing**
   - Calculate prices based on stage and base price
   - Apply multipliers from config

#### Phase 4: Polish & Balance
1. **Visual Polish**
   - Stage transition animation
   - Upgrade celebration effect
   - Progress indicators

2. **Balance Testing**
   - Test difficulty scaling
   - Adjust config values
   - Ensure progression feels rewarding

3. **Save/Load**
   - Persist stage number
   - Persist achievements
   - Save configuration state

## Data Structures

### ProgressionConfig Resource
```gdscript
class_name ProgressionConfig
extends Resource

# Stage definitions
@export var stages: Array[StageConfig] = []

# Stage config for a single stage
class StageConfig:
    var stage_index: int
    var stage_name: String
    var grid_size: Vector2i
    var max_tier: int = 11
    var difficulty_multiplier: float = 1.0
    var zone_price_multiplier: float = 1.0
    var bot_price_multiplier: float = 1.0
    var merge_requirement_multiplier: float = 1.0  # Optional
    var spawn_rate_multiplier: float = 1.0  # Optional
```

### StageManager (in Main)
```gdscript
var current_stage: int = 0
var highest_tier_achieved: int = 0
var progression_config: ProgressionConfig
var can_upgrade_stage: bool = false
```

## Progression Flow

1. **Stage 0 (Area)**
   - Start fresh game
   - Collect resources, unlock zones
   - Merge items through tiers
   - Progress: T0 → T1 → ... → T11
   - Once T11 achieved, upgrade button enables

2. **Stage Upgrade**
   - Player clicks "Upgrade to River"
   - Confirmation dialog
   - Complete reset occurs
   - New map generated (River)
   - Fresh start with increased difficulty

3. **Stage 1 (River)**
   - All zones locked except BASE/FOREST
   - Prices 1.5x higher
   - Larger map
   - Player must reach T11 again (harder)

4. **Repeat**
   - Progress through stages 0 → 7
   - Each stage is a fresh challenge
   - Difficulty increases progressively
   - Achievement: Reaching highest tier in each stage

## Balance Considerations

### Stage Difficulty Scaling
- **Linear Scaling**: Each stage adds fixed multiplier (e.g., +0.5x per stage)
- **Exponential Scaling**: Each stage multiplies by factor (e.g., 1.5x per stage)
- **Custom Scaling**: Each stage has manually tuned values

### Recommended Defaults
```
Stage 0: 1.0x (baseline)
Stage 1: 1.5x (50% harder)
Stage 2: 2.0x (100% harder)
Stage 3: 2.5x (150% harder)
Stage 4: 3.0x (200% harder)
Stage 5: 4.0x (300% harder)
Stage 6: 5.0x (400% harder)
Stage 7: 6.0x (500% harder)
```

### Map Size Scaling (Optional)
```
Stage 0: 20x32 (base)
Stage 1: 24x38 (+20%)
Stage 2: 28x44 (+40%)
Stage 3: 32x50 (+60%)
Stage 4: 36x56 (+80%)
Stage 5: 40x64 (+100%)
Stage 6: 44x72 (+120%)
Stage 7: 48x80 (+140%)
```

## Visual Design

### Stage Indicator
- Current stage name displayed prominently
- Progress bar showing highest tier / max tier
- Visual effect when upgrade available

### Reset Transition
- Fade out current world
- Show "Upgrading to [Stage Name]" message
- Fade in new world
- Celebration particles

### Base Appearance
- Base could have subtle visual changes per stage
- Or keep same visual (clean reset aesthetic)

## Implementation Priority

### Must Have (MVP)
1. ProgressionConfig resource with stage definitions
2. Stage tracking system (current stage, highest tier)
3. Upgrade requirement checking (T11 detection)
4. Complete reset functionality
5. Stage Upgrade tab in shop

### Should Have
1. Map size scaling per stage
2. Difficulty multiplier application
3. Save/load stage progress
4. Visual progress indicators

### Nice to Have
1. Stage transition animations
2. Custom merge requirements per stage
3. Spawn rate adjustments per stage
4. Achievement tracking and display

## Configuration Example

See `progression_config.gd` for full configurable settings including:
- Stage names
- Grid sizes per stage
- Difficulty multipliers
- Price multipliers
- Max tier requirements
- Optional advanced settings (merge requirements, spawn rates)

---

**Design Date**: 2024-12-25
**Status**: Stage-Based Progression Design
