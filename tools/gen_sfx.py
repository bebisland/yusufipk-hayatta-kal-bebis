#!/usr/bin/env python3
"""Synthesizes the game's sound effects into assets/audio/sfx/*.wav.

Every sound is built from oscillators, filtered noise and envelopes, so the
output is fully reproducible: `python3 tools/gen_sfx.py` from the repo root.
"""

from pathlib import Path

import numpy as np
from scipy.io import wavfile
from scipy.signal import butter, sosfilt

SR = 44100
OUT = Path(__file__).resolve().parent.parent / "assets" / "audio" / "sfx"
rng = np.random.default_rng(7)


def t_axis(dur):
    return np.arange(int(SR * dur)) / SR


def env(n, attack, decay_curve):
    """Linear attack, exponential decay; decay_curve is the time constant in s."""
    t = np.arange(n) / SR
    a = np.clip(t / max(attack, 1e-4), 0, 1)
    return a * np.exp(-np.maximum(t - attack, 0) / decay_curve)


def sweep(f0, f1, dur, shape="sine"):
    t = t_axis(dur)
    f = f0 * (f1 / f0) ** (t / dur)
    ph = 2 * np.pi * np.cumsum(f) / SR
    if shape == "sine":
        return np.sin(ph)
    if shape == "tri":
        return 2 / np.pi * np.arcsin(np.sin(ph))
    if shape == "saw":
        return 2 * ((ph / (2 * np.pi)) % 1) - 1
    return np.sign(np.sin(ph))


def noise(dur):
    return rng.uniform(-1, 1, int(SR * dur))


def band(x, lo, hi, order=2):
    return sosfilt(butter(order, [lo, hi], "bandpass", fs=SR, output="sos"), x)


def low(x, fc, order=2):
    return sosfilt(butter(order, fc, "lowpass", fs=SR, output="sos"), x)


def high(x, fc, order=2):
    return sosfilt(butter(order, fc, "highpass", fs=SR, output="sos"), x)


def mix(*parts):
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[: len(p)] += p
    return out


def save(name, x, peak=0.85):
    x = x - np.mean(x)
    # Short fade-out so no sound ends with a click.
    fade = min(len(x), int(SR * 0.01))
    x[-fade:] *= np.linspace(1, 0, fade)
    x = x / (np.max(np.abs(x)) + 1e-9) * peak
    OUT.mkdir(parents=True, exist_ok=True)
    wavfile.write(OUT / f"{name}.wav", SR, (x * 32767).astype(np.int16))
    print(f"{name}.wav  {len(x) / SR:.2f}s")


def shoot():
    # Crossbow: string twang (fast falling pluck) plus an airy whoosh.
    d = 0.22
    twang = sweep(420, 180, d, "tri") * env(int(SR * d), 0.002, 0.05)
    whoosh = band(noise(d), 1500, 6000) * env(int(SR * d), 0.01, 0.07)
    click = high(noise(0.01), 3000) * np.linspace(1, 0, int(SR * 0.01))
    return mix(twang * 0.8, whoosh * 0.6, click * 0.5)


def hit():
    d = 0.12
    thud = sweep(160, 55, d) * env(int(SR * d), 0.001, 0.035)
    crack = band(noise(0.04), 800, 4000) * env(int(SR * 0.04), 0.0005, 0.01)
    return mix(thud, crack * 0.7)


def enemy_die():
    d = 0.35
    crunch = band(noise(d), 300, 2500) * env(int(SR * d), 0.002, 0.07)
    drop = sweep(300, 70, d, "saw") * env(int(SR * d), 0.005, 0.09)
    return mix(crunch * 0.8, low(drop, 1200) * 0.7)


def brute_die():
    d = 0.8
    boom = sweep(90, 35, d) * env(int(SR * d), 0.005, 0.25)
    rumble = low(noise(d), 400) * env(int(SR * d), 0.01, 0.2)
    metal = band(noise(0.3), 2000, 5000) * env(int(SR * 0.3), 0.001, 0.05)
    return mix(boom, rumble * 0.9, metal * 0.35)


def gem():
    d = 0.3
    t = t_axis(d)
    n1 = np.sin(2 * np.pi * 1318.5 * t) * env(len(t), 0.002, 0.06)
    t2 = t_axis(d - 0.05)
    n2 = np.sin(2 * np.pi * 1975.5 * t2) * env(len(t2), 0.002, 0.09)
    return mix(n1 * 0.7, np.concatenate([np.zeros(int(SR * 0.05)), n2]) * 0.8)


def level_up():
    notes = [523.25, 659.25, 783.99, 1046.5, 1318.5]
    step = 0.07
    parts = []
    for i, f in enumerate(notes):
        d = 0.9 - i * step
        tone = (sweep(f, f, d, "tri") * 0.7 + np.sin(2 * np.pi * 2 * f * t_axis(d)) * 0.2)
        tone *= env(len(tone), 0.004, 0.25)
        parts.append(np.concatenate([np.zeros(int(SR * i * step)), tone]))
    shimmer = high(noise(0.9), 6000) * env(int(SR * 0.9), 0.2, 0.25) * 0.15
    return mix(*parts, shimmer)


def hurt():
    d = 0.25
    buzz = low(sweep(180, 90, d, "square"), 900) * env(int(SR * d), 0.003, 0.08)
    hitn = band(noise(0.06), 400, 2000) * env(int(SR * 0.06), 0.0005, 0.015)
    return mix(buzz * 0.8, hitn * 0.6)


def wave_horn():
    # War horn: detuned saws on a fifth, slow swell, lowpassed.
    d = 1.6
    t = t_axis(d)
    body = sum(sweep(f * (1 + dt), f * (1 + dt), d, "saw") for f in (98.0, 147.0) for dt in (-0.004, 0.004))
    vib = 1 + 0.004 * np.sin(2 * np.pi * 5 * t)
    body = low(body * vib, 900)
    shape = np.clip(t / 0.25, 0, 1) * np.clip((d - t) / 0.5, 0, 1)
    return body * shape


def game_over():
    notes = [(392.0, 0.0), (311.13, 0.35), (261.63, 0.7), (196.0, 1.05)]
    parts = []
    for f, start in notes:
        d = 1.9 - start
        tone = low(sweep(f, f * 0.985, d, "saw"), 1400) * env(int(SR * d), 0.01, 0.45)
        parts.append(np.concatenate([np.zeros(int(SR * start)), tone]))
    return mix(*parts)


def card_pick():
    d = 0.2
    click = high(noise(0.012), 2500) * np.linspace(1, 0, int(SR * 0.012))
    chime = np.sin(2 * np.pi * 987.8 * t_axis(d)) * env(int(SR * d), 0.002, 0.05)
    return mix(click * 0.6, chime)


if __name__ == "__main__":
    for name, fn in [
        ("shoot", shoot), ("hit", hit), ("enemy_die", enemy_die),
        ("brute_die", brute_die), ("gem", gem), ("level_up", level_up),
        ("hurt", hurt), ("wave", wave_horn), ("game_over", game_over),
        ("card_pick", card_pick),
    ]:
        save(name, fn())
