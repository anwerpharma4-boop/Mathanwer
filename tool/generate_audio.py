#!/usr/bin/env python3
"""Generate the bundled offline British English (en-GB) audio.

Voice: Piper neural TTS, voice "en_GB-cori-high" (UK English female,
trained on public-domain LibriVox recordings; phonemes from espeak-ng "en",
which is British English: non-rhotic, "zed", /təˈmɑːtəʊ/ ...).

Inputs : build/speech.json  (from `dart run tool/export_speech.dart`)
Outputs: assets/audio/speech/*.mp3 + assets/audio/speech_manifest.json
         assets/audio/letters/name_<x>.mp3, sound_<x>.mp3
         assets/audio/sfx/*.mp3

Usage:
  python tool/generate_audio.py --model /path/en_GB-cori-high.onnx
Requires: piper-tts (pip), numpy, ffmpeg with libmp3lame.
"""
import argparse
import hashlib
import json
import math
import os
import subprocess
import tempfile
import wave

import numpy as np
from piper import PiperVoice, SynthesisConfig

# Child-friendly pace: slightly slower than the model default.
LENGTH_SCALE = 1.15

# British letter names with stress marks (IPA).
LETTER_NAMES = {
    "a": "ˈeɪ", "b": "bˈiː", "c": "sˈiː", "d": "dˈiː", "e": "ˈiː", "f": "ˈɛf",
    "g": "dʒˈiː", "h": "ˈeɪtʃ", "i": "ˈaɪ", "j": "dʒˈeɪ", "k": "kˈeɪ", "l": "ˈɛl",
    "m": "ˈɛm", "n": "ˈɛn", "o": "ˈəʊ", "p": "pˈiː", "q": "kjˈuː", "r": "ˈɑː",
    "s": "ˈɛs", "t": "tˈiː", "u": "jˈuː", "v": "vˈiː", "w": "dˈʌbəljuː",
    "x": "ˈɛks", "y": "wˈaɪ", "z": "zˈɛd",
}
# Phonics sounds. Stops get a very short schwa so they are audible;
# continuants are lengthened. A final "." gives a clean ending.
LETTER_SOUNDS = {
    "a": "ˈæ!", "b": "bə!", "c": "kə!", "d": "də!", "e": "ˈɛ!", "f": "fffff!",
    "g": "ɡə!", "h": "hə!", "i": "ˈɪ!", "j": "dʒə!", "k": "kə!", "l": "lllll!",
    "m": "mmmmm!", "n": "nnnnn!", "o": "ˈɒ!", "p": "pə!", "q": "kwə!", "r": "ɹə!",
    "s": "sssss!", "t": "tə!", "u": "ˈʌ!", "v": "vvvvv!", "w": "wə!", "x": "ks!",
    "y": "jə!", "z": "zzzzz!",
}


def clip_name(text):
    return hashlib.sha1(text.encode("utf-8")).hexdigest()[:16] + ".mp3"


def write_wav(path, audio, rate):
    if audio.dtype != np.int16:
        audio = np.clip(audio, -1.0, 1.0)
        audio = (audio * 32767).astype(np.int16)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(audio.tobytes())


def pad(audio, rate, lead=0.08, tail=0.15):
    return np.concatenate([np.zeros(int(rate * lead), audio.dtype), audio,
                           np.zeros(int(rate * tail), audio.dtype)])


def to_mp3(wav_path, mp3_path, quality=6):
    """MP3 plays everywhere: Android, iPad/iPhone Safari and desktop browsers."""
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", wav_path, "-ac", "1", "-ar", "22050",
                    "-c:a", "libmp3lame", "-q:a", str(quality), mp3_path], check=True)


def active_region(audio, rate, rel=0.05):
    """(start, end) sample indices of the voiced part of a clip."""
    a = np.abs(audio)
    w = max(1, int(rate * 0.02))
    env = np.array([a[i:i + w].max() for i in range(0, len(a), w)])
    if env.size == 0 or env.max() <= 0:
        return 0, len(audio)
    on = np.where(env > rel * env.max())[0]
    return int(on[0] * w), int(min(len(audio), (on[-1] + 1) * w))


