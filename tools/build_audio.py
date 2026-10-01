"""Build the small SFX set offline; never contacts a generation API.

Requires Python 3 and ffmpeg. Original clips and prompts are in art/audio/.
"""

from array import array
import argparse
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


def pitched(samples, speed):
    """Offline linear resampling for short, toy-like character/impact layers."""
    result = []
    for i in range(int((len(samples) - 1) / speed)):
        position = i * speed
        index = int(position)
        fraction = position - index
        result.append(samples[index] * (1 - fraction) + samples[index + 1] * fraction)
    return result


def mix(duration, layers):
    samples = [0.0] * round(duration * RATE)
    for clip, gain, start in layers:
        offset = round(start * RATE)
        for i, value in enumerate(clip[:max(0, len(samples) - offset)]):
            samples[offset + i] += value * gain
    return samples


def glide(duration, start, end, decay, noise=0.0):
    rng = random.Random(309)
    samples = []
    phase = 0.0
    low = 0.0
    for i in range(round(duration * RATE)):
        t = i / RATE
        frequency = end + (start - end) * exp(-7 * t / duration)
        phase += 2 * pi * frequency / RATE
        low += (rng.uniform(-1, 1) - low) * 0.16
        samples.append((sin(phase) + noise * low) * exp(-decay * t))
    return samples


def build_perks():
    """Six one-shots from existing recordings and synthesis; zero API credits."""
    grunt = decode("zombie_grunt")
    stone = decode("grave_stone")
    hit = decode("halberd_hit")
    bite = decode("zombie_bite")
    write("mine_arm", mix(0.62, [
        (chime([190, 240, 310], spacing=0.1, tail=0.22), 0.35, 0),
        (pitched(grunt, 1.45), 0.7, 0.05),
    ]), peak=0.5)
    write("mine_blast", mix(0.85, [
        (glide(0.8, 155, 48, 8, noise=3.5), 0.8, 0),
        (pitched(hit, 0.72), 0.65, 0),
        (pitched(stone, 1.4), 0.35, 0.08),
    ]), peak=0.7)
    write("sling_launch", mix(0.48, [
        (glide(0.42, 760, 115, 10), 0.45, 0),
        (whoosh(), 1.3, 0.07),
        (pitched(grunt, 1.7), 0.3, 0.04),
    ]), peak=0.55)
    write("sling_land", mix(0.46, [
        (glide(0.4, 115, 62, 15, noise=0.9), 0.7, 0),
        (pitched(hit, 0.9), 0.35, 0),
        (pitched(bite, 0.85), 0.45, 0.02),
    ]), peak=0.6)
    write("feast_start", mix(0.72, [
        (pitched(grunt, 0.8), 0.65, 0),
        (chime([147, 196, 294], spacing=0.12, tail=0.36), 0.3, 0.03),
        (whoosh()[::-1], 0.6, 0),
    ]), peak=0.5)
    write("feast_end", mix(0.42, [
        (chime([294, 196], spacing=0.12, tail=0.28), 0.25, 0),
        (expiry(), 0.5, 0),
    ]), peak=0.25)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--perks-only", action="store_true", help="rebuild only the six perk cues")
    args = parser.parse_args()
    OUTPUT.mkdir(parents=True, exist_ok=True)
    build_perks()
    if args.perks_only:
        raise SystemExit(0)
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
