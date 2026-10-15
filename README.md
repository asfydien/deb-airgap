# Debian Air-Gapped Lab
*Offline APT Repository & VM Template for Isolated Lab Environments*

Otomatisasi pembuatan repositori lokal APT yang terisolasi (*air-gapped*) dan bertanda tangan kriptografis (GPG) pada Debian Linux. Dilengkapi skrip pembersihan dan *zero-filling* disk untuk menghasilkan berkas ekspor OVA yang sangat ramping.

Dirancang khusus untuk menyiapkan *Golden Master VM* di VMware agar siswa dapat mempraktikkan instalasi dan konfigurasi server jaringan secara mandiri tanpa memerlukan koneksi internet.

---

## 🎯 Latar Belakang & Tujuan

Pada lingkungan laboratorium sekolah atau praktikum jaringan (TJKT), ketergantungan terhadap koneksi internet sering menimbulkan beberapa kendala:
- *Bandwidth* lab tersedot habis saat puluhan siswa menjalankan perintah `apt install` secara bersamaan.
- Praktikum terhenti saat koneksi ISP atau jaringan sekolah mengalami gangguan.
- Siswa terkendala repositori luar negeri atau mirror lokal yang lambat dan tidak konsisten.

Proyek ini menyediakan solusi komprehensif melalui dua skrip utama:
1. **`buildrepo.sh`**: Mengunduh paket materi praktikum server beserta seluruh pohon dependensinya, menyusun hierarki standar Debian (`pool/` dan `dists/`), menandatanganinya dengan kunci GPG lokal, dan mengunci konfigurasi sistem ke repositori lokal format modern **DEB822**.
2. **`shrink.sh`**: Membersihkan log sistem, cache residu, riwayat bash, dan menimpa ruang disk kosong dengan angka nol (*zero-filling*) agar ukuran ekspor **.OVA** menjadi sangat padat dan efisien untuk dibagikan ke siswa.

---

## 🌐 Skema Jaringan Lab (DHCP & Host-Only)

Mesin virtual Debian dalam skema ini dikonfigurasi sebagai **DHCP Client**:
- **Alokasi IP Dinamis:** Antarmuka jaringan VM tidak diatur secara statis, melainkan menerima alamat IP otomatis dari layanan DHCP VMware.
- **Topologi VMware Host-Only (Mode Localhost):**
  - Antarmuka jaringan VM dihubungkan ke adaptor **Host-Only** (misalnya `VMnet1`).
  - Layanan DHCP internal VMware VMnet otomatis membagikan IP ke sistem operasi Debian.
  - Komunikasi jaringan berlangsung secara privat dan terisolasi antara sistem operasi laptop host siswa dan guest Debian tanpa memerlukan router fisik, WiFi, maupun akses internet luar.
  - Siswa dapat mengecek IP yang diperoleh dengan perintah:
    ```bash
    hostname -I
    # atau
    ip a
    ```
  - Layanan server (Web, Database, Webmin, Grafana) dapat langsung diakses dari peramban laptop siswa menggunakan alamat IP tersebut.

---

## 🚀 Fitur Utama

- **Deteksi Codename Otomatis:** Mendeteksi rilis Debian secara dinamis (`trixie`, `bookworm`, dll.) langsung dari berkas `/etc/os-release`.
- **Hierarki Standar Debian:** Disusun rapi pada direktori `/opt/repo/pool/main` dan `/opt/repo/dists/$CODENAME/main` menggunakan utilitas `apt-ftparchive`.
- **Standar Keamanan Modern (DEB822 & GPG):** Mengenerate pasangan kunci GPG lokal dan menandatangani indeks berkas `Release` (`InRelease`), sehingga APT tidak mengeluarkan peringatan *untrusted* atau *insecure repository*.
- **Integrasi Paket Pihak Ketiga:** Otomatis mengambil dan membedah paket eksternal (Webmin, Usermin, dan Grafana OSS v12) beserta pustaka dependensinya.
- **Auto-Clean Slate:** Membersihkan tumpukan paket versi usang di direktori pool saat skrip dijalankan ulang.
- **Optimasi Ukuran Ekspor OVA:** Menyediakan skrip pemadatan ruang kosong untuk menghasilkan berkas `.ova` seringkas mungkin.

---

## 📦 Daftar Layanan & Paket yang Disediakan

| Kategori | Layanan / Paket |
| :--- | :--- |
| **Layanan Jaringan Dasar** | `dnsmasq`, `vsftpd`, `samba`, `wsdd2` (Discovery Windows) |
| **Web Server (LAMP & LEMP)** | `apache2`, `apache2-utils`, `libapache2-mod-php`, `nginx` |
| **Basis Data** | `mariadb-server`, `mariadb-client`, `phpmyadmin` |
| **PHP Stack & Ekstensi CMS** | `php`, `php-cli`, `php-fpm`, `php-common`, `php-bcmath`, `php-bz2`, `php-curl`, `php-gd`, `php-gmp`, `php-imagick`, `php-intl`, `php-ldap`, `php-mbstring`, `php-mysql`, `php-opcache`, `php-pgsql`, `php-readline`, `php-soap`, `php-sqlite3`, `php-xml`, `php-zip` |
| **Mail Server Stack** | `postfix`, `dovecot-imapd`, `dovecot-pop3d`, `roundcube`, `roundcube-mysql`, `mailutils`, `swaks`, `telnet`, `sasl2-bin`, `libsasl2-modules` |
| **Panel Administrasi** | `webmin` (Server Admin Port 10000), `usermin` (Webmail Klien Port 20000) |
| **Monitoring Sistem** | `prometheus`, `prometheus-node-exporter`, `grafana` (Grafana OSS v12) |
| **Utilitas Sistem & Diagnostik** | `openssl`, `fastfetch`, `htop`, `unzip`, `tar`, `curl`, `wget`, `rsync` |