def cut_at_gap(audio, rate, gap=0.35, rel=0.05):
    """Keep only the first voiced stretch: the model sometimes appends a
    garbled second segment after a long silence on very short inputs."""
    a = np.abs(audio)
    w = max(1, int(rate * 0.02))
    env = np.array([a[i:i + w].max() for i in range(0, len(a), w)])
    if env.size == 0 or env.max() <= 0:
        return audio
    idx = np.where(env > rel * env.max())[0]
    last = idx[0]
    for i in idx[1:]:
        if (i - last) * 0.02 > gap:
            break
        last = i
    return audio[:min(len(audio), (last + 1) * w + int(0.03 * rate))]


def count_phonemes(voice, text):
    return sum(len([c for c in s if c not in "ˈˌ ."]) for s in voice.phonemize(text))


def best_of(make, n_phonemes, rate, scale, tries=14, short=False):
    """VITS sampling is stochastic and very short utterances sometimes come
    out with long garbled tails. Generate candidates and keep the one whose
    voiced duration is closest to what the phoneme count predicts."""
    expected = 0.095 * n_phonemes * scale + 0.12
    best, best_score = None, None
    for i in range(tries):
        noise = 0.667 if i < 3 else 0.45
        noise_w = 0.8 if i < 3 else 0.4
        audio = make(SynthesisConfig(length_scale=scale, noise_scale=noise, noise_w_scale=noise_w), i)
        if short:
            audio = cut_at_gap(audio, rate)
        s, e = active_region(audio, rate)
        dur = (e - s) / rate
        score = abs(dur - expected) / expected
        if best_score is None or score < best_score:
            best, best_score = audio[max(0, s - int(0.04 * rate)):min(len(audio), e + int(0.08 * rate))], score
        if score < 0.35:
            break
    return best, best_score


def synth_text(voice, text, scale):
    words = text.strip()
    short = len(words.split()) <= 4
    # Very short inputs are unstable. Final punctuation helps; "!" gives the
    # cleanest single words, so short texts try both endings.
    base = words if words[-1:] in ".!?" else words + "."
    variants = [base]
    if short and base.endswith("."):
        variants = [base[:-1] + "!", base]
    n = count_phonemes(voice, base)

    def make(cfg, i):
        spoken = variants[i % len(variants)]
        return np.concatenate([c.audio_float_array for c in voice.synthesize(spoken, syn_config=cfg)])

    return best_of(make, n, voice.config.sample_rate, scale, short=short)


def synth_phonemes(voice, ipa, scale):
    id_map = voice.config.phoneme_id_map
    for ch in ipa:
        if ch not in id_map:
            raise SystemExit(f"phoneme {ch!r} not supported by voice")
    ids = voice.phonemes_to_ids(list(ipa))
    n = len([c for c in ipa if c not in "ˈˌ.!"])

    def make(cfg, i):
        return voice.phoneme_ids_to_audio(ids, cfg)

    return best_of(make, n, voice.config.sample_rate, scale, short=True)


def tone(freqs, dur, rate=22050, vol=0.35, decay=6.0):
    t = np.linspace(0, dur, int(rate * dur), endpoint=False)
    sig = np.zeros_like(t)
    for f in freqs:
        sig += np.sin(2 * math.pi * f * t) + 0.25 * np.sin(4 * math.pi * f * t)
    sig /= max(1, len(freqs)) * 1.25
    env = np.exp(-decay * t) * np.minimum(1.0, t / 0.01)
    return (sig * env * vol).astype(np.float32)


def seq(parts, rate=22050):
    return np.concatenate(parts + [np.zeros(int(rate * 0.05), np.float32)])


