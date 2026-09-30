# Survive Vampiror

A short Godot 4.7 / GDScript game: command a zombie horde and overwhelm one
knight. A run takes roughly three to four minutes. Development continues on
`main`, with complete gameplay, a styled in-game HUD, pause/result screens,
weightier character animation and a larger
60 × 44 clearing with simple low-poly rocks, scrub and ground detail. Attack
markers remain functional placeholders. Short sound effects accompany attack
warnings, weapon swings/hits, zombie movement/bites, commands, sprint,
recruitment/expiry, graves and victory/defeat. The selected Undead March plays
quietly during battle, pauses with gameplay and stops at the outcome.

Open `project.godot` in Godot and press **F5**, or run `godot --path .`.
The main menu offers Play, Quit and separate music/sound-effect volume sliders.
After Play, the fight waits until your first ground command. The same sliders
are available on pause; 0% mutes the category. Levels survive replay and menu
transitions for the current application session, but are not saved to disk.

Sound sources were generated with ElevenLabs; warning patterns and swing noise
were synthesized locally. See [audio sources and rebuilding](art/audio/README.md).

| Control | Action |
| --- | --- |
| Left-click the floor | Move the entire horde; zombies bite automatically in range |
| Space | Sprint toward the current command for 1.4 seconds; 7-second cooldown |
| Esc | Pause / resume |
| R | Restart, including from pause or the result screen |
| HUD buttons | Sprint, pause, resume and restart / play again |
| Main menu (pause/results) | End the current run and return to the title screen |

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

At most one site is available. The west site opens on the first command.
Each successful summon closes its site, even when only part of the batch fits
under the cap; excess recruits are discarded. After a configurable pause
(5 seconds by default), a random different site opens with a fresh batch of 12.
An unused site moves to a random different location after 30 seconds.
Gravestones rise when a site opens and sink when it closes; the empty crater
stays visible. A mint diamond identifies
the available crater, and its ring fills clockwise while summoning. The HUD uses
the same diamond for remaining stock, without compass labels or percentages.
HUD shows both zombie
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