---

## 🛠️ Persyaratan Sistem

1. Sistem Operasi: **Debian 13 (Trixie)** atau **Debian 12 (Bookworm)** arsitektur `amd64`.
2. Hak Akses: `root` (atau `sudo`).
3. Ruang Penyimpanan: Minimal free space **5 GB** di partisi `/opt`.
4. Koneksi Internet: Diperlukan **hanya satu kali** saat guru/administrator membangun master repositori.

---

## 📖 Panduan Penggunaan (Sisi Guru / Lab Admin)

### 1. Persiapan Skrip di Golden Master VM
Pastikan VM master terhubung sementara ke internet, lalu unduh kedua skrip langsung via `wget`:

```bash
wget -O buildrepo.sh https://raw.githubusercontent.com/asfydien/deb-airgap/main/buildrepo.sh
wget -O shrink.sh https://raw.githubusercontent.com/asfydien/deb-airgap/main/shrink.sh
chmod +x buildrepo.sh shrink.sh
./buildrepo.sh
./shrink.sh
```

### 2. Membangun Repositori Lokal
Jalankan skrip pembuat repositori sebagai root:

```bash
./buildrepo.sh
```
Tunggu hingga proses selesai dari langkah `[1/6]` hingga `[6/6]`. Skrip akan otomatis mengalihkan sumber APT ke direktori `/opt/repo`.

### 3. Sanitasi Paket Praktikum
Agar kondisi VM kembali bersih dan siswa dapat mempraktikkan instalasi dari nol, hapus paket-paket server yang sempat terpasang saat proses pengambilan dependensi:

```bash
# Copot paket praktikum (direktori /opt/repo tetap aman)
apt purge -y apache2 mariadb-server php-fpm nginx postfix dovecot-imapd grafana prometheus prometheus-node-exporter

# Bersihkan sisa pustaka yang tidak terpakai sistem dasar
apt autoremove --purge -y
```

### 4. Merampingkan Disk VM Menggunakan `shrink.sh`
Jalankan skrip `shrink.sh` untuk membersihkan log residu, menghapus riwayat perintah bash, dan melakukan *zero-filling*:

```bash
./shrink.sh
```
*Catatan: Saat proses penulisan nol berjalan, pesan peringatan `No space left on device` adalah normal. Setelah proses selesai, VM akan otomatis mati (poweroff).*

### 5. Ekspor ke Format OVA di VMware
1. Buka VMware Workstation pada komputer host.
2. Pastikan mesin virtual berstatus **Powered Off** dan hapus seluruh *Snapshot* jika ada.
3. Pastikan konfigurasi Network Adapter disetel ke **Host-Only** (misalnya `VMnet1`).
4. Klik menu **File** > **Export to OVF...**.
5. Pada pilihan format penyimpanan, ubah nama/ekstensi berkas menjadi **`.ova`**.
6. Berkas `.ova` yang padat siap didistribusikan ke komputer siswa via flashdisk atau jaringan lokal lab.

---

## 🎓 Panduan Penggunaan di Sisi Siswa (Mode Offline)

Siswa mengimpor berkas `.ova` ke VMware masing-masing tanpa menyambungkan kartu jaringan ke internet luar.

### 1. Memeriksa Alamat IP VM
Siswa menjalankan perintah berikut di terminal VM untuk mengetahui alamat IP dari VMware DHCP:
```bash
hostname -I
```

### 2. Memeriksa Repositori Lokal
Pastikan repositori lokal terbaca dengan benar:
```bash
apt update
```
*(Keluaran terminal membaca baris `file:/opt/repo ... InRelease` tanpa galat).*

### 3. Contoh Praktik Siswa di Kelas

- **Praktik Web Server (LEMP Stack):**
  ```bash
  apt install nginx mariadb-server php-fpm php-mysql
  ```
- **Praktik Mail Server & Webmail:**
  ```bash
  apt install postfix dovecot-imapd roundcube usermin
  ```
- **Praktik Monitoring Server:**
  ```bash
  apt install prometheus prometheus-node-exporter grafana
  systemctl enable --now prometheus prometheus-node-exporter grafana-server
  ```
- **Mengakses Layanan dari Peramban Laptop Host:**
  Siswa cukup membuka peramban di laptop mereka dan mengakses IP VM yang tertera:
  - Layanan Web: `http://<IP_VM>`
  - Webmin Panel: `https://<IP_VM>:10000`
  - Usermin Webmail: `https://<IP_VM>:20000`
  - Grafana Dashboard: `http://<IP_VM>:3000`

---

## 📂 Struktur Berkas Repositori

```text
/opt/repo/
├── dists/
│   └── trixie/
│       ├── InRelease          # Indeks rilis bertanda tangan GPG
│       ├── Release            # Metadata rilis
│       ├── Release.gpg        # Detached signature GPG
│       └── main/
│           └── binary-amd64/
│               ├── Packages   # Metadata katalog paket
│               └── Packages.gz
└── pool/
    └── main/                  # Arsip seluruh berkas biner paket (.deb)
```

---

## 📄 Lisensi
Proyek ini didistribusikan di bawah lisensi [MIT](LICENSE). Bebas digunakan, dimodifikasi, dan dibagikan untuk kepentingan pendidikan dan laboratorium sekolah.
