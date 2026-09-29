# Gameplay Spec

## Playable Fight

The player commands the horde as a group. Launching the project immediately
shows a flat arena, one stationary knight, and 40 zombies through a fixed
angled top-down camera. The goal is to kill the knight before all zombies die.

## Commands And Movement

- The horde waits in its initial scatter until the first valid command.
- Zombies idle while stationary, run while moving, and face their movement.
- A left mouse press on the floor selects a world-space ground position.
  Right clicks and clicks outside the floor have no effect.
- The yellow marker displays the latest command. A new valid click redirects
  the entire horde, including during combat.
- Agents slow near the command and repel nearby agents. They gather around the
  target rather than stack on it. There are no selection controls or formations.
- Agent bodies stay inside the arena and outside the living knight's radius.
  This is simple planar steering/clamping, not general collision or navigation.

## Health And Melee

| Entity | Health | Attack | Range | Timing |
| --- | --- | --- | --- | --- |
| Zombie | 30 | 4 damage to knight | 1.15 | One bite per 0.8 seconds |
| Knight | 1000 | 15 damage to each zombie in a 160-degree arc | 2.2 | 1.3-second windup, 0.18-second swing, 1.2-second recovery |

These are component exports. Each zombie survives one sword hit. The wider
sector punishes staying in place; the longer tell lets the player move the
crowd sideways, then return during recovery. Passive/active comparisons are
recorded in [TESTING.md](TESTING.md); they are not a global balance guarantee.

- Living zombies automatically bite when close enough; no separate attack input.
- The knight selects the nearest zombie in range, turns, and locks the swing
  direction. The orange ground arc warns where damage will land. He stays in
  place, so the horde can approach from another side or retreat during windup.
- Damage resolves once at the end of windup, using current positions. A target
  that has left the arc/range is missed. The held sword and runtime arm swing
  show the attack; the sword mesh itself is not a damage collider.
- Hit characters briefly flash red. Health cannot fall below zero, and death
  emits once. Dead zombies leave movement/separation/combat immediately, fall
  and shrink, then are freed. The dead knight falls and remains in the arena.
- The HUD shows knight health and remaining zombies. Knight death is victory;
  losing every zombie is defeat. Combat and movement commands stop at either
  outcome. Press R at any time to reload a fresh battle.

## Scope Boundary

No roaming survivor AI, abilities, progression, waves, inventory, menus, saves,
multiplayer, custom shaders, sound, procedural maps, or complex navigation or
flocking. These are excluded systems, not planned tasks.

Source idle/run Actions remain unchanged. Combat adds only a runtime arm swing,
a hand-attached primitive sword, simple hit/death feedback, and the small HUD.
Observable checks are in [TESTING.md](TESTING.md).
