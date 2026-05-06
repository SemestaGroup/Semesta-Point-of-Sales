# 🛒 Daftar Fitur Semesta POS (Point of Sales)

Aplikasi POS ini dirancang dengan arsitektur **Offline-First**, memungkinkan operasional kasir tetap berjalan tanpa internet dan akan melakukan sinkronisasi ke server (Perfex) secara otomatis di latar belakang.

Berikut adalah daftar detail fitur utama yang tersedia, disusun secara singkat dan padat:

## 1. 🔐 Autentikasi & Multi-Role
- **Login Pegawai/Admin:** Sistem login terintegrasi dengan backend.
- **Role-Based Access:** Mendukung akses berdasarkan peran (Owner, Admin, Manager, Kasir), di mana setiap peran memiliki batasan menu yang berbeda.
- **Pindah Akun (Switch User):** Memudahkan pergantian kasir tanpa harus logout total.

## 2. 📊 Dashboard & Analitik
- **Ringkasan Pendapatan:** Menampilkan total pendapatan hari ini dan bulan ini (Real-time).
- **Grafik Metode Pembayaran:** Analisis proporsi pembayaran (Cash, QRIS, Transfer, dll).
- **Top Products:** Menampilkan produk paling laris (Harian/Bulanan).
- **Recent Transactions:** Pantauan riwayat transaksi terbaru beserta statusnya.

## 3. 🛍️ Modul Kasir (Point of Sale)
- **Katalog Produk & Kategori:** Menampilkan item dalam bentuk grid dengan filter kategori.
- **Pencarian Cepat & Barcode:** Mencari produk berdasarkan nama atau scan barcode.
- **Custom Item:** Menambahkan produk manual di luar katalog dengan harga bebas.
- **Manajemen Keranjang (Cart):** Ubah kuantitas, beri catatan per item, dan tipe pesanan (Dine In, Take Away).
- **Diskon Fleksibel:** Mendukung diskon persentase (%) maupun nominal tetap (Rp) secara manual per transaksi.
- **Pajak (Tax):** Penghitungan pajak otomatis.

## 4. 💳 Sistem Pembayaran
- **Multi-Payment Method:** Mendukung pembayaran Cash, QRIS, Bank Transfer, dan metode custom lainnya.
- **Kalkulator Kembalian:** Hitung otomatis uang kembalian untuk pembayaran tunai (Cash).
- **Hold Order / Draft:** Simpan pesanan sementara (Active Orders) jika pelanggan menunda pembayaran.

## 5. 👥 Manajemen Pelanggan (Member)
- **Database Pelanggan:** Registrasi member baru langsung dari aplikasi.
- **Loyalty Points:** Akumulasi poin belanja untuk pelanggan terdaftar (Walk-in vs Member).
- **Pencarian Member:** Pilih pelanggan saat checkout untuk pencatatan transaksi spesifik.

## 6. 🕒 Manajemen Shift Kasir
- **Buka/Tutup Shift (Open/Close Register):** Pencatatan saldo kas awal (Opening Cash).
- **Shift Audit/Recap:** Rangkuman total penjualan, estimasi uang tunai di laci, dan selisih (Cash Variance) saat shift ditutup.

## 7. 🖨️ Integrasi Perangkat keras (Hardware)
- **Printer Thermal Bluetooth:** Cetak struk belanja otomatis melalui printer thermal.
- **Cetak Ulang (Reprint Receipt):** Fitur untuk mencetak ulang struk dari riwayat transaksi.
- **Format Struk Kustom:** Mendukung logo toko, antrean (Queue Number), nama kasir, dan footer kustom (IG/Feedback QR).

## 8. 📈 Laporan & Riwayat (Report & History)
- **Riwayat Transaksi:** Filter berdasarkan tanggal dan metode pembayaran.
- **Refund / Credit Notes:** Terintegrasi dengan sistem pengembalian dana dari server.
- **Shift Report:** Rekapitulasi shift harian untuk manajerial.

## 9. 🔄 Sistem Sinkronisasi & Offline-First (Sync Service)
- **Local Database (SQLite):** Semua transaksi disimpan ke lokal terlebih dahulu, operasi 100% cepat tanpa loading server.
- **Background Sync Queue:** Antrean transaksi otomatis terkirim ke server (Perfex) saat perangkat terhubung internet.
- **Sync Master Data:** Tarik data produk, kategori, pelanggan, order history, dan metode pembayaran dari server secara manual/otomatis.
- **Error Logging:** Pencatatan error ke server jika ada transaksi yang gagal tersinkronisasi.
