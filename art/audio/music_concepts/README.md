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
previews with fades. The user now selected **Undead March** for the main menu
and **Graveyard Groove** for battle. Tiny Siege remains an unused alternative.
This source folder inherits `art/audio/.gdignore`.

`assets/audio/undead_march.ogg` is a 26.181837-second menu loop
derived from the committed unfaded `01_undead_march_source.flac` render.
`python tools/build_music.py` rebuilds it offline with Python and ffmpeg; the
instrument bank is not needed. Final note/reverb tails wrap onto the start,
with a 2 ms endpoint correction and constant gain to preserve seam levels.
Godot imports it with looping enabled; the menu stops it on departure.

`assets/audio/graveyard_groove.ogg` is a 25.263175-second battle loop from
`02_graveyard_groove_source.flac`. The MIDI was rendered with the same bank
checksum and settings as the comparison preview. Rebuild with
`python tools/build_music.py --track groove`; the source includes the release
tail, which the same builder wraps onto the start. Verified level is -18.36
LUFS / -2.09 dBTP. It starts on the first movement command, freezes on pause,
and stops at outcome/restart. Menu and battle use the same Music volume bus.
No new API calls or music-generation credits were used.

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
