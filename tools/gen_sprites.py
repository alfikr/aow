#!/usr/bin/env python3
"""Membuat sprite pixel-art rumah, toko, dan isi interiornya (CC0, digambar lewat kode).

Pakai:  python3 tools/gen_sprites.py
Hasil:  assets/sprites/*.png

Setiap sprite digambar pada grid 16 px per tile lalu diperbesar 2x (nearest),
sehingga ukuran akhir = jumlah tile x 32 px, pas dengan tile game.
"""
import os
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites")
SCALE = 2


def hx(s):
    s = s.lstrip("#")
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


# ------------------------------------------------------------------ palet
OUTLINE = hx("2a1a14")
WOOD_D, WOOD, WOOD_L, WOOD_HL = hx("4f3220"), hx("7a4f2e"), hx("9a6a3e"), hx("b78650")
CREAM, CREAM_S, CREAM_D = hx("ead9ae"), hx("d6c595"), hx("b8a578")
ROOF_R, ROOF_RD, ROOF_RL = hx("b5483a"), hx("8a3328"), hx("d0624e")
ROOF_B, ROOF_BD, ROOF_BL = hx("3f6fa6"), hx("2f5280"), hx("5b8cc4")
BRICK, BRICK_D, BRICK_L, MORTAR = hx("c98f5f"), hx("b07a4c"), hx("d9a273"), hx("9a6540")
STONE, STONE_D, STONE_L = hx("8f8f93"), hx("6e6e74"), hx("adadb2")
GLASS, GLASS_D, GLASS_HL = hx("9bd5ee"), hx("6fb4d6"), hx("e2f6fc")
WHITE, OFFWHITE = hx("f7f3ea"), hx("e4ddcc")
GREEN, GREEN_D = hx("4e9a4e"), hx("357535")
RED, RED_D = hx("d94a3d"), hx("a8322a")
GOLD = hx("e6b93a")
TRANSPARENT = (0, 0, 0, 0)


