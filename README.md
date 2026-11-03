# Catatan Harian

Aplikasi catatan harian sederhana berbasis Flutter. Dibuat sebagai tugas project penggunaan paket/plugin dari [pub.dev](https://pub.dev), dengan fitur utama menyimpan catatan secara lokal dan menampilkan tanggal pembuatannya.

## Fitur

- Tambah, ubah, dan hapus catatan dengan validasi judul dan isi tidak boleh kosong.
- Tanggal dan jam pembuatan tampil dalam bahasa Indonesia, misalnya `Senin, 2 November 2026 • 19:56`.
- Data tersimpan di perangkat dan tetap ada setelah aplikasi ditutup.
- **Sidebar** (ikon menu kiri atas) dengan tiga menu:
  - **Semua Catatan**: catatan biasa yang tidak terkunci.
  - **Catatan Terkunci**: catatan yang dilindungi PIN 4 angka. PIN dibuat saat menu ini dibuka pertama kali.
  - **Baru Dihapus**: catatan yang dihapus. Bisa dipulihkan atau dihapus permanen, dan otomatis dihapus permanen setelah 30 hari.
- **Tema gelap/terang** (ikon kanan atas). Pilihan tersimpan.
- **Tiga pilihan tampilan** (ikon kanan atas): daftar, kartu, dan kisi. Pilihan tersimpan.
- Menu titik tiga (⋮) pada setiap catatan: ubah, kunci/lepas kunci, hapus (atau pulihkan/hapus permanen di Baru Dihapus).
- Tombol **URUNGKAN** muncul setelah menghapus catatan.

## Paket yang Digunakan

| Paket | Fungsi dalam aplikasi |
|---|---|
| [`shared_preferences`](https://pub.dev/packages/shared_preferences) | Menyimpan daftar catatan (JSON), PIN, pilihan tema, dan pilihan tampilan secara lokal. |
| [`intl`](https://pub.dev/packages/intl) | Memformat tanggal dan jam dalam bahasa Indonesia (`id_ID`). |

## Struktur Proyek

```
catatan_application/
├── lib/
│   └── main.dart        # seluruh kode aplikasi
├── pubspec.yaml         # dependencies
└── README.md
```

Kelas utama di `lib/main.dart`:

- `CatatanApp`: aplikasi dan pengaturan tema terang/gelap.
- `Catatan`: model data (judul, isi, tanggal, status terkunci, status dihapus).
- `HomePage`: halaman utama, sidebar, daftar catatan, dan logika PIN serta sampah.
- `FormCatatanPage`: form tambah dan ubah catatan.

## Cara Menjalankan

Prasyarat: [Flutter SDK](https://docs.flutter.dev/get-started/install) terpasang dan `flutter doctor` tidak menunjukkan masalah berarti.

1. Buka folder proyek, lalu pasang paket:

   ```bash
   flutter pub add shared_preferences intl
   flutter pub get
   ```

   Setelah itu `pubspec.yaml` berisi:

   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     shared_preferences: ^x.x.x
     intl: ^x.x.x
   ```

2. Jalankan aplikasi:

   ```bash
   flutter run
   ```

   Pilih perangkat yang tersedia (emulator Android, HP, atau Chrome). Untuk Chrome dengan port tetap:

   ```bash
   flutter run -d web-server --web-port=5000
   ```

   lalu buka `http://localhost:5000`.

## Cara Menggunakan

1. Tekan tombol **+** untuk membuat catatan, isi judul dan isi, lalu tekan **Simpan**.
2. Ketuk catatan untuk mengubahnya, atau tekan titik tiga (⋮) untuk memilih ubah, kunci, atau hapus.
3. Buka sidebar lewat ikon menu di kiri atas untuk berpindah antar halaman.
4. Ganti tema dan tampilan lewat dua ikon di kanan atas.
5. Untuk mengunci catatan, aktifkan saklar **Kunci catatan** di form atau pilih **Kunci** dari menu titik tiga. Catatan terkunci hanya tampil di **Catatan Terkunci** setelah memasukkan PIN.

## Pengujian

Skenario pengujian ada di `dokumentasi_pengujian.md` (17 skenario), mencakup tambah/ubah/hapus catatan, validasi form, penyimpanan setelah aplikasi ditutup, format tanggal, sidebar, tema, tampilan, PIN, dan sampah.

## Catatan

- PIN disimpan apa adanya di `shared_preferences`. Ini pengamanan sederhana untuk keperluan belajar dan bukan enkripsi.
- Di Chrome, data tersimpan di `localStorage` yang terpisah untuk setiap port. Pakai port tetap (`--web-port`) agar catatan tidak tampak hilang. Menghapus data browser juga menghapus catatan dan PIN.
- `initializeDateFormatting('id_ID', null)` di fungsi `main()` wajib ada. Tanpa itu, format tanggal berbahasa Indonesia menimbulkan error `LocaleDataException`.
- Catatan versi lama (tanpa field terkunci dan dihapus) tetap terbaca dan tampil di Semua Catatan.
