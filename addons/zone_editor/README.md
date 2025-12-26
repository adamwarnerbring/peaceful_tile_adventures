# Zone Editor Plugin

A visual editor for creating and editing zone configurations in the Godot editor.

## Setup

1. Enable the plugin in Godot:
   - Go to **Project → Project Settings → Plugins**
   - Find "Zone Editor" and enable it
   - The Zone Editor dock will appear on the left side of the editor

## Usage

### Drawing Zones

1. **Select Stage**: Choose which stage you're editing (Area, River, Valley, etc.)
2. **Select Zone**: Choose which zone type (Forest, Cave, Crystal, Volcano, Abyss)
3. **Select Shape Type**:
   - **Polygon**: Click to add points, right-click to finish
   - **Rectangle**: Click once for top-left, click again for bottom-right
   - **Circle**: Click once for center, click again for radius
   - **Distance Layers**: Edit in code (distance-based rings)

4. **Draw**: Click on the canvas to draw your zone
5. **Save**: Click "Save" to save zones to `res://zone_configs/[stage]_zones.json`
6. **Load**: Click "Load" to load saved zones for the current stage
7. **Clear**: Click "Clear" to reset to default zones

### Zone Shapes

- **Polygon**: Click points to create custom shapes. Right-click when done (needs at least 3 points)
- **Rectangle**: Two clicks to define corners
- **Circle**: Two clicks (center, then edge for radius)
- **Distance Layers**: Use code in `zone_config.gd` - these are radial zones from base center

### Coordinate System

- All coordinates are in "base grid units" (20x32)
- Base center is at (10, 28)
- The grid shows the base grid (0-20 for x, 0-32 for y)
- Zones automatically scale when the game grid size changes

### Saving and Loading

- Zones are saved as JSON files in `res://zone_configs/`
- Files are named: `[stage]_zones.json` (e.g., `area_zones.json`)
- Saved zones automatically override default zones when the game runs
- The game checks for saved files first, then falls back to defaults

### Tips

- Use different zones for different shapes (one zone = one shape)
- You can overlap zones - they're checked in order
- Distance Layers are great for simple radial zones
- Polygons work best for irregular coastlines or territories
- Rectangles are perfect for structured areas like valleys or cities

