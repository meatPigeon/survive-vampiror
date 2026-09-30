"""Author three original MIDI sketches. Offline; Python standard library only.

Run this file to rebuild the sibling MIDI files. Rendering uses external
FluidSynth/GeneralUser GS instruments; these are not game dependencies.
"""

from pathlib import Path
import random
import struct


ROOT = Path(__file__).resolve().parent
PPQ = 480
BARS = 12


def variable_length(value):
    parts = [value & 127]
    while value >> 7:
        value >>= 7
        parts.insert(0, (value & 127) | 128)
    return bytes(parts)


def track(events):
    data = bytearray()
    previous = 0
    for tick, order, message in sorted(events):
        data += variable_length(tick - previous) + message
        previous = tick
    data += b'\x00\xff\x2f\x00'
    return b'MTrk' + struct.pack('>I', len(data)) + data


class Sketch:
    def __init__(self, name, bpm, instruments, seed):
        self.name = name
        self.bpm = bpm
        self.rng = random.Random(seed)
        self.parts = {}
        for channel, (program, volume, pan) in instruments.items():
            self.parts[channel] = [
                (0, 0, bytes([0xc0 | channel, program])),
                (0, 1, bytes([0xb0 | channel, 7, volume])),
                (0, 1, bytes([0xb0 | channel, 10, pan])),
                (0, 1, bytes([0xb0 | channel, 91, 24])),
                (0, 1, bytes([0xb0 | channel, 93, 0])),
            ]

    def note(self, channel, beat, pitch, length=0.35, velocity=74):
        onset = max(0, round(beat * PPQ) + self.rng.randrange(-4, 5))
        end = onset + round(length * PPQ)
        strength = max(1, min(127, velocity + self.rng.randrange(-5, 6)))
        self.parts[channel].extend([
            (onset, 3, bytes([0x90 | channel, pitch, strength])),
            (end, 2, bytes([0x80 | channel, pitch, 0])),
        ])

    def melody(self, channel, bar, phrase, velocity=78):
        for offset, pitch, length in phrase:
            self.note(channel, bar * 4 + offset, pitch, length, velocity)

    def save(self):
        tempo = round(60_000_000 / self.bpm).to_bytes(3, 'big')
        conductor = [(0, 0, b'\xff\x51\x03' + tempo),
                     (0, 1, b'\xff\x58\x04\x04\x02\x18\x08'),
                     (BARS * 4 * PPQ, 0, b'\xff\x01\x00')]
        chunks = [track(conductor)] + [track(part) for part in self.parts.values()]
        data = b'MThd' + struct.pack('>IHHH', 6, 1, len(chunks), PPQ)
        (ROOT / f'{self.name}.mid').write_bytes(data + b''.join(chunks))
        print(f'{self.name}: {BARS} bars, {self.bpm} BPM, {BARS * 240 / self.bpm:.2f}s + release')


def undead_march():
    # Pizzicato strings, bassoon, nylon-string lute substitute, acoustic bass.
    song = Sketch('01_undead_march', 110, {
        0: (45, 87, 39), 1: (70, 80, 76), 2: (24, 64, 94),
        3: (32, 80, 61), 9: (0, 66, 64),
    }, 110)
    chords = [(50, 53, 57), (50, 53, 57), (55, 58, 62), (57, 61, 64),
              (58, 62, 65), (55, 58, 62), (50, 53, 57), (57, 61, 64),
              (50, 53, 57), (55, 58, 62), (57, 61, 64), (50, 53, 57)]
    phrases = [
        [(0, 62, .45), (.75, 65, .22), (1, 69, .45), (2, 68, .22), (2.5, 69, .25), (3, 65, .65)],
        [(0, 62, .65), (1, 60, .35), (1.75, 62, .2), (2, 65, .45), (3, 64, .25), (3.5, 62, .25)],
        [(0, 67, .65), (1, 70, .3), (1.75, 69, .2), (2, 67, .45), (3, 65, .65)],
        [(0, 64, .45), (.75, 61, .2), (1.5, 64, .3), (2, 69, .4), (3, 61, .65)],
    ]
    for bar, chord in enumerate(chords):
        base = bar * 4
        for offset, pitch in [(0, chord[0]), (1, chord[2]), (2, chord[0]), (3, chord[1]), (3.5, chord[2])]:
            song.note(0, base + offset, pitch, .28, 72 if offset % 2 else 84)
        song.note(3, base, chord[0] - 12, .65, 77)
        song.note(3, base + 2, chord[2] - 12, .6, 69)
        for offset in [1, 3]:
            for pitch in chord:
                song.note(2, base + offset + (pitch - chord[0]) * .006, pitch + 12, .22, 59)
        for offset, pitch, strength in [(0, 41, 77), (1, 76, 59), (2, 41, 65), (3, 77, 64), (3.5, 61, 48)]:
            song.note(9, base + offset, pitch, .12, strength)
        phrase = phrases[bar % 4]
        if 4 <= bar < 8:
            # Middle four bars answer quietly with a new contour.
            phrase = [(0, chord[2] + 12, .7), (1.5, chord[1] + 12, .3), (2.5, chord[0] + 12, .8)]
        if bar == 11:
            phrase = [(0, 65, .4), (1, 64, .4), (2, 62, 1.1)]
        song.melody(1, bar, phrase)
    song.save()


