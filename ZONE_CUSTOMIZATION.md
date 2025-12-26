# Zone Customization Guide

## Overview

Zones are now configured per-stage and use a flexible shape system. Zones maintain fixed sizes in "base grid units" (20x32), so when the grid expands, zones don't grow - instead, more space is revealed around them.

## Zone Configuration System

Zones are defined in `scripts/zone_config.gd`. Each stage can have its own set of zones with:
- Custom names (e.g., "Moon", "Mars" for Space stage)
- Custom colors
- Custom tier ranges
- Custom prices
- Custom shapes

## Current Zone Shape Types

### DISTANCE_LAYERS (Default)
Simple distance-based circular zones around the base.

**Configuration:**
```gdscript
forest.shape_type = ZoneConfig.ShapeType.DISTANCE_LAYERS
forest.shape_data = {
    "min_dist": 5.0,   # Distance in base grid units from base center
    "max_dist": 8.0    # End distance for this zone
}
```

**How it works:**
- Zones are rings around the base
- `min_dist` and `max_dist` are measured in base grid units (20x32)
- When grid expands, zones stay the same size (same number of tiles), just appear smaller

## Adding Custom Zone Shapes

### 1. Add New ShapeType

In `zone_config.gd`, add to `ShapeType` enum:
```gdscript
enum ShapeType {
    CIRCLE,
    RECTANGLE,
    POLYGON,
    DISTANCE_LAYERS,
    CUSTOM_FUNCTION  # New shape type
}
```

### 2. Add Shape Evaluation Logic

In `tile_grid.gd`, update `_get_zone_at_distance()` or create new function:
```gdscript
func _get_zone_for_position(base_x: float, base_y: float, zone_def: ZoneConfig.ZoneDef) -> bool:
    match zone_def.shape_type:
        ZoneConfig.ShapeType.DISTANCE_LAYERS:
            var dist = _calculate_distance(base_x, base_y)
            return dist >= zone_def.shape_data.min_dist and dist < zone_def.shape_data.max_dist
        
        ZoneConfig.ShapeType.RECTANGLE:
            var rect = zone_def.shape_data.rect  # {x, y, width, height}
            return base_x >= rect.x and base_x < rect.x + rect.width and \
                   base_y >= rect.y and base_y < rect.y + rect.height
        
        ZoneConfig.ShapeType.POLYGON:
            var points = zone_def.shape_data.points  # Array of Vector2
            return _point_in_polygon(Vector2(base_x, base_y), points)
        
        _:
            return false
```

### 3. Example: Rectangle Zone

```gdscript
var field = ZoneDef.new()
field.zone_id = TileGrid.Zone.CAVE
field.zone_name = "Wheat Field"
field.shape_type = ZoneConfig.ShapeType.RECTANGLE
field.shape_data = {
    "rect": {"x": 5, "y": 5, "width": 10, "height": 8}  # In base grid units
}
```

### 4. Example: Polygon Zone

```gdscript
var mountain = ZoneDef.new()
mountain.zone_id = TileGrid.Zone.VOLCANO
mountain.zone_name = "Mountain Range"
mountain.shape_type = ZoneConfig.ShapeType.POLYGON
mountain.shape_data = {
    "points": [
        Vector2(8, 2),
        Vector2(12, 5),
        Vector2(15, 3),
        Vector2(18, 6),
        Vector2(16, 10),
        Vector2(10, 12),
        Vector2(6, 8)
    ]  # Polygon points in base grid units
}
```

## Stage-Specific Zones

Each stage function in `zone_config.gd` returns an array of zone definitions:

```gdscript
static func _get_river_zones() -> Array[ZoneDef]:
    var zones: Array[ZoneDef] = []
    
    var stream = ZoneDef.new()
    stream.zone_id = TileGrid.Zone.FOREST
    stream.zone_name = "Stream"
    stream.zone_colors = [Color("#0ea5e9"), Color("#0284c7")]
    # ... configure shape, tiers, price
    
    zones.append(stream)
    return zones
```

## Key Points

1. **Fixed Sizes**: Zone distances are in "base grid units" (20x32), not current grid size
2. **Scale Mapping**: The system automatically maps base grid coordinates to the actual grid size
3. **Easy Customization**: Just edit zone config functions to change zone names, colors, shapes
4. **Extensible**: Add new shape types by extending the ShapeType enum and evaluation logic

## Current Stage Zones

- **Area**: Forest, Cave, Crystal Mine, Volcano, Abyss
- **River**: Stream, Hills, Deep Forest, Mountains, Peaks  
- **Space**: Moon, Mars, Jupiter, Saturn, Nebula
- **Others**: Currently use Area zones (TODO: customize)

## Next Steps

To add more customization:
1. Complete zone definitions for Valley, Region, Country, Continent, World stages
2. Add more shape types (POLYGON, RECTANGLE, etc.)
3. Add visual zone boundaries/outlines
4. Add zone-specific spawn rules or behaviors

