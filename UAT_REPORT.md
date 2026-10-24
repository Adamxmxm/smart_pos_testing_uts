# 📋 LAPORAN USER ACCEPTANCE TESTING (UAT)
## Proyek Ujian Tengah Semester (UTS) - Mobile Testing

---

### 📌 Informasi Proyek & Penguji
- **Mata Kuliah**: Mobile Testing
- **Program Studi**: S1 Teknik Informatika
- **Kelas**: TI23B
- **Institusi**: Fakultas Ilmu Komputer, Universitas Duta Bangsa Surakarta
- **Dosen Pengampu**: Triyono M.Kom
- **Nama Aplikasi**: Smart POS (Point of Sale) Mobile App
- **Penyusun / Mahasiswa**:
  - **Nama**: [Nama Mahasiswa]
  - **NIM**: [NIM Mahasiswa]
  - **Peran**: Mobile Tester & Developer

---

### 🎯 1. Gambaran Umum & Tujuan Pengujian
Tujuan pengujian User Acceptance Testing (UAT) ini adalah untuk memvalidasi kesesuaian fungsionalitas aplikasi kasir digital (**Smart POS**) dengan kebutuhan operasional pengguna kasir dan manajer toko, memastikan stabilitas alur transaksi, responsivitas antarmuka pada berbagai ukuran layar, serta keandalan validasi kesalahan input.

#### Persona / Peran Pengguna:
- **Kasir (Cashier)**: Melakukan transaksi harian, mengelola keranjang, hold/retrieve open nota, memproses pembayaran (tunai/QRIS), dan mencetak struk.
- **Manajer Toko / Pemilik**: Mengelola stok/katalog produk (CRUD) dan memantau analitik omset transaksi.

#### Kriteria Penerimaan (Acceptance Criteria):
1. Pengguna kasir dapat membuka aplikasi, login, dan mempertahankan sesi aktif.
2. Form input memiliki validasi otomatis untuk mencegah data kosong atau salah format.
3. Alur pencarian produk, penambahan ke keranjang, dan kalkulasi subtotal/kembalian 100% akurat.
4. Fitur *Open Nota (Hold & Retrieve)* berfungsi tanpa menghilangkan data pesanan.
5. Transaksi tunai dan non-tunai tersimpan secara realtime di backend Supabase.
6. Seluruh skenario pengujian otomatisasi Maestro lolos assertion (Status: **PASS**).

#### Prasyarat Pengujian:
1. Perangkat fisik Android atau Emulator Android (API 30+) terhubung via ADB.
2. Koneksi internet aktif ke backend Supabase.
3. Aplikasi Smart POS terpasang dan dapat dijalankan.

---

### 📊 2. Matriks Skenario & Hasil Pengujian UAT

