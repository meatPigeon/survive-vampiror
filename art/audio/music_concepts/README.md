# Music comparison sketches

Three original instrumental compositions for the user's selection. These are
locally authored MIDI arrangements, not ElevenLabs-generated tracks. The single
Music API request was rejected with HTTP 402 `paid_plan_required`; no successful
music generation or retry occurred. Local rendering uses zero API credits.

| Preview | Direction | Tempo | Length |
| --- | --- | --- | --- |
| [Undead March](01_undead_march.mp3) | Comic pizzicato march with bassoon | 110 BPM | 27.5 s |
| [Graveyard Groove](02_graveyard_groove.mp3) | Syncopated plucked folk groove with flute | 114 BPM | 26.6 s |
| [Tiny Siege](03_tiny_siege.mp3) | Low string pulse, dulcimer and restrained drums | 102 BPM | 29.5 s |

The sketches contain twelve bars and a short release. The MP3s are comparison
previews with fades. The user selected **Undead March** for battle; concepts 2
and 3 remain unused alternatives for possible later screens or waves.
This source folder inherits `art/audio/.gdignore`.

The runtime asset is `assets/audio/undead_march.ogg`, a 26.181837-second loop
derived from the committed unfaded `01_undead_march_source.flac` render.
`python tools/build_music.py` rebuilds it offline with Python and ffmpeg; the
instrument bank is not needed. Final note/reverb tails wrap onto the start,
with a 2 ms endpoint correction and constant gain to preserve seam levels.
Godot imports it with looping enabled. One quiet player starts on the first
command, freezes on pause and stops on outcome/restart. No new API calls.

## Sources and rendering

`python art/audio/music_concepts/compose.py` rebuilds the three editable `.mid`
files using Python's standard library. The score, harmony, note timing,
instrument assignments and deterministic variation are in that script.

The instrument bank is [GeneralUser GS 2.0.3 by S. Christian Collins](https://www.schristiancollins.com/generaluser),
rendered with the installed FluidSynth 2.6.1. The bank was downloaded to a
temporary working directory; it is not a game or repository dependency. Its
[upstream license](https://github.com/mrbumpy409/GeneralUser-GS/blob/main/documentation/LICENSE.txt)
permits music creation; a copy is retained here as `GENERALUSER_LICENSE.txt`.
Each JSON records the bank checksum and preview settings.

Example rendering command, with a locally downloaded bank:

```sh
fluidsynth -ni -a file -r 44100 -g 0.45 -C 0 -R 1 \
  -o synth.reverb.room-size=0.35 -o synth.reverb.level=0.22 \
  -T wav -F /tmp/undead_march.wav /path/to/GeneralUser-GS.sf2 \
  art/audio/music_concepts/01_undead_march.mid
```

MP3 previews are stereo, 44.1 kHz, 192 kbps. Post-processing trims to twelve bars
plus 1.3 seconds, adds a 25 ms opening fade and 800 ms ending fade, and uses
FFmpeg two-pass loudness normalization targeting -18 LUFS and -2 dBTP.
These are technical level targets, not subjective listening approval.
