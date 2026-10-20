#!/bin/bash

# Hentikan pencatatan bash history untuk sesi aktif ini
unset HISTFILE

if [ "$EUID" -ne 0 ]; then
    echo "[-] Jalankan script ini sebagai root (sudo)."
    exit 1
fi

# Trap pengaman untuk menghapus berkas dummy jika proses dibatalkan di tengah jalan
cleanup_trap() {
    rm -f /EMPTY
}
trap cleanup_trap EXIT INT TERM

echo "[1/6] Optimasi Kernel, Filesystem & Timer"
# 1. Atur swappiness ke nilai 10 jika belum ada
if [ ! -f /etc/sysctl.d/99-vm-tuning.conf ]; then
    echo "vm.swappiness=10" > /etc/sysctl.d/99-vm-tuning.conf
    sysctl -p /etc/sysctl.d/99-vm-tuning.conf >/dev/null 2>&1
    echo "[+] Nilai swappiness disetel ke 10."
fi

# 2. Pasang flag noatime pada partisi root di fstab secara aman jika belum terpasang
if ! grep -q "noatime" /etc/fstab; then
    sed -i '/[[:space:]]\/[[:space:]]/ s/defaults/defaults,noatime/' /etc/fstab 2>/dev/null || true
    mount -o remount,noatime / 2>/dev/null || true
    echo "[+] Flag noatime diaktifkan pada partisi root."
fi

# 3. Nonaktifkan background timer agar tidak mengunci APT saat VM baru menyala
systemctl disable --now apt-daily.timer apt-daily-upgrade.timer man-db.timer 2>/dev/null || true

# 4. Potong timeout bootloader GRUB menjadi instan (0 detik)
if [ -f /etc/default/grub ] && grep -q 'GRUB_TIMEOUT=[0-9]\+' /etc/default/grub; then
    if ! grep -q 'GRUB_TIMEOUT=0' /etc/default/grub; then
        sed -i 's/GRUB_TIMEOUT=[0-9]\+/GRUB_TIMEOUT=0/' /etc/default/grub
        update-grub >/dev/null 2>&1
        echo "[+] GRUB timeout disetel ke 0 detik."
    fi
fi

echo "[2/6] Membersihkan Cache APT & Sisa Konfigurasi"
apt-get clean
apt-get autoremove --purge -y

# Hapus sisa konfigurasi dari paket yang sebelumnya di-uninstall
REDUNDANT_CONFIGS=$(dpkg -l | awk '/^rc/ {print $2}')
if [ -n "$REDUNDANT_CONFIGS" ]; then
    echo "[+] Membersihkan sisa file konfigurasi paket usang..."
    dpkg --purge $REDUNDANT_CONFIGS 2>/dev/null || true
fi

echo "[3/6] Memangkas Log & Menghapus Cache Sementara"
# Batasi log jurnal hingga 20M agar riwayat error terkini tetap tersimpan
journalctl --vacuum-size=20M 2>/dev/null

# Hapus file log lama yang terkompresi (.gz / penomoran log)
find /var/log -type f -regex ".*(\.gz|\.[0-9]+)$" -delete

# Kosongkan file log teks aktif tanpa menghapus strukturnya
find /var/log -type f -name "*.log" -exec truncate -s 0 {} \; 2>/dev/null

# Bersihkan direktori temporary
rm -rf /tmp/* /var/tmp/* /var/cache/fontconfig/* 2>/dev/null

echo "[4/6] Membersihkan Riwayat Perintah Bash"
cat /dev/null > /root/.bash_history
for h in /home/*; do
    if [ -d "$h" ]; then
        cat /dev/null > "$h/.bash_history" 2>/dev/null || true
    fi
done

echo "[5/6] Mengosongkan Blok Kosong Disk"
# Gunakan fstrim terlebih dahulu untuk menghemat penulisan SSD
if command -v fstrim >/dev/null 2>&1 && fstrim -av >/dev/null 2>&1; then
    echo "[+] Ruang kosong berhasil dibebaskan via TRIM."
else
    echo "[+] TRIM tidak didukung, menjalankan penulisan blok nol..."
    dd if=/dev/zero of=/EMPTY bs=1M status=progress 2>/dev/null || true
    sync
    rm -f /EMPTY
    sync
fi

echo "[6/6] Menjalankan Penyusutan Disk VMware"
if command -v vmware-toolbox-cmd >/dev/null 2>&1; then
    vmware-toolbox-cmd disk shrink / || echo "[!] Catatan: Penyusutan gagal jika VM memiliki Snapshot aktif."
else
    echo "[!] open-vm-tools tidak ditemukan, melewati tahap shrink."
fi

echo "[+] Seluruh proses selesai. VM akan mati dalam 5 detik..."
sleep 5
poweroff
