# Presensi Mobile

Aplikasi Android Presensi Guru berbasis Flutter.

## CI/CD

Workflow berada di `.github/workflows/mobile.yml`.

- Pull request: menjalankan `dart analyze` dan `flutter test`.
- Push ke `main` atau `master`: menjalankan test, build APK release, lalu membuat/memperbarui prerelease `mobile-latest` di tab GitHub Releases.
- Push tag `mobile-v*` atau `v*`: menjalankan test, build APK release, lalu membuat GitHub Release sesuai tag.
- Manual workflow dispatch: bisa membuat release dengan tag input, default `mobile-latest`.

Variable opsional:

- `MOBILE_API_BASE_URL`: URL API backend mobile. Jika tidak diisi, workflow memakai `https://example.com/api/mobile`.

Contoh release final:

```bash
git tag mobile-v1.0.0
git push origin mobile-v1.0.0
```