def graveyard_groove():
    # Plucked folk dance: nylon strings, dulcimer, flute, bass and soft reed drone.
    song = Sketch('02_graveyard_groove', 114, {
        0: (24, 96, 38), 1: (15, 61, 88), 2: (73, 61, 78),
        3: (32, 84, 61), 4: (21, 37, 55), 9: (0, 68, 64),
    }, 114)
    chords = [(50, 53, 57), (48, 52, 55), (43, 47, 50), (50, 53, 57)] * 3
    for bar, chord in enumerate(chords):
        base = bar * 4
        high = [p + 12 for p in chord]
        # Dorian B-natural in the G-major harmony makes this version brighter.
        riff = [(0, high[0]), (.75, high[2]), (1.5, high[1]), (2, high[0]), (2.75, high[2]), (3.5, high[1])]
        for offset, pitch in riff:
            song.note(0, base + offset, pitch, .32, 82 if offset in (0, 2) else 69)
        for offset, pitch in [(0, chord[0] - 12), (1.5, chord[2] - 12), (2.75, chord[0] - 12), (3.5, chord[0])]:
            song.note(3, base + offset, pitch, .35, 77)
        if bar % 4 == 0:
            song.note(4, base, 50, 7.7, 53)
            song.note(4, base, 57, 7.7, 41)
        for offset, pitch, velocity in [(0, 64, 85), (.5, 82, 39), (1, 62, 58), (1.75, 76, 58), (2, 64, 75), (2.5, 82, 41), (3, 63, 62), (3.5, 76, 50)]:
            song.note(9, base + offset, pitch, .1, velocity)
        if bar % 2 == 1:
            for offset, pitch in [(0.5, high[2] + 12), (1.5, high[1] + 12), (2.5, high[0] + 12)]:
                song.note(1, base + offset, pitch, .28, 62)
        if bar in (2, 6, 10):
            song.melody(2, bar, [(0, 74, .65), (1, 71, .3), (1.5, 69, .3), (2.5, 67, .65), (3.5, 69, .3)], 71)
        if bar in (3, 7, 11):
            song.melody(2, bar, [(0, 69, .7), (1.5, 65, .3), (2, 64, .4), (3, 62, .7)], 68)
    song.save()


def tiny_siege():
    # Low cello pulse, dark string bed, dulcimer motif and restrained drums.
    song = Sketch('03_tiny_siege', 102, {
        0: (42, 79, 44), 1: (15, 73, 83), 2: (48, 43, 67),
        3: (24, 63, 33), 4: (47, 60, 64), 9: (0, 75, 64),
    }, 102)
    chords = [(38, 41, 45), (38, 41, 45), (34, 38, 41), (33, 37, 40),
              (43, 46, 50), (34, 38, 41), (38, 41, 45), (33, 37, 40),
              (38, 41, 45), (34, 38, 41), (33, 37, 40), (38, 41, 45)]
    for bar, chord in enumerate(chords):
        base = bar * 4
        for step, index in enumerate([0, 0, 2, 0, 1, 0, 2, 0]):
            song.note(0, base + step * .5, chord[index] + 12, .29, 75 if step % 4 == 0 else 58)
        for pitch in (chord[0], chord[2]):
            song.note(2, base + .02, pitch + 12, 3.8, 59)
        for offset in (.75, 2.75):
            song.note(3, base + offset, chord[2] + 24, .28, 58)
        for offset, pitch, velocity in [(0, 41, 91), (1.5, 43, 56), (2.5, 41, 70), (3.5, 77, 49)]:
            song.note(9, base + offset, pitch, .15, velocity)
        if bar % 4 == 0:
            song.note(4, base, chord[0] + 12, 1.1, 71)
        if bar % 2 == 0:
            song.melody(1, bar, [(0, chord[0] + 36, .45), (1.5, chord[2] + 36, .35), (2.5, chord[1] + 36, .7)], 72)
        else:
            song.melody(1, bar, [(1, chord[1] + 36, .5), (2.5, chord[0] + 36, .8)], 66)
    song.save()


if __name__ == '__main__':
    undead_march()
    graveyard_groove()
    tiny_siege()
