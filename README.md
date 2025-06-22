# 📘 CatatIn – Pencatat Keuangan & Evaluasi Finansial

CatatIn adalah aplikasi Flutter yang terhubung ke backend Laravel. Aplikasi ini membantu mencatat pemasukan dan pengeluaran harian, mengelola target tabungan, serta mengevaluasi kesehatan keuangan secara otomatis menggunakan metode **Simple Additive Weighting (SAW)**.

## 🚀 Fitur Utama

### Autentikasi
- Registrasi dan login menggunakan token
- Penyimpanan token dengan `shared_preferences`

### Dashboard
- Ringkasan pemasukan, pengeluaran, dan sisa saldo bulan berjalan
- Grafik tren pemasukan/pengeluaran dan komposisi kategori
- Notifikasi cerdas: defisit, jarang mencatat, pengeluaran berlebihan, pendapatan menurun, hingga target tabungan belum tercapai

### Pencatatan Transaksi
- Input pemasukan atau pengeluaran dengan kategori yang dapat dipilih
- Form keterangan, tanggal, serta nominal (format Rupiah)
- Edit atau hapus transaksi melalui layar riwayat

### Target Tabungan Bulanan
- Atur target tabungan setiap bulan dan pantau progresnya
- Fitur tambah tabungan harian dan riwayat tabungan bulan sebelumnya

### Evaluasi Keuangan
- Hitung skor SAW berdasarkan:
  - Rasio pemasukan/pengeluaran
  - Konsistensi menabung
  - Pengeluaran tak terduga
  - Frekuensi pencatatan
  - Persentase tabungan
- Kategori hasil: Sangat Baik, Baik, Cukup, Kurang, atau Sangat Kurang
- Rekomendasi otomatis sesuai skor

### Riwayat & Filter
- Daftar transaksi lengkap dengan filter jenis (pemasukan/pengeluaran) dan tanggal
- Tersedia opsi hapus atau edit

### Profil Pengguna
- Informasi akun dan ringkasan finansial bulan ini
- Pengaturan sederhana dan fitur logout

## 🛠 Teknologi
- **Flutter** 3.7
- **Laravel** (REST API)
- `fl_chart`, `google_fonts`, `lottie`, `shared_preferences`, dll
- Folder `android/`, `ios/`, `linux/`, `macos/`, `windows/`, dan `web/` untuk dukungan multiplatform

## 📂 Struktur Folder Penting

```
lib/
├── main.dart
├── screens/
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── dashboard_screen.dart
│   ├── add_transaction_screen.dart
│   ├── savings_screen.dart
│   ├── evaluation_screen.dart
│   ├── history_screen.dart
│   ├── profile_screen.dart
│   └── alert_screen.dart
├── models/
│   ├── user.dart
│   ├── transaction.dart
│   └── alert.dart
├── services/
│   └── auth_service.dart
├── widgets/
│   ├── bottom_nav.dart
│   ├── expense_pie_chart.dart
│   ├── sparkline_painter.dart
│   └── trend_bar_chart.dart
├── utils/
│   ├── score_calculator.dart
│   └── constants.dart
└── ...
```

## ⚙️ Cara Menjalankan

1. Clone repo ini
   ```bash
   git clone https://github.com/danangjune/catatin_app
   cd catatin_app
   ```
2. Install dependensi
   ```bash
   flutter pub get
   ```
3. Jalankan aplikasi
   ```bash
   flutter run
   ```
   Pastikan backend Laravel berjalan sesuai alamat yang didefinisikan pada `AuthService.baseUrl`.

### Menjalankan Backend Laravel

1. Clone `https://github.com/danangjune/catatin-backend`.
2. Jalankan `composer install`.
3. Salin `.env.example` ke `.env`, atur database, dan jalankan `php artisan key:generate`.
4. Eksekusi `php artisan migrate`.
5. Mulai server dengan `php artisan serve --port=8000`.

`AuthService.baseUrl` dan seluruh URL HTTP mengarah ke `http://localhost:8000`.

## 🧑‍💻 Kontribusi
Pull request dan issue sangat terbuka. Silakan laporkan bug atau saran fitur melalui halaman issue.

## 📄 Lisensi
© 2025 D. June
