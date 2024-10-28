# 3D Cursor Plugin for Godot Engine

This plugin implements a 3D Cursor in the Godot Engine, inspired by the 3D cursor functionality in Blender. It provides an intuitive way to place and position new nodes within a 3D scene and includes additional positioning tools.

## Features

- **3D Cursor Placement**: Use `Shift + Right Click` to place the 3D cursor in a 3D scene. The cursor only appears when clicking on a surface with a collider, ensuring accurate placement on interactable objects. The cursor appears in the Node Tree and can be toggled visible or hidden.
- **Node Placement at Cursor**: New nodes that inherit from `Node3D` are automatically placed at the cursor’s position instead of the scene origin or the parent node’s origin. If the cursor is hidden, this functionality is disabled.
- **Cursor Persistence**: If the cursor is deleted, it can be restored by pressing `Shift + Right Click` again. The cursor can also be moved manually with Godot's standard gizmos.
- **Additional Commands**: The following commands are available in the Command Palette:
  - **3D Cursor to Origin**: Resets the cursor's position to the scene origin.
  - **3D Cursor to Selected Object**: Moves the cursor to the position of a selected object. If multiple objects are selected, it moves to their average position.
- **Customizable Appearance**: 
  - An optional label can be shown alongside the cursor, with an option to scale the label in sync with the cursor or keep it at a fixed size.
  - The cursor can be scaled as needed.
- **Scene Compatibility**: The cursor can be used across different scenes. When placed in a new scene, it is automatically removed from the previous scene.

## Installation

1. Download or clone the repository into your Godot project’s `addons` folder.
2. Enable the 3D Cursor Plugin in **Project > Project Settings > Plugins**.

## Usage

- **Placing the Cursor**: Press `Shift + Right Click` within a 3D scene to place the cursor. Note that the cursor only appears when clicking on a surface with a collider. The cursor appears in the Node Tree and can be toggled visible or hidden.
- **Node Placement**: When adding a new node that inherits from `Node3D`, it will automatically be positioned at the cursor’s location if the cursor is visible.
- **Moving the Cursor**: Use the following commands from the Command Palette:
  - **3D Cursor to Origin**: Resets the cursor’s position to the scene origin.
  - **3D Cursor to Selected Object**: Moves the cursor to the selected object’s position or to the average position if multiple objects are selected.
- **Customizing the Cursor**: In the cursor's settings, adjust the scale and enable or disable the label. You can choose to scale the label with the cursor or keep it at its original size.

## Version

**1.0.0** - Initial release with core functionality implemented and fully operational. Minor bugs may still exist; feedback and bug reports are appreciated.
