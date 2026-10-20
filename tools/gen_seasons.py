#!/usr/bin/env python3
"""Membuat variasi musim (panas, gugur, dingin) dari sprite dasar (musim semi) + hiasan musiman. CC0.

Pakai:  python3 tools/gen_world.py && python3 tools/gen_seasons.py
Hasil:  assets/sprites/<nama>_summer|autumn|winter.png, sunflowers, leaf_pile, snowman, snow_pile
"""
import colorsys
import os
import random
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_characters import outline  # noqa: E402
from gen_sprites import OUT, Canvas, hx  # noqa: E402

SEASONAL = ["grass", "grass_field", "tree_oak", "tree_pine", "bush", "path", "water", "fence_h"]
FOLIAGE = {"tree_oak", "tree_pine", "bush"}
SNOW = (236, 243, 250)


def mix(a, b, t):
    return tuple(int(a[i] * (1 - t) + b[i] * t) for i in range(3))


def is_green(h, s):
    return 0.17 < h < 0.50 and s > 0.22


def recolor(name, season):
    img = Image.open(os.path.join(OUT, name + ".png")).convert("RGBA")
    px = img.load()
    w, h = img.size
    rng = random.Random(hash((name, season)) & 0xFFFF)
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            hh, ss, vv = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            new = (r, g, b)
            if name in ("water",):
                if season == "winter":      # kolam membeku
                    ice = (205, 228, 244)
                    new = mix((r, g, b), ice, 0.62)
                    if (x * 5 + y * 3) % 23 == 0:
                        new = (250, 253, 255)
                elif season == "summer":
                    new = mix((r, g, b), (40, 170, 220), 0.18)
                elif season == "autumn":
                    new = mix((r, g, b), (70, 110, 150), 0.18)
            elif name == "path":
                if season == "winter":
                    new = mix((r, g, b), (240, 244, 248), 0.45)
                elif season == "autumn":
                    new = mix((r, g, b), (170, 120, 80), 0.18)
            elif name == "fence_h":
                if season == "winter" and y < 6 + (h // 8):
                    new = mix((r, g, b), SNOW, 0.8)
            elif is_green(hh, ss):
                if season == "summer":
                    nh = max(0.0, hh - 0.012)
                    new = tuple(int(c * 255) for c in colorsys.hsv_to_rgb(nh, min(1.0, ss * 1.12), min(1.0, vv * 1.05)))
                elif season == "autumn":
                    if name in FOLIAGE:
                        pick = rng.random()
                        hue = 0.11 if pick < 0.4 else (0.065 if pick < 0.8 else 0.02)
                        hue += (vv - 0.5) * 0.04
                        new = tuple(int(c * 255) for c in colorsys.hsv_to_rgb(hue, min(1.0, 0.75 + ss * 0.2), min(1.0, vv * 1.08)))
                    else:   # rumput kering
                        hue = 0.135 + (rng.random() - 0.5) * 0.02
                        new = tuple(int(c * 255) for c in colorsys.hsv_to_rgb(hue, ss * 0.62, vv * 0.96))
                elif season == "winter":
                    if name in FOLIAGE:
                        t = 0.78 if vv > 0.5 else 0.40
                        if name == "tree_oak" and y > h * 0.62:
                            t = 0.30
                    else:
                        t = 0.86
                    shade = 0.80 + vv * 0.32
                    snow = tuple(min(255, int(c * shade)) for c in SNOW)
                    new = mix((r, g, b), snow, t)
            px[x, y] = new + (a,)
    img.save(os.path.join(OUT, "%s_%s.png" % (name, season)))


# --------------------------------------------------------- hiasan musiman
def make_sunflowers():
    cv = Canvas(16, 24)
    for x, top in ((3, 6), (8, 2), (12, 8)):
        cv.vline(x, top + 3, 24 - top - 3, hx("3f8f3f"))
        cv.px(x - 1, top + 9, hx("3f8f3f"))
        cv.px(x + 1, top + 12, hx("3f8f3f"))
        cv.d.ellipse([x - 3, top - 1, x + 3, top + 5], fill=hx("f0c020"))
        cv.d.ellipse([x - 1, top + 1, x + 1, top + 3], fill=hx("6a4018"))
        cv.px(x, top - 1, hx("f8e060"))
    outline(cv, hx("3a3a10"))
    cv.save("sunflowers")


def make_leaf_pile():
    cv = Canvas(16, 16)
    rng = random.Random(9)
    cv.d.ellipse([1, 6, 14, 14], fill=hx("c8701e"))
    cv.d.ellipse([3, 4, 12, 11], fill=hx("e08a2a"))
    for _ in range(26):
        x, y = rng.randrange(2, 14), rng.randrange(5, 13)
        cv.px(x, y, rng.choice([hx("b8481e"), hx("f0b030"), hx("c8701e"), hx("a83a18")]))
    outline(cv, hx("4a2410"))
    cv.save("leaf_pile")


def make_snowman():
    cv = Canvas(16, 24)
    white, shade = hx("f4f8fc"), hx("c8d8ea")
    cv.d.ellipse([2, 12, 13, 23], fill=white)
    cv.d.ellipse([3, 6, 12, 15], fill=white)
    cv.d.ellipse([4, 1, 11, 8], fill=white)
    cv.d.ellipse([8, 15, 13, 22], fill=shade)
    cv.px(6, 4, hx("2a1a14"))
    cv.px(9, 4, hx("2a1a14"))
    cv.rect(7, 5, 3, 1, hx("f08a1a"))
    for y in (9, 12, 15):
        cv.px(7, y, hx("2a1a14"))
    cv.rect(4, 0, 8, 1, hx("2a2a30"))      # topi
    cv.rect(5, -1 + 1, 6, 1, hx("2a2a30"))
    cv.hline(3, 7, 10, hx("d94a3d"))       # syal
    cv.vline(11, 7, 4, hx("d94a3d"))
    cv.d.line([(1, 10), (3, 11)], fill=hx("6a4018"))
    cv.d.line([(14, 10), (12, 11)], fill=hx("6a4018"))
    outline(cv, hx("46586e"))
    cv.save("snowman")


def make_snow_pile():
    cv = Canvas(16, 16)
    cv.d.ellipse([1, 7, 14, 15], fill=hx("f4f8fc"))
    cv.d.ellipse([3, 5, 11, 12], fill=hx("ffffff"))
    cv.d.ellipse([8, 9, 14, 15], fill=hx("d8e4f0"))
    for x, y in ((4, 8), (7, 7), (10, 10)):
        cv.px(x, y, hx("c0d4e8"))
    outline(cv, hx("6e84a0"))
    cv.save("snow_pile")


def make_forest_ground():
    """Rumput hutan: lebih gelap dan kebiruan dari rumput biasa."""
    img = Image.open(os.path.join(OUT, "grass.png")).convert("RGBA")
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            h, s_, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            if is_green(h, s_):
                nr, ng, nb = colorsys.hsv_to_rgb(min(0.5, h + 0.035), min(1.0, s_ * 1.05), v * 0.74)
                px[x, y] = (int(nr * 255), int(ng * 255), int(nb * 255), a)
    img.save(os.path.join(OUT, "grass_forest.png"))


if __name__ == "__main__":
    for n in SEASONAL:
        for season in ("summer", "autumn", "winter"):
            recolor(n, season)
    make_forest_ground()
    make_sunflowers()
    make_leaf_pile()
    make_snowman()
    make_snow_pile()
    print("selesai:", len([f for f in os.listdir(OUT) if f.endswith(("_summer.png", "_autumn.png", "_winter.png"))]), "variasi")
