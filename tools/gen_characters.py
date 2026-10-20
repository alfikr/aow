#!/usr/bin/env python3
"""Membuat sprite karakter (pemain + 5 warga) dan hewan (ayam, sapi, anjing). CC0.

Pakai:  python3 tools/gen_characters.py
Hasil:  assets/sprites/char_*.png, chicken.png, cow.png, dog.png

Karakter: sel 16x24 (final 32x48 px), kolom = [diam, langkah A, langkah B],
baris = [bawah, kiri, kanan, atas].
Hewan: baris 0 = menghadap kiri, baris 1 = menghadap kanan; kolom = bingkai animasi.
"""
import os
import sys

from PIL import Image, ImageOps

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_sprites import OUT, OUTLINE, SCALE, Canvas, hx  # noqa: E402

CW, CH = 16, 24


def darker(c, f=0.78):
    return (int(c[0] * f), int(c[1] * f), int(c[2] * f), 255)


def outline(cv, color=OUTLINE):
    """Garis tepi 1 px di luar siluet."""
    src = cv.img.copy()
    px = src.load()
    for y in range(cv.h):
        for x in range(cv.w):
            if px[x, y][3] != 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < cv.w and 0 <= ny < cv.h and px[nx, ny][3] != 0:
                    cv.img.putpixel((x, y), color)
                    break


# ---------------------------------------------------------------- karakter
STRAW, STRAW_D = hx("e6c35a"), hx("b8932f")
WHITE = hx("f7f3ea")
DARKLINE = hx("2a1a14")
LENS, FRAME = hx("dfeaf2"), hx("6a6a78")

SPECS = {
    "player": dict(skin=hx("f3c9a0"), hair=hx("6a4326"), style="short", shirt=hx("3f6fc0"),
                   pants=hx("6a4a30"), shoes=hx("3a2616"), acc=["cap", "scarf"], cap=hx("3f6fc0")),
    "mira": dict(skin=hx("f6d2b0"), hair=hx("8a4a2a"), style="long", shirt=hx("e0709a"),
                 pants=hx("e0709a"), shoes=hx("6a3a30"), acc=["dress", "apron"]),
    "sari": dict(skin=hx("e8b890"), hair=hx("2a2a40"), style="ponytail", shirt=hx("6fb5a0"),
                 pants=hx("4a5a7a"), shoes=hx("3a2a20"), acc=["scarf2"]),
    "raka": dict(skin=hx("e8b890"), hair=hx("3b2a18"), style="short", shirt=hx("7a9a4a"),
                 pants=hx("5a7090"), shoes=hx("4a3220"), acc=["straw", "overalls"]),
    "dodi": dict(skin=hx("f0c8a0"), hair=hx("c8c8c8"), style="balding", shirt=hx("f0ece0"),
                 pants=hx("4a4060"), shoes=hx("2a2020"), acc=["vest", "beard", "glasses"], vest=hx("8c6bb1")),
    "lila": dict(skin=hx("f2d0b0"), hair=hx("e8e8e8"), style="bun", shirt=hx("c9a9a6"),
                 pants=hx("c9a9a6"), shoes=hx("5a4a44"), acc=["dress", "shawl", "glasses"], shawl=hx("a87a8a")),
}


def has(sp, a):
    return a in sp["acc"]


def leg_bottoms(f):
    return (22 - (1 if f == 2 else 0), 22 - (1 if f == 1 else 0))


def draw_legs_front(cv, sp, f):
    bl, br = leg_bottoms(f)
    pants, shoes = sp["pants"], sp["shoes"]
    skin = sp["skin"]
    if has(sp, "dress"):
        # rok panjang, hanya kaki bawah terlihat
        cv.rect(3, 15, 10, 6, sp["shirt"])
        cv.hline(3, 20, 10, darker(sp["shirt"]))
        for x, b in ((5, bl), (9, br)):
            cv.rect(x, 21, 2, b - 21, skin)
            cv.rect(x - 1, b - 1, 4, 2, shoes)
        return
    for x, b in ((4, bl), (9, br)):
        cv.rect(x, 18, 3, b - 19, pants)
        cv.rect(x, b - 1, 3, 2, shoes)
        cv.rect(x + (0 if x == 4 else 0), b - 1, 3, 1, darker(shoes, 1.2))


