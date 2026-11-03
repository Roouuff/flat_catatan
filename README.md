# Dokumentasi Project: Aplikasi Catatan Harian (Flutter)

Nama      : Muhammad Abdul Rouf
Kelas     : Teknik Informatika

## 1. Deskripsi Aplikasi
Aplikasi Catatan Harian adalah aplikasi mobile sederhana untuk menulis, melihat, mengubah, dan menghapus catatan. Setiap catatan menampilkan tanggal dan jam pembuatan dalam format bahasa Indonesia. Data tersimpan di perangkat sehingga tidak hilang setelah aplikasi ditutup.

## 2. Paket yang Digunakan
| Paket | Versi (lihat pubspec.yaml) | Fungsi dalam aplikasi |
|---|---|---|
| shared_preferences | ......... | Menyimpan daftar catatan secara lokal (format JSON) |
| intl | ......... | Memformat tanggal, misalnya "Senin, 2 November 2026 • 19:56" |

Sumber: https://pub.dev/packages/shared_preferences dan https://pub.dev/packages/intl

## 3. Langkah Implementasi
1. Membuat proyek Flutter `catatan_application` di Visual Studio Code.
2. Mencari paket `shared_preferences` dan `intl` di pub.dev.
3. Menambahkan paket dengan `flutter pub add shared_preferences intl`.
4. Menjalankan `flutter pub get`.
5. Mengimpor paket di `lib/main.dart`.
6. Membuat model `Catatan`, halaman daftar, dan halaman form.
7. Menjalankan aplikasi di emulator Android.
8. Menguji seluruh fitur.

## 4. Potongan Kode Penting
(Tempel potongan kode `pubspec.yaml` bagian dependencies dan fungsi `_simpanCatatan` / `_muatCatatan`.)

## 5. Hasil Pengujian
| No | Skenario Uji | Hasil yang Diharapkan | Hasil Aktual | Status |
|---|---|---|---|---|
| 1 | Membuka aplikasi pertama kali | Tampil pesan "Belum ada catatan" | | |
| 2 | Menambah catatan baru | Catatan muncul di daftar dengan tanggal | | |
| 3 | Menyimpan dengan judul kosong | Muncul pesan "Judul wajib diisi" | | |
| 4 | Menyimpan dengan isi kosong | Muncul pesan "Isi catatan wajib diisi" | | |
| 5 | Mengetuk catatan untuk mengubah | Form terisi data lama, perubahan tersimpan | | |
| 6 | Geser catatan ke kiri | Catatan terhapus, muncul SnackBar | | |
| 7 | Tekan "URUNGKAN" setelah hapus | Catatan kembali ke daftar | | |
| 8 | Tutup aplikasi lalu buka lagi | Semua catatan masih ada (shared_preferences) | | |
| 9 | Cek format tanggal | Tanggal dalam bahasa Indonesia (intl) | | |
| 10 | Tekan ikon menu (kiri atas) | Sidebar terbuka dengan 3 menu: Semua Catatan, Catatan Terkunci, Baru Dihapus | | |
| 11 | Tekan ikon tema (kanan atas) | Tema berganti gelap/terang, pilihan tetap tersimpan setelah aplikasi dibuka ulang | | |
| 12 | Tekan ikon tampilan (kanan atas) | Muncul 3 pilihan: Daftar, Kartu, Kisi; tampilan berubah sesuai pilihan dan tersimpan | | |
| 13 | Aktifkan "Kunci catatan" lalu simpan | Catatan hilang dari Semua Catatan dan pindah ke Catatan Terkunci | | |
| 14 | Buka Catatan Terkunci pertama kali | Diminta membuat PIN 4 angka, lalu ulangi PIN | | |
| 15 | Buka Catatan Terkunci dengan PIN salah / benar | PIN salah ditolak; PIN benar menampilkan catatan terkunci | | |
| 16 | Hapus catatan (menu titik tiga) | Catatan pindah ke Baru Dihapus, muncul SnackBar "URUNGKAN" | | |
| 17 | Pulihkan catatan di Baru Dihapus | Catatan kembali ke halaman asalnya | | |
| 18 | Hapus permanen / Kosongkan di Baru Dihapus | Muncul konfirmasi, lalu catatan hilang selamanya | | |

## 6. Screenshot
(Sisipkan screenshot: daftar kosong, form tambah, daftar berisi, form ubah, hapus, data tetap ada setelah restart.)

## 7. Kesimpulan
(Tulis kesimpulan: paket berhasil dipakai, fitur berjalan, kendala yang ditemui dan solusinya.)