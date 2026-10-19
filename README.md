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
- I: inventori. Di toko (E): W/S pilih, Enter beli benih atau upgrade alat, Esc tutup
- E: interaksi (panen, kotak kirim, toko benih, isi air di kolam, tidur di pintu rumah)

## Dunia
Peternakan -> (pintu timur) -> Desa -> Toko (buka 09:00-18:00). Benih dan upgrade alat dibeli di konter toko.

## Hewan
Beli pakan, ayam (300G), dan sapi (1500G) di toko desa. Kandang ada di sisi barat peternakan. Beri pakan tiap hari (E pada hewan), ambil telur/susu keesokan harinya, lalu kirim lewat kotak kirim. Anjing mengikutimu; elus dengan E.

## Warga
Bicara dengan E pada NPC (menu: Bicara / Beri hadiah). Tiap NPC punya jadwal, selera hadiah, dan ulang tahun. Sampai 8 hati, bawa Bulu Biru untuk melamar Mira atau Sari.

## Alur
Cangkul -> tanam -> siram tiap hari -> panen setelah matang -> kirim -> tidur untuk menerima uang.

## Rencana
Lihat `docs/DESIGN.md`.
