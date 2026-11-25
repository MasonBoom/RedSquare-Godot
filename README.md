# Red Square

A first-person walking sandbox for Godot 4.7.2, written in GDScript. You start on the cobblestones facing Saint Basil’s Cathedral. Turn right for the Kremlin Wall or turn around and walk toward the State Historical Museum. The square has six exterior landmarks and uses a compressed, stylized layout for short walks.

## Play on Windows

1. Download the standard x86_64 edition of [Godot Engine for Windows](https://godotengine.org/download/windows/), extract the engine, and run it.
2. In Godot’s Project Manager, choose **Import**. Select the project ZIP, or select `project.godot` if you have already extracted it.
3. Open the project, let Godot finish importing the artwork, and press **F5**. Click inside the game window to capture the mouse if needed.

All models, textures, and sounds are included. The project uses the Compatibility renderer and runs offline after you have the editor.

## Controls

| Action | Input |
| --- | --- |
| Walk and strafe | W A S D |
| Look around | Mouse |
| Run | Hold Shift while moving |
| Jump | Space |
| Open or close the district map | M |
| Pause or resume | Esc |
| Walk and turn with the keyboard | Up and Down move, Left and Right turn |

If the editor releases the mouse, you can also hold the left mouse button and drag to look around. The pause menu lets you toggle sound and return to the starting point.

## Change the game

Open `scenes/red_square.tscn` to edit the district. Move the **Spawn** marker to change the starting point. Its local forward direction is negative Z. The **Landmarks** branch contains individual scenes with their own artwork and collision shapes. The **SquareBoundary** branch holds the perimeter railings.

Select **Player** to tune the walking speed, sprint speed, jump height, or mouse sensitivity in the Inspector. The movement code is in `scripts/walker.gd`. You can edit the landmark models in a 3D editor that supports GLB. The models share a paint palette in `art/pigments.png`.

The district layout draws on the south-end cathedral, the Kremlin wall, and the historic trading rows. [UNESCO’s guide to the Kremlin and Red Square](https://whc.unesco.org/en/list/545/)