def make_sfx(out_dir, tmp):
    r = 22050
    sounds = {
        "correct": seq([tone([784], 0.12), tone([1047], 0.35)]),
        "wrong": seq([tone([392], 0.16, vol=0.22), tone([330], 0.3, vol=0.22)]),
        "complete": seq([tone([523], 0.12), tone([659], 0.12), tone([784], 0.12),
                         tone([1047, 1319], 0.6, decay=3.0)]),
        "tap": tone([880], 0.06, vol=0.2, decay=40),
        "star": seq([tone([1319], 0.08, vol=0.25), tone([1568], 0.08, vol=0.25),
                     tone([2093], 0.3, vol=0.25)]),
        "flip": tone([600, 900], 0.08, vol=0.18, decay=30),
    }
    for name, audio in sounds.items():
        wav = os.path.join(tmp, name + ".wav")
        write_wav(wav, audio, r)
        to_mp3(wav, os.path.join(out_dir, name + ".mp3"), quality=5)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", required=True)
    ap.add_argument("--speech", default="build/speech.json")
    ap.add_argument("--out", default="assets/audio")
    ap.add_argument("--force", action="store_true")
    args = ap.parse_args()

    voice = PiperVoice.load(args.model)
    if not voice.config.espeak_voice.startswith("en") or "en-us" in voice.config.espeak_voice:
        raise SystemExit("Refusing to use a non-British phonemizer voice: " + voice.config.espeak_voice)
    rate = voice.config.sample_rate
    report = []

    data = json.load(open(args.speech, encoding="utf-8"))
    speech_dir = os.path.join(args.out, "speech")
    letters_dir = os.path.join(args.out, "letters")
    sfx_dir = os.path.join(args.out, "sfx")
    for d in (speech_dir, letters_dir, sfx_dir):
        os.makedirs(d, exist_ok=True)

    manifest = {}
    with tempfile.TemporaryDirectory() as tmp:
        wav = os.path.join(tmp, "x.wav")
        for i, text in enumerate(data["texts"]):
            name = clip_name(text)
            manifest[text] = name
            target = os.path.join(speech_dir, name)
            if os.path.exists(target) and not args.force:
                continue
            audio, score = synth_text(voice, text, LENGTH_SCALE)
            report.append((score, text))
            write_wav(wav, pad(audio, rate), rate)
            to_mp3(wav, target)
            if i % 50 == 0:
                print(f"{i}/{len(data['texts'])}", flush=True)

        for letter in LETTER_NAMES:
            # Letter names: espeak reads a capital letter as its British name
            # (e.g. "Z." -> /zˈɛd/), which is more stable than raw phonemes.
            audio, score = synth_text(voice, letter.upper() + "!", 1.1)
            report.append((score, "name " + letter))
            write_wav(wav, pad(audio, rate, tail=0.2), rate)
            to_mp3(wav, os.path.join(letters_dir, f"name_{letter}.mp3"))
            audio, score = synth_phonemes(voice, LETTER_SOUNDS[letter], 1.3)
            report.append((score, "sound " + letter))
            write_wav(wav, pad(audio, rate, tail=0.2), rate)
            to_mp3(wav, os.path.join(letters_dir, f"sound_{letter}.mp3"))

        make_sfx(sfx_dir, tmp)

    # Remove stale clips that are no longer referenced.
    keep = set(manifest.values())
    for f in os.listdir(speech_dir):
        if f not in keep:
            os.remove(os.path.join(speech_dir, f))

    with open(os.path.join(args.out, "speech_manifest.json"), "w", encoding="utf-8") as f:
        json.dump({"voice": "en_GB-cori-high (Piper)", "locale": "en-GB",
                   "clips": manifest}, f, ensure_ascii=False, indent=0, sort_keys=True)
    report.sort(reverse=True)
    print("worst duration mismatches (score = relative error):")
    for sc, t in report[:15]:
        print(f"  {sc:.2f}  {t!r}")
    print(f"done: {len(manifest)} clips")


if __name__ == "__main__":
    main()
