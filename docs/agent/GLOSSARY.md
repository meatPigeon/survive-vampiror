# Glossary

- **Horde**: the player-commanded crowd; starts at 40. Grave recruitment stops at 60; permanent round rewards may exceed that cap.
- **Agent**: one zombie with its own movement, health, bite cooldown and visuals.
- **Survivor / knight**: the single enemy, with pursuit and three health phases.
- **Movement intent**: the shared camera-relative direction from held physical WASD keys; zero on release.
- **Separation**: local repulsion keeping the crowd's individual bodies readable.
- **Sprint**: Space-triggered temporary movement boost with a cooldown.
- **Warning / attack area**: locked orange sector, yellow lane, purple circle or cyan bolt lane; red stampede chevrons follow the knight's changing heading.
- **Recovery**: the knight's stationary interval after an attack; safe bite window.
- **Permanent zombie**: a starter or round-reward addition; white ring, no expiry or resurrection. Losing the last one loses the run.
- **Temporary zombie**: blue-ring recruit; dies after 45 seconds or earlier from damage.
- **Recruitment site**: a crater with one batch of up to 12 per activation. A summon consumes the site; after a configurable gap, a random different site opens. Unused sites relocate after 30 seconds.
- **Health**: entity HP; zero emits death once.
- **Run**: one scene instance, from first command to victory/defeat or restart.

- **Wave**: one knight life; three per run, adding crossbow and then mount.
- **Intermission**: reward selection after a non-final knight defeat, followed by a configurable countdown; the horde and battle timers are preserved.
- **Crossbow bolt**: a non-homing ranged shot with a locked cyan warning; it pierces and instantly kills zombies on its line until its range ends or combat stops.
- **Stampede**: mounted-only sustained pursuit with acceleration and steering inertia; a timer or floor edge ends it in a longer recovery. One damage hit per zombie per pursuit.