def draw_body_front(cv, sp, f):
    shirt = sp["shirt"]
    sleeve = shirt
    cv.rect(4, 11, 8, 7, shirt)
    if has(sp, "vest"):
        cv.rect(4, 11, 2, 7, sp["vest"])
        cv.rect(10, 11, 2, 7, sp["vest"])
    if has(sp, "overalls"):
        cv.rect(5, 14, 6, 4, sp["pants"])
        cv.px(5, 11, sp["pants"])
        cv.px(5, 12, sp["pants"])
        cv.px(5, 13, sp["pants"])
        cv.px(10, 11, sp["pants"])
        cv.px(10, 12, sp["pants"])
        cv.px(10, 13, sp["pants"])
        cv.px(6, 15, hx("e6c35a"))
        cv.px(9, 15, hx("e6c35a"))
    if has(sp, "apron"):
        cv.rect(5, 12, 6, 6, WHITE)
        cv.px(5, 11, WHITE)
        cv.px(10, 11, WHITE)
        cv.hline(5, 13, 6, hx("e8dcc8"))
    if has(sp, "shawl"):
        cv.rect(3, 11, 10, 3, sp["shawl"])
        cv.px(7, 14, sp["shawl"])
        cv.px(8, 14, sp["shawl"])
    if has(sp, "scarf"):
        cv.rect(4, 11, 8, 1, hx("d94a3d"))
    if has(sp, "scarf2"):
        cv.rect(5, 11, 6, 1, hx("f0d040"))
    # lengan (berayun berlawanan)
    la = 1 if f == 1 else (-1 if f == 2 else 0)
    ra = -la
    sk = sp["skin"]
    for x, off in ((2, la), (12, ra)):
        cv.rect(x, 11 + off, 2, 5, sleeve)
        cv.rect(x, 16 + off, 2, 2, sk)


def draw_head_front(cv, sp):
    skin, hair = sp["skin"], sp["hair"]
    st = sp["style"]
    if st == "long":
        cv.rect(3, 3, 10, 11, hair)
    cv.rect(4, 3, 8, 8, skin)
    # mata & mulut
    cv.rect(5, 6, 1, 2, DARKLINE)
    cv.rect(10, 6, 1, 2, DARKLINE)
    cv.hline(7, 9, 2, darker(skin, 0.7))
    if st == "balding":
        cv.rect(4, 2, 8, 1, hair)
        cv.rect(3, 3, 1, 5, hair)
        cv.rect(12, 3, 1, 5, hair)
    else:
        cv.rect(3, 1, 10, 4, hair)
        cv.rect(3, 5, 1, 3, hair)
        cv.rect(12, 5, 1, 3, hair)
        cv.px(4, 5, hair)
        cv.px(5, 5, hair)
        cv.px(10, 5, hair)
        cv.px(11, 5, hair)
        cv.px(6, 5, hair)
    if st == "bun":
        cv.rect(6, 0, 4, 2, hair)
        cv.hline(7, 0, 2, hx("ffffff"))
    if st == "ponytail":
        cv.rect(3, 5, 1, 5, hair)
        cv.rect(12, 5, 1, 5, hair)
    if st == "long":
        # rambut jatuh di depan bahu
        cv.rect(3, 5, 2, 9, hair)
        cv.rect(11, 5, 2, 9, hair)
    if has(sp, "beard"):
        cv.rect(4, 9, 8, 3, hx("f0f0f0"))
        cv.hline(6, 9, 4, hx("e0e0e0"))
        cv.hline(7, 10, 2, hx("d0d0d0"))
    if has(sp, "glasses"):
        for gx in (4, 9):
            cv.rect(gx, 5, 3, 4, LENS)
            cv.frame(gx, 5, 3, 4, FRAME)
            cv.px(gx + 1, 7, DARKLINE)
        cv.hline(7, 6, 2, FRAME)
    if has(sp, "straw"):
        cv.rect(1, 3, 14, 2, STRAW)
        cv.hline(1, 4, 14, STRAW_D)
        cv.rect(4, 1, 8, 3, STRAW)
        cv.hline(4, 3, 8, hx("8a5a30"))
    if has(sp, "cap"):
        cv.rect(3, 1, 10, 4, sp["cap"])
        cv.hline(3, 1, 10, darker(sp["cap"], 1.15))
        cv.rect(3, 5, 10, 1, darker(sp["cap"], 0.7))


def front(sp, f):
    cv = Canvas(CW, CH)
    draw_legs_front(cv, sp, f)
    draw_body_front(cv, sp, f)
    draw_head_front(cv, sp)
    return cv


