# Zone Editor Setup Guide

## Quick Start

1. **Enable the Plugin**
   - Open Godot
   - Go to **Project → Project Settings → Plugins**
   - Find "Zone Editor" and click **Enable**
   - A "Zone Editor" dock will appear on the left side of the editor

2. **Using the Editor**
   - Select a **Stage** (Area, River, Valley, etc.)
   - Select a **Zone** type (Forest, Cave, Crystal, etc.)
   - Choose a **Shape Type** (Polygon, Rectangle, Circle, or Distance Layers)
   - **Click on the canvas** to draw zones
   - Click **Save** to save your zones
   - Click **Load** to load previously saved zones

## Drawing Zones

### Polygon Zones
1. Select "Polygon" shape type
2. Click multiple times on the canvas to add points
3. Right-click to finish (needs at least 3 points)
4. The polygon will be closed automatically

### Rectangle Zones
1. Select "Rectangle" shape type
2. Click once for top-left corner
3. Click again for bottom-right corner
4. Rectangle is created automatically

### Circle Zones
1. Select "Circle" shape type
2. Click once for center
3. Click again for radius (distance from center)
4. Circle is created automatically

### Distance Layers
- These are radial zones from base center
- Currently best edited in code (`zone_config.gd`)
- Define `min_dist` and `max_dist` in base grid units

## File Locations

- **Saved zones**: `res://zone_configs/[stage]_zones.json`
  - Example: `area_zones.json`, `river_zones.json`
- **Default zones**: Defined in `scripts/zone_config.gd`

## How It Works

1. **Drawing**: Zones are drawn visually on a 20x32 grid (base grid units)
2. **Saving**: Zones are saved as JSON files
3. **Loading**: The game automatically checks for saved files first, then uses defaults
4. **Scaling**: All zones use base grid units, so they scale automatically with grid size

## Tips

- **One zone = one shape**: Each zone type (Forest, Cave, etc.) can have one shape
- **Overlapping zones**: Zones are checked in order - later zones can override earlier ones
- **Visual feedback**: The canvas shows:
  - Grid lines
  - Base center (white circle)
  - Existing zones (colored shapes)
  - Currently drawing shape (green outline)
- **Test in game**: Use the Debug tab to jump to your stage and see how zones look

## Troubleshooting

- **Plugin not showing**: Make sure it's enabled in Project Settings → Plugins
- **Can't save**: Make sure you're running in the editor (not exported game)
- **Zones not loading**: Check that JSON files are in `res://zone_configs/` folder
- **Canvas not drawing**: Try closing and reopening the editor dock

