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
- Data konten ada di `data/*.json`; menambah tanaman cukup menambah entri.
- Urutan akhir hari: `day_ended` (tumbuh, bayar) -> maju tanggal (`season_changed`) -> cuaca -> `day_started` (hujan menyiram, simpan otomatis).

## Peta jalan
1. [x] Fondasi: autoload, data JSON, simpan/muat, uji asap.
2. [ ] Pertanian penuh: inventori + UI, upgrade alat, tanaman berulang, festival.
3. [ ] Dunia: peta desa, pintu/transisi scene, toko.
4. [ ] Hewan: ayam, sapi, anjing, kuda.
5. [ ] NPC: jadwal, dialog, hadiah, hubungan, event.
6. [ ] Lanjutan: tambang, memancing, memasak, pernikahan, ending.
7. [ ] Polesan: suara, menu, export Linux.

## Risiko
Volume konten (dialog, peta, event), konsistensi aset, dan pengujian visual oleh manusia.
