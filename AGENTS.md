# Project Agent Instructions

## Project Goal

Survive Vampiror is an early Godot 3D prototype in which the player commands a
horde against one knight in a complete short jam-style encounter. Keep gameplay
logic complete. The `ui-hud-prototype` branch additionally explores the in-game
HUD and pause/result screens.

## Required Context Before Work

Read these before making changes:

- [Project state](docs/agent/PROJECT_STATE.md): what exists and what is verified.
- [Tasks](docs/agent/TASKS.md): the current authorized scope.
- [Decisions](docs/agent/DECISIONS.md): accepted choices and their rationale.

Read the relevant deeper reference when needed:

- [Architecture](docs/agent/SPEC_ARCHITECTURE.md)
- [Gameplay](docs/agent/SPEC_GAMEPLAY.md)
- [Testing](docs/agent/TESTING.md)
- [Glossary](docs/agent/GLOSSARY.md)

## Task Intake

Use the user's request and existing conversation to identify the goal, scope,
observable acceptance criteria, and verification. Proceed when these are clear.
For vague requests without an active task, inspect the current state and ask
only for the missing scope. Do not invent a next milestone or expand the backlog.

## Hard Rules

- Preserve user changes; do not rewrite unrelated files.
- Current authorized scope: a complete jam-style gameplay loop with knight
  phases/attacks, horde movement and sprint, permanent zombies and rotating
  temporary reinforcements, outcomes, pause and restart. This supersedes the earlier basic-combat-only scope.
- UI exploration is authorized on `ui-hud-prototype`: in-game HUD and working
  pause/result controls. Keep gameplay tuning unchanged. No audio, custom
  shaders, decorative world assets, persistence, networking, or unrelated systems.
- Do not introduce dependencies, plugins, global services, event buses, ECS,
  pooling, or navigation infrastructure without a concrete current need.
- Reuse applicable sibling conventions, not sibling-specific game systems.
- Document implemented behaviour accurately; do not create TODO-only components.

## Architecture And Coding Style

- Use Godot 4.7 and typed GDScript with Godot's tab indentation.
- Use snake_case files, functions, variables, and signals; PascalCase classes
  and scene nodes. Prefer typed exports and lifecycle-safe `@onready` references.
- Compose scenes in `scenes/`; reusable entities belong in `scenes/components/`.
- `scripts/input/` emits player intent; `scripts/gameplay/` owns commands and
  movement and combat. Keep those responsibilities separate.
- Follow signal-up/call-down composition through explicit scene references.
- Keep component tuning in exported properties. Avoid configuration frameworks.
- Keep permanent rules here, current reality in `PROJECT_STATE.md`, work in
  `TASKS.md`, rationale in `DECISIONS.md`, and contracts in the relevant spec.
  Prefer links over duplicating detailed documentation.

## Verification And Definition Of Done

Commands, from the project root:

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/prototype_smoke.gd --fixed-fps 60
godot --headless --path . --script res://tests/combat_smoke.gd --fixed-fps 60
godot --headless --path . --script res://tests/reinforcement_smoke.gd --fixed-fps 60
godot --headless --path . --script res://tests/combat_balance.gd --fixed-fps 60
godot --path .
```

For gameplay changes, run the relevant automated checks and inspect rendered
behaviour when appearance or interaction changes. Fix runtime errors. Report
automated checks, visual inspection, and remaining manual checks separately.
Update the affected agent docs, keep the change scoped, and stop when the
requested acceptance criteria are met. Documentation-only edits require checking
paths and accuracy, not rerunning unchanged gameplay tests.
