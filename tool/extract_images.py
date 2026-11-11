#!/usr/bin/env python3
"""Extract original textbook illustrations from the bundled PDF.

The interactive learning layer re-uses the *original* illustrations of
"English for Iraq - 1st Primary - Pupil's Book" (no generated artwork).
Images are cropped from rendered PDF pages; the PDF itself is never modified.

Usage:  python3 tool/extract_images.py [--pdf PATH] [--out assets/images]
Requires: poppler-utils (pdftoppm) and Pillow.
"""
import argparse
import os
import subprocess
import tempfile

from PIL import Image, ImageChops

DPI = 200
# Crop boxes below are expressed in a 827 x 1170 reference frame (an A4 page
# displayed at 827 px wide). They are scaled to the render resolution.
REF_W = 827.0

# Picture dictionary (PDF pages 94-96): rows of [left word, right word].
DICTIONARY = {
    94: [("apple", "ant"), ("ball", "bus"), ("car", "cat"), ("dog", "duck"),
         ("egg", "elephant"), ("flower", "fish"), ("girl", "goat"), ("horse", "house")],
    95: [("ink", "in"), ("juice", "jumper"), ("key", "kite"), ("lemon", "lion"),
         ("monkey", "moon"), ("net", "nose"), ("orange", "olive"), ("plane", "pizza")],
    96: [("question", "queen"), ("robot", "rabbit"), ("snake", "sun"), ("taxi", "tomato"),
         ("umbrella", "up"), ("van", "violin"), ("window", "watch"), ("x-ray", "yo-yo"),
         ("zebra", None)],
}
# Horizontal bands (reference frame) where the dictionary pictures sit, per page.
DICT_BANDS = {
    94: {"left": (95, 285), "right": (415, 585)},
    95: {"left": (95, 250), "right": (415, 560)},
    96: {"left": (95, 262), "right": (430, 575)},
}

# Topic vocabulary crops: name -> (pdf page, (x0, y0, x1, y1)) in reference frame.
TOPIC_CROPS = {
    # Override: the picture-dictionary egg is a faint outline the segmenter cannot isolate.
    "egg": (94, (150, 598, 248, 700)),
    # Unit 2 - classroom objects (page 21 top row, page 19 labelled scene)
    "book": (21, (145, 370, 205, 437)),
    "bin": (21, (228, 376, 276, 432)),
    "desk": (21, (308, 352, 458, 444)),
    "chair": (21, (488, 336, 572, 440)),
    "cd": (21, (600, 370, 655, 420)),
    "bag": (19, (168, 712, 272, 836)),
    "pencil_case": (19, (438, 655, 532, 712)),
    "rubber": (19, (498, 706, 558, 744)),
    "pen": (19, (378, 712, 452, 744)),
    "pencil": (19, (515, 750, 595, 780)),
    "ruler": (19, (365, 605, 415, 700)),
    # Unit 3 - toys (page 28)
    "balloon": (28, (236, 328, 302, 418)),
    "skates": (28, (328, 378, 424, 457)),
    "bike": (28, (423, 316, 539, 414)),
    "doll": (28, (518, 360, 588, 470)),
    "toy": (28, (300, 690, 535, 805)),
    # Unit 5 - animals and adjectives (pages 45, 46)
    "camel": (46, (418, 815, 557, 965)),
    "tiger": (45, (160, 820, 315, 918)),
    "penguin": (45, (548, 795, 606, 858)),
    "funny": (46, (128, 815, 292, 965)),
    "little": (46, (292, 815, 418, 965)),
    "big": (46, (418, 815, 557, 965)),
    "long": (46, (557, 815, 724, 965)),
    # Unit 6 - body (page 56)
    "head": (56, (148, 128, 258, 282)),
    "toes": (56, (266, 150, 412, 272)),
    "ears": (56, (418, 128, 548, 282)),
    "nose_robot": (56, (578, 128, 708, 300)),
    "hands": (56, (133, 843, 268, 1002)),
    "eyes": (56, (432, 828, 543, 1006)),
    # Unit 7 - family (page 64)
    "dad": (64, (153, 343, 320, 480)),
    "mum": (64, (330, 343, 497, 480)),
    "sister": (64, (508, 343, 677, 480)),
    "brother": (64, (173, 528, 342, 668)),
    "grandma": (64, (348, 528, 520, 668)),
    "grandpa": (64, (526, 528, 694, 668)),
    "family": (64, (134, 740, 728, 1062)),
    # Unit 7 - in the house (pages 68, 69)
    "bed": (68, (176, 805, 356, 918)),
    "table": (68, (543, 835, 712, 948)),
    "roof": (69, (88, 92, 645, 395)),
    "door": (69, (222, 512, 405, 765)),
    "house_painting": (69, (88, 92, 700, 975)),
}

# Alphabet picture cards (pages 6-7), card grid in reference frame.
CARD_PAGES = {
    6: {"letters": "abcdefghijkl", "cols": [(100, 248), (272, 420), (445, 593), (617, 765)],
        "rows": [(105, 300), (325, 518), (543, 737)]},
    7: {"letters": "mnopqrstuvwx", "cols": [(94, 242), (266, 414), (437, 586), (609, 757)],
        "rows": [(99, 294), (318, 512), (537, 730)]},
}
EXTRA_CARDS = {"y": (7, (265, 755, 414, 948)), "z": (7, (437, 755, 586, 948))}


