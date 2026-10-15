# debian-offline-repo-builder

Otomatisasi pembuatan repositori lokal APT yang terisolasi (*air-gapped*) dan ditandatangani secara kriptografis (GPG) pada Debian Linux. Dirancang khusus untuk menyiapkan *Golden Master VM* di VMware agar siswa dapat mempraktikkan instalasi dan konfigurasi berbagai layanan jaringan secara mandiri tanpa memerlukan koneksi internet.

---

## 🎯 Latar Belakang & Tujuan

Pada lingkungan laboratorium sekolah atau praktikum jaringan (TJKT), ketergantungan terhadap koneksi internet sering kali menimbulkan beberapa kendala:
- *Bandwidth* lab tersedot habis saat puluhan siswa menjalankan `apt install` secara bersamaan.
- Praktikum terhenti saat koneksi internet sekolah mengalami gangguan.
- Siswa terkendala repositori eksternal yang lambat atau tidak stabil.

Proyek ini menyediakan skrip **`buildrepo.sh`** yang mengunduh seluruh materi server praktikum beserta seluruh pohon dependensinya secara lengkap, menyusunnya ke dalam struktur repositori standar Debian (`pool/` dan `dists/`), menandatanganinya dengan kunci GPG lokal, dan mengunci konfigurasi sistem ke repositori lokal berbasis format modern **DEB822**.

---

## 🚀 Fitur Utama

- **Deteksi Otomatis Codename Sistem:** Mendeteksi rilis Debian secara dinamis (`trixie`, `bookworm`, dll.) langsung dari sistem.
- **Hierarki Repositori Standar:** Menggunakan struktur resmi `pool/main` dan `dists/$CODENAME/main` menggunakan `apt-ftparchive`.
- **Standar Keamanan Debian Modern (DEB822 & GPG):** Mengenerate pasangan kunci GPG lokal dan menandatangani indeks berkas `Release` (`InRelease`), sehingga APT tidak mengeluarkan peringatan `Notice: Missing Signed-By` atau `Insecure Repository`.
- **Integrasi Paket Pihak Ketiga:** Otomatis menarik dan membedah paket eksternal populer (Webmin, Usermin, dan Grafana OSS v12) beserta dependensi pustaka sistemnya.
- **Pembersihan Otomatis (*Clean Slate*):** Membersihkan berkas unduhan sementara dan cache versi usang saat skrip dijalankan ulang.

---

## 📦 Daftar Layanan & Paket yang Disediakan

| Kategori | Layanan / Paket |
| :--- | :--- |
| **Layanan Jaringan Dasar** | `dnsmasq`, `vsftpd`, `samba`, `wsdd2` (Network Discovery Windows) |
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
2. Akses Pengguna: `root` (atau `sudo`).
3. Ruang Penyimpanan: Minimal free space **5 GB** di partisi `/opt`.
4. Koneksi Internet: Diperlukan **hanya satu kali** saat guru/instruktur mengeksekusi skrip pembuat repositori.

---

## 📖 Panduan Penggunaan (Sisi Guru / Lab Admin)

### 1. Persiapan Skrip
Pastikan VM master terhubung ke internet. Unduh repositori ini atau buat berkas skripnya:

```bash
git clone [https://github.com/username-anda/debian-offline-repo-builder.git](https://github.com/username-anda/debian-offline-repo-builder.git)
cd debian-offline-repo-builder
chmod +x buildrepo.sh
