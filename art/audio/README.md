# Gameplay sound sources

Three original one-second sound effects were generated with
[ElevenLabs Sound Effects](https://elevenlabs.io/docs/api-reference/text-to-sound-effects/convert)
on 2026-09-30. Each sibling JSON file records its prompt, model, request settings
and the returned `character-cost` header. The three successful requests each
reported **10 credits**, **30 total**. No retries or music generation were used.
These receipts describe this run, not a general pricing guarantee.

| Source | In-game use |
| --- | --- |
| `grave_stone.mp3` | Grave rise; reversed/shortened copy for sinking |
| `halberd_hit.mp3` | First confirmed contact of each knight attack |
| `zombie_grunt.mp3` | Sparse bite, casualty and recruitment voices with local pitch variation |

`python tools/build_audio.py` rebuilds the committed mono WAV assets in
`assets/audio/` using Python's standard library and ffmpeg. It trims leading
silence, applies short fades and sets peak levels. Three different short warning
patterns and a swing whoosh are synthesized locally by that script. Rebuilding
uses no API, key, network connection or credits. Godot needs only the committed
WAV files; source MP3s are excluded from import by `.gdignore`.

Playback volumes are authored in `scenes/components/battle_audio.tscn`.
There are six single-voice players; the shared zombie voice also has a 0.9-second
cooldown and waits for its previous clip to finish. These are non-positional
cues for the fixed arena camera. No music or per-agent ambient loop is included.
