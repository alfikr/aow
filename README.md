# Lembah Panen

Game simulasi pertanian 2D (Godot 4, GDScript), **terinspirasi** dari *Harvest Moon: Back to Nature*.
Proyek penggemar: dunia, nama, dan karakternya orisinal. Semua aset dibuat lewat kode dan bebas lisensi (CC0):
- semua bangunan dan isi interiornya memakai sprite pixel-art (`tools/gen_sprites.py`);
- pemain, 5 warga, ayam, sapi, dan anjing juga bersprite berarah dengan animasi jalan (`tools/gen_characters.py`);
- dunia: tekstur rumput/jalan/pasir/air beranimasi, pohon, pagar, lampu (bercahaya malam hari), tanaman per tahap, tambang, dll. (`tools/gen_world.py`);
- variasi musim (panas, gugur, dingin) dan hiasan musiman (`tools/gen_seasons.py`); jalankan `gen_world.py` dulu, lalu `gen_seasons.py`;
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

## Musim & cuaca
Tampilan dunia berubah tiap musim: semi (bunga, kelopak beterbangan), panas (bunga matahari, kunang-kunang di malam hari), gugur (daun oranye, rumput kering, daun berguguran), dingin (salju, kolam membeku, boneka salju). Hujan dan salju punya partikel sendiri, dan hujan punya suara latar di luar ruangan.

## Cara bermain
- **Bertani:** cangkul, tanam, siram tiap hari, panen, masukkan ke kotak kirim (E). Uang diterima saat tidur.
  4 musim × 30 hari; tanaman layu bila musim berganti. Tomat dan jagung berbuah berulang.
- **Desa:** toko (09:00-18:00) menjual benih, pakan, hewan, upgrade alat, dan Bulu Biru. Di deretan utara ada toko, penginapan, dan balai desa; tambang di utara, pantai di timur, dan **Permukiman** di selatan (rumah Raka, Nenek Lila, dan Pak Dodi, masing-masing berbeda).
- **Hewan:** ayam dan sapi (beri pakan tiap hari, ambil telur/susu), plus anjing yang mengikutimu.
- **Warga:** 5 NPC dengan jadwal harian, dialog musiman, hadiah (tiap orang punya selera dan ulang tahun), 10 hati, event hati.
- **Batu:** ladang berisi batu kecil (sekali pukul) dan batu besar 2×2 (4 pukulan dengan Cangkul Dasar, 2 dengan Tembaga, 1 dengan Perak) yang menghalangi pencangkulan; batu kecil baru muncul dari waktu ke waktu. Di tambang ada batu kecil dan batu besar berbijih.
- **Tambang:** 10 lantai; pecahkan batu dengan cangkul. Bijih tembaga/perak dipakai untuk upgrade alat.
- **Hutan Rahasia:** peta tersembunyi di balik batu raksasa bersulur di tepi timur ladang (butuh Cangkul Tembaga). Isinya patung Dewi Panen (persembahan hasil panen memberi berkah esok pagi), peti harta, dan jamur serta herba langka yang tumbuh lagi tiap hari. Nenek Lila memberi petunjuknya.
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
assets/sprites/  sprite pixel-art (tools/gen_sprites.py, gen_characters.py, gen_world.py, gen_seasons.py)
docs/DESIGN.md Keputusan desain dan peta jalan
```
Menambah tanaman, ikan, resep, atau warga cukup dengan mengedit berkas JSON di `data/`.

## Catatan
- Data simpanan: `user://save.json` (Linux: `~/.local/share/godot/app_userdata/Lembah Panen/`).
- Belum ada lisensi yang dipilih untuk kode ini.
