# Spice Pixels

A small Godot puzzle game prototype where falling spice pixels must be filtered, caught, or allowed to settle into a template shape.

The game combines ideas from falling-block games, color-matching puzzles, and template-based image completion. Spices fall from the top of the screen as colored pixels. The player controls a movable bucket inside a limited control area and decides which spices should pass and which should be blocked.

## Game Concept

The player is given a blank template made of multiple sections. The template defines the shape and regions of the final object, but it does not define the colors.

Spices fall from above. When a spice settles into a template section for the first time, that section becomes locked to the spice's color. From then on, any spice landing in that same section should ideally match the locked color.

For example:

* White pixel = salt
* Black pixel = pepper
* Red pixel = paprika
* Yellow pixel = turmeric
* Brown pixel = cinnamon
* Green pixel = herbs

If a section first receives a red spice, the whole section becomes a red section. Later spices that land in that section should also be red.

## Current Gameplay

The player controls a blue bucket using keyboard input. The bucket can move inside a controlled area above the template.

The player uses the bucket to catch unwanted falling spices before they reach the template.

If a spice is not caught, it continues falling until it hits the bottom or another settled spice. Then it becomes permanent.

## Controls

| Action     | Keys               |
| ---------- | ------------------ |
| Move left  | `A` or Left Arrow  |
| Move right | `D` or Right Arrow |
| Move up    | `W` or Up Arrow    |
| Move down  | `S` or Down Arrow  |

## Current Features

* Grid-based falling spice system
* Multiple spices falling at the same time
* Random spice generation
* Bottom-aligned template
* Template divided into sections
* Section color locking
* Penalty system for wrong spices
* Wrong spices still settle permanently
* Player-controlled bucket
* Bucket movement inside a restricted control area
* Spices only spawn from the template width
* Column-based shaker logic
* A column stops spawning spices once its template cells are filled
* Active falling spices are removed when their column becomes complete
* Game ends when all template tiles are filled

## Game Rules

### Section Locking

Each template section starts without a color.

When the first spice settles inside a section, that section locks to the spice's color.

Example:

```text
Outline receives black pepper first.
Outline section is now locked to black.
```

After that:

```text
Black spice in outline = correct
Any other spice in outline = penalty
```

### Penalties

If a wrong spice lands inside an already locked section:

* The spice still settles permanently
* The penalty counter increases

This makes mistakes visible in the final template instead of simply deleting them.

### Shaker Columns

Spices spawn only from columns that belong to the template width.

Each column acts like a shaker. When all template cells in that column are filled, that shaker stops spawning spices.

If there are already falling spices in a completed column, they are removed so the finished column does not receive extra unwanted spices.

### Game End

The game ends when all template tiles are filled.

The final message shows the total number of penalties.

## Technical Details

This prototype is implemented in Godot using a simple grid-based system.

The game does not use physics for the falling spices. Instead, each spice moves one grid cell at a time using a timer. This makes the logic predictable and easier to control.

### Main Systems

| System               | Description                                     |
| -------------------- | ----------------------------------------------- |
| Grid system          | Stores template cells and settled spices        |
| Falling spice system | Handles active falling spices                   |
| Bucket system        | Allows the player to catch falling spices       |
| Template system      | Stores section IDs and locked section colors    |
| Penalty system       | Counts wrong spices in locked sections          |
| Shaker system        | Stops spawning from completed columns           |
| End condition        | Finishes the game when the template is complete |

## Template Structure

The template uses numeric section IDs:

```gdscript
0 = empty
1 = outline
2 = body
3 = detail
```

Each template cell belongs either to no section or to one of the template sections.

The current prototype uses a simple bottom-aligned bowl/pot shape.

## Project Status

This is currently a playable prototype.

Implemented:

* Core falling logic
* Player bucket
* Multiple falling spices
* Section color locking
* Penalty counting
* Column completion logic
* Game completion logic

Still planned:

* Better art and visual polish
* Actual spice sprites instead of plain colored pixels
* Sound effects
* Start menu
* Restart button
* Multiple levels
* Better templates
* Score grading based on penalties
* UI improvements
* Animations when a section locks
* Better bucket design

## Setup

1. Install Godot 4.
2. Clone this repository.
3. Open the project in Godot.
4. Run the main scene.

## Suggested Project Structure

```text
project/
├── scenes/
│   └── Game.tscn
├── scripts/
│   └── Game.gd
├── assets/
│   ├── sprites/
│   └── sounds/
└── README.md
```

## Development Notes

The current prototype is intentionally kept simple. Most of the logic is inside a single `Game.gd` file so the mechanics can be tested quickly.

Later, the project can be cleaned up by splitting the code into separate scripts:

```text
GameManager.gd
GridManager.gd
TemplateManager.gd
Spawner.gd
Bucket.gd
UIManager.gd
```

## Future Ideas

Possible future improvements:

* Add different spice types with special behavior
* Add limited bucket capacity
* Add different bucket shapes
* Add hazards or fake spices
* Add template preview goals
* Add level progression
* Add score stars based on mistake count
* Add a timer mode
* Add local high scores
* Add animated spice particles

## License

This project is currently a prototype. Add a license before publishing or sharing widely.
