# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> [!info]
> Changelog entries are fully maintained starting with version **2.0.0**.
> Earlier releases are included on a best-effort basis and may be incomplete.
>
> **Version support policy:** The plugin is maintained in two tracks:
> - **1.4.x (LTS)** supports **Godot 4.2+** and receives bug fixes only.
> - **2.x.x** supports **Godot 4.5+** and receives new features and improvements.

## [2.0.1] - 2026-01-07

### Fixed

- Nil object access when toggling checkboxes in the settings dock without an active cursor.

### Changed

- Improved the plugin info dialog (accessible through the settings dock)
	- Added contribution link for the Godot Engine
	- Extract displayed plugin version from the `plugin.cfg`

## [2.0.0] - 2025-12-29

### Added

#### Settings Dock

##### 3D Cursor Settings
- All previously existing settings for 3D Cursors (`Cursor3D`).
- New *Show Number Label* checkbox to toggle the numeric label on *3D Cursor* instances.
- Settings persist and are restored when a *3D Cursor* is selected as active.

##### Active Cursor
- *Raycast Mode* dropdown:
	- Allows selecting how the *3D Cursor* determines its position.
	- *Physicsless* (introduced in 1.4.0) for Godot 4.5+. Fully compatible with `Terrain3D` by *TokisanGames*.
	- *Physics* for Godot 4.2+ (legacy; maintenance and fixes only).
- *Active Cursor* field:
	- Displays the name of the active *3D Cursor* in the current scene.
	- No active cursor selected:
		- `Left Click` opens a node selector (restricted to `Cursor3D` nodes).
		- Drag-and-drop *3D Cursor* (`Cursor3D`) instances to assign them as active.
	- Active cursor selected:
		- `Left Click` selects the active *3D Cursor* in the node tree and editor.
		- `Double Left Click` selects the cursor and focuses the editor camera on it.
		- `Ctrl + Left Click` selects the cursor, focuses the camera, and zooms to a fixed distance.
		- `Alt + Left Click` opens the node selector again.
- *Deselect* button:
	- Deselects the active cursor in both the node tree and editor.
- *Clear* button:
	- Clears the *Active Cursor* field.
	- Unsets the active *3D Cursor* internally.
	- Disables the *Pie Menu*.
	- Allows reassignment of a *3D Cursor* (`Cursor3D`).

##### Extensions
- *Use Terrain3D* checkbox:
	- Toggles visibility of `Terrain3D`-specific group controls.
- *Add “Terrain3D” Group to Instances* button:
	- Adds the required group to all `Terrain3D` instances in the active scene (required for *Physicsless* raycast mode).
- *Remove “Terrain3D” Group from Instances* button:
	- Removes the group from all `Terrain3D` instances in the active scene.

##### Actions
- All previously available *3D Cursor* actions as buttons.
- *Remove All 3D Cursors From Scene* button.
- *Move Active 3D Cursor To* button:
	- Clicking opens a node selector; selecting a node moves the active cursor to its position.
	- Supports drag-and-drop of nodes inheriting from `Node3D` (excluding the active cursor).
	- Supports drag-and-drop of inspector properties with the following types:
		- `PackedVector2Array`, `PackedVector3Array`, `PackedVector4Array`
			- Only the first element is used.
			- Default mapping: `x -> x`, `y -> y`, `0 -> z`
			- Hold `Shift` to use: `x -> x`, `0 -> y`, `y -> z`
		- `Transform2D`, `Transform3D`
		- `Vector2`, `Vector2i`
			- Default mapping: `x -> x`, `y -> y`, `0 -> z`
			- Hold `Shift` to use: `x -> x`, `0 -> y`, `y -> z`
		- `Vector3`, `Vector3i`
			- Mapping: `x -> x`, `y -> y`, `z -> z`
		- `Vector4`, `Vector4i`
			- Mapping: `x -> x`, `y -> y`, `z -> z` (`w` is discarded)
		- Specially structured `Dictionary`:
			- Must contain keys `x`, `y`, and `z` (case-insensitive),
			  each mapping to either a `float` or an `int`.

#### General
- Support for multiple *3D Cursors* per scene, with active cursor selection via the new *Settings Dock*.
- *3D Cursor* instances now display an additional numeric ID label above the existing label.
	- IDs are assigned sequentially per scene and reset when all cursors are removed.
- When multiple cursors exist, their ID is appended to the node name, respecting the
  `editor/naming/node_name_num_separator` project setting.
- Additional key combinations:
	- `Shift + Ctrl + Left Click` on a collider or mesh places a new cursor and sets it as active.
	- `Shift + Alt + Left Click` moves the most recently created cursor to the target location and sets it as active.
- `Cursor3D` instances now automatically remove themselves when the plugin is disabled
  and a scene containing them is opened.

### Changed

- **1.5.x:** Raised the minimum supported Godot version to 4.5+ (Godot 4.2.x, 4.3.x, 4.4.x is no longer supported on this track)
- Major refactor of the whole plugin.
- Reorganized scripts, assets, and scenes for improved maintainability.
- Replaced scene file paths with UIDs.
- Reworked the Godot version compatibility check.
- Moved settings previously stored on `Cursor3D` instances into the settings dock.
- Split the *Remove 3D Cursor from Scene* action into:
	- *Remove Active 3D Cursor from Scene*
	- *Remove All 3D Cursors From Scene*

### Fixed

- Fixed *3D Cursor* not functioning until switching editor tabs after startup or plugin activation.

---

## [1.4.1] - 2025-12-17

---

## [1.4.0] - 2025-12-17

### Added

- Introduced physics-independent, mesh-based raycasting, fixing #3
- Full compatibility with **Terrain3D** by *TokisanGames,* fixing #6

### Changed

- License shift from **MIT** to **ISC** (equivalent to MIT).

---

## [1.3.5] - 2025-12-14

### Fixed

- *3D Cursor* placement not working in orthogonal view; fixed #7

---

## [1.3.4] - 2025-11-17

### Added

- Warning if the 'Run on Separate Thread' project setting is activated. (#3)

---

## [1.3.3] - 2025-11-10

### Fixed

- The plugin does not work in scenes where the root is not a `Node3D` or inherits from it. Fixing #4

---

## [1.3.2] - 2025-09-10

---

## [1.3.1] - 2025-08-29

### Fixed

- *Pie Menu* opening with no *3D Cursor* in the scene.

---

## [1.3.0] - 2024-11-11

### Added

- Disable / Enable command
- Background for *Pie Menu*
- Selection indicator for *Pie Menu*

---

## [1.2.0] - 2024-11-02

### Added

- *Pie Menu* for quick access to *3D Cursor* actions, similar to Blender `Shift + S`
- Undo / Redo functionality for most *3D Cursor* actions.

---

## [1.1.0] - 2024-10-28

### Added

- Cursor recovery when visiting another scene containing a *3D Cursor*.
- Cursor remove command.

---

## [1.0.1] - 2024-10-28

### Fixed

- Wrong location of cursor texture.

---

## [1.0.0] - 2024-10-28

### Release
