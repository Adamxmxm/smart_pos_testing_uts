# 🧪 Maestro E2E Automation Test Suite - Smart POS App

Dokumentasi otomatisasi pengujian antarmuka (End-to-End E2E Testing) menggunakan **Maestro** yang disusun berdasarkan berkas User Acceptance Testing: **`UAT_Interactive_Smart_POS_App.xlsx`**.

---

## 📁 Struktur Direktori Pengujian

Semua skenario pengujian ditempatkan di dalam folder `maestro/` dengan pemisahan per modul fungsional:

```text
maestro/
├── common/                               # Helper & Subflow Reusable
│   ├── launch_app.yaml                   # Subflow buka aplikasi & tunggu splash
│   └── ensure_logged_in.yaml             # Subflow verifikasi status login kasir
│
├── auth/                                 # Modul 1: Autentikasi
│   ├── AUTH_01_splash_screen.yaml        # AUTH-01: Auto-check session & splash
│   ├── AUTH_02_register_toko.yaml        # AUTH-02: Pendaftaran kasir baru
│   └── AUTH_03_login_kasir.yaml          # AUTH-03: Login kasir
│
├── responsive/                           # Modul 2: Responsive Layout
│   ├── RESP_01_mobile_portrait.yaml      # RESP-01: Layout Smartphone (Bottom sheet)
│   └── RESP_02_tablet_landscape.yaml     # RESP-02: Layout Tablet Landscape (Split screen)
│
├── navigation/                           # Modul 3: Navigasi
│   └── NAV_01_navigation_bar.yaml        # NAV-01: Pindah modul (POS, Produk, Laporan, Akun)
│
├── pos/                                  # Modul 4: Point of Sale & Katalog
│   ├── POS_01_katalog_filter.yaml        # POS-01: Pencarian real-time & tab kategori
│   ├── POS_02_keranjang_belanja.yaml     # POS-02: Tambah, ubah qty (+/-), subtotal
│   ├── POS_03_open_nota_hold.yaml        # POS-03: Simpan tagihan sementara (Hold)
│   └── POS_04_open_nota_retrieve.yaml    # POS-04: Muat kembali nota terbuka (Retrieve)
│
├── payment/                              # Modul 5: Checkout & Pembayaran
│   ├── PAY_01_pembayaran_tunai.yaml      # PAY-01: Bayar tunai, uang pas, kembalian
│   └── PAY_02_pembayaran_non_tunai.yaml  # PAY-02: QRIS / EDC / Transfer
│
├── print/                                # Modul 6: Cetak Struk ESC/POS
│   ├── PRT_01_cetak_struk.yaml           # PRT-01: Cetak struk Bluetooth thermal (58/80mm)
│   └── PRT_02_reprint_struk.yaml         # PRT-02: Cetak ulang struk dari riwayat
│
├── products/                             # Modul 7: Manajemen Produk
│   ├── PRD_01_tambah_produk.yaml         # PRD-01: Tambah produk & foto/URL
│   └── PRD_02_edit_hapus_produk.yaml     # PRD-02: Ubah harga/stok & hapus produk
│
├── reports/                              # Modul 8: Laporan & Analitik
│   ├── REP_01_laporan_penjualan.yaml     # REP-01: KPI Omset, Transaksi, Filter periode
│   └── REP_02_riwayat_transaksi.yaml     # REP-02: Tabel riwayat & status completed
│
├── account/                              # Modul Tambahan: Akun & Logout
│   └── ACC_01_logout_kasir.yaml          # ACC-01: Profil kasir & konfirmasi logout
│
├── run_all_uat.yaml                      # 🚀 Master Suite (Menjalankan semua UAT)
└── README.md                             # Panduan lengkap eksekusi pengujian
```

---

## 📊 Matriks Pemetaan UAT Excel ke File Maestro

