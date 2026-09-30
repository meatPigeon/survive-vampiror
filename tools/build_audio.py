"""Build the small SFX set offline; never contacts a generation API.

Requires Python 3 and ffmpeg. Original clips and prompts are in art/audio/.
"""

from array import array
from math import exp, pi, sin
from pathlib import Path
import random
import subprocess
import wave


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "art/audio"
OUTPUT = ROOT / "assets/audio"
RATE = 44100


def decode(name):
    raw = subprocess.check_output([
        "ffmpeg", "-v", "error", "-i", str(SOURCE / f"{name}.mp3"),
        "-f", "f32le", "-ac", "1", "-ar", str(RATE), "-",
    ])
    samples = list(array("f", raw))
    # Remove generator lead-in so impacts line up with damage, retaining 5 ms.
    window = 220
    levels = [sum(x * x for x in samples[i:i + window]) / window
              for i in range(0, len(samples), window)]
    threshold = max(levels) * 0.006
    first = next(i for i, level in enumerate(levels) if level > threshold)
    return samples[max(0, first * window - window):]


def write(name, samples, peak=0.65):
    samples = list(samples)
    for i in range(len(samples)):
        fade_in = min(1.0, i / (RATE * 0.004))
        fade_out = min(1.0, (len(samples) - 1 - i) / (RATE * 0.035))
        samples[i] *= fade_in * fade_out
    scale = peak / max(abs(x) for x in samples)
    data = array("h", (round(x * scale * 32767) for x in samples))
    with wave.open(str(OUTPUT / f"{name}.wav"), "wb") as output:
        output.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
        output.writeframes(data.tobytes())
    print(f"{name}: {len(samples) / RATE:.3f} s, peak {peak:.2f}")


def warning(pulses, frequency):
    rng = random.Random(128 + pulses)
    duration = 0.24 + (pulses - 1) * 0.16
    samples = []
    for i in range(round(duration * RATE)):
        t = i / RATE
        value = 0.0
        for pulse in range(pulses):
            local = t - pulse * 0.16
            if 0.0 <= local < 0.24:
                value += (sin(2 * pi * frequency * local) * exp(-25 * local)
                          + 0.32 * sin(2 * pi * frequency * 2.71 * local) * exp(-40 * local)
                          + rng.uniform(-0.15, 0.15) * exp(-70 * local))
        samples.append(value)
    return samples


def whoosh():
    rng = random.Random(42)
    samples = []
    low = 0.0
    for i in range(round(RATE * 0.3)):
        phase = i / (RATE * 0.3)
        noise = rng.uniform(-1, 1)
        low += (noise - low) * (0.06 + 0.28 * phase)
        samples.append(low * sin(pi * phase) ** 1.6)
    return samples


def chime(notes, spacing=0.13, tail=0.3):
    """Short wooden/metallic UI cue, not a musical backing track."""
    length = (len(notes) - 1) * spacing + tail
    samples = []
    for i in range(round(RATE * length)):
        t = i / RATE
        value = 0.0
        for index, frequency in enumerate(notes):
            local = t - index * spacing
            if 0 <= local < tail:
                attack = min(1.0, local / 0.004)
                value += attack * (sin(2 * pi * frequency * local) * exp(-12 * local)
                                   + 0.22 * sin(2 * pi * frequency * 2.4 * local) * exp(-25 * local))
        samples.append(value)
    return samples


def expiry():
    rng = random.Random(70)
    low = 0.0
    samples = []
    for i in range(round(RATE * 0.55)):
        t = i / RATE
        low += (rng.uniform(-1, 1) - low) * 0.08
        tone = sin(2 * pi * (420 * t - 240 * t * t))
        samples.append((low + tone * 0.12) * exp(-6 * t))
    return samples


if __name__ == "__main__":
    OUTPUT.mkdir(parents=True, exist_ok=True)
    stone = decode("grave_stone")
    write("grave_rise", stone)
    # Reverse and shorten the same recording for the settling/closing motion.
    reverse = stone[::-1]
    write("grave_sink", (reverse[int(i * 1.3)] for i in range(int(len(reverse) / 1.3))))
    write("halberd_hit", decode("halberd_hit"), peak=0.7)
    write("zombie_grunt", decode("zombie_grunt"), peak=0.6)
    for name, pulses, frequency in [("sweep", 1, 520), ("charge", 2, 390), ("spin", 3, 650)]:
        write(f"warning_{name}", warning(pulses, frequency), peak=0.55)
    write("halberd_swish", whoosh(), peak=0.6)
    write("horde_step", decode("horde_step"), peak=0.5)
    write("zombie_bite", decode("zombie_bite"), peak=0.55)
    write("command", chime([360], tail=0.16), peak=0.4)
    sprint = chime([180, 310], spacing=0.09, tail=0.27)
    for i, value in enumerate(whoosh()):
        sprint[i] += value * 0.8
    write("sprint", sprint, peak=0.55)
    write("recruited", chime([330, 440, 554]), peak=0.5)
    write("expired", expiry(), peak=0.45)
    write("victory", chime([196, 233, 294, 392], spacing=0.15, tail=0.5), peak=0.6)
    write("defeat", chime([196, 174, 130], spacing=0.21, tail=0.6), peak=0.55)
