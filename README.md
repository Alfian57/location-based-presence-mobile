# Presensi Mobile

Aplikasi mobile Presensi Guru berbasis Flutter. Aplikasi ini dipakai guru untuk presensi masuk/pulang berbasis lokasi sekolah, melihat riwayat presensi, mengajukan izin/sakit/cuti, dan mengelola profil dasar.

## Ringkasan Bisnis

Presensi Mobile adalah kanal utama guru untuk mencatat kehadiran harian. Aplikasi mengambil lokasi perangkat, mengirim ID perangkat yang terikat, dan mengirim status lokasi palsu ke backend agar presensi dapat divalidasi secara lebih akurat.

Manfaat untuk sekolah:

- Guru bisa presensi dari perangkat sendiri tanpa mesin presensi fisik.
- Presensi divalidasi dengan radius lokasi sekolah.
- Perangkat guru dapat diikat untuk mengurangi penyalahgunaan akun.
- Pengajuan izin dapat dikirim langsung dari aplikasi dengan dokumen pendukung.
- Riwayat presensi dan status pengajuan transparan untuk guru.

## Role dan Fitur

Mobile ditujukan untuk role `guru`. Role pengelola menggunakan dashboard web.

| Role | Kanal | Fitur |
| --- | --- | --- |
| Guru | Mobile | Login, aktivasi perangkat, presensi masuk/pulang, riwayat presensi, pengajuan izin/sakit/cuti, upload dokumen, profil, pengaturan notifikasi, logout. |
| Admin | Web | Membuat akun guru, mengelola jadwal/lokasi, reset perangkat guru, koreksi presensi, approval izin, laporan. |
| Kepala Sekolah | Web | Dashboard analitik, monitoring presensi/pengajuan, laporan, ekspor. |

## Fitur Mobile

- Login guru memakai email dan kata sandi dari admin sekolah.
- Penyimpanan token lokal melalui platform channel.
- Binding perangkat saat login pertama.
- Presensi masuk dan pulang berdasarkan lokasi GPS.
- Deteksi lokasi palsu dari native platform dan pengiriman status ke backend.
- Ringkasan status presensi hari ini.
- Jadwal kerja dan lokasi aktif dari backend.
- Riwayat presensi bulanan.
- Pengajuan izin, sakit, dan cuti.
- Upload dokumen pendukung pengajuan.
- Daftar pengajuan dan status review.
- Profil guru, mata pelajaran, jabatan, jadwal mengajar, dan status notifikasi.
- Toggle notifikasi aktif.
- Logout dan pembersihan token lokal.

## Stack Teknis

- Flutter dengan Dart SDK `^3.11.1`
- Material 3
- HTTP native melalui `dart:io` `HttpClient`
- `flutter_dotenv` untuk membaca konfigurasi `.env`
- Native bridge `MethodChannel('presensi/device')`
- Penyimpanan token lokal melalui method channel
- Pengambilan lokasi, status mock location, info perangkat, dan dokumen melalui native platform
- Asset logo di `assets/images/app_logo.png`

## Struktur Penting

```text
lib/main.dart                         Composition root aplikasi
lib/core/domain/                      Value object dan model domain lintas fitur
lib/core/data/                        Infrastruktur data bersama, seperti API client
lib/core/platform/                    Bridge native perangkat
lib/core/presentation/                Widget, tema, dan helper UI bersama
lib/features/auth/                    Fitur login, aktivasi, reset kata sandi
lib/features/presence/                Fitur presensi masuk/pulang dan validasi lokasi
lib/features/leave/                   Fitur izin, sakit, cuti, dan upload dokumen
lib/features/history/                 Fitur riwayat presensi bulanan
lib/features/profile/                 Fitur profil, notifikasi, dan logout
assets/images/app_logo.png            Logo aplikasi
assets/images/avatar_placeholder.png  Avatar placeholder
android/                              Implementasi Android dan launcher icon
ios/                                  Konfigurasi iOS
web/                                  Konfigurasi Flutter web/PWA
test/                                 Widget/unit test
pubspec.yaml                          Dependency, asset, dan metadata aplikasi
.env.example                          Contoh konfigurasi API mobile
```

## Arsitektur Mobile

Aplikasi memakai pendekatan clean architecture secara feature-first:

- `features/<nama>/presentation`: halaman dan widget yang berhubungan langsung dengan tampilan fitur.
- `features/<nama>/data`: repository tipis yang menyembunyikan detail endpoint API atau akses platform dari presentation.
- `core/domain`: model domain lintas fitur yang tidak bergantung pada UI, seperti snapshot lokasi dan dokumen pilihan.
- `core/data`: komponen data lintas fitur seperti `ApiClient`.
- `core/platform`: integrasi native lintas fitur seperti info perangkat, lokasi, dokumen, dan permission notifikasi.
- `core/presentation`: komponen UI bersama, formatter, dialog, toast, dan helper responsif.

