#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "[-] Jalankan script ini sebagai root (sudo su)."
    exit 1
fi

echo "=== [1/5] Membersihkan Cache APT & Paket Tak Terpakai ==="
apt-get clean
apt-get autoremove --purge -y

echo "=== [2/5] Menghapus Berkas Sementara & Memangkas Log ==="
rm -rf /tmp/* /var/tmp/*
journalctl --vacuum-time=1d 2>/dev/null
find /var/log -type f -regex ".*\.gz$" -delete
find /var/log -type f -regex ".*\.[0-9]$" -delete
find /var/log -type f -exec cp /dev/null {} \; 2>/dev/null

echo "=== [3/5] Membersihkan Riwayat Bash ==="
cat /dev/null > ~/.bash_history
history -c

echo "=== [4/5] Melakukan Zero-Filling Ruang Kosong Disk ==="
echo "[+] Menulis blok nol ke ruang kosong (abaikan jika muncul 'No space left on device')..."
dd if=/dev/zero of=/EMPTY bs=1M status=progress 2>/dev/null || true
rm -f /EMPTY
sync

echo "=== [5/5] Melakukan Shrink Disk VMware ==="
if command -v vmware-toolbox-cmd >/dev/null 2>&1; then
    vmware-toolbox-cmd disk shrink /
else
    echo "[!] open-vm-tools tidak terdeteksi, melewati pemadatan via utilitas."
fi

echo "[+] Optimasi selesai. VM akan otomatis dimatikan dalam 5 detik..."
sleep 5
poweroff
