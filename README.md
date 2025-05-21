# 📘 CatatIn – Aplikasi Pencatat Keuangan Pribadi

CatatIn adalah aplikasi mobile berbasis Flutter yang terhubung ke backend Laravel, dirancang untuk membantu pengguna mencatat transaksi keuangan harian, mengelola tabungan, dan mengevaluasi kondisi finansial secara otomatis menggunakan metode SAW (Simple Additive Weighting).

## 🚀 Fitur Utama

### 1. Pencatatan Transaksi Harian
- Tambah pemasukan & pengeluaran
- Pilihan kategori (makan, transportasi, dll)
- Tambah keterangan dan tanggal

### 2. Manajemen Tabungan
- Tentukan target tabungan bulanan
- Lihat progres tabungan
- Dorongan untuk konsistensi

### 3. Rekapitulasi Bulanan
- Ringkasan pemasukan, pengeluaran, dan sisa
- (Opsional) Grafik batang atau pie chart

### 4. Evaluasi Keuangan Otomatis (SAW)
- Skor kesehatan finansial berdasarkan 5 kriteria:
  - Rasio pemasukan/pengeluaran
  - Konsistensi menabung
  - Pengeluaran tak terduga
  - Frekuensi pencatatan
  - Persentase tabungan
- Kategori: Baik / Cukup / Buruk
- Rekomendasi personal

### 5. Peringatan Cerdas (Smart Insight)
- Defisit pengeluaran
- Tidak mencatat transaksi 7+ hari
- Tidak menabung bulan ini
- Penurunan pendapatan

### 6. Riwayat & Filter
- Lihat riwayat transaksi dan evaluasi
- Filter data berdasarkan kategori, tanggal, dll

### 7. Profil Pengguna
- Nama, ringkasan keuangan
- Pengingat pencatatan harian

## 🛠 Teknologi
- **Frontend:** Flutter
- **Backend:** Laravel (API)
- **Database:** MySQL

## 📂 Struktur Proyek (Frontend)

lib/
├── main.dart
├── screens/
│ ├── dashboard_screen.dart
│ ├── add_transaction_screen.dart
│ ├── savings_screen.dart
│ ├── evaluation_screen.dart
│ ├── history_screen.dart
│ └── profile_screen.dart
├── widgets/
│ ├── transaction_card.dart
│ └── summary_card.dart
├── models/
│ └── transaction.dart
└── utils/
└── helpers.dart

## 📂 Struktur Proyek (Backend)

soon.

## ⚙️ Cara Menjalankan (Frontend)

1. Clone repo:
   #### git clone https://github.com/danangjune/catatin.git
   #### cd catatin
2. Jalankan:
   #### flutter pub get
   #### flutter run

## 🧑‍💻 Kontribusi
Pull Request dipersilakan! Buka issue jika ada bug atau saran fitur.

## 📄 Lisensi
© 2025 D. June