class Canvas:
    def __init__(self, w, h):
        self.img = Image.new("RGBA", (w, h), TRANSPARENT)
        self.d = ImageDraw.Draw(self.img)
        self.w, self.h = w, h

    def rect(self, x, y, w, h, c):
        if w > 0 and h > 0:
            self.d.rectangle([x, y, x + w - 1, y + h - 1], fill=c)

    def px(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.img.putpixel((x, y), c)

    def hline(self, x, y, w, c):
        self.rect(x, y, w, 1, c)

    def vline(self, x, y, h, c):
        self.rect(x, y, 1, h, c)

    def frame(self, x, y, w, h, c):
        self.hline(x, y, w, c)
        self.hline(x, y + h - 1, w, c)
        self.vline(x, y, h, c)
        self.vline(x + w - 1, y, h, c)

    def save(self, name):
        os.makedirs(OUT, exist_ok=True)
        big = self.img.resize((self.w * SCALE, self.h * SCALE), Image.NEAREST)
        big.save(os.path.join(OUT, name + ".png"))


# --------------------------------------------------------------- huruf 3x5
FONT = {
    "T": ["111", "010", "010", "010", "010"],
    "O": ["111", "101", "101", "101", "111"],
    "K": ["101", "101", "110", "101", "101"],
}


def text(cv, s, x, y, c, shadow=None, scale=2):
    cx = x
    for ch in s:
        glyph = FONT[ch]
        for gy, row in enumerate(glyph):
            for gx, bit in enumerate(row):
                if bit == "1":
                    if shadow:
                        cv.rect(cx + gx * scale + 1, y + gy * scale + 1, scale, scale, shadow)
                    cv.rect(cx + gx * scale, y + gy * scale, scale, scale, c)
        cx += 3 * scale + scale


# ------------------------------------------------------------- komponen
def shingles(cv, x, y, w, h, base, dark, light):
    cv.rect(x, y, w, h, base)
    for yy in range(h):
        row = yy // 4
        if yy % 4 == 3:
            cv.hline(x, y + yy, w, dark)
        else:
            off = 4 if row % 2 else 0
            for xx in range(off, w, 8):
                cv.px(x + xx, y + yy, dark)
    cv.hline(x, y, w, light)


def window(cv, x, y, w, h, shutters=True, flowers=True):
    if shutters:
        cv.rect(x - 4, y, 3, h, GREEN)
        cv.vline(x - 4, y, h, GREEN_D)
        cv.rect(x + w + 1, y, 3, h, GREEN)
        cv.vline(x + w + 3, y, h, GREEN_D)
        for sy in range(y + 2, y + h - 1, 3):
            cv.hline(x - 3, sy, 1, GREEN_D)
            cv.hline(x + w + 2, sy, 1, GREEN_D)
    cv.rect(x - 1, y - 1, w + 2, h + 2, WHITE)
    cv.rect(x, y, w, h, GLASS)
    cv.rect(x, y + h // 2, w, 1, WHITE)
    cv.rect(x + w // 2, y, 1, h, WHITE)
    cv.hline(x + 1, y + 1, 3, GLASS_HL)
    cv.px(x + 1, y + 2, GLASS_HL)
    cv.hline(x - 2, y + h + 1, w + 4, OFFWHITE)
    if flowers:
        cv.rect(x - 1, y + h + 2, w + 2, 3, WOOD_D)
        cv.hline(x - 1, y + h + 2, w + 2, WOOD)
        for i, fx in enumerate(range(x, x + w, 3)):
            cv.px(fx, y + h + 1, [hx("f090b0"), hx("f0d040"), RED][i % 3])
            cv.px(fx + 1, y + h + 1, hx("3f8f3f"))


def door(cv, x, y, w, h, glass_top=True):
    cv.rect(x - 1, y - 1, w + 2, h + 1, WOOD_D)
    cv.rect(x, y, w, h, WOOD)
    cv.vline(x, y, h, WOOD_L)
    cv.vline(x + w - 1, y, h, WOOD_D)
    py = y + (h // 2 if not glass_top else h // 2 + 1)
    cv.frame(x + 2, py, w - 4, y + h - py - 3, WOOD_D)
    cv.rect(x + 3, py + 1, w - 6, y + h - py - 5, WOOD_L)
    if glass_top:
        cv.rect(x + 2, y + 2, w - 4, h // 2 - 4, GLASS)
        cv.frame(x + 2, y + 2, w - 4, h // 2 - 4, WHITE)
        cv.hline(x + 3, y + 3, 2, GLASS_HL)
    else:
        cv.frame(x + 2, y + 2, w - 4, h // 2 - 3, WOOD_D)
        cv.rect(x + 3, y + 3, w - 6, h // 2 - 5, WOOD_L)
    cv.rect(x + w - 4, y + h // 2, 2, 2, GOLD)


def stone_base(cv, x, y, w, h):
    cv.rect(x, y, w, h, STONE)
    cv.hline(x, y, w, STONE_L)
    cv.hline(x, y + h - 1, w, STONE_D)
    for i, sx in enumerate(range(x, x + w, 6)):
        cv.vline(sx + (i % 2) * 2, y + 1, h - 2, STONE_D)


# ------------------------------------------------------------ bangunan
def make_house():
    cv = Canvas(80, 48)
    # dinding papan krem
    cv.rect(0, 22, 80, 26, CREAM)
    for x in range(2, 80, 4):
        cv.vline(x, 22, 26, CREAM_S)
    cv.hline(0, 22, 80, CREAM_D)
    cv.hline(0, 23, 80, CREAM_S)
    stone_base(cv, 0, 44, 80, 4)
    # cerobong di belakang atap
    cv.rect(58, 0, 10, 12, BRICK)
    for y in range(1, 12, 3):
        cv.hline(58, y, 10, MORTAR)
    cv.rect(57, 0, 12, 2, STONE_L)
    cv.hline(57, 1, 12, STONE_D)
    # atap
    shingles(cv, 0, 4, 80, 18, ROOF_R, ROOF_RD, ROOF_RL)
    cv.rect(58, 0, 10, 4, BRICK)  # cerobong tampil di atas punggung atap
    cv.rect(57, 0, 12, 2, STONE_L)
    cv.hline(57, 1, 12, STONE_D)
    cv.vline(0, 4, 18, ROOF_RD)
    cv.vline(79, 4, 18, ROOF_RD)
    cv.hline(0, 20, 80, hx("6a2a20"))
    cv.hline(0, 21, 80, hx("6a2a20"))
    cv.hline(1, 24, 78, CREAM_D)  # bayangan lis atap pada dinding
    # jendela & pintu
    window(cv, 10, 28, 12, 10)
    window(cv, 58, 28, 12, 10)
    door(cv, 33, 26, 14, 22, glass_top=True)
    cv.rect(30, 46, 20, 2, STONE_L)
    cv.hline(30, 46, 20, WHITE)
    # lampu kecil di sisi pintu
    cv.rect(29, 31, 2, 3, GOLD)
    cv.px(29, 30, OUTLINE)
    cv.rect(49, 31, 2, 3, GOLD)
    cv.px(50, 30, OUTLINE)
    cv.save("house")


def make_shop():
    cv = Canvas(96, 64)
    # dinding bata
    cv.rect(0, 26, 96, 38, BRICK)
    for row in range(0, 38, 4):
        cv.hline(0, 26 + row + 3, 96, MORTAR)
        off = 4 if (row // 4) % 2 else 0
        for x in range(off, 96, 8):
            cv.vline(x, 26 + row, 3, MORTAR)
    for x in range(0, 96, 16):
        cv.rect(x + 1, 27, 3, 1, BRICK_L)
    stone_base(cv, 0, 60, 96, 4)
    # atap biru + papan nama
    shingles(cv, 0, 0, 96, 16, ROOF_B, ROOF_BD, ROOF_BL)
    cv.hline(0, 14, 96, hx("22405f"))
    cv.hline(0, 15, 96, hx("22405f"))
    cv.vline(0, 0, 16, ROOF_BD)
    cv.vline(95, 0, 16, ROOF_BD)
    cv.rect(24, 2, 48, 12, WOOD)
    cv.frame(24, 2, 48, 12, WOOD_D)
    cv.hline(25, 3, 46, WOOD_L)
    text(cv, "TOKO", 35, 4, hx("fbf0cf"), shadow=WOOD_D, scale=2)
    # kanopi belang merah-putih
    for i, x in enumerate(range(0, 96, 4)):
        col = RED if (i // 1) % 2 == 0 else WHITE
        dk = RED_D if (i // 1) % 2 == 0 else OFFWHITE
        cv.rect(x, 16, 4, 9, col)
        cv.hline(x, 24, 4, dk)
        # scallop
        if i % 2 == 0:
            cv.rect(x, 25, 4, 1, col)
        else:
            cv.rect(x, 25, 4, 1, col)
        cv.px(x, 25, TRANSPARENT if False else col)
    cv.hline(0, 26, 96, BRICK_D)
    cv.hline(0, 27, 96, MORTAR)
    # jendela kiri
    cv.rect(5, 32, 22, 17, WHITE)
    cv.rect(6, 33, 20, 15, GLASS)
    cv.vline(15, 33, 15, WHITE)
    cv.hline(6, 40, 20, WHITE)
    cv.hline(7, 34, 4, GLASS_HL)
    cv.px(7, 35, GLASS_HL)
    cv.rect(3, 49, 26, 2, OFFWHITE)
    # pot tanaman di ambang jendela
    cv.rect(9, 46, 4, 3, hx("b5603a"))
    cv.rect(9, 43, 4, 3, hx("3f8f3f"))
    cv.px(10, 42, hx("f090b0"))
    cv.px(12, 43, hx("f0d040"))
    # pintu
    door(cv, 33, 28, 14, 32 + 4, glass_top=True)
    cv.rect(30, 62, 20, 2, STONE_L)
    cv.hline(30, 62, 20, WHITE)
    # papan BUKA kecil
    cv.rect(37, 38, 6, 4, hx("f4e7b8"))
    cv.frame(37, 38, 6, 4, WOOD_D)
    # etalase besar
    cv.rect(51, 31, 41, 23, WHITE)
    cv.rect(52, 32, 39, 21, GLASS_D)
    cv.rect(52, 32, 39, 3, GLASS)
    cv.rect(52, 44, 39, 1, WOOD)  # rak
    cv.rect(52, 52, 39, 1, WOOD)
    # barang di etalase: apel, roti, toples, kotak
    for ax in (54, 58, 62):
        cv.rect(ax, 41, 3, 3, RED)
        cv.px(ax, 41, RED_D)
        cv.px(ax + 1, 40, hx("3f8f3f"))
    cv.rect(67, 41, 6, 3, hx("c8863a"))
    cv.hline(67, 41, 6, hx("e0a85a"))
    for jx, jc in ((76, hx("6fc06f")), (81, hx("e9a23a")), (86, hx("7aa7e0"))):
        cv.rect(jx, 38, 4, 6, jc)
        cv.hline(jx, 38, 4, OFFWHITE)
    cv.rect(54, 47, 8, 5, hx("8c6a3a"))
    cv.hline(54, 47, 8, WOOD_L)
    cv.rect(64, 47, 7, 5, hx("c9a05a"))
    cv.rect(74, 48, 4, 4, hx("e0603c"))
    cv.rect(80, 48, 4, 4, hx("f0d040"))
    cv.rect(86, 48, 4, 4, hx("6fc06f"))
    cv.hline(53, 33, 4, GLASS_HL)
    cv.hline(53, 34, 2, GLASS_HL)
    cv.rect(49, 54, 45, 2, OFFWHITE)
    cv.save("shop")


# ------------------------------------------------------------ interior
def make_floors():
    cv = Canvas(16, 16)
    tones = [hx("c9a06a"), hx("bf9660"), hx("cfa874"), hx("c29a63")]
    seams = [5, 12, 2, 9]
    for i in range(4):
        cv.rect(0, i * 4, 16, 4, tones[i])
        cv.hline(0, i * 4 + 3, 16, hx("8a6238"))
        cv.vline(seams[i], i * 4, 3, hx("8a6238"))
        cv.hline(0, i * 4, 16, hx("d8b682"))
    cv.save("floor_wood")

    cv = Canvas(16, 16)
    for ty in range(2):
        for tx in range(2):
            c = hx("efe4c8") if (tx + ty) % 2 == 0 else hx("e3d5b0")
            cv.rect(tx * 8, ty * 8, 8, 8, c)
            cv.frame(tx * 8, ty * 8, 8, 8, hx("d6c7a0"))
    cv.save("floor_tile")


def make_bed():
    cv = Canvas(48, 32)
    cv.rect(2, 0, 44, 32, WOOD)
    cv.rect(2, 0, 44, 10, WOOD_L)
    cv.hline(3, 1, 42, WOOD_HL)
    cv.frame(2, 0, 44, 32, WOOD_D)
    cv.rect(6, 5, 36, 3, WOOD_D)
    cv.rect(4, 9, 40, 20, hx("f3ead2"))
    # bantal
    for px in (7, 27):
        cv.rect(px, 10, 14, 6, WHITE)
        cv.hline(px, 15, 14, OFFWHITE)
        cv.hline(px + 1, 10, 12, hx("ffffff"))
    # selimut biru
    cv.rect(4, 16, 40, 13, hx("4d78c0"))
    cv.hline(4, 16, 40, hx("e8efff"))
    cv.hline(4, 17, 40, hx("e8efff"))
    for sx in range(8, 44, 8):
        cv.vline(sx, 18, 11, hx("6a93d8"))
    cv.hline(4, 28, 40, hx("3a5f9c"))
    cv.rect(2, 29, 44, 3, WOOD_D)
    cv.hline(3, 29, 42, WOOD)
    cv.save("bed")


def make_kitchen():
    cv = Canvas(64, 32)
    # dinding belakang berubin
    cv.rect(0, 0, 64, 10, hx("f1efe6"))
    for x in range(0, 64, 8):
        cv.vline(x, 0, 10, hx("cfd6dc"))
    for y in (3, 7):
        cv.hline(0, y, 64, hx("cfd6dc"))
    # toples di rak
    cv.hline(46, 5, 16, WOOD)
    for jx, jc in ((48, hx("e9a23a")), (53, hx("6fc06f")), (58, hx("c9503a"))):
        cv.rect(jx, 1, 4, 4, jc)
        cv.hline(jx, 1, 4, OFFWHITE)
    # meja dapur
    cv.rect(0, 10, 64, 5, hx("d8c7a0"))
    cv.hline(0, 10, 64, hx("f0e4c6"))
    cv.hline(0, 14, 64, hx("a89466"))
    # kabinet
    cv.rect(0, 15, 64, 17, WOOD)
    cv.frame(0, 15, 64, 17, WOOD_D)
    for x in range(0, 64, 16):
        cv.frame(x + 2, 17, 12, 13, WOOD_D)
        cv.rect(x + 3, 18, 10, 11, WOOD_L)
        cv.rect(x + 12 if x % 32 == 0 else x + 3, 22, 1, 3, GOLD)
    # bak cuci
    cv.rect(4, 8, 14, 3, STONE_L)
    cv.rect(6, 9, 10, 2, hx("5c6a78"))
    cv.vline(11, 4, 5, STONE_D)
    cv.hline(11, 4, 3, STONE_D)
    # kompor
    cv.rect(24, 9, 20, 6, hx("3a3a40"))
    cv.hline(24, 9, 20, hx("55555c"))
    for bx in (28, 38):
        cv.rect(bx, 10, 4, 3, hx("202024"))
        cv.px(bx + 1, 11, hx("e06a2c"))
    # panci
    cv.rect(26, 4, 8, 6, hx("8c9096"))
    cv.hline(26, 4, 8, hx("c8ccd2"))
    cv.vline(25, 6, 2, hx("55555c"))
    cv.vline(34, 6, 2, hx("55555c"))
    cv.px(29, 2, hx("e8eef2"))
    cv.px(31, 1, hx("e8eef2"))
    cv.save("kitchen")


def make_tv():
    cv = Canvas(32, 16)
    # meja
    cv.rect(2, 11, 28, 3, WOOD)
    cv.hline(2, 11, 28, WOOD_L)
    cv.rect(3, 14, 3, 2, WOOD_D)
    cv.rect(26, 14, 3, 2, WOOD_D)
    # tabung TV
    cv.rect(5, 2, 22, 10, hx("2a2a2e"))
    cv.frame(5, 2, 22, 10, hx("111114"))
    cv.rect(7, 4, 15, 6, hx("6fa8dc"))
    cv.hline(7, 4, 15, hx("a8d0f0"))
    cv.px(8, 5, hx("e8f4ff"))
    cv.hline(10, 8, 6, hx("4f85bb"))
    cv.px(24, 5, RED)
    cv.rect(24, 7, 2, 1, hx("888890"))
    cv.rect(24, 9, 2, 1, hx("888890"))
    # antena
    cv.px(12, 1, hx("c0c0c8"))
    cv.px(11, 0, hx("c0c0c8"))
    cv.px(19, 1, hx("c0c0c8"))
    cv.px(20, 0, hx("c0c0c8"))
    cv.save("tv")


def make_counter():
    cv = Canvas(128, 16)
    cv.rect(0, 4, 128, 12, WOOD)
    cv.rect(0, 2, 128, 4, WOOD_L)
    cv.hline(0, 2, 128, WOOD_HL)
    cv.hline(0, 5, 128, WOOD_D)
    cv.frame(0, 2, 128, 14, WOOD_D)
    for x in range(0, 128, 16):
        cv.frame(x + 2, 8, 12, 7, WOOD_D)
        cv.rect(x + 3, 9, 10, 5, hx("8a5a34"))
    # keranjang apel
    cv.rect(6, 0, 14, 4, hx("b5833a"))
    cv.hline(6, 3, 14, WOOD_D)
    for ax in (8, 12, 16):
        cv.rect(ax, 0, 3, 3, RED)
        cv.px(ax, 0, RED_D)
    # mesin kasir
    cv.rect(50, 0, 14, 6, hx("8c9096"))
    cv.rect(52, 0, 10, 2, hx("7fc47f"))
    cv.hline(50, 5, 14, hx("55555c"))
    for bx in (52, 55, 58, 61):
        cv.px(bx, 3, hx("e8eef2"))
    # toples dan timbangan
    cv.rect(94, 0, 6, 4, hx("d8d8e0"))
    cv.rect(95, 1, 4, 3, hx("e9a23a"))
    cv.rect(108, 1, 10, 2, hx("c0c0c8"))
    cv.rect(111, 0, 4, 1, hx("c0c0c8"))
    cv.save("counter")


def make_shelf():
    cv = Canvas(48, 32)
    cv.rect(0, 0, 48, 32, WOOD_D)
    cv.rect(2, 2, 44, 28, hx("3a2616"))
    cv.rect(2, 14, 44, 2, WOOD)
    cv.hline(2, 14, 44, WOOD_L)
    cv.rect(2, 29, 44, 3, WOOD)
    cv.hline(2, 29, 44, WOOD_L)
    cv.frame(0, 0, 48, 32, hx("2a1a10"))
    # rak atas: toples warna-warni
    for jx, jc in ((4, hx("6fc06f")), (11, hx("e9a23a")), (18, hx("c9503a")), (25, hx("7aa7e0")), (33, hx("f0d040")), (40, hx("c58ae0"))):
        cv.rect(jx, 6, 5, 8, jc)
        cv.hline(jx, 6, 5, OFFWHITE)
        cv.px(jx + 1, 8, hx("ffffff"))
    # rak bawah: karung & kotak
    cv.rect(4, 20, 12, 9, hx("d8c08a"))
    cv.hline(4, 20, 12, hx("efe0b0"))
    cv.rect(7, 18, 6, 2, hx("c8b078"))
    cv.rect(19, 21, 10, 8, hx("9a6a3e"))
    cv.frame(19, 21, 10, 8, WOOD_D)
    cv.rect(21, 23, 6, 2, hx("b78650"))
    cv.rect(32, 22, 5, 7, hx("e0603c"))
    cv.rect(38, 22, 6, 7, hx("6fc06f"))
    cv.save("shelf")


if __name__ == "__main__":
    make_house()
    make_shop()
    make_floors()
    make_bed()
    make_kitchen()
    make_tv()
    make_counter()
    make_shelf()
    print("selesai:", sorted(os.listdir(OUT)))
