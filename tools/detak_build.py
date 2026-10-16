#!/usr/bin/env python3
"""Build Detak layered sprites from the source character renders.

Source:  ~/workspace/detak-assets/raga-characters/detak/  (16 PNGs, 1024x1024 RGBA)
Output:  ~/workspace/raga/assets/images/detak/            (30 PNGs, 512x512 RGBA)

The source files are full-character renders (not layers), but their geometry
is pixel-identical, so layers are decomposed programmatically:

1. detak_{expr}_{color}.png (24) — body+face, recolored via hue-shift
   (target hue sampled from the warna-* reference files, shading preserved),
   sprout erased, gauge needle erased.
2. detak_tunas_{1..4}.png (4) — sprout-only overlays (color independent).
3. detak_acc_{kacamata,pita}.png (2) — accessory-only overlays.

Runtime composites Stack[body, tunas, accessory] -> 288 combos from 30 files.
The gauge needle is drawn dynamically in Flutter (CustomPainter); its pivot
(in fractions of the sprite) is printed by this script — keep in sync with
lib/detak/detak_widget.dart (kNeedlePivot).
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image

SRC = Path.home() / "workspace/detak-assets/raga-characters/detak"
OUT = Path.home() / "workspace/raga/assets/images/detak"
SIZE = 512

EXPRS = ["halo", "senang", "semangat", "ngantuk", "dukung", "bangga"]
COLORS = ["lavender", "langit", "mint", "persik"]
STAGE_FILES = {
    1: "tahap-1-kuncup",
    2: "tahap-2-dua-daun",
    3: "tahap-3-rimbun",
    4: "tahap-4-berbunga",
}

YY, XX = np.mgrid[0:1024, 0:1024]


def load(rel: str) -> np.ndarray:
    return np.array(Image.open(SRC / rel).convert("RGBA")).astype(np.float32)


def rgb_to_hls(rgb: np.ndarray):
    r, g, b = rgb[..., 0] / 255, rgb[..., 1] / 255, rgb[..., 2] / 255
    mx = np.maximum(np.maximum(r, g), b)
    mn = np.minimum(np.minimum(r, g), b)
    l = (mx + mn) / 2
    d = mx - mn
    s = np.zeros_like(l)
    m = d > 1e-6
    s[m] = np.where(l[m] <= 0.5, d[m] / (mx[m] + mn[m] + 1e-9),
                    d[m] / (2 - mx[m] - mn[m] + 1e-9))
    h = np.zeros_like(l)
    m1 = m & (mx == r)
    h[m1] = ((g[m1] - b[m1]) / d[m1]) % 6
    m2 = m & (mx == g)
    h[m2] = (b[m2] - r[m2]) / d[m2] + 2
    m3 = m & (mx == b)
    h[m3] = (r[m3] - g[m3]) / d[m3] + 4
    return (h * 60) % 360, l, s


def hls_to_rgb(h, l, s):
    h = (h % 360) / 360

    def hue2p(p, q, t):
        t = t % 1.0
        out = np.where(t < 1 / 6, p + (q - p) * 6 * t, 0.0)
        out = np.where((t >= 1 / 6) & (t < 1 / 2), q, out)
        out = np.where((t >= 1 / 2) & (t < 2 / 3), p + (q - p) * (2 / 3 - t) * 6, out)
        out = np.where(t >= 2 / 3, p, out)
        return out

    q = np.where(l < 0.5, l * (1 + s), l + s - l * s)
    p = 2 * l - q
    return (np.stack([hue2p(p, q, h + 1 / 3), hue2p(p, q, h),
                      hue2p(p, q, h - 1 / 3)], -1) * 255)


def save(arr: np.ndarray, name: str):
    im = Image.fromarray(arr.clip(0, 255).astype(np.uint8))
    im = im.resize((SIZE, SIZE), Image.LANCZOS)
    im.save(OUT / name)
    print(f"  wrote {name}")


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)

    # ---- sample target hues from the warna-* reference renders ----
    ref_hue = {}
    for c in COLORS:
        arr = load(f"variants/warna-{c}.png")
        H, L, S = rgb_to_hls(arr[..., :3])
        m = (arr[..., 3] > 16) & (S > 0.25) & (L > 0.30) & (L < 0.95)
        ref_hue[c] = float(np.median(H[m]))
        print(f"ref hue {c}: {ref_hue[c]:.1f} (px {m.sum()})")

    src = load("detak-halo.png")
    H0, L0, S0 = rgb_to_hls(src[..., :3])
    src_body = (src[..., 3] > 16) & (H0 >= 240) & (H0 <= 300) & (S0 > 0.20) \
        & (L0 > 0.28) & (L0 < 0.96)
    src_hue = float(np.median(H0[src_body]))
    print(f"src hue (lavender): {src_hue:.1f}")

    pivot = None
    for expr in EXPRS:
        arr = load(f"detak-{expr}.png")
        H, L, S = rgb_to_hls(arr[..., :3])
        opaque = arr[..., 3] > 16
        for color in COLORS:
            shift = ref_hue[color] - src_hue
            out = arr.copy()
            body = opaque & (H >= 240) & (H <= 300) & (S > 0.20) \
                & (L > 0.28) & (L < 0.96)
            rgb2 = hls_to_rgb((H + shift) % 360, L, S)
            tmp = out[body]
            tmp[:, :3] = rgb2[body]
            out[body] = tmp

            # erase old sprout (green pixels in the sprout bbox)
            sprout_zone = (XX >= 350) & (XX <= 700) & (YY >= 40) & (YY <= 360)
            out[sprout_zone & (H >= 85) & (H <= 170) & (S > 0.25), 3] = 0

            # erase gauge needle (near-white pixels in the gauge bbox)
            # gauge sits around x~510,y~785; needle points up (varies per expr)
            gauge_zone = (XX >= 460) & (XX <= 570) & (YY >= 690) & (YY <= 860)
            needle = gauge_zone & opaque & (L > 0.82) & (S < 0.22)
            if expr == "halo" and color == "lavender":
                ys, xs = np.where(needle)
                if len(xs) == 0:
                    print("ERROR: needle mask empty!", file=sys.stderr)
                    return 1
                bulb = needle & (XX >= 488) & (XX <= 532) & (YY >= 788) & (YY <= 848)
                bys, bxs = np.where(bulb)
                pivot = (float(bxs.mean()) / 1024, float(bys.mean()) / 1024)
                print(f"needle px: {len(xs)} pivot: ({pivot[0]:.4f}, {pivot[1]:.4f})")
            out[needle, 3] = 0

            save(out, f"detak_{expr}_{color}.png")

    # ---- sprout-only overlays (color independent) ----
    for stage, fname in STAGE_FILES.items():
        arr = load(f"variants/{fname}.png")
        H, L, S = rgb_to_hls(arr[..., :3])
        zone = (XX >= 330) & (XX <= 720) & (YY >= 20) & (YY <= 380)
        purple = (H >= 240) & (H <= 300) & (S > 0.15)
        m = zone & (arr[..., 3] > 16) & (~purple)
        ov = np.zeros((1024, 1024, 4), dtype=np.float32)
        ov[m] = arr[m]
        save(ov, f"detak_tunas_{stage}.png")

    # ---- glasses overlay: diff vs the neutral lavender base.
    # Geometry is pixel-identical, so changed pixels are the frames only
    # (the hollow rings leave the eyes untouched).
    base = load("variants/warna-lavender.png")
    arr = load("variants/aksesori-kacamata.png")
    diff = np.abs(arr[..., :3] - base[..., :3]).sum(axis=-1)
    keep = (arr[..., 3] > 16) & (diff > 30)
    print(f"glasses: kept {int(keep.sum())} px")
    ov = np.zeros((1024, 1024, 4), dtype=np.float32)
    ov[keep] = arr[keep]
    save(ov, "detak_acc_kacamata.png")

    # ---- bow overlay: same diff trick (pink bow on the head) ----
    arr = load("variants/aksesori-pita.png")
    diff = np.abs(arr[..., :3] - base[..., :3]).sum(axis=-1)
    pink = (arr[..., 3] > 16) & (diff > 30)
    print(f"bow: {int(pink.sum())} px")
    ov = np.zeros((1024, 1024, 4), dtype=np.float32)
    ov[pink] = arr[pink]
    save(ov, "detak_acc_pita.png")

    if pivot:
        print(f"kNeedlePivot = Offset({pivot[0]:.4f}, {pivot[1]:.4f})")
    print("done.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
