# Desain: farm sim 2D terinspirasi Harvest Moon: Back to Nature

## Keputusan
- 2D top-down, Godot 4.3, GDScript.
- Terinspirasi, bukan salinan: dunia, nama, dan karakter orisinal. Tidak memakai aset game aslinya.
- Aset placeholder (bentuk kotak digambar lewat kode) sampai ada paket aset.
- Cakupan awal kecil: 1 desa kecil, sekitar 5 NPC, 4 musim, sekitar 5 tanaman.

## Arsitektur
- Autoload: `Events` (sinyal), `Data` (JSON statis), `Clock` (waktu/kalender/cuaca),
  `Inventory` (uang/barang/kotak kirim), `SaveSystem` (satu file JSON).
- Node yang punya state masuk grup `saveable` dan menyediakan `save_key`, `save_data()`, `load_data()`.
- Area didefinisikan di `data/areas.json` sebagai daftar fitur (building, exit, bin, shop, water, ...); `World` menggambar dan menjawab pertanyaan lintasan.
- Data konten ada di `data/*.json`; menambah tanaman cukup menambah entri.
- Urutan akhir hari: `day_ended` (tumbuh, bayar) -> maju tanggal (`season_changed`) -> cuaca -> `day_started` (hujan menyiram, simpan otomatis).

## Peta jalan
1. [x] Fondasi: autoload, data JSON, simpan/muat, uji asap.
2. [x] Pertanian penuh: menu toko & inventori, upgrade alat (Dasar/Tembaga/Perak), tanaman berulang (tomat, jagung), festival musiman (bonus harga jual).
3. [x] Dunia: area berbasis data (`data/areas.json`: peternakan, desa, interior toko), pintu perpindahan, jam buka toko.
4. [x] Hewan: ayam & sapi (kandang interior, pakan, telur/susu, kasih sayang), anjing pengikut. Kuda ditunda.
5. [x] NPC: 5 warga (jadwal harian/cuaca/akhir pekan, jalan BFS, dialog musiman, hadiah dengan selera & ulang tahun, hati 0-10, event hati dengan hadiah, lamaran).
6. [x] Lanjutan: memancing (kolam & pantai, musim/kelangkaan), tambang 10 lantai (bijih untuk upgrade alat), memasak (6 resep, makan pulihkan stamina), TV ramalan cuaca, pernikahan + anak, ending setelah 2 tahun.
7. [x] Polesan: audio sintetis (efek + 3 musik, bus Music/SFX), pengaturan, menu judul/jeda/bantuan, renderer Compatibility, preset export Linux + skrip build, validator data, uji soak.

## Tambahan
Batu kecil/besar di ladang dan tambang; Hutan Rahasia (peta tersembunyi: batu raksasa -> Cangkul Tembaga, patung Dewi Panen, peti, hasil hutan).

## Status
Semua tahap pada peta jalan selesai. Ide lanjutan: kuda, hewan sakit, pohon buah, kota kedua, festival interaktif, lebih banyak NPC/event, seni piksel sungguhan menggantikan placeholder.

## Risiko
Volume konten (dialog, peta, event), konsistensi aset, dan pengujian visual oleh manusia.
