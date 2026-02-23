# 📱 Flutter Documentation: Coffee App

Dokumentasi ini menjelaskan secara rinci tentang arsitektur, dependensi, dan langkah-langkah pengembangan untuk modul frontend Coffee App.

## 🛠 Tech Stack Detail

- **Framework:** Flutter (Channel Stable)
- **Dart SDK:** `^3.7.0`
- **State Management:** `provider`
- **Storage:** `shared_preferences`
- **Networking:** `http`, `cached_network_image`
- **Extra UI:** `curved_navigation_bar`, `another_flushbar`

## 🚀 Persiapan Lingkungan

### 1. Install Flutter SDK

Pastikan Flutter SDK sudah terpasang dengan menjalankan perintah:

```bash
flutter doctor
```

Setidaknya Anda memerlukan:

- [ ] Flutter installed
- [ ] Android toolchain (untuk pengembangan Android)
- [ ] Chrome (untuk debugging web)
- [ ] VS Code / Android Studio with Flutter plugin

### 2. Setup Assets & Config

Aplikasi ini menggunakan aset gambar dan font kustom (Pacifico). Pastikan file `.env` sudah ada di root folder `coffee-app` karena dideklarasikan di `pubspec.yaml`.

## 📦 Dependensi Utama

| Package                | Kegunaan                                           |
| :--------------------- | :------------------------------------------------- |
| `http`                 | Melakukan request ke Laravel API.                  |
| `provider`             | Mengelola state aplikasi (Cart, Auth, dll).        |
| `flutter_dotenv`       | Membaca konfigurasi dari file `.env`.              |
| `cached_network_image` | Menampilkan gambar produk dari URL dengan caching. |
| `image_picker`         | Mengambil foto untuk profil atau produk.           |

## 🔗 Integrasi API

Konfigurasi koneksi API berada di `lib/` (biasanya file `constants.dart` atau `config.dart`).

> [!CAUTION]  
> Jika menjalankan di **Android Emulator**, jangan gunakan `localhost`. Gunakan `10.0.2.2`.

## 🧪 Perintah Pengembangan

- **Ambil Dependensi:** `flutter pub get`
- **Jalankan Aplikasi:** `flutter run`
- **Build APK:** `flutter build apk --release`
- **Clean Project:** `flutter clean`

---

_Dibuat untuk Project Coffee App - 2026_
