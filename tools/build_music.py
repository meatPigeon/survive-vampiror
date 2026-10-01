"""Build menu/battle music loops offline from their committed lossless renders.

Requires Python's standard library and ffmpeg. No API or instrument bank needed.
"""

from array import array
import argparse
import json
from pathlib import Path
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]
RATE = 44100
CHANNELS = 2
TRACKS = {
    "march": ("01_undead_march", "undead_march", "Undead March", 110),
    "groove": ("02_graveyard_groove", "graveyard_groove", "Graveyard Groove", 114),
}


def build(track):
    source_name, output_name, title, bpm = TRACKS[track]
    source_path = ROOT / f"art/audio/music_concepts/{source_name}_source.flac"
    output_path = ROOT / f"assets/audio/{output_name}.ogg"
    # The MIDI tempo is stored in whole microseconds per beat.
    frames = round(48 * round(60_000_000 / bpm) / 1_000_000 * RATE)
    decoded = subprocess.check_output([
        "ffmpeg", "-v", "error", "-i", str(source_path), "-f", "f32le",
        "-ac", str(CHANNELS), "-ar", str(RATE), "-",
    ])
    samples = array("f", decoded)
    length = frames * CHANNELS
    loop = samples[:length]
    # Carry the final notes/reverb over the first beat instead of fading to silence.
    for index, sample in enumerate(samples[length:]):
        loop[index % length] += sample
    # Remove the tiny endpoint mismatch over 2 ms without moving the downbeat.
    blend = round(RATE * 0.002)
    for channel in range(CHANNELS):
        difference = loop[-CHANNELS + channel] - loop[channel]
        for frame in range(blend):
            loop[frame * CHANNELS + channel] += difference * (1 - frame / blend)
    with tempfile.TemporaryDirectory(prefix="survive_music_") as directory:
        raw = Path(directory) / "loop.f32"
        raw.write_bytes(loop.tobytes())
        source = ["ffmpeg", "-hide_banner", "-nostats", "-f", "f32le",
                  "-ar", str(RATE), "-ac", str(CHANNELS), "-i", str(raw)]
        analysis = subprocess.run(source + ["-af", "loudnorm=I=-18:TP=-2:LRA=7:print_format=json",
                                           "-f", "null", "-"], capture_output=True, text=True, check=True)
        levels = json.JSONDecoder().raw_decode(analysis.stderr[analysis.stderr.rfind("{"):])[0]
        # Constant gain preserves the same level on both sides of the loop seam.
        gain = min(-18 - float(levels["input_i"]), -2 - float(levels["input_tp"]))
        subprocess.run(source + ["-y", "-v", "error", "-af", f"volume={gain}dB",
                                 "-ar", str(RATE), "-c:a", "libvorbis", "-q:a", "5",
                                 "-metadata", f"title={title}", str(output_path)], check=True)
    print(f"{title}: {frames} frames, {frames / RATE:.6f}s, gain {gain:.2f} dB")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--track", choices=TRACKS, default="march")
    build(parser.parse_args().track)
