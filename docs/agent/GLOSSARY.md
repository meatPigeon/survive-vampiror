# Glossary

- **Horde**: the entire player-commanded crowd; initially 40 agents.
- **Agent**: one zombie, represented by a HordeAgent scene with animated visuals.
- **Survivor**: the single knight target; stationary, turning and swinging at nearby zombies.
- **Command position**: the shared world-space ground point selected by a click.
- **Target marker**: the yellow ring displaying that command position.
- **Separation**: local repulsion between nearby agents so bodies remain readable.
- **Arena bounds**: the floor's X/Z rectangle used to constrain movement.
- **GroundCommand / HordeController / HordeAgent**: the canonical input,
  shared-intent, and individual-movement classes, respectively.

- **Health**: per-entity hit points; zero emits death once.
- **Attack arc**: the orange ground warning for the knight's locked sword swing.