def back(sp, f):
    cv = Canvas(CW, CH)
    st = sp["style"]
    hair = sp["hair"]
    draw_legs_front(cv, sp, f)
    draw_body_front(cv, sp, f)
    # hapus detail depan (apron/dll) dengan menimpa punggung
    if has(sp, "apron"):
        cv.rect(4, 11, 8, 7, sp["shirt"])
        cv.vline(7, 12, 5, WHITE)
        cv.vline(8, 12, 5, WHITE)
    if has(sp, "overalls"):
        cv.rect(4, 11, 8, 7, sp["shirt"])
        cv.rect(5, 15, 6, 3, sp["pants"])
        cv.vline(5, 11, 5, sp["pants"])
        cv.vline(10, 11, 5, sp["pants"])
    if has(sp, "vest"):
        cv.rect(4, 11, 8, 7, sp["vest"])
    if has(sp, "shawl"):
        cv.rect(3, 11, 10, 6, sp["shawl"])
    # kepala dari belakang
    cv.rect(4, 3, 8, 8, sp["skin"])
    if st == "balding":
        cv.rect(3, 2, 10, 7, hair)
        cv.rect(5, 2, 6, 3, sp["skin"])
    else:
        cv.rect(3, 1, 10, 9, hair)
    if st == "long":
        cv.rect(3, 3, 10, 11, hair)
        cv.vline(7, 6, 7, darker(hair, 0.85))
    if st == "ponytail":
        cv.rect(7, 5, 3, 3, darker(hair, 1.2))
        cv.rect(7, 8, 2, 7, hair)
        cv.px(7, 8, hx("f0d040"))
    if st == "bun":
        cv.rect(6, 0, 4, 3, hair)
        cv.hline(7, 0, 2, hx("ffffff"))
    if has(sp, "straw"):
        cv.rect(1, 3, 14, 2, STRAW)
        cv.rect(4, 1, 8, 3, STRAW)
        cv.hline(4, 3, 8, hx("8a5a30"))
    if has(sp, "cap"):
        cv.rect(3, 1, 10, 5, sp["cap"])
        cv.hline(3, 1, 10, darker(sp["cap"], 1.15))
    return cv


