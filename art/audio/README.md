# Gameplay sound sources

Music sketches and the selected Undead March loop are documented in
[music_concepts/README.md](music_concepts/README.md). Only the march is used at runtime.

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
There are eleven single-voice effect players and one music player. The shared zombie voice has a 0.9-second
cooldown; bites have 0.35 seconds. Both wait for their previous clip to finish.
Footfalls follow mean actual travel with a shared 0.85-unit stride; they finish
without looping when movement stops. Commands are throttled at 0.12 seconds and
cannot interrupt sprint feedback. Expiry batches share a cue, with recruitment
taking precedence. Outcome stops gameplay voices and plays one short result cue;
restart clears it. These are non-positional
cues for the fixed arena camera. The march starts once on the first command,
loops at -12 dB player volume, pauses with the tree and stops at outcome/restart.
There is no per-agent ambient loop.
