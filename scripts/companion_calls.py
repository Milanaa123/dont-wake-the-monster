"""Render two original, short animal calls as mono PCM for the existing sound bank."""
from array import array
from math import exp, pi, sin
from pathlib import Path
import sys
import wave

RATE = 22050
ROOT = Path(__file__).resolve().parents[1] / "assets" / "audio"


def render(name, length, notes):
    samples = array("h", [0]) * round(length * RATE)
    for start, duration, frequency, sweep, roughness in notes:
        phase = 0
        for i in range(round(duration * RATE)):
            t = i / RATE
            u = t / duration
            phase += 2 * pi * frequency * (1 + sweep*u + .08*sin(pi*u)) / RATE
            envelope = sin(pi*u)**1.3 * exp(-1.5*u)
            voice = sin(phase + roughness*sin(phase*2)) + .18*sin(phase*3)
            samples[round(start*RATE)+i] += round(19600*envelope*voice)
    if sys.byteorder != "little":
        samples.byteswap()
    with wave.open(str(ROOT / (name+".wav")), "wb") as sound:
        sound.setparams((1,2,RATE,0,"NONE","not compressed"))
        sound.writeframes(samples.tobytes())


if __name__ == "__main__":
    render("PuppyYip", .54, [(0,.16,392,-.60,.74),(.235,.275,356,-.59,.70)])
    render("BirdEcho", .63, [(0,.14,1220,.52,.07),(.19,.13,1600,-.30,.08),(.39,.20,1180,.49,.06)])