def side(sp, f):
    """Menghadap kiri."""
    cv = Canvas(CW, CH)
    skin, hair, shirt = sp["skin"], sp["hair"], sp["shirt"]
    pants, shoes = sp["pants"], sp["shoes"]
    st = sp["style"]
    # kaki
    if has(sp, "dress"):
        cv.rect(4, 15, 8, 6, shirt)
        cv.hline(4, 20, 8, darker(shirt))
        if f == 0:
            cv.rect(6, 21, 3, 1, skin)
            cv.rect(5, 21, 5, 2, shoes)
        elif f == 1:
            cv.rect(4, 21, 4, 2, shoes)
            cv.rect(9, 21, 4, 2, shoes)
        else:
            cv.rect(5, 21, 4, 2, shoes)
            cv.rect(8, 21, 4, 2, shoes)
    else:
        if f == 0:
            cv.rect(6, 18, 4, 3, pants)
            cv.rect(5, 21, 5, 2, shoes)
        elif f == 1:
            cv.rect(4, 18, 3, 3, pants)
            cv.rect(3, 21, 4, 2, shoes)
            cv.rect(9, 18, 3, 3, pants)
            cv.rect(9, 21, 4, 2, shoes)
        else:
            cv.rect(9, 18, 3, 3, pants)
            cv.rect(8, 21, 4, 2, shoes)
            cv.rect(4, 18, 3, 3, pants)
            cv.rect(4, 21, 4, 2, shoes)
    # rambut panjang (lapisan belakang)
    if st == "long":
        cv.rect(8, 3, 4, 11, hair)
    if st == "ponytail":
        cv.rect(10, 6, 2, 8, hair)
    # badan
    cv.rect(5, 11, 6, 7, shirt)
    if has(sp, "vest"):
        cv.rect(5, 11, 6, 7, sp["vest"])
        cv.rect(4, 12, 2, 5, sp["shirt"])
    if has(sp, "overalls"):
        cv.rect(5, 14, 6, 4, pants)
        cv.vline(8, 11, 3, pants)
    if has(sp, "apron"):
        cv.rect(4, 12, 2, 6, WHITE)
    if has(sp, "shawl"):
        cv.rect(4, 11, 7, 3, sp["shawl"])
    if has(sp, "scarf"):
        cv.rect(5, 11, 6, 1, hx("d94a3d"))
    if has(sp, "scarf2"):
        cv.rect(5, 11, 6, 1, hx("f0d040"))
    # kepala
    cv.rect(3, 3, 7, 8, skin)
    cv.px(2, 7, skin)            # hidung
    cv.rect(4, 6, 1, 2, DARKLINE)
    cv.hline(3, 9, 2, darker(skin, 0.7))
    if st == "balding":
        cv.rect(7, 3, 3, 5, hair)
        cv.rect(5, 2, 4, 1, hair)
    else:
        cv.rect(4, 1, 8, 4, hair)
        cv.rect(8, 4, 3, 5, hair)
        cv.px(3, 4, hair)
        cv.px(4, 4, hair)
    if st == "bun":
        cv.rect(8, 0, 4, 3, hair)
        cv.hline(9, 0, 2, hx("ffffff"))
    if has(sp, "beard"):
        cv.rect(3, 9, 5, 3, hx("f0f0f0"))
        cv.hline(2, 9, 2, hx("f0f0f0"))
    if has(sp, "glasses"):
        cv.rect(3, 5, 3, 4, LENS)
        cv.frame(3, 5, 3, 4, FRAME)
        cv.px(4, 7, DARKLINE)
        cv.hline(6, 6, 4, FRAME)
    if has(sp, "straw"):
        cv.rect(0, 3, 12, 2, STRAW)
        cv.hline(0, 4, 12, STRAW_D)
        cv.rect(4, 1, 7, 3, STRAW)
        cv.hline(4, 3, 7, hx("8a5a30"))
    if has(sp, "cap"):
        cv.rect(3, 1, 9, 4, sp["cap"])
        cv.hline(3, 1, 9, darker(sp["cap"], 1.15))
        cv.rect(1, 4, 4, 1, darker(sp["cap"], 0.7))
    # lengan (depan badan)
    swing = {0: 0, 1: -1, 2: 1}[f]
    cv.rect(6 + swing, 11, 3, 5, shirt if not has(sp, "vest") else sp["shirt"])
    cv.rect(6 + swing, 16, 3, 2, skin)
    if has(sp, "shawl"):
        cv.rect(6 + swing, 11, 3, 2, sp["shawl"])
    return cv


VIEWS = ["front", "left", "right", "back"]


def make_character(name):
    sp = SPECS[name]
    sheet = Image.new("RGBA", (CW * 3, CH * 4), (0, 0, 0, 0))
    for f in range(3):
        fr = front(sp, f)
        bk = back(sp, f)
        lf = side(sp, f)
        for cv in (fr, bk, lf):
            outline(cv)
        sheet.paste(fr.img, (f * CW, 0 * CH))
        sheet.paste(lf.img, (f * CW, 1 * CH))
        sheet.paste(ImageOps.mirror(lf.img), (f * CW, 2 * CH))
        sheet.paste(bk.img, (f * CW, 3 * CH))
    big = sheet.resize((sheet.width * SCALE, sheet.height * SCALE), Image.NEAREST)
    os.makedirs(OUT, exist_ok=True)
    big.save(os.path.join(OUT, "char_%s.png" % name))


# ------------------------------------------------------------------- hewan
def save_animal(name, frames_left):
    w, h = frames_left[0].w, frames_left[0].h
    sheet = Image.new("RGBA", (w * len(frames_left), h * 2), (0, 0, 0, 0))
    for i, cv in enumerate(frames_left):
        outline(cv)
        sheet.paste(cv.img, (i * w, 0))
        sheet.paste(ImageOps.mirror(cv.img), (i * w, h))
    big = sheet.resize((sheet.width * SCALE, sheet.height * SCALE), Image.NEAREST)
    big.save(os.path.join(OUT, name + ".png"))


