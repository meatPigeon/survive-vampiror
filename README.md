# Survive Vampiror

Small Godot 4.7 / GDScript 3D prototype: command 40 animated zombies around a flat
arena and overwhelm a medieval knight who fights back.

Open `project.godot` in Godot and press **F6** on `scenes/main.tscn`, or **F5** to
run the project. From this directory, `godot --path .` also launches it.
**Left-click the floor** to move the whole horde. Click again to redirect it.
The yellow ring marks the command; agents gather around it with local separation.
Zombies face their movement direction, run while moving, and idle when settled.
Zombies bite automatically in range. The knight turns and swings his sword;
the orange arc warns where the next hit will land. Move the horde sideways out
of the arc, then return during his recovery; staying on him loses the fight. Both sides have health and
can die. Defeat the knight before the horde is wiped out. The HUD shows knight
health and surviving zombies. Press **R** to restart at any time.

## Blender Characters

[Zombie and knight assets](art/characters/README.md) include editable Blender
files, rigs, looping idle/run animations, GLB exports, and preview videos.
The arena uses the zombie and knight GLBs as its character visuals.

## Development Documentation

Start with [AGENTS.md](AGENTS.md) for agent instructions and required context.
The `docs/agent/` structure follows the sibling `sumdyq-sozdik` project:

- [Project state](docs/agent/PROJECT_STATE.md): implementation, limits, verification.
- [Tasks](docs/agent/TASKS.md): current authorized work.
- [Decisions](docs/agent/DECISIONS.md): accepted choices and rationale.
- [Architecture](docs/agent/SPEC_ARCHITECTURE.md): scene tree and ownership.
- [Gameplay](docs/agent/SPEC_GAMEPLAY.md): the current slice's behaviour contract.
- [Testing](docs/agent/TESTING.md): import, automated tests, and manual checks.
- [Glossary](docs/agent/GLOSSARY.md): canonical terms.
# survive-vampiror
