# Survive Vampiror

A short Godot 4.7 / GDScript game: command a zombie horde and overwhelm one
knight through three escalating waves. Development continues on
`main`, with complete gameplay, a styled in-game HUD, pause/result screens,
weightier character animation and a larger
60 × 44 clearing with simple low-poly rocks, scrub and ground detail. Attack
markers remain functional placeholders. Short sound effects accompany attack
warnings, weapon swings/hits, zombie movement/bites, commands, sprint,
recruitment/expiry, graves, perk activations/impacts and victory/defeat. Undead
March plays in the main menu; Graveyard Groove loops quietly during battle,
pauses with gameplay and stops at the outcome.

Open `project.godot` in Godot and press **F5**, or run `godot --path .`.
The current itch.io ZIP and upload steps are in `output/`; see
[`ITCH_UPLOAD.txt`](output/ITCH_UPLOAD.txt). Rebuild with
`godot --headless --path . --export-release Web output/web/index.html`
using the local matching template referenced by `export_presets.cfg`.
The main menu shows an animated graveyard diorama. Choose **Newbie** (the
default, original damage) or **Normal** (every knight hit kills a zombie), then
**Raise the horde**. Crossbow bolts kill instantly in both modes. The selected
mode appears beside the wave readout and survives restart and menu return.
**Audio** reveals separate music/sound-effect volume sliders.
Play enters the arena with an ordinary horde and waits for your first WASD
movement, with sprint locked. After waves 1 and 2, choose one of two random, unowned perks or
**skip for +10 permanent zombies**. The next wave waits for your decision.
The same sliders
are available on pause; 0% mutes the category. Levels survive replay and menu
transitions for the current application session, but are not saved to disk.

Sound sources were generated with ElevenLabs; perk effects reuse those recordings
and local synthesis without more API credits. See [audio sources and rebuilding](art/audio/README.md).

| Control | Action |
| --- | --- |
| Mouse wheel up / down | Zoom in to follow the horde; zoom out to return to the arena overview |
| WASD (hold) | Move the entire horde; release to stop; zombies bite automatically in range |
| Space | After choosing the Sprint perk: 2× speed for 1.4 seconds; 7-second cooldown |
| Q / E / ability buttons | Activate the first / second ability; sling enters mouse aiming |
| Left / right mouse button | Fire / cancel while aiming the sling |
| Esc | Pause / resume |
| R | Restart, including from pause or the result screen |
| HUD buttons | Sprint, pause, resume and restart / play again |
| Main menu (pause/results) | End the current run and return to the title screen |

- **Sprint:** Unlock Space and the sprint HUD button. It uses a reward choice,
  keeps Q/E free, and stays unlocked until restart.
- **Corpse mines:** Leave half the living horde behind, rounded down. They explode
  after 2 seconds and die, including permanent zombies. Each deals 45 damage
  within 2.8 units; cooldown 8 seconds. The other half can retreat safely.
- **Zombie sling:** Press its Q/E key or HUD button, aim with the mouse and
  left-click to launch one temporary zombie. The cyan circle shows a 2.5-unit
  scatter radius: it lands randomly inside it. Red means out of range or too
  close to the arena edge. Right-click or the same ability key cancels for free.
  Launch range is 22 units; after a 0.8-second arc the zombie dies and deals
  100 damage within 2 units of landing. Cooldown starts on firing (2.5 seconds).
  Aim ahead of a moving knight; centered aim does not guarantee a hit.
- **Blood feast:** For 5 seconds, bites are twice as frequent and restore 2 HP
  to the biting zombie, up to its maximum; cooldown 15 seconds.

Perks accumulate during the run. Active skills fill Q, then E; Sprint stays on
Space without occupying either slot. Already owned perks do not appear
again. Pause/intermissions freeze abilities. Restart clears perks and
reward zombies, restoring the original 40-member horde.
Losing the last permanent zombie still loses, including through sacrifice.

The knight returns for three waves: halberd, added crossbow, then a faster
mounted knight carrying both weapons. Health increases from 800 to 1000 to 1200.
After choosing a reward, a four-second countdown starts the next wave;
surviving zombies keep their health and remaining lifetime. Defeat the third knight to win. Wave tuning is exported on
Main. Within each wave, the knight changes attack patterns at two-thirds and
one-third health. **Orange sector:** dodge sideways. **Yellow lane:** leave the
charge path. **Purple circle:** retreat outside it. **Cyan line:** dodge the
piercing crossbow bolt; it instantly kills every zombie it intercepts. Return to bite during his
recovery; following him continuously without dodging loses the fight.

On wave three, **red double chevrons** warn of a mounted stampede. After 1.4
seconds he pursues the horde for up to 4.2 seconds, accelerating into wide turns.
His steering has inertia: bait him past the group and change direction instead
of running straight ahead. Each zombie can be hit once per stampede: 20 damage
in Newbie, an instant kill in Normal.
Reaching the arena edge ends it early. A 2.8-second recovery leaves him exposed.
The normal yellow straight charge remains a separate attack.

The starting **40 permanent zombies** have green skin, warm clothes and solid
ivory rings. They do not expire,
and skipping a round reward adds 10 more. **Losing the last permanent zombie
is defeat**, even with temporary zombies still alive; rewards cannot undo it.

Move to the active **crater with raised gravestones** and keep at least one
zombie there for two seconds to recruit up to 12 **temporary zombies**, marked
with pale-blue skin, blue ragged mantles and broken cyan rings. Matching ring
symbols beside the HUD counts identify both groups, even when abilities recolor
their foot markers.
They die after 45 seconds from recruitment, or earlier from damage. The horde
accepts grave recruits up to 60 in total. Round rewards always add the full
10 permanent zombies, even above that recruitment cap. All zombies share
movement commands and sprint.

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
