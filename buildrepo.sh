#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "[-] Jalankan script ini sebagai root (sudo su)."
    exit 1
fi

REPO_DIR="/opt/repo"
CODENAME=$(grep VERSION_CODENAME /etc/os-release | cut -d= -f2)
ARCH="amd64"
KEYRING_DIR="/etc/apt/keyrings"
KEY_FILE="$KEYRING_DIR/local-repo.asc"

PAKET=(
    # --- Jaringan & Server Lab Dasar ---
    dnsmasq
    vsftpd
    samba
    wsdd2
    
    # --- Web Server (LAMP & LEMP) ---
    apache2
    apache2-utils
    libapache2-mod-php
    nginx
    
    # --- Database Server & Pengelola ---
    mariadb-server
    mariadb-client
    phpmyadmin
    
    # --- PHP Core, CLI & FPM ---
    php
    php-cli
    php-fpm
    php-common
    
    # --- Ekstensi PHP CMS & Webmail ---
    php-bcmath
    php-bz2
    php-curl
    php-gd
    php-gmp
    php-imagick
    php-intl
    php-ldap
    php-mbstring
    php-mysql
    php-opcache
    php-pgsql
    php-readline
    php-soap
    php-sqlite3
    php-xml
    php-zip

    # --- Mail Server Stack & Diagnostik ---
    postfix
    dovecot-imapd
    dovecot-pop3d
    roundcube
    roundcube-mysql
    mailutils
    swaks
    telnet
    sasl2-bin
    libsasl2-modules

    # --- Monitoring System Stack ---
    prometheus
    prometheus-node-exporter
    
    # --- Utilitas Ekstraksi Web & Manajemen File ---
    unzip
    tar
    curl
    wget
    rsync

    # --- Utilitas Sistem & Diagnostik ---
    openssl
    fastfetch
    htop
)

echo "=== [1/6] Mengaktifkan Repo Online & Mengosongkan Direktori Repo ==="
echo "[+] Target OS: Debian ($CODENAME - $ARCH)"
rm -f /etc/apt/sources.list.d/local.sources

