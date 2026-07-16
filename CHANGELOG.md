# Changelog

All notable changes to this project will be documented in this file.

## [1.5.1] - 2026-07-16

### Added
- **Responsive Views Layout Split**: Pemisahan komponen visual secara menyeluruh untuk perangkat Mobile (Portrait) dan Tablet (Landscape) pada halaman Login, Staff Selection, Home, Payment, Recap, dan Sync.
- **Promo Bundling System**:
  - Implementasi popup otomatis promo bundling yang menarik dan sinkron dengan cek produk lokal.
  - Dukungan promo bundling global lintas-brand (cross-brand support) yang otomatis melewati filter brand saat aktif.
  - Filter bar horizontal untuk promo bundling di tampilan Mobile dan Tablet.
  - Tampilan diskon promo bundling pada halaman review pembayaran.
- **Sync Status Indicator**: Indikator sinkronisasi real-time pada sidebar kasir beserta pembaruan layout tombol struk belanja.
- **Z-Report Enhancement**: Redesign layout struk Z-Report dan opsi cetak debug di menu pengaturan.
- **Data Protection Guard**: Sistem proteksi data lokal yang belum tersinkronisasi untuk memblokir logout tidak sengaja sebelum data masuk ke server.

### Fixed
- **Kitchen & Order Synchronization**:
  - Perbaikan status dapur yang tidak sinkron (out-of-sync) dan pencegahan hilangnya catatan item (item notes) saat pesanan ditutup.
  - Perbaikan catatan item ganda dan salah alokasi saat sinkronisasi menggunakan parser antrean terstruktur.
  - Agregasi produk teratas berdasarkan nama produk dengan mengabaikan pemisahan catatan item.
- **Shift & Reconciliation**:
  - Perbaikan perhitungan ganda saldo/transaksi kas pada rekonsiliasi shift dan pemetaan saldo awal (opening balance).
  - Implementasi 24h stale shift guard dan auto-reload sesi shift aktif untuk mencegah duplikasi total transaksi.
- **Payment & Merchant Modes**:
  - Perbaikan isu metode merchant yang terdeteksi sebagai Cash di transaksi terbaru.
  - Auto-select metode pembayaran merchant pada layar pembayaran.
  - Konsolidasi ID metode pembayaran Cash statis ke `Constants.cashPaymentModeIds` dan query SQL pembayaran yang terpusat.
- **Date Formatting**:
  - Penyeragaman format tanggal menggunakan helper `DateFormatter` di halaman Member dan Report.
  - Perbaikan parsing tanggal transaksi agar selalu mengembalikan format YYYY-MM-DD baik dari ISO maupun format spasi.
- **App Update & API Integration**:
  - Pemasangan konstanta versi statis `Constants.appVersion` (`1.5.1`) sebagai nilai acuan terpusat.
  - Sinkronisasi payload PUT/POST `pos_options` dengan parameter versi saat update otomatis ke server tenant Flink.
- **UI & Layout**:
  - Perbaikan RenderFlex overflow pada layar pembayaran Tablet.
  - Penghapusan padding horizontal bawaan pada promo filter chips.
  - Penanganan loop popup promo bundling tanpa akhir.
