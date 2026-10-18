#!/bin/bash

# --- Definisi Format Teks & Warna ANSI ---
CLR_RESET="\e[0m"
CLR_BOLD="\e[1m"
CLR_GREEN="\e[1;32m"
CLR_BLUE="\e[1;34m"
CLR_CYAN="\e[1;36m"
CLR_YELLOW="\e[1;33m"
CLR_RED="\e[1;31m"

if [ "$EUID" -ne 0 ]; then
    echo -e "${CLR_RED}[-]${CLR_RESET} Jalankan script ini sebagai root (sudo su)."
    exit 1
fi

REPO_DIR="/opt/repo"
CODENAME=$(grep VERSION_CODENAME /etc/os-release | cut -d= -f2)
ARCH="amd64"
KEYRING_DIR="/etc/apt/keyrings"
KEY_FILE="$KEYRING_DIR/local-repo.asc"

echo -e "${CLR_BOLD}${CLR_CYAN}==========================================================${CLR_RESET}"
echo -e "${CLR_BOLD}${CLR_CYAN}         Debian Air-Gapped Local Repository Builder       ${CLR_RESET}"
echo -e "${CLR_BOLD}${CLR_CYAN}==========================================================${CLR_RESET}"
echo ""
echo -en "${CLR_YELLOW}[?]${CLR_RESET} Sertakan paket utama Webmin, Usermin, dan Grafana ke repo lokal? [y/N] (Pilih 'n' untuk menghemat ~250 MB): "
read -r INCLUDE_EXT
INCLUDE_EXT=${INCLUDE_EXT:-n}

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

    # --- Keamanan & Hardening Server ---
    ufw
    nftables
    fail2ban
    lynis
    debsums
    rkhunter
    libpam-pwquality
    nmap
    lsof
    tcpdump

    # --- OpenVPN & Routing Stack ---
    openvpn
    iptables
    ca-certificates
    
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

echo ""
echo -e "${CLR_BOLD}${CLR_BLUE}[1/6]${CLR_RESET} ${CLR_BOLD}Mengaktifkan Repo Online & Mengosongkan Direktori Repo${CLR_RESET}"
echo -e "${CLR_GREEN}[+]${CLR_RESET} Target OS: Debian ($CODENAME - $ARCH)"
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

echo ""
echo -e "${CLR_BOLD}${CLR_BLUE}[2/6]${CLR_RESET} ${CLR_BOLD}Mendeteksi & Mengunduh Paket Eksternal${CLR_RESET}"

# Deteksi rilis terbaru Grafana via GitHub Atom feed
echo -e "${CLR_GREEN}[+]${CLR_RESET} Memeriksa rilis terbaru Grafana OSS cabang v12..."
GRAFANA_VER=$(curl -fsSL --max-time 4 "https://github.com/grafana/grafana/releases.atom" 2>/dev/null \
    | grep -oP 'tag/v\K(12\.[0-9]+\.[0-9]+)' \
    | head -n 1)

# Fallback jika terjadi timeout atau kegagalan jaringan
if [ -z "$GRAFANA_VER" ]; then
    GRAFANA_VER="12.0.0"
    echo -e "${CLR_YELLOW}[!]${CLR_RESET} Pengecekan otomatis timeout, menggunakan default versi v${GRAFANA_VER}"
else
    echo -e "${CLR_GREEN}[+]${CLR_RESET} Berhasil mendeteksi Grafana v12 terbaru: v${GRAFANA_VER}"
fi

echo -e "${CLR_GREEN}[+]${CLR_RESET} Mengunduh paket materi praktikum..."
apt-get install -y --reinstall --download-only "${PAKET[@]}"

echo -e "${CLR_GREEN}[+]${CLR_RESET} Mengunduh Webmin, Usermin, dan Grafana OSS (v${GRAFANA_VER})..."
wget -qO /tmp/webmin.deb https://webmin.com/download/deb/webmin-current.deb
wget -qO /tmp/usermin.deb https://webmin.com/download/deb/usermin-current.deb
wget -qO /tmp/grafana.deb "https://dl.grafana.com/oss/release/grafana_${GRAFANA_VER}_amd64.deb"

# Validasi berkas deb Grafana
if ! dpkg-deb -I /tmp/grafana.deb > /dev/null 2>&1; then
    echo -e "${CLR_RED}[-]${CLR_RESET} Gagal: Berkas Grafana v${GRAFANA_VER} rusak atau URL 404!"
    exit 1
fi

echo -e "${CLR_GREEN}[+]${CLR_RESET} Mengunduh dependensi pustaka Webmin, Usermin, dan Grafana..."
apt-get install -y --allow-downgrades --download-only /tmp/webmin.deb /tmp/usermin.deb /tmp/grafana.deb

echo ""
echo -e "${CLR_BOLD}${CLR_BLUE}[3/6]${CLR_RESET} ${CLR_BOLD}Membangun Struktur Hierarki Repo ($CODENAME)${CLR_RESET}"
mkdir -p "$REPO_DIR/pool/main"
mkdir -p "$REPO_DIR/dists/$CODENAME/main/binary-$ARCH"

# Salin seluruh berkas dependensi ke pool
cp -f /var/cache/apt/archives/*.deb "$REPO_DIR/pool/main/" 2>/dev/null

# Opsi penyalinan berkas eksternal
if [[ "$INCLUDE_EXT" =~ ^[Yy]$ ]]; then
    echo -e "${CLR_GREEN}[+]${CLR_RESET} Menyalin Webmin, Usermin, dan Grafana ke repositori lokal..."
    cp -f /tmp/webmin.deb "$REPO_DIR/pool/main/webmin.deb"
    cp -f /tmp/usermin.deb "$REPO_DIR/pool/main/usermin.deb"
    cp -f /tmp/grafana.deb "$REPO_DIR/pool/main/grafana.deb"
else
    echo -e "${CLR_YELLOW}[*]${CLR_RESET} Paket utama Webmin, Usermin, dan Grafana dilewati (hanya dependensinya yang disimpan)."
fi

rm -f /tmp/webmin.deb /tmp/usermin.deb /tmp/grafana.deb

echo ""
echo -e "${CLR_BOLD}${CLR_BLUE}[4/6]${CLR_RESET} ${CLR_BOLD}Mengindeks Repositori${CLR_RESET}"
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

echo ""
echo -e "${CLR_BOLD}${CLR_BLUE}[5/6]${CLR_RESET} ${CLR_BOLD}Menandatangani Release dengan Kunci GPG Lokal${CLR_RESET}"
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

echo ""
echo -e "${CLR_BOLD}${CLR_BLUE}[6/6]${CLR_RESET} ${CLR_BOLD}Mengunci Sistem: Hanya Repo Lokal${CLR_RESET}"
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
