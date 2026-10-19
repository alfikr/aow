# Lembah Panen

Game simulasi pertanian 2D (Godot 4, GDScript), **terinspirasi** dari *Harvest Moon: Back to Nature*.
Proyek penggemar: dunia, nama, dan karakternya orisinal. Semua aset dibuat lewat kode dan bebas lisensi (CC0):
- rumah, toko, dan isi interiornya memakai sprite pixel-art (`tools/gen_sprites.py`); bangunan lain masih placeholder berbentuk kotak;
- semua suara disintesis (`tools/gen_audio.py`).

Tidak memakai aset game aslinya.

## Menjalankan

### Dengan editor Godot
1. Pasang **Godot 4.3 atau lebih baru** (build Linux resmi: https://godotengine.org/download/linux).
2. Buka `project.godot`, tunggu impor aset selesai, lalu tekan **F5**.

Renderer yang dipakai **Compatibility (OpenGL)**, jadi jalan di GPU lama maupun mesin virtual.

### Binary Linux mandiri (tanpa Godot di komputer pemain)
```bash
# sekali saja: Editor > Project > Export > Manage Export Templates > Download and Install
GODOT=/path/ke/Godot_v4.3-stable_linux.x86_64 tools/build_linux.sh
./build/lembah-panen.x86_64
```
Hasilnya satu berkas (`build/lembah-panen.x86_64`, sekitar 70 MB).

## Kontrol
| Tombol | Fungsi |
|---|---|
| WASD / panah | Jalan |
| Spasi | Pakai alat di tile depan (saat memancing: tarik kail) |
| 1 / 2 / 3 / 4 | Cangkul / Penyiram / Benih / Pancing (Q ganti jenis benih) |
| E | Bicara, panen, ambil produk, pakai benda (kasur, dapur, TV, kotak kirim, toko) |
| I | Inventori (Enter pada masakan untuk makan) |
| Esc | Menu jeda (simpan, pengaturan, bantuan, menu utama) |
| F6 / F9 | Simpan / muat cepat. Game juga menyimpan otomatis tiap pagi |
| F11 | Layar penuh |

## Cara bermain
- **Bertani:** cangkul, tanam, siram tiap hari, panen, masukkan ke kotak kirim (E). Uang diterima saat tidur.
  4 musim × 30 hari; tanaman layu bila musim berganti. Tomat dan jagung berbuah berulang.
- **Desa:** toko (09:00-18:00) menjual benih, pakan, hewan, upgrade alat, dan Bulu Biru. Tambang di utara, pantai di timur.
- **Hewan:** ayam dan sapi (beri pakan tiap hari, ambil telur/susu), plus anjing yang mengikutimu.
- **Warga:** 5 NPC dengan jadwal harian, dialog musiman, hadiah (tiap orang punya selera dan ulang tahun), 10 hati, event hati.
- **Tambang:** 10 lantai; pecahkan batu dengan cangkul. Bijih tembaga/perak dipakai untuk upgrade alat.
- **Memancing:** kolam di peternakan dan laut di pantai; ikan bergantung pada musim dan tempat.
- **Memasak:** dapur di rumah. Resep baru didapat dari event hati. TV di rumah menampilkan ramalan cuaca besok.
- **Pernikahan:** beli Bulu Biru (3000G), beri ke Mira atau Sari dengan 8 hati. Pasangan membantu menyiram, dan kelak ada anak.
- **Ending** muncul saat tahun ke-3 dimulai (skor merangkum progresmu); permainan boleh dilanjutkan.

## Uji
```bash
GODOT=/path/ke/godot tools/run_tests.sh      # smoke + validasi data + soak 120 hari
```
- `tests/smoke.tscn` : uji perilaku (144 cek)
- `tests/validate.tscn` : validasi data (area, pintu, spawn, jadwal NPC, resep, ikan)
- `tests/soak.tscn` : aksi acak ratusan hari untuk mencari error runtime
- `tests/shot.tscn` : screenshot tiap layar (butuh display: `xvfb-run -a godot --path . res://tests/shot.tscn -- folder`)

## Struktur
```
scenes/        title.tscn, main.tscn
scripts/autoload/   Events, Settings, Data, Clock, Inventory, Progress, SaveSystem, Audio
scripts/world/      World, Farm, Player, Livestock, Dog, Npcs, Fishing, Mine, ...
scripts/            menu.gd (toko/inventori/dialog/dapur/jeda), hud.gd, title.gd
data/          crops, animals, areas, npcs, items, fish, recipes, festivals (JSON)
assets/audio/    efek suara & musik hasil sintesis (tools/gen_audio.py)
assets/sprites/  sprite pixel-art rumah, toko, dan interior (tools/gen_sprites.py)
docs/DESIGN.md Keputusan desain dan peta jalan
```
Menambah tanaman, ikan, resep, atau warga cukup dengan mengedit berkas JSON di `data/`.

## Catatan
- Data simpanan: `user://save.json` (Linux: `~/.local/share/godot/app_userdata/Lembah Panen/`).
- Belum ada lisensi yang dipilih untuk kode ini.