| No | Test Case ID | Modul / Fitur | Deskripsi Skenario UAT | File Maestro Flow |
|:--:|:------------:|:--------------|:-----------------------|:-------------------|
| 1 | **AUTH-01** | Splash Screen | Cek status sesi login pengguna saat aplikasi dibuka | [`maestro/auth/AUTH_01_splash_screen.yaml`](file:///c:/xampp/htdocs/FLUTTER/UDB/udb_3/maestro/auth/AUTH_01_splash_screen.yaml) |
| 2 | **AUTH-02** | Register Toko | Pendaftaran akun toko dan kasir baru | [`maestro/auth/AUTH_02_register_toko.yaml`](file:///c:/xampp/htdocs/FLUTTER/UDB/udb_3/maestro/auth/AUTH_02_register_toko.yaml) |
| 3 | **AUTH-03** | Login Kasir | Login menggunakan email & password terdaftar | [`maestro/auth/AUTH_03_login_kasir.yaml`](file:///c:/xampp/htdocs/FLUTTER/UDB/udb_3/maestro/auth/AUTH_03_login_kasir.yaml) |
| 4 | **AUTH-04** | Validasi Kesalahan | Pengujian validasi form login (input kosong, format email, password salah) | [`maestro/auth/AUTH_04_validasi_error.yaml`](file:///c:/xampp/htdocs/FLUTTER/UDB/udb_3/maestro/auth/AUTH_04_validasi_error.yaml) |
| 5 | **RESP-01** | Responsive UI | Tampilan layout pada smartphone (Mobile Portrait) | [`maestro/responsive/RESP_01_mobile_portrait.yaml`](file:///c:/xampp/htdocs/FLUTTER/UDB/udb_3/maestro/responsive/RESP_01_mobile_portrait.yaml) |
| 5 | **RESP-02** | Responsive UI | Tampilan layout pada tablet (Landscape Split-Screen) | [`maestro/responsive/RESP_02_tablet_landscape.yaml`](file:///c:/xampp/htdocs/FLUTTER/UDB/udb_3/maestro/responsive/RESP_02_tablet_landscape.yaml) |
| 6 | **NAV-01** | Navigation Bar | Navigasi antar modul utama (POS, Produk, Laporan, Akun) | [`maestro/navigation/NAV_01_navigation_bar.yaml`](file:///c:/xampp/htdocs/FLUTTER/UDB/udb_3/maestro/navigation/NAV_01_navigation_bar.yaml) |
| 7 | **POS-01** | Katalog & Filter | Filtering kategori dan pencarian produk real-time | [`maestro/pos/POS_01_katalog_filter.yaml`](file:///c:/xampp/htdocs/FLUTTER/UDB/udb_3/maestro/pos/POS_01_katalog_filter.yaml) |
| 8 | **POS-02** | Keranjang Belanja | Menambahkan & mengubah kuantitas item (+/-), subtotal | [`maestro/pos/POS_02_keranjang_belanja.yaml`](file:///c:/xampp/htdocs/FLUTTER/UDB/udb_3/maestro/pos/POS_02_keranjang_belanja.yaml) |
| 9 | **POS-03** | Open Nota (Hold) | Menyimpan keranjang transaksi sementara (Hold) | [`maestro/pos/POS_03_open_nota_hold.yaml`](file:///c:/xampp/htdocs/FLUTTER/UDB/udb_3/maestro/pos/POS_03_open_nota_hold.yaml) |
| 10 | **POS-04** | Open Nota (Retrieve) | Memanggil kembali nota terbuka ke keranjang belanja | [`maestro/pos/POS_04_open_nota_retrieve.yaml`](file:///c:/xampp/htdocs/FLUTTER/UDB/udb_3/maestro/pos/POS_04_open_nota_retrieve.yaml) |
| 11 | **PAY-01** | Pembayaran Tunai | Skenario checkout tunai, uang pas, nominal kembalian | [`maestro/payment/PAY_01_pembayaran_tunai.yaml`](file:///c:/xampp/htdocs/FLUTTER/UDB/udb_3/maestro/payment/PAY_01_pembayaran_tunai.yaml) |
| 12 | **PAY-02** | Pembayaran Non-Tunai | Skenario checkout QRIS / EDC / Transfer | [`maestro/payment/PAY_02_pembayaran_non_tunai.yaml`](file:///c:/xampp/htdocs/FLUTTER/UDB/udb_3/maestro/payment/PAY_02_pembayaran_non_tunai.yaml) |
| 13 | **PRT-01** | Cetak Struk | Cetak struk fisik Bluetooth thermal ESC/POS (58/80mm) | [`maestro/print/PRT_01_cetak_struk.yaml`](file:///c:/xampp/htdocs/FLUTTER/UDB/udb_3/maestro/print/PRT_01_cetak_struk.yaml) |
| 14 | **PRT-02** | Reprint Struk | Cetak ulang struk dari riwayat transaksi | [`maestro/print/PRT_02_reprint_struk.yaml`](file:///c:/xampp/htdocs/FLUTTER/UDB/udb_3/maestro/print/PRT_02_reprint_struk.yaml) |
| 15 | **PRD-01** | Tambah Produk | Tambah produk baru beserta foto/URL | [`maestro/products/PRD_01_tambah_produk.yaml`](file:///c:/xampp/htdocs/FLUTTER/UDB/udb_3/maestro/products/PRD_01_tambah_produk.yaml) |
| 16 | **PRD-02** | Edit & Hapus Produk | Mengubah harga/stok & menghapus produk | [`maestro/products/PRD_02_edit_hapus_produk.yaml`](file:///c:/xampp/htdocs/FLUTTER/UDB/udb_3/maestro/products/PRD_02_edit_hapus_produk.yaml) |
| 17 | **REP-01** | Laporan Penjualan | Ringkasan penjualan, omset, transaksi, filter waktu | [`maestro/reports/REP_01_laporan_penjualan.yaml`](file:///c:/xampp/htdocs/FLUTTER/UDB/udb_3/maestro/reports/REP_01_laporan_penjualan.yaml) |
| 18 | **REP-02** | Riwayat Transaksi | Melihat detail transaksi, status completed, kasir | [`maestro/reports/REP_02_riwayat_transaksi.yaml`](file:///c:/xampp/htdocs/FLUTTER/UDB/udb_3/maestro/reports/REP_02_riwayat_transaksi.yaml) |
| + | **ACC-01** | Logout Kasir | Sesi kasir berakhir & kembali ke login | [`maestro/account/ACC_01_logout_kasir.yaml`](file:///c:/xampp/htdocs/FLUTTER/UDB/udb_3/maestro/account/ACC_01_logout_kasir.yaml) |

---

## 🚀 Cara Menjalankan Pengujian Maestro

### 1. Prasyarat
1. Pastikan **Maestro CLI** sudah terinstal di komputer Anda:
   - **Windows (PowerShell)**:
     ```powershell
     powershell -ExecutionPolicy ByPass -c "irm https://get.maestro.mobile.dev | iex"
     ```
   - **macOS / Linux**:
     ```bash
     curl -Ls "https://get.maestro.mobile.dev" | bash
     ```
2. Pastikan Emulator Android atau perangkat fisik Android sudah terhubung via `adb devices`:
   ```powershell
   adb devices
   ```
3. Bangun atau jalankan aplikasi Smart POS di emulator/device minimal 1 kali:
   ```powershell
   flutter run
   ```

---

### 2. Menjalankan Satu Tes Spesifik

Jalankan perintah berikut dari folder root `udb_3`:

```powershell
# Jalankan UAT Login Kasir (AUTH-03)
maestro test maestro/auth/AUTH_03_login_kasir.yaml

# Jalankan UAT Katalog & Filter (POS-01)
maestro test maestro/pos/POS_01_katalog_filter.yaml

# Jalankan UAT Pembayaran Tunai (PAY-01)
maestro test maestro/payment/PAY_01_pembayaran_tunai.yaml

# Jalankan UAT Cetak Struk (PRT-01)
maestro test maestro/print/PRT_01_cetak_struk.yaml

# Jalankan UAT Tambah Produk (PRD-01)
maestro test maestro/products/PRD_01_tambah_produk.yaml
```

---

### 3. Menjalankan Seluruh UAT Sekaligus (Master Suite)

Untuk menjalankan seluruh 18 skenario UAT secara berurutan:

```powershell
maestro test maestro/run_all_uat.yaml
```

---

### 4. Menggunakan Kredensial Khusus (Custom Environment Variables)

Anda dapat mengirim kredensial kasir khusus saat menjalankan tes:

```powershell
maestro test -e EMAIL="kasir_utama@toko.com" -e PASSWORD="secretpassword" maestro/auth/AUTH_03_login_kasir.yaml
```