# Pulihkan repo online bawaan jika sebelumnya pernah dimatikan
[ -f /etc/apt/sources.list.disabled ] && mv /etc/apt/sources.list.disabled /etc/apt/sources.list
for f in /etc/apt/sources.list.d/*.disabled; do
    [ -f "$f" ] && mv "$f" "${f%.disabled}"
done

# Kosongkan direktori repo lokal agar bersih dari file/versi usang
rm -rf "$REPO_DIR/pool" "$REPO_DIR/dists"
rm -f /tmp/*.deb /tmp/release.conf

echo 'APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/01keep-cache

apt-get update
apt-get install -y apt-utils wget curl gnupg

echo "=== [2/6] Mendeteksi & Mengunduh Paket Eksternal ==="

# Deteksi super cepat via GitHub Atom feed (< 1 detik, ~20 KB)
echo "[+] Memeriksa rilis terbaru Grafana OSS cabang v12..."
GRAFANA_VER=$(curl -fsSL --max-time 4 "https://github.com/grafana/grafana/releases.atom" 2>/dev/null \
    | grep -oP 'tag/v\K(12\.[0-9]+\.[0-9]+)' \
    | head -n 1)

# Fallback instan jika koneksi bermasalah atau timeout
if [ -z "$GRAFANA_VER" ]; then
    GRAFANA_VER="12.0.0"
    echo "[!] Pengecekan otomatis timeout, menggunakan default versi v${GRAFANA_VER}"
else
    echo "[+] Berhasil mendeteksi Grafana v12 terbaru: v${GRAFANA_VER}"
fi

echo "[+] Mengunduh paket materi praktikum..."
apt-get install -y --reinstall --download-only "${PAKET[@]}"

echo "[+] Mengunduh Webmin, Usermin, dan Grafana OSS (v${GRAFANA_VER})..."
wget -qO /tmp/webmin.deb https://webmin.com/download/deb/webmin-current.deb
wget -qO /tmp/usermin.deb https://webmin.com/download/deb/usermin-current.deb
wget -qO /tmp/grafana.deb "https://dl.grafana.com/oss/release/grafana_${GRAFANA_VER}_amd64.deb"

# Validasi integritas berkas deb Grafana
if ! dpkg-deb -I /tmp/grafana.deb > /dev/null 2>&1; then
    echo "[-] Gagal: Berkas Grafana v${GRAFANA_VER} rusak atau URL 404!"
    exit 1
fi

apt-get install -y --allow-downgrades --download-only /tmp/webmin.deb /tmp/usermin.deb /tmp/grafana.deb

echo "=== [3/6] Membangun Struktur Hierarki Repo ($CODENAME) ==="
mkdir -p "$REPO_DIR/pool/main"
mkdir -p "$REPO_DIR/dists/$CODENAME/main/binary-$ARCH"

# Salin seluruh berkas .deb ke pool
cp -f /var/cache/apt/archives/*.deb "$REPO_DIR/pool/main/" 2>/dev/null
cp -f /tmp/webmin.deb "$REPO_DIR/pool/main/webmin.deb"
cp -f /tmp/usermin.deb "$REPO_DIR/pool/main/usermin.deb"
cp -f /tmp/grafana.deb "$REPO_DIR/pool/main/grafana.deb"

rm -f /tmp/webmin.deb /tmp/usermin.deb /tmp/grafana.deb

echo "=== [4/6] Mengindeks Repositori ==="
cd "$REPO_DIR" || exit

apt-ftparchive packages pool/main > "dists/$CODENAME/main/binary-$ARCH/Packages"
gzip -kf9 "dists/$CODENAME/main/binary-$ARCH/Packages"

cat <<EOF > /tmp/release.conf
APT::FTPArchive::Release::Origin "LocalRepo";
APT::FTPArchive::Release::Label "LocalRepo";
APT::FTPArchive::Release::Suite "$CODENAME";
APT::FTPArchive::Release::Codename "$CODENAME";
APT::FTPArchive::Release::Architectures "$ARCH all";
APT::FTPArchive::Release::Components "main";
EOF

apt-ftparchive -c /tmp/release.conf release "dists/$CODENAME" > "dists/$CODENAME/Release"
rm -f /tmp/release.conf

echo "=== [5/6] Menandatangani Release dengan Kunci GPG Lokal ==="
mkdir -p "$KEYRING_DIR"

if ! gpg --list-keys "repo-lokal@lab" > /dev/null 2>&1; then
    gpg --batch --passphrase '' --quick-generate-key "repo-lokal@lab" default default never
fi

KEY_ID=$(gpg --list-keys --with-colons "repo-lokal@lab" | awk -F: '/^pub:/ { print $5 }')

rm -f "dists/$CODENAME/InRelease" "dists/$CODENAME/Release.gpg"
gpg --batch --yes --default-key "$KEY_ID" --clearsign -o "dists/$CODENAME/InRelease" "dists/$CODENAME/Release"
gpg --batch --yes --default-key "$KEY_ID" -abs -o "dists/$CODENAME/Release.gpg" "dists/$CODENAME/Release"

gpg --armor --export "$KEY_ID" > "$KEY_FILE"
chmod 644 "$KEY_FILE"
chmod -R 755 "$REPO_DIR"

echo "=== [6/6] Mengunci Sistem: Hanya Repo Lokal ==="
[ -f /etc/apt/sources.list ] && mv /etc/apt/sources.list /etc/apt/sources.list.disabled
for f in /etc/apt/sources.list.d/*.sources /etc/apt/sources.list.d/*.list; do
    [ -f "$f" ] && mv "$f" "$f.disabled"
done

cat <<EOF > /etc/apt/sources.list.d/local.sources
Types: deb
URIs: file:$REPO_DIR
Suites: $CODENAME
Components: main
Signed-By: $KEY_FILE
EOF

apt-get update
