# Gameplay sound sources

Music sketches and the selected Undead March loop are documented in
[music_concepts/README.md](music_concepts/README.md). The march plays on the title
screen; Graveyard Groove plays during battle.

Five original sound effects were generated with
[ElevenLabs Sound Effects](https://elevenlabs.io/docs/api-reference/text-to-sound-effects/convert)
on 2026-09-30. Each sibling JSON file records its prompt, model, request settings
and the returned `character-cost` header. The initial three one-second requests
reported 10 credits each. Two additional half-second recordings reported 5 each:
**40 credits total**, with no retries or music generation.
These receipts describe this run, not a general pricing guarantee.

| Source | In-game use |
| --- | --- |
| `grave_stone.mp3` | Grave rise; reversed/shortened copy for sinking |
| `halberd_hit.mp3` | First confirmed contact of each knight attack |
| `zombie_grunt.mp3` | Sparse bite, casualty and recruitment voices with local pitch variation |
| `horde_step.mp3` | Shared dirt/grass footfalls driven by actual horde travel |
| `zombie_bite.mp3` | Throttled contact sound when bites damage the knight |

`python tools/build_audio.py` rebuilds the committed mono WAV assets in
`assets/audio/` using Python's standard library and ffmpeg. It trims leading
silence, applies short fades and sets peak levels. Three different short warning
patterns, a swing whoosh, command/sprint/recruitment/expiry and outcome cues are
synthesized locally by that script. Rebuilding
uses no API, key, network connection or credits. Godot needs only the committed
WAV files; source MP3s are excluded from import by `.gdignore`.

Playback volumes are authored in `scenes/components/battle_audio.tscn`.
The Music and Effects buses in `default_bus_layout.tres` multiply those authored
levels. Shared menu/pause controls adjust each independently and mute at zero;
levels survive scene changes in the current application session. The main menu
previews the selected march, and the effect slider previews a short command cue.
There are thirteen single-voice effect players and one music player. The shared zombie voice has a 0.9-second
cooldown; bites have 0.35 seconds. Both wait for their previous clip to finish.
Footfalls follow mean actual travel with a shared 0.85-unit stride; they finish
without looping when movement stops. Commands are throttled at 0.12 seconds and
cannot interrupt sprint feedback. Expiry batches share a cue, with recruitment
taking precedence. Outcome stops gameplay voices and plays one short result cue;
restart clears it. These are non-positional
cues for the arena camera. Graveyard Groove starts once on the first command,
loops at -12 dB player volume, pauses with the tree and stops at outcome/restart.
There is no per-agent ambient loop.

## Perk effects (2026-10-01)

Six new WAVs are built locally from the existing grunt, impact, stone and bite
recordings plus short synthesized layers: **zero additional API credits**.
`python tools/build_audio.py --perks-only` rebuilds just this set; the ordinary
build now includes it too. Original recordings and existing WAVs are unchanged.

| Cue | Playback |
| --- | --- |
| `mine_arm.wav` | Short rising rattle when zombies are actually planted |
| `mine_blast.wav` | One low burst for the entire detonating batch |
| `sling_launch.wav` | Elastic twang/whoosh on actual firing, not entering aim |
| `sling_land.wav` | Short body thud at landing, including a ground miss |
| `feast_start.wav` | Low zombie growl with an ascending activation cue |
| `feast_end.wav` | Quiet descending cue when the buff naturally expires |

Sprint retains its existing cue. Cast and impact each share one Effects-bus
player, at -13/-10 dB, so a mine batch cannot stack dozens of sounds. All clips
are under a second with fades and no loops. Invalid/cancelled actions and
destroyed projectiles produce no false impact. Feast expiry cannot interrupt a
fresh cast; pause freezes playback, wave breaks stop these voices, and outcome
or restart clears them. Peak checks find no clipped samples. Runtime recording
verification is documented in [Testing](../../docs/agent/TESTING.md).
