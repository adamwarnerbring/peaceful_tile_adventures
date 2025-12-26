# Complex Zone Shapes Guide

## Overview

The zone system now supports multiple shape types for creating complex, customized zones. Zones are defined in "base grid units" (20x32), so they maintain consistent sizes regardless of the actual grid size.

## Available Shape Types

### 1. DISTANCE_LAYERS (Default)
Simple circular/ring zones based on distance from base center.

**Example:**
```gdscript
var forest = ZoneDef.new()
forest.shape_type = ZoneConfig.ShapeType.DISTANCE_LAYERS
forest.shape_data = {
    "min_dist": 5.0,   # Start distance from base center (in base grid units)
    "max_dist": 8.0    # End distance (exclusive)
}
```

**Use when:** You want simple radial zones that expand outward from the base.

---

### 2. CIRCLE
A circular zone at a specific location.

**Example:**
```gdscript
var mountain = ZoneDef.new()
mountain.shape_type = ZoneConfig.ShapeType.CIRCLE
mountain.shape_data = {
    "center": Vector2(15, 10),  # Center position in base grid units
    "radius": 6.0                # Radius in base grid units
}
```

**Use when:** You want a circular zone at a specific location (not centered on base).

---

### 3. RECTANGLE
A rectangular zone defined by position and size.

**Example:**
```gdscript
var valley_floor = ZoneDef.new()
valley_floor.shape_type = ZoneConfig.ShapeType.RECTANGLE
valley_floor.shape_data = {
    "rect": {
        "x": 3.0,       # Left edge (base grid units)
        "y": 12.0,      # Top edge (base grid units)
        "width": 14.0,  # Width (base grid units)
        "height": 10.0  # Height (base grid units)
    }
}
```

**Use when:** You want rectangular areas like valleys, fields, or buildings.

---

### 4. POLYGON
A custom polygon zone defined by a series of points.

**Example:**
```gdscript
var forest_region = ZoneDef.new()
forest_region.shape_type = ZoneConfig.ShapeType.POLYGON
forest_region.shape_data = {
    "points": [
        Vector2(5, 8),   # Point 1
        Vector2(12, 6),  # Point 2
        Vector2(15, 10), # Point 3
        Vector2(18, 15), # Point 4
        Vector2(14, 20), # Point 5
        Vector2(8, 22),  # Point 6
        Vector2(3, 18),  # Point 7
        Vector2(2, 12)   # Point 8 (closes the polygon)
    ]
}
```

**Important:** Points must be in counter-clockwise or clockwise order, and the polygon will be automatically closed. Minimum 3 points required.

**Use when:** You want irregular, custom-shaped zones like coastlines, mountain ranges, or custom territories.

---

## Coordinate System

All coordinates are in **base grid units** (20x32):
- X ranges from 0 (left) to 20 (right)
- Y ranges from 0 (top) to 32 (bottom)
- Base center is at approximately (10, 28)

The system automatically converts these to the actual grid size, so zones maintain their relative positions and sizes.

## Shape Priority

When zones overlap, the order matters. Zones are checked from **farthest to nearest** (by min_dist), so closer zones can override farther ones. This allows you to create:
- Base zones that override outer zones
- Specific zones (polygons/rectangles) that override general distance zones
- Layered zone systems

## Examples

### Example 1: Valley with Rectangular Floor
```gdscript
# Stream around base
var stream = ZoneDef.new()
stream.shape_type = ZoneConfig.ShapeType.DISTANCE_LAYERS
stream.shape_data = {"min_dist": 5.0, "max_dist": 8.0}

# Rectangular valley floor
var valley = ZoneDef.new()
valley.shape_type = ZoneConfig.ShapeType.RECTANGLE
valley.shape_data = {"rect": {"x": 3, "y": 12, "width": 14, "height": 10}}
```

### Example 2: Coastal Region with Polygon
```gdscript
# Ocean (distance-based outer zone)
var ocean = ZoneDef.new()
ocean.shape_type = ZoneConfig.ShapeType.DISTANCE_LAYERS
ocean.shape_data = {"min_dist": 15.0, "max_dist": 999.0}

# Coastal land (polygon shape)
var coast = ZoneDef.new()
coast.shape_type = ZoneConfig.ShapeType.POLYGON
coast.shape_data = {
    "points": [
        Vector2(2, 20),
        Vector2(8, 18),
        Vector2(12, 22),
        Vector2(18, 20),
        Vector2(16, 15),
        Vector2(10, 12)
    ]
}
```

### Example 3: Multiple Circular Zones
```gdscript
# Lake 1
var lake1 = ZoneDef.new()
lake1.shape_type = ZoneConfig.ShapeType.CIRCLE
lake1.shape_data = {"center": Vector2(6, 15), "radius": 3.0}

# Lake 2
var lake2 = ZoneDef.new()
lake2.shape_type = ZoneConfig.ShapeType.CIRCLE
lake2.shape_data = {"center": Vector2(14, 18), "radius": 2.5}
```

## Tips for Creating Complex Shapes

1. **Start with distance layers** for the outer zones
2. **Use polygons for coastlines** or irregular boundaries
3. **Use rectangles for structured areas** like cities or valleys
4. **Use circles for features** like lakes, mountains, or resource nodes
5. **Test in the editor** - use the Debug tab to jump between stages
6. **Keep coordinates in base grid units** - they'll scale automatically

## Visualizing Your Zones

To visualize zones while designing:
1. Use the Debug tab to jump to your stage
2. Zones are drawn in different colors
3. Adjust coordinates until the zones look right
4. Remember: coordinates are in base grid units (0-20 for x, 0-32 for y)

## Advanced: Combining Shapes

You can create complex zone layouts by mixing shape types:

```gdscript
# Outer desert (distance)
# Inner oasis (circle)
# River through it (polygon)
# City in center (rectangle)
```

The system checks zones in order, so define them from general (outer) to specific (inner) for best results.