`main.dart` berperan sebagai composition root: membaca konfigurasi `.env`, membangun theme, memulihkan sesi, dan memilih halaman awal. Fitur baru sebaiknya dibuat di folder `lib/features/<nama_fitur>/` dengan minimal layer `data` dan `presentation`.

## Kebutuhan Backend

Aplikasi mobile membutuhkan API dari project web Laravel pada path `/api/mobile`.

Base URL lokal umum:

```text
http://127.0.0.1:8000/api/mobile
```

Untuk emulator Android gunakan:

```text
http://10.0.2.2:8000/api/mobile
```

Pastikan backend sudah menjalankan migrasi dan seeder, minimal memiliki:

- Akun guru aktif.
- Jadwal kerja aktif.
- Lokasi sekolah aktif dengan latitude, longitude, dan radius.
- API mobile dapat diakses dari perangkat/emulator.

## Menjalankan Lokal

1. Install dependency.

```bash
flutter pub get
```

2. Siapkan `.env`.

```bash
cp .env.example .env
```

Untuk perangkat fisik, gunakan IP komputer pada jaringan lokal:

```env
API_BASE_URL=http://192.168.1.10:8000
```

Nilai boleh berupa domain root, `/api`, atau `/api/mobile`; aplikasi akan menormalkan ke endpoint `/api/mobile`.

3. Jalankan aplikasi.

```bash
flutter run
```

4. Login dengan akun guru dari seeder demo.

```text
Email: guru@presensi.test
Password: password
```

## Build

Build APK release:

```bash
flutter build apk --release
```

Build untuk platform lain mengikuti target Flutter yang tersedia:

```bash
flutter build web
```

## Konfigurasi API

Base URL API dibaca dari file `.env`:

```env
API_BASE_URL=http://10.0.2.2:8000
```

File `.env` tidak di-commit. Gunakan `.env.example` sebagai template, lalu isi `API_BASE_URL` sesuai backend target sebelum menjalankan atau membangun aplikasi.

## Integrasi API

Endpoint yang dipakai aplikasi:

| Method | Endpoint | Fungsi |
| --- | --- | --- |
| POST | `/autentikasi/masuk` | Login guru dan binding perangkat. |
| POST | `/autentikasi/keluar` | Logout token. |
| GET | `/profil` | Ambil profil guru. |
| PUT | `/profil/pengaturan-notifikasi` | Ubah pengaturan notifikasi. |
| GET | `/jadwal-kerja` | Ambil jadwal kerja dan lokasi aktif. |
| GET | `/presensi/hari-ini` | Ambil status presensi hari ini. |
| POST | `/presensi/catat` | Kirim presensi masuk/pulang. |
| GET | `/presensi/riwayat` | Ambil riwayat presensi bulanan. |
| GET | `/pengajuan-izin` | Ambil daftar pengajuan izin. |
| POST | `/pengajuan-izin` | Kirim pengajuan izin/sakit/cuti dengan dokumen opsional. |

Payload presensi mengirim data penting berikut:

- `jenis`: `masuk` atau `pulang`
- `latitude`
- `longitude`
- `akurasi`
- `id_perangkat`
- `lokasi_palsu`
- `waktu_klien`

## Alur Pengguna Guru

1. Guru login memakai akun yang dibuat admin.
2. Backend mengikat perangkat pertama yang berhasil login.
3. Aplikasi mengambil lokasi dan status mock location dari perangkat.
4. Guru menekan presensi masuk atau pulang.
5. Backend memvalidasi lokasi, radius, perangkat, jadwal, hari libur, dan status akun.
6. Guru dapat melihat status hari ini dan riwayat bulanan.
7. Jika berhalangan, guru mengirim pengajuan izin/sakit/cuti beserta dokumen opsional.
8. Status pengajuan akan berubah setelah admin meninjau di web.

## Testing

Jalankan test:

```bash
flutter test
```

Analisis statis:

```bash
flutter analyze
```

## CI/CD

Workflow berada di `.github/workflows/mobile.yml`.

- Pull request: menjalankan `dart analyze` dan `flutter test`.
- Push ke `main` atau `master`: menjalankan test, build APK release, lalu membuat/memperbarui prerelease `mobile-latest` di tab GitHub Releases.
- Push tag `mobile-v*` atau `v*`: menjalankan test, build APK release, lalu membuat GitHub Release sesuai tag.
- Manual workflow dispatch: bisa membuat release dengan tag input, default `mobile-latest`.

Variable opsional:

- `MOBILE_API_BASE_URL`: URL API backend mobile. Jika tidak diisi, workflow membuat `.env` dengan `https://example.com/api/mobile`.

Workflow CI membuat file `.env` dari `.env.example` untuk analyze/test, dan membuat `.env` dari `MOBILE_API_BASE_URL` untuk build release APK.

Contoh release final:

```bash
git tag mobile-v1.0.0
git push origin mobile-v1.0.0
```

## Branding

Logo aplikasi berada di `assets/images/app_logo.png`.
Launcher icon Android/iOS/macOS/Windows dan icon web sudah memakai logo yang sama.
