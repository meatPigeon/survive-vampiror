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

The sketches contain twelve bars and a short release. They are comparison
previews with fades, not prepared seamless game loops. Nothing plays in Godot;
this folder inherits `art/audio/.gdignore`. Await the user's choice before
arranging a longer track or adding runtime music.

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