| No | ID Skenario | Modul / Fitur | Prasyarat & Langkah Pengujian | Hasil yang Diharapkan | Hasil Aktual | Status | Bukti Pengujian |
|:--:|:-----------:|:--------------|:------------------------------|:----------------------|:-------------|:------:|:----------------|
| 1 | **AUTH-01** | Splash Screen | Buka aplikasi, tunggu splash selesai | Transisi mulus ke login screen atau dashboard jika sesi ada | Splash screen muncul 2 detik lalu menuju login screen | **LULUS** | `01_splash_screen.png` |
| 2 | **AUTH-02** | Register Toko | Klik 'Daftar Toko Baru', isi nama, email, password | Akun kasir dan toko baru terdaftar di database | Akun berhasil dibuat dan dialihkan ke dashboard | **LULUS** | Maestro Flow PASS |
| 3 | **AUTH-03** | Login Kasir | Input email & password valid, klik Masuk | Berhasil autentikasi dan masuk ke layar utama POS | Dashboard POS terbuka menampilkan katalog produk | **LULUS** | Maestro Flow PASS |
| 4 | **AUTH-04** | Validasi Kesalahan | 1. Klik Masuk saat field kosong<br>2. Input email tanpa '@'<br>3. Input password < 6 digit<br>4. Input kredensial palsu | Muncul pesan error/validasi: "Email wajib diisi", "Format email tidak valid", dll. | Pesan validasi form & SnackBar error tampil tepat | **LULUS** | `04_error_field_kosong.png`, `04_error_kredensial_salah.png` |
| 5 | **RESP-01** | UI Portrait Smartphone | Buka aplikasi dalam orientasi portrait pada HP | Layout vertikal rapi, keranjang dalam modal bottom sheet | Antarmuka adaptif, tombol navigasi bawah mudah dijangkau | **LULUS** | Maestro Flow PASS |
| 6 | **RESP-02** | UI Tablet Landscape | Buka aplikasi dalam orientasi landscape pada tablet | Layout split-screen 2 kolom (katalog kiri, keranjang kanan) | Tampilan tablet terbagi otomatis tanpa overlap | **LULUS** | Maestro Flow PASS |
| 7 | **NAV-01** | Navigasi Bar | Klik bergantian tab: POS, Produk, Laporan, Akun | Layar berpindah mulus sesuai modul yang dipilih | Perpindahan halaman instan tanpa lagging | **LULUS** | `02_navigation_pos.png` |
| 8 | **POS-01** | Pencarian & Filter | Ketik nama produk di search bar, klik filter kategori | Daftar produk terfilter secara realtime | Produk terfilter akurat sesuai query & kategori | **LULUS** | Maestro Flow PASS |
| 9 | **POS-02** | Keranjang Belanja | Tambah item ke cart, ubah qty (+/-), cek total tagihan | Total harga terhitung otomatis sesuai kuantitas | Total tagihan dan rincian item sesuai | **LULUS** | Maestro Flow PASS |
| 10 | **POS-03** | Open Nota (Hold) | Buat pesanan, klik 'Simpan Tagihan', beri label 'Meja 5' | Nota disimpan sementara, keranjang aktif kembali kosong | Nota berhasil di-hold, keranjang bersih | **LULUS** | Maestro Flow PASS |
| 11 | **POS-04** | Open Nota (Retrieve) | Buka daftar nota aktif, pilih 'Meja 5', klik 'Muat Nota' | Item dari nota aktif kembali masuk ke keranjang belanja | Seluruh item dan rincian kembali ke keranjang | **LULUS** | Maestro Flow PASS |
| 12 | **PAY-01** | Pembayaran Tunai | Checkout pesanan, pilih uang pas, klik selesaikan bayar | Pembayaran sukses, kembalian dihitung, muncul nota transaksi | Modal struk muncul, status order COMPLETED | **LULUS** | `03_transaksi_tunai_sukses.png` |
| 13 | **PAY-02** | Pembayaran QRIS/Non-Tunai | Checkout pesanan, pilih Non-Tunai (QRIS), konfirmasi | Transaksi non-tunai diverifikasi, nota muncul | Order tercatat dengan metode NON_TUNAI | **LULUS** | Maestro Flow PASS |
| 14 | **PRT-01** | Cetak Struk ESC/POS | Dari dialog nota, pilih ukuran kertas 58mm/80mm, klik cetak | Perintah cetak Bluetooth/Thermal dikirimkan | Output struk tercetak rapi sesuai layout ESC/POS | **LULUS** | Maestro Flow PASS |
| 15 | **PRT-02** | Reprint Struk | Buka Riwayat Transaksi, klik icon printer pada order lama | Struk transaksi lama dicetak ulang | Salinan nota transaksi berhasil ditampilkan ulang | **LULUS** | Maestro Flow PASS |
| 16 | **PRD-01** | Tambah Produk Baru (CRUD) | Buka menu Produk, klik Tambah, isi nama, harga, stok | Produk baru tersimpan dan langsung tampil di daftar | Produk 'Kopi Arabika UAT' muncul di katalog | **LULUS** | `03_crud_tambah_produk.png` |
| 17 | **PRD-02** | Edit & Hapus Produk | Ubah harga produk, lalu uji hapus produk dengan konfirmasi | Data produk terupdate, produk terhapus dari katalog | Update dan delete produk berhasil | **LULUS** | Maestro Flow PASS |
| 18 | **REP-01** | Laporan Penjualan | Buka menu Laporan, filter periode (Hari Ini, Bulan Ini) | Kartu KPI total omset & total transaksi terupdate | Data analitik sinkron dengan riwayat transaksi | **LULUS** | Maestro Flow PASS |
| 19 | **REP-02** | Riwayat Transaksi | Scroll tabel riwayat penjualan, cek status transaksi | Riwayat memuat daftar invoice dengan status lengkap | Status 'COMPLETED' dan rincian tampil detail | **LULUS** | Maestro Flow PASS |
| 20 | **ACC-01** | Profil & Logout | Buka tab Akun, klik 'Keluar dari Akun', konfirmasi keluar | Sesi login dihapus, kembali ke layar login | Pengguna berhasil logout dengan aman | **LULUS** | Maestro Flow PASS |

---

### 📈 3. Ringkasan Temuan (Summary of Findings)
- **Total Skenario UAT**: 20 Skenario
- **Total Lulus (Passed)**: 20 Skenario (100%)
- **Total Gagal (Failed)**: 0 Skenario (0%)
- **Catatan & Evaluasi**:
  1. Semua alur inti kasir (transaksi tunai, kalkulasi kembalian, cetak nota) berjalan secara presisi.
  2. Fitur validasi form (AUTH-04) berhasil memblokir input kosong maupun salah format sebelum request dikirim ke backend.
  3. Aplikasi stabil saat diuji menggunakan Maestro E2E test suite.

