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
Sebelum memulai, pastikan laptop sudah terinstall:
* **Flutter SDK** (Channel Stable)
* **PHP >= 8.1** & **Composer**
* **MySQL Server** (XAMPP / Laragon / Native)
* **IDE:** VS Code / Android Studio (dengan ekstensi Flutter & Dart)

---

## ⚙️ Langkah Instalasi

### 1. Setup Backend (Laravel API)
1.  Buka terminal dan masuk ke folder backend:
    ```bash
    cd folder-backend-anda
    ```
2.  Install semua dependency PHP:
    ```bash
    composer install
    ```
3.  Duplikasi file environment:
    ```bash
    cp .env.example .env
    ```
4.  Generate application key:
    ```bash
    php artisan key:generate
    ```
5.  Sesuaikan konfigurasi database di file `.env`:
    ```env
    DB_CONNECTION=mysql
    DB_HOST=127.0.0.1
    DB_PORT=3306
    DB_DATABASE=nama_db_anda
    DB_USERNAME=root
    DB_PASSWORD=
    ```
6.  Jalankan migrasi database:
    ```bash
    php artisan migrate
    ```
7.  Nyalakan server lokal:
    ```bash
    php artisan serve
    ```

---

### 2. Setup Frontend (Flutter)
1.  Buka terminal baru dan masuk ke folder frontend:
    ```bash
    cd folder-flutter-anda
    ```
2.  Ambil paket-paket yang diperlukan:
    ```bash
    flutter pub get
    ```
3.  **Konfigurasi API URL:**
    Buka file konfigurasi API (misal: `lib/constants.dart`) dan sesuaikan `baseUrl`:
    - **Emulator Android:** Gunakan `http://10.0.2.2:8000/api`
    - **Physical Device:** Gunakan IP Laptop Anda (contoh: `http://192.168.1.5:8000/api`)
4.  Jalankan aplikasi:
    ```bash
    flutter run
    ```