# Survive Vampiror

A short Godot 4.7 / GDScript game: command a zombie horde and overwhelm one
knight. A run takes roughly three minutes. The gameplay is complete on
`gpt-full-game-test`; the interface, arena and attack markers are functional
placeholders. Sound and visual polish are intentionally absent.

Open `project.godot` in Godot and press **F5**, or run `godot --path .`.
The fight waits until your first ground command.

| Control | Action |
| --- | --- |
| Left-click the floor | Move the entire horde; zombies bite automatically in range |
| Space | Sprint toward the current command for 1.4 seconds; 7-second cooldown |
| Esc | Pause / resume |
| R | Restart, including from pause or the result screen |

The knight hunts the horde and changes attack patterns at two-thirds and
one-third health. **Orange sector:** dodge sideways. **Yellow lane:** leave the
charge path. **Purple circle:** retreat outside it. Return to bite during his
recovery; following him continuously without dodging loses the fight.

Command a **green circle** and keep at least one zombie there for two seconds
to recruit its reserve. Each of three sites holds 12 zombies; they do not
regenerate. The horde starts with 40 and can hold 60. Unused reserves remain at
a site when you reach the cap. Losing every zombie ends the run, even if
reserves remain. Defeat the knight to win; the result shows time, casualties
and recruited zombies.

## Characters

[Zombie and knight assets](art/characters/README.md) include editable Blender
sources, rigs, idle/run animations and GLB exports. Gameplay uses these models
and adds a small runtime sword animation; no Blender rebuild is needed to play.

## Development

Start with [AGENTS.md](AGENTS.md). The agent documentation follows the sibling
`sumdyq-sozdik` project's separation of responsibilities:

- [Project state](docs/agent/PROJECT_STATE.md): current implementation and evidence.
- [Tasks](docs/agent/TASKS.md): authorized scope and completion status.
- [Decisions](docs/agent/DECISIONS.md): choices and rationale.
- [Architecture](docs/agent/SPEC_ARCHITECTURE.md): scene ownership and data flow.
- [Gameplay](docs/agent/SPEC_GAMEPLAY.md): rules and tuning.
- [Testing](docs/agent/TESTING.md): reproducible checks and limits.
- [Glossary](docs/agent/GLOSSARY.md): terms.
