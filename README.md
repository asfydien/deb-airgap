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

## 📦 Daftar Paket & Modul Praktikum yang Tersedia

Repositori lokal ini telah memuat seluruh dependensi yang dibutuhkan untuk berbagai materi praktikum administrasi server dan jaringan. Paket-paket telah diindeks ke dalam arsitektur DEB822 lokal (`file:/opt/repo`) dan dapat dipasang secara *air-gapped* tanpa memerlukan koneksi internet.

### 1. Layanan Jaringan & Server Dasar
| Paket | Deskripsi / Fungsi Praktikum |
| :--- | :--- |
| `dnsmasq` | Server DNS & DHCP ringan untuk resolusi nama domain lokal dan alokasi IP lab |
| `vsftpd` | Server File Transfer Protocol (FTP) yang aman, cepat, dan hemat sumber daya |
| `samba` | Berbagi berkas dan printer lintas platform berbasis SMB/CIFS (Windows & Linux) |
| `wsdd2` | *Web Services for Devices Daemon* untuk deteksi otomatis server di Windows Explorer |

---

### 2. Web Server Stack (LAMP & LEMP) & Database
| Paket | Deskripsi / Fungsi Praktikum |
| :--- | :--- |
| `apache2` & `apache2-utils` | HTTP Web Server modular beserta utilitas benchmark (`ab`) dan autentikasi (`htpasswd`) |
| `nginx` | Web server berkinerja tinggi serta *reverse proxy* / *load balancer* |
| `mariadb-server` & `mariadb-client` | Server basis data relasional SQL (RDBMS) dan antarmuka baris perintah (CLI) |
| `phpmyadmin` | Panel berbasis web untuk mempermudah pengelolaan basis data MariaDB/MySQL |

---

### 3. PHP Runtime & Ekstensi (CMS & Web Apps)
| Kategori | Paket yang Disediakan |
| :--- | :--- |
| **PHP Core & FPM** | `php`, `php-cli`, `php-fpm`, `php-common`, `libapache2-mod-php` |
| **Pustaka Ekstensi** | `php-bcmath`, `php-bz2`, `php-curl`, `php-gd`, `php-gmp`, `php-imagick`, `php-intl`, `php-ldap`, `php-mbstring`, `php-mysql`, `php-opcache`, `php-pgsql`, `php-readline`, `php-soap`, `php-sqlite3`, `php-xml`, `php-zip` |

> *Catatan: Ekstensi di atas sudah memenuhi prasyarat dependensi untuk menjalankan CMS populer seperti WordPress, Moodle LMS, Roundcube Webmail, dan aplikasi web berbasis PHP lainnya secara offline.*

---

### 4. Mail Server Stack & Diagnostik Protokol
| Paket | Deskripsi / Fungsi Praktikum |
| :--- | :--- |
| `postfix` | *Mail Transfer Agent* (MTA) untuk pengiriman dan penerimaan surat (protokol SMTP) |
| `dovecot-imapd` & `dovecot-pop3d` | *Mail Delivery Agent* (MDA) untuk pengambilan kotak surat klien (IMAP & POP3) |
| `roundcube` & `roundcube-mysql` | Klien antarmuka webmail modern beserta pustaka integrasi basis data |
| `mailutils` | Kumpulan perkakas terminal untuk manipulasi dan pengujian pesan surel (`mail`) |
| `swaks` | *Swiss Army Knife for SMTP* untuk simulasi dan diagnostik pengiriman email |
| `telnet` | Pengujian manual *handshake* dan komunikasi teks pada port layanan (SMTP, POP3, IMAP) |
| `sasl2-bin` & `libsasl2-modules` | Pustaka autentikasi SASL untuk pengamanan pengiriman relai surel (*SMTP Auth*) |

---

### 5. Keamanan Sistem & Hardening Server
| Paket | Deskripsi / Fungsi Praktikum |
| :--- | :--- |
| `ufw` | *Uncomplicated Firewall* untuk pengenalan aturan filter port dan *default deny policy* |
| `nftables` | Kerangka kerja *packet filtering* modern pengganti iptables bawaan Linux |
| `fail2ban` | Sistem pertahanan otomatis terhadap serangan *brute-force* pada SSH dan web server |
| `lynis` | Alat audit keamanan sistem komprehensif dan perhitungan *Hardening Index* |
| `debsums` | Verifikasi integritas berkas biner sistem terhadap database *checksum* resmi Debian |
| `rkhunter` | Pemindai anomali sistem operasi untuk mendeteksi *rootkit*, *backdoor*, dan eksploitasi |
| `libpam-pwquality` | Modul PAM untuk penegakan kebijakan kompleksitas kata sandi pengguna |
| `nmap` | Pemindai jaringan untuk memvalidasi port terbuka dan efektivitas aturan firewall |
| `lsof` | Utilitas pelacak soket jaringan aktif dan proses yang membuka berkas sistem |
| `tcpdump` | Penganalisis paket jaringan (*packet sniffer*) langsung dari antarmuka CLI |

---

### 6. VPN & Routing Stack
| Paket | Deskripsi / Fungsi Praktikum |
| :--- | :--- |
| `openvpn` | Server dan klien Virtual Private Network (VPN) berbasis protokol SSL/TLS |
| `iptables` | Utilitas manipulasi tabel kernel untuk kebutuhan *IP Forwarding* dan NAT (*Masquerading*) |
| `ca-certificates` | Manajemen sertifikat otoritas digital (*CA root store*) sistem |

---

### 7. Monitoring & Visualisasi Server
| Paket | Deskripsi / Fungsi Praktikum |
| :--- | :--- |
| `prometheus` | Basis data deret waktu (*time-series database*) dan mesin pengumpul metrik server |
| `prometheus-node-exporter` | Agen pengumpul metrik kinerja perangkat keras dan sistem operasi Linux |
| **Grafana OSS (v12.x)** | Dasbor visualisasi data metrik Prometheus modern (Port `3000`) *(Paket eksternal opsional)* |

---

### 8. Utilitas Sistem, Ekstraksi & Administrasi
| Kategori | Paket |
| :--- | :--- |
| **Transfer & Unduhan** | `curl`, `wget`, `rsync` |
| **Arsip & Kompresi** | `tar`, `unzip` |
| **Diagnostik & Sistem** | `htop`, `fastfetch`, `openssl` |
| **Web GUI Eksternal (Opsional)** | `webmin` (Administrasi sistem via browser di port `10000`), `usermin` (Port `20000`) |

> 💡 **Informasi Opsi Paket Eksternal:**  
> Berkas `.deb` mandiri untuk **Webmin**, **Usermin**, dan **Grafana OSS** dapat diatur penyertaannya ke dalam repositori saat menjalankan `buildrepo.sh`. Jika opsi penyimpanan dilewati demi menjaga ukuran berkas `.ova` VM tetap ramping di bawah 1 GB, seluruh dependensi pustakanya tetap tersedia lengkap di dalam repositori lokal `/opt/repo`. Siswa dapat mengunggah berkas instalasi biner secara terpisah untuk mempraktikkan alur instalasi manual via `dpkg -i` atau `apt install ./<file>.deb`.

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
