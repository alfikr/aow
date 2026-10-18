# Harvest Moon: Back to Nature (fan remake)

Prototipe pertanian 2D dengan Godot 4 (GDScript, tanpa aset eksternal).

Buka folder ini di Godot 4.3+ lalu jalankan (F5). Berjalan di Linux.

Uji asap tanpa jendela:

    godot --headless --path . res://tests/smoke.tscn


## Kontrol
- WASD / panah: jalan
- 1 / 2 / 3: cangkul / penyiram / benih (Q ganti jenis benih)
- Spasi: pakai alat di tile depan
- F6 simpan, F9 muat, F10 game baru (simpan otomatis tiap pagi)
- E: interaksi (panen, kotak kirim, toko benih, isi air di kolam, tidur di pintu rumah)

## Alur
Cangkul -> tanam -> siram tiap hari -> panen setelah matang -> kirim -> tidur untuk menerima uang.

## Rencana
Lihat `docs/DESIGN.md`.
