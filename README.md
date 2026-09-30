# Survive Vampiror

A short Godot 4.7 / GDScript game: command a zombie horde and overwhelm one
knight. A run takes roughly three to four minutes. The gameplay is complete on
`gpt-full-game-test`. The separate `ui-hud-prototype` branch adds a styled
in-game HUD, pause/result screens, weightier character animation and a larger
60 × 44 clearing with simple low-poly rocks, scrub and ground detail. Attack
markers remain functional placeholders; there is no sound.

Open `project.godot` in Godot and press **F5**, or run `godot --path .`.
The fight waits until your first ground command.

| Control | Action |
| --- | --- |
| Left-click the floor | Move the entire horde; zombies bite automatically in range |
| Space | Sprint toward the current command for 1.4 seconds; 7-second cooldown |
| Esc | Pause / resume |
| R | Restart, including from pause or the result screen |
| HUD buttons (UI branch) | Sprint, pause, resume and restart / play again |

The knight hunts the horde and changes attack patterns at two-thirds and
one-third health. **Orange sector:** dodge sideways. **Yellow lane:** leave the
charge path. **Purple circle:** retreat outside it. Return to bite during his
recovery; following him continuously without dodging loses the fight.

The starting **40 permanent zombies** have white rings. They do not expire,
but cannot be replaced: **losing the last permanent zombie is defeat**, even
with temporary zombies still alive. Kill the knight to win.

Command the active **crater with raised gravestones** and keep at least one
zombie there for two seconds to recruit up to 12 **temporary zombies**, marked
with blue rings.
They die after 45 seconds from recruitment, or earlier from damage. The horde
can hold 60 in total. All zombies share movement commands and sprint.

One site is active at a time: west → south → east, switching every 30 seconds
from the first command. Each activation has a fresh batch; unused stock is lost
when the site switches. Reaching the cap preserves leftovers only until that
switch. Gravestones rise when a site opens and sink when its window closes or
its batch is exhausted; the empty crater stays visible. HUD shows both zombie
counts, next expiry and site timer; results separate combat casualties from
expired recruits. Pause freezes these timers.

## Characters

[Zombie and knight assets](art/characters/README.md) include editable Blender
sources, rigs, idle/run animations and GLB exports. Gameplay uses these models
and adds runtime whole-body knight attacks, zombie bite lunges, movement lean,
hit reactions and death feedback; no Blender rebuild is needed to play.

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
