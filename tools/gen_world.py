#!/usr/bin/env python3
"""Membuat tekstur dan dekorasi dunia (CC0): tanah, pohon, pagar, air, tanaman, tambang.

Pakai:  python3 tools/gen_world.py
Hasil:  assets/sprites/*.png  (digambar pada grid 16 px/tile lalu diperbesar 2x)
"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_characters import outline  # noqa: E402
from gen_sprites import (BRICK, CREAM, OFFWHITE, OUT, OUTLINE, RED, SCALE, STONE, STONE_D,  # noqa: E402
                         STONE_L, WHITE, WOOD, WOOD_D, WOOD_HL, WOOD_L, Canvas, hx)

# ------------------------------------------------------------------ palet
GRASS, GRASS_D, GRASS_L = hx("5aa84e"), hx("4a9440"), hx("72c062")
LEAF, LEAF_D, LEAF_L = hx("3f8f3f"), hx("2c6a2c"), hx("5ccf62")
DIRT, DIRT_D, DIRT_L = hx("cdb07a"), hx("bf9f68"), hx("dcc08c")
SAND, SAND_D, SAND_L = hx("ecdca8"), hx("d8c690"), hx("f6eac0")
SOIL, SOIL_D, SOIL_L = hx("8a5a32"), hx("6e4624"), hx("a8723e")
WET, WET_D, WET_L = hx("5a3a1e"), hx("452b14"), hx("7a5232")
TRUNK, TRUNK_D, TRUNK_L = hx("7a4f2e"), hx("573820"), hx("9a6a3e")
TREE_LINE = hx("1f3a22")


def tile_noise(cv, rng, base_specks, count, wrap=True):
    for _ in range(count):
        x, y = rng.randrange(cv.w), rng.randrange(cv.h)
        cv.px(x % cv.w, y % cv.h, rng.choice(base_specks))


def tuft(cv, x, y, c):
    for dx, dy in ((0, 0), (-1, -1), (1, -1), (0, -1)):
        cv.px((x + dx) % cv.w, (y + dy) % cv.h, c)


# ----------------------------------------------------------------- tanah
def make_grass():
    rng = random.Random(3)
    cv = Canvas(32, 32)
    cv.rect(0, 0, 32, 32, GRASS)
    tile_noise(cv, rng, [GRASS_D, GRASS_L], 40)
    for _ in range(34):
        tuft(cv, rng.randrange(32), rng.randrange(32), rng.choice([GRASS_D, GRASS_L]))
    for _ in range(5):
        x, y = rng.randrange(32), rng.randrange(32)
        cv.px(x, y, rng.choice([hx("f7f3ea"), hx("f0d040"), hx("f090b0")]))
        cv.px((x + 1) % 32, y, hx("3f8f3f"))
    cv.save("grass")


def make_grass_field():
    rng = random.Random(4)
    cv = Canvas(32, 32)
    for y in range(32):
        cv.hline(0, y, 32, hx("57a64b") if (y // 8) % 2 == 0 else hx("5eae52"))
    tile_noise(cv, rng, [hx("4d9a42"), hx("6cba5c")], 30)
    for _ in range(10):
        tuft(cv, rng.randrange(32), rng.randrange(32), hx("4d9a42"))
    cv.save("grass_field")


def make_path():
    rng = random.Random(5)
    cv = Canvas(16, 16)
    cv.rect(0, 0, 16, 16, DIRT)
    tile_noise(cv, rng, [DIRT_D, DIRT_L, DIRT_D], 36)
    for _ in range(4):
        x, y = rng.randrange(14), rng.randrange(14)
        cv.rect(x, y, 2, 1, hx("a8a8a0"))
        cv.px(x, y + 1, hx("8a8a84"))
    cv.save("path")


def make_sand():
    rng = random.Random(6)
    cv = Canvas(32, 32)
    cv.rect(0, 0, 32, 32, SAND)
    tile_noise(cv, rng, [SAND_D, SAND_L], 60)
    for _ in range(4):
        x, y = rng.randrange(30), rng.randrange(30)
        cv.rect(x, y, 2, 1, hx("c8b080"))
    cv.save("sand")


def make_water():
    cv = Canvas(32, 16)   # dua bingkai 16x16
    for f in range(2):
        ox = f * 16
        cv.rect(ox, 0, 16, 16, hx("3d7fd8"))
        for y in range(0, 16, 4):
            cv.hline(ox, y + 2, 16, hx("3774c8"))
        # riak
        for (rx, ry) in ((2, 3), (9, 8), (4, 12), (12, 1)):
            sx = (rx + f * 3) % 14
            cv.hline(ox + sx, ry, 3, hx("78aef0"))
            cv.px(ox + sx + 3, ry + 1, hx("78aef0"))
    cv.save("water")


def make_soil():
    cv = Canvas(32, 16)   # [kering, basah]
    for f, (base, dark, light) in enumerate(((SOIL, SOIL_D, SOIL_L), (WET, WET_D, WET_L))):
        ox = f * 16
        cv.rect(ox, 0, 16, 16, base)
        for y in range(0, 16, 4):
            cv.hline(ox, y + 3, 16, dark)
            cv.hline(ox, y, 16, light if f == 0 else WET_L)
        rng = random.Random(10 + f)
        for _ in range(14):
            cv.px(ox + rng.randrange(16), rng.randrange(16), dark)
        cv.frame(ox, 0, 16, 16, dark)
        if f == 1:
            for sx in (3, 9, 13):
                cv.px(ox + sx, 5, hx("8a6a46"))
    cv.save("soil")


def make_cave_floor():
    rng = random.Random(8)
    cv = Canvas(16, 16)
    cv.rect(0, 0, 16, 16, hx("34343e"))
    tile_noise(cv, rng, [hx("2a2a33"), hx("42424e"), hx("2e2e38")], 50)
    cv.px(3, 4, hx("1e1e26"))
    cv.px(4, 5, hx("1e1e26"))
    cv.px(5, 5, hx("1e1e26"))
    cv.px(11, 11, hx("1e1e26"))
    cv.px(12, 12, hx("1e1e26"))
    cv.save("floor_cave")


def make_pier():
    cv = Canvas(16, 16)
    cv.rect(0, 0, 16, 16, hx("9a6a3e"))
    for y in range(0, 16, 4):
        cv.hline(0, y + 3, 16, hx("573820"))
        cv.hline(0, y, 16, hx("b78650"))
    cv.vline(5, 0, 16, hx("6e4524"))
    cv.vline(11, 0, 16, hx("6e4524"))
    for nx in (1, 8, 14):
        cv.px(nx, 1, hx("3a3a40"))
        cv.px(nx, 9, hx("3a3a40"))
    cv.rect(0, 0, 16, 1, hx("573820"))
    cv.rect(0, 15, 16, 1, hx("573820"))
    cv.save("pier")


# ----------------------------------------------------------------- pohon
def canopy(cv, cx, cy, rx, ry, dark=LEAF_D, mid=LEAF, light=LEAF_L):
    cv.d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=mid)
    cv.d.ellipse([cx - rx + 2, cy - ry + 3, cx + rx, cy + ry], fill=dark)       # bayangan bawah
    cv.d.ellipse([cx - rx, cy - ry, cx + rx - 3, cy + ry - 4], fill=mid)
    cv.d.ellipse([cx - rx + 2, cy - ry + 1, cx - 1, cy - 1], fill=light)         # sorot kiri-atas


def make_tree_oak():
    cv = Canvas(24, 32)
    # batang
    cv.rect(10, 21, 4, 10, TRUNK)
    cv.vline(10, 21, 10, TRUNK_L)
    cv.vline(13, 21, 10, TRUNK_D)
    cv.rect(8, 29, 8, 2, TRUNK)
    cv.px(8, 30, TRUNK_D)
    cv.px(15, 30, TRUNK_D)
    cv.hline(9, 30, 6, TRUNK_L)
    # tajuk
    canopy(cv, 12, 9, 10, 8)
    canopy(cv, 6, 14, 6, 6)
    canopy(cv, 18, 14, 6, 6)
    canopy(cv, 12, 17, 8, 5)
    # daun detail
    rng = random.Random(1)
    for _ in range(18):
        x, y = rng.randrange(3, 21), rng.randrange(3, 21)
        cv.px(x, y, LEAF_D if rng.random() < 0.5 else LEAF_L)
    outline(cv, TREE_LINE)
    cv.save("tree_oak")


def make_tree_pine():
    cv = Canvas(16, 32)
    cv.rect(7, 26, 3, 5, TRUNK)
    cv.vline(9, 26, 5, TRUNK_D)
    tiers = [(8, 2, 6), (8, 8, 8), (8, 14, 10), (8, 20, 12)]
    for cx, top, half in tiers:
        cv.d.polygon([(cx, top), (cx - half // 2 - 1, top + 8), (cx + half // 2 + 1, top + 8)], fill=hx("2f7a4a"))
        cv.d.polygon([(cx, top), (cx - half // 2 - 1, top + 8), (cx, top + 8)], fill=hx("3f9a5a"))
        cv.hline(cx - half // 2 - 1, top + 8, half + 3, hx("245f38"))
    outline(cv, TREE_LINE)
    cv.save("tree_pine")


def make_palm():
    cv = Canvas(24, 40)
    # batang melengkung
    pts = [(11, 38), (11, 30), (12, 22), (13, 15), (14, 10)]
    for i in range(len(pts) - 1):
        cv.d.line([pts[i], pts[i + 1]], fill=hx("a8743e"), width=3)
        cv.d.line([(pts[i][0] - 1, pts[i][1]), (pts[i + 1][0] - 1, pts[i + 1][1])], fill=hx("c8925a"), width=1)
    for y in range(14, 38, 4):
        cv.hline(11 + (38 - y) // 12 - 1 + (1 if y < 22 else 0), y, 3, hx("7a4f2a"))
    cv.rect(8, 37, 8, 2, hx("8a5a30"))
    # daun
    hubx, huby = 14, 9
    leaf, leaf_d = hx("3f9a4a"), hx("2a7038")
    for ang in (-170, -135, -100, -60, -25, 10):
        a = math.radians(ang)
        ex, ey = hubx + math.cos(a) * 10, huby + math.sin(a) * 6 + 6
        mx, my = hubx + math.cos(a) * 6, huby + math.sin(a) * 8
        cv.d.line([(hubx, huby), (mx, my), (ex, ey)], fill=leaf, width=3)
        cv.d.line([(hubx, huby + 1), (mx, my + 1), (ex, ey + 1)], fill=leaf_d, width=1)
    for cx, cy in ((12, 12), (15, 12), (13, 14)):
        cv.d.ellipse([cx - 1, cy - 1, cx + 1, cy + 1], fill=hx("7a4a24"))
    outline(cv, TREE_LINE)
    cv.save("palm")


def make_bush():
    cv = Canvas(16, 16)
    canopy(cv, 8, 9, 7, 5)
    canopy(cv, 5, 10, 4, 4)
    canopy(cv, 11, 10, 4, 4)
    for bx, by in ((5, 9), (9, 7), (11, 11)):
        cv.px(bx, by, RED)
    outline(cv, TREE_LINE)
    cv.save("bush")


def make_flowers(name, colors):
    cv = Canvas(16, 16)
    rng = random.Random(len(name))
    for _ in range(9):
        x, y = rng.randrange(2, 14), rng.randrange(5, 14)
        cv.vline(x, y, 3, LEAF)
        cv.px(x - 1, y + 1, LEAF_D)
        c = rng.choice(colors)
        cv.px(x, y - 1, c)
        cv.px(x - 1, y - 1, c)
        cv.px(x + 1, y - 1, c)
        cv.px(x, y - 2, c)
        cv.px(x, y - 1, hx("f0d040"))
    cv.save(name)


def make_rock_decor():
    cv = Canvas(16, 16)
    cv.d.ellipse([2, 6, 14, 14], fill=hx("8f8f93"))
    cv.d.ellipse([4, 4, 12, 11], fill=hx("a8a8ad"))
    cv.d.ellipse([3, 7, 10, 12], fill=hx("a0a0a6"))
    cv.hline(5, 5, 3, hx("d0d0d6"))
    cv.px(10, 10, hx("5a8a4a"))
    cv.px(11, 11, hx("5a8a4a"))
    cv.px(4, 12, hx("6e6e74"))
    outline(cv, hx("2a2a30"))
    cv.save("rock_decor")


def make_stump():
    cv = Canvas(16, 16)
    cv.rect(4, 7, 8, 7, TRUNK)
    cv.d.ellipse([4, 4, 11, 9], fill=hx("c8925a"))
    cv.d.ellipse([5, 5, 10, 8], fill=hx("dcb07a"))
    cv.d.ellipse([6, 6, 9, 7], fill=hx("c8925a"))
    cv.vline(5, 8, 5, TRUNK_L)
    cv.vline(10, 8, 5, TRUNK_D)
    cv.px(3, 13, TRUNK_D)
    cv.px(12, 13, TRUNK_D)
    outline(cv, hx("3a2616"))
    cv.save("stump")


def make_fence():
    wood, wood_d, wood_l = hx("e4d4a8"), hx("9a8658"), hx("f4e8c4")
    cv = Canvas(16, 16)
    cv.rect(0, 5, 16, 2, wood)
    cv.rect(0, 10, 16, 2, wood)
    cv.hline(0, 6, 16, wood_d)
    cv.hline(0, 11, 16, wood_d)
    for px_ in (1, 5, 9, 13):
        cv.rect(px_, 3, 3, 12, wood)
        cv.px(px_ + 1, 2, wood)
        cv.vline(px_, 3, 12, wood_l)
        cv.vline(px_ + 2, 3, 12, wood_d)
        cv.px(px_ + 1, 3, wood_l)
    cv.save("fence_h")

    cv = Canvas(16, 16)
    cv.rect(6, 0, 4, 16, wood)
    cv.vline(6, 0, 16, wood_l)
    cv.vline(9, 0, 16, wood_d)
    for y in (2, 10):
        cv.rect(4, y, 8, 4, wood)
        cv.hline(4, y + 3, 8, wood_d)
        cv.hline(4, y, 8, wood_l)
    cv.save("fence_v")


def make_signpost():
    cv = Canvas(24, 24)
    cv.rect(11, 6, 2, 17, WOOD)
    cv.vline(11, 6, 17, WOOD_L)
    cv.rect(1, 2, 22, 8, hx("e8d4a0"))
    cv.frame(1, 2, 22, 8, WOOD_D)
    cv.hline(2, 3, 20, hx("f4e8c4"))
    cv.rect(9, 21, 6, 2, hx("6e6e74"))
    outline(cv, hx("2a1a10"))
    cv.save("signpost")


def make_lamp():
    cv = Canvas(16, 32)
    iron = hx("3a3a44")
    cv.rect(7, 8, 2, 22, iron)
    cv.rect(5, 28, 6, 3, hx("4a4a56"))
    cv.rect(6, 26, 4, 2, hx("4a4a56"))
    cv.rect(4, 3, 8, 6, hx("f4e08a"))
    cv.rect(5, 4, 6, 4, hx("fff6c0"))
    cv.frame(4, 3, 8, 6, iron)
    cv.rect(3, 1, 10, 2, iron)
    cv.px(7, 0, iron)
    cv.px(8, 0, iron)
    outline(cv, hx("1a1a20"))
    cv.save("lamp")


def make_bench():
    cv = Canvas(32, 16)
    cv.rect(2, 3, 28, 4, WOOD_L)
    for x in range(4, 30, 7):
        cv.vline(x, 3, 4, WOOD_D)
    cv.hline(2, 3, 28, WOOD_HL)
    cv.rect(2, 8, 28, 3, WOOD)
    cv.hline(2, 8, 28, WOOD_HL)
    cv.hline(2, 10, 28, WOOD_D)
    for lx in (4, 26):
        cv.rect(lx, 11, 3, 4, WOOD_D)
        cv.rect(lx, 3, 2, 8, WOOD_D)
    outline(cv, hx("2a1a10"))
    cv.save("bench")


def make_bin():
    cv = Canvas(16, 16)
    cv.rect(1, 6, 14, 9, WOOD)
    cv.rect(1, 3, 14, 4, WOOD_L)
    cv.hline(1, 3, 14, WOOD_HL)
    cv.hline(1, 6, 14, WOOD_D)
    cv.vline(5, 3, 12, WOOD_D)
    cv.vline(10, 3, 12, WOOD_D)
    cv.rect(0, 9, 16, 2, hx("6e6e74"))
    cv.rect(6, 7, 4, 4, hx("f0d040"))
    cv.px(7, 8, hx("b8932f"))
    cv.px(8, 9, hx("b8932f"))
    outline(cv, hx("2a1a10"))
    cv.save("bin")


def make_fountain():
    cv = Canvas(48, 32)
    cv.d.ellipse([1, 8, 46, 31], fill=STONE_D)
    cv.d.ellipse([1, 6, 46, 28], fill=STONE_L)
    cv.d.ellipse([4, 9, 43, 25], fill=hx("3d7fd8"))
    cv.d.ellipse([6, 11, 41, 24], fill=hx("56a0ee"))
    for rx, ry in ((12, 17), (30, 19), (22, 21)):
        cv.hline(rx, ry, 5, hx("9cc8f8"))
    cv.rect(21, 4, 6, 14, STONE)
    cv.rect(21, 4, 2, 14, STONE_L)
    cv.rect(19, 3, 10, 3, STONE_L)
    cv.rect(23, 0, 2, 4, hx("9cc8f8"))
    for dx, dy in ((-2, 1), (2, 1), (-4, 3), (4, 3), (-5, 6), (5, 6)):
        cv.px(24 + dx, 2 + dy, hx("cfe6fc"))
    for x in range(3, 45, 5):
        cv.hline(x, 25 if x % 10 else 26, 3, STONE)
    outline(cv, hx("2a2a30"))
    cv.save("fountain")


def make_well():
    cv = Canvas(32, 32)
    # cincin batu
    cv.d.ellipse([4, 17, 27, 31], fill=STONE_D)
    cv.d.ellipse([4, 15, 27, 28], fill=STONE_L)
    cv.d.ellipse([8, 17, 23, 25], fill=hx("1c2a3a"))
    cv.d.ellipse([9, 18, 22, 24], fill=hx("2a4a70"))
    for x in range(6, 26, 4):
        cv.vline(x, 24, 5, STONE_D)
    # rangka & atap
    cv.rect(5, 6, 2, 18, WOOD_D)
    cv.rect(25, 6, 2, 18, WOOD_D)
    cv.rect(5, 6, 2, 18, WOOD)
    cv.vline(5, 6, 18, WOOD_L)
    cv.rect(13, 12, 6, 1, hx("c8b078"))
    cv.vline(16, 12, 5, hx("c8b078"))
    cv.rect(14, 17, 4, 3, hx("8a5a30"))
    cv.d.polygon([(2, 8), (16, 0), (30, 8)], fill=hx("a8433a"))
    cv.d.polygon([(2, 8), (16, 0), (16, 8)], fill=hx("c85a4a"))
    cv.hline(2, 8, 29, hx("6a2a22"))
    outline(cv, hx("2a1a14"))
    cv.save("well")


def make_shells():
    cv = Canvas(16, 16)
    cv.d.polygon([(4, 6), (6, 9), (4, 12), (7, 10), (10, 12), (9, 9), (11, 7), (8, 8), (7, 5)], fill=hx("f0a030"))
    cv.px(7, 8, hx("c87a1a"))
    cv.d.ellipse([10, 10, 14, 13], fill=hx("f4c8d0"))
    cv.hline(10, 11, 4, hx("e8a0b0"))
    cv.px(12, 10, hx("ffffff"))
    outline(cv, hx("8a6a3a"))
    cv.save("shells")


def make_driftwood():
    cv = Canvas(16, 16)
    cv.rect(1, 8, 13, 4, hx("b09068"))
    cv.hline(1, 8, 13, hx("d0b088"))
    cv.hline(1, 11, 13, hx("8a6a48"))
    cv.px(3, 9, hx("8a6a48"))
    cv.px(8, 10, hx("8a6a48"))
    cv.rect(11, 5, 2, 4, hx("b09068"))
    outline(cv, hx("5a4028"))
    cv.save("driftwood")


def make_umbrella():
    cv = Canvas(32, 32)
    cv.vline(15, 8, 22, hx("c8b078"))
    cv.vline(16, 8, 22, hx("a89058"))
    cv.d.pieslice([2, 1, 29, 22], 180, 360, fill=hx("d94a3d"))
    for x0, x1 in ((2, 8), (14, 19), (25, 29)):
        cv.d.pieslice([2, 1, 29, 22], 180, 360, fill=hx("d94a3d"))
    # belang putih
    for ang0, ang1 in ((205, 225), (255, 275), (305, 325)):
        cv.d.pieslice([2, 1, 29, 22], ang0, ang1, fill=hx("f7f3ea"))
    cv.d.polygon([(4, 12), (7, 14), (10, 12), (13, 14), (16, 12), (19, 14), (22, 12), (25, 14), (28, 12), (28, 11), (4, 11)],
                 fill=hx("d94a3d"))
    cv.rect(2, 28, 28, 3, hx("5a9ae0"))      # handuk
    cv.hline(2, 28, 28, hx("f7f3ea"))
    cv.hline(2, 30, 28, hx("3f78c0"))
    outline(cv, hx("3a2418"))
    cv.save("umbrella")


def make_reeds():
    cv = Canvas(16, 16)
    for x, h in ((4, 11), (7, 13), (10, 10), (13, 12)):
        cv.vline(x, 15 - h, h, hx("5a8a3a"))
        cv.rect(x - 1, 15 - h - 3, 3, 4, hx("7a4a24"))
        cv.px(x, 15 - h - 4, hx("9a6a3e"))
    cv.hline(2, 15, 13, hx("3f6a2a"))
    outline(cv, hx("1f3a22"))
    cv.save("reeds")


def make_lily():
    cv = Canvas(16, 16)
    cv.d.ellipse([3, 6, 12, 12], fill=hx("4aa84a"))
    cv.d.ellipse([3, 6, 12, 12], outline=hx("2c6a2c"))
    cv.px(8, 6, hx("3d7fd8"))
    cv.d.ellipse([6, 7, 9, 10], fill=hx("f090b0"))
    cv.px(7, 8, hx("f0d040"))
    cv.save("lily")


# ---------------------------------------------------------------- tambang
def make_mine_objects():
    def rock(name, ore=None):
        cv = Canvas(16, 16)
        cv.d.ellipse([1, 3, 14, 14], fill=hx("6e6e78"))
        cv.d.ellipse([2, 2, 13, 11], fill=hx("8a8a96"))
        cv.d.ellipse([2, 3, 9, 9], fill=hx("a0a0ac"))
        cv.hline(4, 3, 3, hx("c8c8d4"))
        cv.px(11, 11, hx("55555e"))
        cv.px(5, 12, hx("55555e"))
        if ore:
            main, light = {"tembaga": (hx("c8782a"), hx("f0a050")),
                           "perak": (hx("b8c4d8"), hx("f0f6ff")),
                           "emas": (hx("e8b820"), hx("fff0a0"))}[ore]
            for ox, oy in ((4, 5), (9, 7), (6, 9)):
                cv.rect(ox, oy, 3, 2, main)
                cv.px(ox, oy, light)
        outline(cv, hx("1a1a22"))
        cv.save(name)

    rock("rock_plain")
    for o in ("tembaga", "perak", "emas"):
        rock("rock_" + o, o)
    # tangga turun
    cv = Canvas(16, 16)
    cv.rect(0, 0, 16, 16, hx("22222a"))
    for i in range(5):
        y = 2 + i * 3
        shade = 0x50 - i * 0x0c
        cv.rect(1 + i, y, 14 - i * 2, 3, (shade, shade, shade + 8, 255))
        cv.hline(1 + i, y, 14 - i * 2, (shade + 24, shade + 24, shade + 32, 255))
    cv.frame(0, 0, 16, 16, hx("14141a"))
    cv.save("stairs_down")


# ---------------------------------------------------------------- tanaman
def sprout(cv, ox, color):
    cv.px(ox + 8, 22, color)
    cv.px(ox + 8, 21, color)
    cv.px(ox + 7, 20, color)
    cv.px(ox + 9, 20, color)


def mound(cv, ox):
    cv.d.ellipse([ox + 3, 20, ox + 12, 25], fill=hx("7a4a28"))
    cv.d.ellipse([ox + 4, 20, ox + 10, 23], fill=hx("9a6234"))


def crop_common(cv, ox, stage, leaf, leaf_d):
    """Tahap 0 (benih) dan 1 (tunas) yang mirip untuk semua tanaman."""
    if stage == 0:
        mound(cv, ox)
        cv.px(ox + 8, 20, leaf_d)
        cv.px(ox + 8, 19, leaf)
    elif stage == 1:
        mound(cv, ox)
        for dx, dy in ((0, 0), (-1, -1), (1, -1), (-2, -2), (2, -2)):
            cv.px(ox + 8 + dx, 19 + dy, leaf)
        cv.px(ox + 8, 20, leaf_d)
        cv.px(ox + 8, 19, leaf_d)


def make_crops():
    W, H = 16, 24

    def sheet(name, stage_fn):
        cv = Canvas(W * 4, H)
        for st in range(4):
            stage_fn(cv, st * W, st)
        outline_cells(cv)
        cv.save(name)

    def outline_cells(cv):
        # garis tepi tipis per sel agar tidak melewati batas
        for i in range(4):
            sub = Canvas(W, H)
            sub.img.paste(cv.img.crop((i * W, 0, (i + 1) * W, H)), (0, 0))
            outline(sub, hx("2a3a1a"))
            cv.img.paste(sub.img, (i * W, 0))

    def lobak(cv, ox, st):
        leaf, leaf_d = hx("5ccf62"), hx("3f8f3f")
        crop_common(cv, ox, st, leaf, leaf_d)
        if st >= 2:
            mound(cv, ox)
            for dx, h in ((-3, 5), (-1, 7), (1, 7), (3, 5)):
                cv.d.line([(ox + 8, 21), (ox + 8 + dx, 21 - h)], fill=leaf, width=1)
                cv.px(ox + 8 + dx, 21 - h - 1, leaf_d)
            for dx in (-3, 3):
                cv.px(ox + 8 + dx, 19, leaf)
        if st == 3:
            cv.d.ellipse([ox + 5, 18, ox + 10, 23], fill=hx("f7f3ea"))
            cv.px(ox + 6, 19, hx("ffffff"))
            cv.hline(ox + 6, 22, 3, hx("e8a0b0"))

    def kentang(cv, ox, st):
        leaf, leaf_d = hx("4aa84a"), hx("2c6a2c")
        crop_common(cv, ox, st, leaf, leaf_d)
        if st >= 2:
            mound(cv, ox)
            for dx, dy, r in ((-3, 15, 3), (0, 13, 3), (3, 15, 3), (-1, 17, 3)):
                cv.d.ellipse([ox + 8 + dx - r, dy - r + 2, ox + 8 + dx + r, dy + r], fill=leaf)
                cv.px(ox + 8 + dx - 1, dy - 1, hx("8ae48a"))
        if st == 3:
            for dx, dy in ((-4, 12), (2, 11)):
                cv.px(ox + 8 + dx, dy, hx("f7f3ea"))
                cv.px(ox + 9 + dx, dy, hx("f0d040"))
            for dx in (-2, 2):
                cv.d.ellipse([ox + 7 + dx, 21, ox + 10 + dx, 24], fill=hx("b8884a"))

    def tomat(cv, ox, st):
        leaf, leaf_d = hx("4aa84a"), hx("2c6a2c")
        crop_common(cv, ox, st, leaf, leaf_d)
        if st >= 2:
            mound(cv, ox)
            cv.vline(ox + 8, 8 if st == 3 else 11, 14, hx("c8a070"))     # tiang
            cv.vline(ox + 8, 10 if st == 3 else 13, 10, leaf_d)
            for dy in range(11, 20, 3):
                cv.d.ellipse([ox + 3, dy, ox + 7, dy + 3], fill=leaf)
                cv.d.ellipse([ox + 9, dy + 1, ox + 13, dy + 4], fill=leaf)
        if st == 3:
            for dx, dy in ((4, 15), (10, 13), (5, 19), (11, 18)):
                cv.d.ellipse([ox + dx - 1, dy - 1, ox + dx + 2, dy + 2], fill=hx("e63326"))
                cv.px(ox + dx - 1, dy - 1, hx("ff8a7a"))

    def jagung(cv, ox, st):
        leaf, leaf_d = hx("6ac04a"), hx("3f8f3f")
        crop_common(cv, ox, st, leaf, leaf_d)
        if st >= 2:
            mound(cv, ox)
            top = 6 if st == 3 else 11
            cv.rect(ox + 7, top, 2, 17 - (top - 6) // 2 * 0, hx("6ac04a"))
            for dy, side in ((top + 3, -1), (top + 6, 1), (top + 9, -1), (top + 12, 1)):
                cv.d.line([(ox + 8, dy), (ox + 8 + side * 5, dy - 3)], fill=leaf, width=1)
                cv.d.line([(ox + 8, dy + 1), (ox + 8 + side * 6, dy - 1)], fill=leaf_d, width=1)
        if st == 3:
            for cx, cy in ((11, 12), (4, 15)):
                cv.rect(ox + cx, cy, 2, 5, hx("f0d040"))
                cv.vline(ox + cx, cy, 5, hx("f8e888"))
                cv.rect(ox + cx - 1, cy + 3, 4, 3, hx("5ccf62"))

    def labu(cv, ox, st):
        leaf, leaf_d = hx("4aa84a"), hx("2c6a2c")
        crop_common(cv, ox, st, leaf, leaf_d)
        if st >= 2:
            mound(cv, ox)
            for dx, dy in ((-4, 17), (4, 16), (0, 14)):
                cv.d.ellipse([ox + 8 + dx - 3, dy - 3, ox + 8 + dx + 3, dy + 2], fill=leaf)
                cv.px(ox + 8 + dx - 1, dy - 1, hx("8ae48a"))
            cv.d.line([(ox + 4, 21), (ox + 12, 21)], fill=leaf_d, width=1)
        if st == 3:
            cv.d.ellipse([ox + 3, 15, ox + 13, 24], fill=hx("e68019"))
            cv.d.ellipse([ox + 3, 15, ox + 8, 24], fill=hx("f09a3a"))
            cv.vline(ox + 8, 15, 9, hx("b8610f"))
            cv.vline(ox + 5, 16, 7, hx("c8700f"))
            cv.vline(ox + 11, 16, 7, hx("c8700f"))
            cv.rect(ox + 7, 13, 2, 3, hx("4a7a2a"))

    for name, fn in (("lobak", lobak), ("kentang", kentang), ("tomat", tomat), ("jagung", jagung), ("labu", labu)):
        sheet("crop_" + name, fn)


def make_mine_entrance():
    cv = Canvas(32, 16)
    rock, rock_d, rock_l = hx("7d7d85"), hx("5a5a64"), hx("9a9aa6")
    cv.d.ellipse([0, 0, 31, 22], fill=rock)
    cv.d.ellipse([2, 1, 29, 18], fill=rock_l)
    cv.d.ellipse([3, 3, 28, 22], fill=rock)
    for x, y in ((4, 4), (10, 2), (18, 2), (25, 5), (6, 9), (24, 10)):
        cv.rect(x, y, 3, 2, rock_d)
        cv.px(x, y, rock_l)
    cv.d.ellipse([8, 5, 23, 22], fill=hx("16161c"))
    cv.rect(8, 10, 16, 6, hx("16161c"))
    cv.rect(7, 7, 2, 9, hx("7a4f2e"))      # tiang kayu
    cv.rect(23, 7, 2, 9, hx("7a4f2e"))
    cv.rect(6, 5, 20, 2, hx("9a6a3e"))
    cv.hline(6, 5, 20, hx("b78650"))
    cv.rect(10, 12, 12, 3, hx("22222c"))
    outline(cv, hx("1a1a22"))
    cv.save("mine_entrance")


def make_doormat():
    cv = Canvas(16, 16)
    rug, rug_d, cream = hx("b04a3e"), hx("8a3328"), hx("ecd9a8")
    cv.rect(2, 6, 12, 6, rug)
    cv.frame(2, 6, 12, 6, cream)
    cv.frame(3, 7, 10, 4, rug_d)
    for x in range(4, 12, 2):
        cv.px(x, 8, cream)
        cv.px(x + 1, 9, cream)
    for y in range(6, 12, 2):            # rumbai di kiri-kanan
        cv.px(1, y, cream)
        cv.px(14, y + 1, cream)
    cv.hline(2, 12, 12, hx("5a2a20"))
    cv.save("mat")


if __name__ == "__main__":
    make_grass()
    make_grass_field()
    make_path()
    make_sand()
    make_water()
    make_soil()
    make_cave_floor()
    make_pier()
    make_tree_oak()
    make_tree_pine()
    make_palm()
    make_bush()
    make_flowers("flowers_red", [hx("e04848"), hx("f08a8a")])
    make_flowers("flowers_yellow", [hx("f0d040"), hx("f8e888")])
    make_flowers("flowers_blue", [hx("6a8ae0"), hx("a8b8f4"), hx("f090d0")])
    make_rock_decor()
    make_stump()
    make_fence()
    make_signpost()
    make_lamp()
    make_bench()
    make_bin()
    make_fountain()
    make_well()
    make_shells()
    make_driftwood()
    make_umbrella()
    make_reeds()
    make_lily()
    make_mine_objects()
    make_mine_entrance()
    make_doormat()
    make_crops()
    print("selesai")
