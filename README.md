# debian-offline-repo-builder

Otomatisasi pembuatan repositori lokal APT yang terisolasi (*air-gapped*) dan bertanda tangan kriptografis (GPG) pada Debian Linux. Dilengkapi utilitas pembersihan dan *zero-filling* disk untuk menghasilkan berkas ekspor OVA yang ramping.

Dirancang khusus untuk menyiapkan *Golden Master VM* di VMware agar siswa dapat mempraktikkan instalasi dan administrasi server jaringan secara mandiri tanpa memerlukan koneksi internet.

---

## 🎯 Latar Belakang & Tujuan

Pada lingkungan laboratorium sekolah atau praktikum jaringan (TJKT), ketergantungan terhadap koneksi internet sering menimbulkan kendala:
- *Bandwidth* lab tersedot habis saat puluhan siswa menjalankan `apt install` secara bersamaan.
- Praktikum terhenti saat koneksi ISP atau internet sekolah mengalami gangguan.
- Repositori eksternal yang lambat atau tidak stabil memperlambat alur evaluasi belajar.

Proyek ini menyediakan skrip otomasi lengkap:
1. **`buildrepo.sh`**: Mengunduh seluruh materi server praktikum beserta seluruh pohon dependensinya, menyusun hierarki standar Debian (`pool/` & `dists/`), menandatanganinya dengan GPG lokal, dan mengunci konfigurasi ke repositori lokal format modern **DEB822**.
2. **`shrink.sh`**: Membersihkan log, cache residu, riwayat terminal, dan melakukan *zero-filling* blok disk kosong agar ukuran berkas ekspor **.OVA** menjadi sangat kecil dan efisien saat didistribusikan ke komputer siswa.

---

## 🌐 Skema Jaringan Lab (DHCP & Host-Only)

Mesin virtual Debian dalam skema ini dikonfigurasi sebagai **DHCP Client**:
- **Alokasi IP Otomatis:** Antarmuka jaringan VM tidak dipatok menggunakan IP statis bawaan, melainkan menerima alamat IP dinamis dari layanan DHCP server.
- **Topologi VMware Host-Only (Mode Localhost):**
  - Pada komputer siswa/host, antarmuka jaringan VM dihubungkan ke adaptor **Host-Only** (misalnya `VMnet1`).
  - DHCP server internal VMware VMnet akan otomatis memberikan IP ke VM Debian.
  - Komunikasi jaringan berlangsung secara terisolasi dan aman antara sistem operasi laptop host siswa dan guest Debian (mode *local private network*) tanpa memerlukan router fisik, WiFi, maupun akses internet luar.
  - Siswa dapat mengecek IP yang diperoleh cukup dengan menjalankan:
    ```bash
    ip a
    # atau
    hostname -I
    ```
  - Siswa dapat langsung mengakses layanan web (Apache/Nginx/Webmin/Grafana) dari peramban laptop host menggunakan alamat IP tersebut.

---

## 🚀 Fitur Utama

- **Deteksi Otomatis Codename Sistem:** Mendeteksi rilis Debian secara dinamis (`trixie`, `bookworm`, dll.) langsung dari sistem.
- **Hierarki Repositori Standar:** Menggunakan struktur resmi `pool/main` dan `dists/$CODENAME/main` melalui `apt-ftparchive`.
- **Standar Keamanan Debian Modern (DEB822 & GPG):** Menghasilkan pasangan kunci GPG lokal dan menandatangani indeks rilis (`InRelease`), sehingga bebas peringatan *untrusted/insecure repository*.
- **Integrasi Paket Pihak Ketiga:** Otomatis menarik dan membedah paket eksternal (Webmin, Usermin, dan Grafana OSS v12) beserta seluruh pustaka dependensinya.
- **Auto-Clean Slate:** Membersihkan tumpukan paket versi usang di direktori pool saat skrip dijalankan ulang.
- **Optimasi Ukuran Ekspor OVA:** Menyediakan utilitas *zero-fill* ruang kosong untuk memaksimalkan rasio kompresi OVA VMware.

---

## 📦 Daftar Layanan & Paket Praktikum

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
3. Ruang Penyimpanan: Minimal ruang kosong **5 GB** di partisi `/opt`.
4. Koneksi Internet: Diperlukan **hanya satu kali** saat guru/instruktur membangun master repositori.

---

## 📖 Panduan Penggunaan (Sisi Guru / Lab Admin)

### 1. Persiapan Skrip di Golden Master VM
Pastikan mesin master terhubung ke internet untuk tahap pengunduhan awal:

```bash
git clone [https://github.com/username-anda/debian-offline-repo-builder.git](https://github.com/username-anda/debian-offline-repo-builder.git)
cd debian-offline-repo-builder
chmod +x buildrepo.sh shrink.sh
