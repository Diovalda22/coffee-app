# 🚀 Fullstack Project: Flutter & Laravel API

Dokumentasi ini dibuat untuk mempermudah proses setup lingkungan pengembangan (development environment) pada perangkat baru. Project ini mengintegrasikan mobile app (Flutter) dengan backend (Laravel) dan database (MySQL).

---

## 🛠 Tech Stack

- **Frontend:** Flutter (Dart)
- **Backend:** Laravel (PHP)
- **Database:** MySQL
- **Tooling:** Composer, Flutter SDK, Git

---

## 📋 Prasyarat Sistem

Sebelum memulai, pastikan perangkat Anda sudah terinstall komponen berikut dengan versi yang sesuai:

| Komponen         | Versi Minimal            | Link Download                                                                                      |
| :--------------- | :----------------------- | :------------------------------------------------------------------------------------------------- |
| **Flutter SDK**  | `3.29.0` (Stable)        | [Download Flutter](https://docs.flutter.dev/get-started/install)                                   |
| **Dart SDK**     | `3.7.0`                  | [Download Dart](https://dart.dev/get-dart)                                                         |
| **PHP**          | `^8.2`                   | [Download PHP](https://www.php.net/downloads)                                                      |
| **Composer**     | `Latest`                 | [Download Composer](https://getcomposer.org/download/)                                             |
| **MySQL Server** | `8.0`                    | [Download XAMPP](https://www.apachefriends.org/download.html)                                      |
| **IDE**          | VS Code / Android Studio | [VS Code](https://code.visualstudio.com/) / [Android Studio](https://developer.android.com/studio) |

> [!IMPORTANT]  
> Pastikan ekstensi **Flutter** dan **Dart** sudah terinstall pada IDE pilihan Anda.

---

## ⚙️ Langkah Instalasi

### 1. Setup Backend (Laravel API)

1.  Buka terminal dan masuk ke folder backend:
    ```bash
    cd backend-coffee
    ```
2.  Install dependency PHP:
    ```bash
    composer install
    ```
3.  Konfigurasi Environment:
    ```bash
    cp .env.example .env
    php artisan key:generate
    ```
4.  Sesuaikan konfigurasi database di file `.env`:
    ```env
    DB_CONNECTION=mysql
    DB_HOST=127.0.0.1
    DB_PORT=3306
    DB_DATABASE=coffee_db
    DB_USERNAME=root
    DB_PASSWORD=
    ```
5.  Jalankan migrasi database:
    ```bash
    php artisan migrate
    ```
6.  Jalankan server API:
    ```bash
    php artisan serve
    ```

---

### 2. Setup Frontend (Flutter)

1.  Masuk ke folder frontend:
    ```bash
    cd coffee-app
    ```
2.  Install paket-paket Flutter:
    ```bash
    flutter pub get
    ```
3.  **Konfigurasi Environment Flutter:**
    Buat file `.env` di root folder `coffee-app` (jika belum ada) dan sesuaikan:
    ```env
    API_BASE_URL=http://localhost:8000/api
    ```
4.  **Konfigurasi API URL (Manual):**
    Buka `lib/constants.dart` atau file konfigurasi terkait dan sesuaikan `baseUrl`:
    - **Emulator Android:** `http://10.0.2.2:8000/api`
    - **Chrome / Lokal:** `http://localhost:8000/api`
    - **Physical Device:** Gunakan IP Private Laptop Anda.
5.  Jalankan aplikasi:
    ```bash
    flutter run
    ```