def render(pdf, page, tmp):
    base = os.path.join(tmp, f"p{page}")
    subprocess.run(["pdftoppm", "-r", str(DPI), "-f", str(page), "-l", str(page),
                    "-png", "-singlefile", pdf, base], check=True)
    return Image.open(base + ".png").convert("RGB")


def content_mask(img, thresh=232, sat=28):
    """Mask of pixels that are not near-white (dark or clearly coloured)."""
    rgb = img.convert("RGB")
    r, g, b = rgb.split()
    mx = ImageChops.lighter(ImageChops.lighter(r, g), b)
    mn = ImageChops.darker(ImageChops.darker(r, g), b)
    chroma = ImageChops.subtract(mx, mn).point(lambda v: 255 if v > sat else 0)
    dark = rgb.convert("L").point(lambda v: 255 if v < thresh else 0)
    return ImageChops.lighter(chroma, dark)


def trim(img, pad=8):
    """Trim near-white margins."""
    box = content_mask(img).getbbox()
    if not box:
        return img
    x0, y0, x1, y1 = box
    return img.crop((max(0, x0 - pad), max(0, y0 - pad),
                     min(img.width, x1 + pad), min(img.height, y1 + pad)))


def save(img, path, max_side=420):
    img = img.copy()
    img.thumbnail((max_side, max_side), Image.LANCZOS)
    img.save(path, "WEBP", quality=88, method=6)


def segment_rows(img, x0, x1, min_gap, min_h):
    """Find vertical runs of non-white content within a band."""
    band = content_mask(img.crop((x0, 0, x1, img.height)))
    w, h = band.size
    px = band.load()
    rows = []
    for y in range(h):
        dark = 0
        for x in range(0, w, 2):
            if px[x, y]:
                dark += 1
                if dark > 2:
                    break
        rows.append(dark > 2)
    runs, start, gap = [], None, 0
    for y, on in enumerate(rows):
        if on:
            if start is None:
                start = y
            gap = 0
        elif start is not None:
            gap += 1
            if gap > min_gap:
                end = y - gap
                if end - start >= min_h:
                    runs.append((start, end))
                start, gap = None, 0
    if start is not None:
        runs.append((start, h - 1))
    return runs


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--pdf", default="assets/book/english_for_iraq_1st_primary_pupils_book.pdf")
    ap.add_argument("--out", default="assets/images")
    args = ap.parse_args()
    words_dir = os.path.join(args.out, "words")
    cards_dir = os.path.join(args.out, "letters")
    os.makedirs(words_dir, exist_ok=True)
    os.makedirs(cards_dir, exist_ok=True)

    with tempfile.TemporaryDirectory() as tmp:
        pages = {}

        def page(n):
            if n not in pages:
                pages[n] = render(args.pdf, n, tmp)
            return pages[n]

        def scale_box(img, box):
            s = img.width / REF_W
            return tuple(int(round(v * s)) for v in box)

        # 1. Picture dictionary.
        for pg, rows in DICTIONARY.items():
            img = page(pg)
            s = img.width / REF_W
            top = int(120 * s)  # skip the page title
            for side, idx in (("left", 0), ("right", 1)):
                bx0, bx1 = (int(v * s) for v in DICT_BANDS[pg][side])
                sub = img.crop((bx0, top, bx1, int(1040 * s)))
                runs = segment_rows(sub, 0, sub.width, min_gap=int(10 * s), min_h=int(25 * s))
                names = [r[idx] for r in rows if r[idx]]
                if len(runs) != len(names):
                    raise SystemExit(f"page {pg} {side}: found {len(runs)} pictures, expected {len(names)}: {runs}")
                for name, (y0, y1) in zip(names, runs):
                    crop = trim(sub.crop((0, y0, sub.width, y1 + 1)))
                    save(crop, os.path.join(words_dir, name.replace("-", "_") + ".webp"))

        # 2. Topic vocabulary crops.
        for name, (pg, box) in TOPIC_CROPS.items():
            img = page(pg)
            save(img.crop(scale_box(img, box)), os.path.join(words_dir, name + ".webp"), max_side=520)

        # 3. Alphabet cards.
        for pg, spec in CARD_PAGES.items():
            img = page(pg)
            i = 0
            for (y0, y1) in spec["rows"]:
                for (x0, x1) in spec["cols"]:
                    letter = spec["letters"][i]
                    i += 1
                    save(img.crop(scale_box(img, (x0 + 4, y0 + 4, x1 - 4, y1 - 4))),
                         os.path.join(cards_dir, f"card_{letter}.webp"), max_side=360)
        for letter, (pg, box) in EXTRA_CARDS.items():
            img = page(pg)
            x0, y0, x1, y1 = box
            save(img.crop(scale_box(img, (x0 + 4, y0 + 4, x1 - 4, y1 - 4))),
                 os.path.join(cards_dir, f"card_{letter}.webp"), max_side=360)

    print("done")


if __name__ == "__main__":
    main()