def chicken(f):
    cv = Canvas(16, 16)
    white, shade, orange, red = hx("f7f3ea"), hx("d8d0bc"), hx("f0a030"), hx("d94a3d")
    tilt = 1 if f == 2 else 0
    cv.d.polygon([(11, 6 + tilt), (14, 3 + tilt), (14, 9 + tilt), (12, 11 + tilt)], fill=shade)
    cv.d.ellipse([3, 6 + tilt, 12, 13], fill=white)
    cv.d.ellipse([6, 8 + tilt, 11, 12], fill=shade)
    cv.hline(7, 9 + tilt, 3, hx("ece4d0"))
    hy = 3 if f != 2 else 8
    hxo = 2 if f != 2 else 1
    cv.d.ellipse([hxo, hy, hxo + 4, hy + 4], fill=white)
    cv.rect(hxo + 1, hy - 1, 2, 2, red)
    cv.rect(hxo - 2 if hxo >= 2 else 0, hy + 2, 2, 1, orange)
    cv.px(hxo + 1, hy + 2, DARKLINE)
    cv.px(hxo, hy + 4, red)
    # kaki
    cv.rect(6, 13, 1, 3, orange)
    cv.rect(9, 13, 1, 3 if f != 1 else 2, orange)
    cv.hline(5, 15, 3, orange)
    cv.hline(8 if f != 1 else 9, 15 if f != 1 else 14, 3, orange)
    return cv


def cow(f):
    cv = Canvas(24, 18)
    white, patch, pink = hx("f6f2ea"), hx("5a4034"), hx("f0a8b0")
    graze = f == 3
    # ekor
    cv.vline(21, 5, 7, white)
    cv.rect(21, 11, 2, 2, patch)
    # badan
    cv.d.ellipse([5, 3, 21, 13], fill=white)
    cv.d.ellipse([9, 3, 13, 8], fill=patch)
    cv.d.ellipse([15, 6, 19, 11], fill=patch)
    cv.rect(11, 10, 2, 2, patch)
    cv.hline(7, 4, 4, hx("ffffff"))
    # ambing
    cv.rect(14, 12, 3, 2, pink)
    # kaki
    lift_a = 1 if f == 1 else 0
    lift_b = 1 if f == 2 else 0
    for x, lift in ((7, lift_a), (10, lift_b), (16, lift_b), (19, lift_a)):
        cv.rect(x, 12, 2, 4 - lift, white)
        cv.rect(x, 16 - lift, 2, 1, hx("3a2a24"))
    # kepala
    hy = 3 if not graze else 8
    cv.d.ellipse([1, hy, 8, hy + 7], fill=white)
    cv.rect(0, hy + 4, 3, 3, pink)
    cv.px(0, hy + 5, hx("3a2a24"))
    cv.px(3, hy + 2, DARKLINE)
    cv.px(3, hy - 1, hx("efe0b0"))
    cv.px(6, hy - 1, hx("efe0b0"))
    cv.rect(7, hy, 2, 2, patch)
    if graze:
        cv.rect(5, 6, 4, 4, white)   # leher
    return cv


def dog(f):
    cv = Canvas(18, 14)
    brown, dark, light = hx("b07a42"), hx("7a4f2a"), hx("e0b484")
    # ekor (naik, bergoyang)
    tail = {0: [(14, 5), (16, 2)], 1: [(14, 5), (17, 3)], 2: [(14, 5), (16, 3)], 3: [(14, 5), (16, 3)]}[f]
    cv.d.line(tail, fill=brown, width=2)
    # badan
    cv.d.ellipse([5, 4, 15, 10], fill=brown)
    cv.hline(7, 5, 6, hx("c8905a"))
    cv.d.ellipse([6, 8, 13, 10], fill=light)
    # kaki
    la = 1 if f == 2 else 0
    lb = 1 if f == 3 else 0
    for x, lift in ((5, la), (8, lb), (12, lb), (15, la)):
        cv.rect(x, 9, 2, 4 - lift, brown)
        cv.rect(x, 12 - lift, 2, 1, dark)
    # kepala
    cv.d.ellipse([2, 2, 8, 8], fill=brown)
    cv.rect(0, 5, 4, 3, light)          # moncong
    cv.px(0, 5, DARKLINE)               # hidung
    cv.px(1, 5, DARKLINE)
    cv.hline(1, 7, 2, hx("b86a5a"))     # mulut
    cv.px(4, 4, DARKLINE)               # mata
    cv.d.polygon([(5, 1), (7, 2), (8, 6), (6, 6)], fill=dark)   # telinga terkulai
    return cv


if __name__ == "__main__":
    for n in SPECS:
        make_character(n)
    save_animal("chicken", [chicken(0), chicken(1), chicken(2)])
    save_animal("cow", [cow(0), cow(1), cow(2), cow(3)])
    save_animal("dog", [dog(0), dog(1), dog(2), dog(3)])
    print("selesai:", sorted(f for f in os.listdir(OUT) if f.startswith(("char_", "chicken", "cow", "dog")) and f.endswith(".png")))
