# 🚀 MT7902 WiFi 6E Driver Guide for Linux (Ubuntu / Debian)

Panduan lengkap untuk memperbaiki dan mengaktifkan kembali driver **MediaTek MT7902 WiFi 6E** pada Linux, terutama setelah pembaruan kernel yang menyebabkan WiFi atau Bluetooth tidak berfungsi.

Dokumentasi ini menggabungkan:

- ✅ Metode **otomatis** menggunakan script installer
- ✅ Metode **manual build & install driver**
- ✅ Konfigurasi persistensi setelah reboot
- ✅ Dukungan Bluetooth
- ✅ Langkah rebuild setelah update kernel

---

# 📌 Tentang Project

Chipset **MediaTek MT7902** hingga saat ini belum memiliki dukungan penuh pada mainline Linux kernel.
Akibatnya, banyak pengguna mengalami masalah seperti:

- WiFi tidak muncul
- Bluetooth hilang
- Driver gagal dimuat setelah update kernel
- Error:

```bash
Failed to get patch semaphore
```

Project ini menggunakan driver hasil patch komunitas sebagai workaround agar perangkat tetap dapat digunakan.

---

# ✅ Tested Environment

Panduan ini telah diuji dan berhasil berjalan pada:

| Komponen | Detail |
|---|---|
| Brand | ASUS |
| Model | Vivobook Go E1504FA / E1404FA |
| Chipset | MediaTek MT7902 (WiFi 6E) |
| OS | Ubuntu 24.04 / Ubuntu 25.10 |
| Kernel | 6.17.x – 6.19.x |
| BIOS | E1504FA.308 |
| Compiler | GCC 15.2.0 |

> [!NOTE]
> Pengguna dengan spesifikasi serupa memiliki peluang keberhasilan yang lebih tinggi.

---

# ⚡ Quick Automatic Fix (Recommended)

Metode paling mudah untuk memperbaiki WiFi dan Bluetooth.

## 1️⃣ Clone Repository

```bash
git clone --depth 1 https://github.com/OnlineLearningTutorials/mt7902_temp
cd mt7902_temp
```

## 2️⃣ Jalankan Script Otomatis

```bash
sudo bash fix_my_wifi.sh
```

---

## 📖 Apa yang dilakukan script ini?

Script otomatis akan:

- ✅ Mengecek dependency (`gcc`, `make`, `kernel headers`)
- ✅ Meng-compile driver WiFi & Bluetooth
- ✅ Menginstall module secara otomatis
- ✅ Membuat service systemd agar tetap aktif setelah reboot
- ✅ Menggunakan direktori custom:

```bash
/lib/modules/mt7902_custom
```

agar tidak merusak module bawaan sistem.

> [!IMPORTANT]
> Pastikan Anda memiliki koneksi internet saat pertama kali menjalankan script.
>
> Gunakan:
> - LAN
> - USB tethering smartphone
> - atau adapter WiFi eksternal

---

# 🔧 Manual Build & Install Driver

Jika script otomatis gagal atau Anda ingin melakukan instalasi manual.

---

# 1️⃣ Install Dependency

```bash
sudo apt update
sudo apt install -y build-essential linux-headers-$(uname -r) bc
```

---

# 2️⃣ Clone Repository

```bash
cd ~/dev
git clone --depth 1 https://github.com/OnlineLearningTutorials/mt7902_temp
cd mt7902_temp/latest
```

---

# 3️⃣ Compile Driver

```bash
cd ~/dev/mt7902_temp/latest
make clean
make module_compile
```

Jika berhasil maka akan dihasilkan module:

```text
mt76.ko
mt76-connac-lib.ko
mt792x-lib.ko
mt7921-common.ko
mt7921e.ko
```

---

# 4️⃣ Install Custom Kernel Modules

Buat direktori custom:

```bash
sudo mkdir -p /lib/modules/mt7902_custom/
```

Copy seluruh module:

```bash
sudo cp ~/dev/mt7902_temp/latest/mt76.ko /lib/modules/mt7902_custom/
sudo cp ~/dev/mt7902_temp/latest/mt76-connac-lib.ko /lib/modules/mt7902_custom/
sudo cp ~/dev/mt7902_temp/latest/mt792x-lib.ko /lib/modules/mt7902_custom/
sudo cp ~/dev/mt7902_temp/latest/mt7921/mt7921-common.ko /lib/modules/mt7902_custom/
sudo cp ~/dev/mt7902_temp/latest/mt7921/mt7921e.ko /lib/modules/mt7902_custom/
```

---

# 📦 Firmware Installation

Masuk ke folder firmware:

```bash
cd ~/dev/mt7902_temp/mt7902_firmware/latest
```

Copy firmware:

```bash
sudo cp WIFI_MT7902_patch_mcu_1_1_hdr.bin /lib/firmware/mediatek/
sudo cp WIFI_RAM_CODE_MT7902_1.bin /lib/firmware/mediatek/
sudo cp BT_RAM_CODE_MT7902_1_1_hdr.bin /lib/firmware/mediatek/
```

---

# 🔒 Blacklist Driver Bawaan

Kernel sering memuat module bawaan yang tidak kompatibel.

Buat file blacklist:

```bash
sudo tee /etc/modprobe.d/mt7902-blacklist.conf > /dev/null << 'EOF'
# Block default kernel modules
blacklist mt7925e
blacklist mt7925_common
EOF
```

Update initramfs:

```bash
sudo update-initramfs -u
```

---

# ⚙️ Auto Load Driver on Boot

## 1️⃣ Buat Script Loader

```bash
sudo tee /usr/local/bin/mt7902-setup.sh > /dev/null << 'EOF'
#!/bin/bash

# Remove conflicting modules
rmmod btusb btmtk mt7925e mt7925_common mt7921e mt7921_common mt792x_lib mt76_connac_lib mt76 2>/dev/null

modprobe cfg80211
modprobe mac80211

insmod /lib/modules/mt7902_custom/mt76.ko
insmod /lib/modules/mt7902_custom/mt76-connac-lib.ko
insmod /lib/modules/mt7902_custom/mt792x-lib.ko
insmod /lib/modules/mt7902_custom/mt7921-common.ko
insmod /lib/modules/mt7902_custom/mt7921e.ko
EOF
```

Berikan permission:

```bash
sudo chmod +x /usr/local/bin/mt7902-setup.sh
```

---

## 2️⃣ Buat systemd Service

```bash
sudo tee /etc/systemd/system/mt7902.service > /dev/null << 'EOF'
[Unit]
Description=Load custom MT7902 Wi-Fi drivers
After=network-pre.target
Before=network.target
Wants=network-pre.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/mt7902-setup.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
```

Enable service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable mt7902.service
```

---

# 🔵 Bluetooth Support

Bluetooth juga dapat diperbaiki menggunakan module custom.

---

# ⚠️ Jika Terjadi Konflik Firmware

Hapus firmware lama:

```bash
sudo rm /lib/firmware/mediatek/mt7902/BT_RAM_CODE_MT7902_1_1_hdr.bin.zst
```

Firmware yang digunakan project ini:

```bash
/lib/firmware/mediatek/BT_RAM_CODE_MT7902_1_1_hdr.bin.zst
```

---

# 🔧 Compile Bluetooth Module

Masuk ke direktori:

```bash
./linux-<kernel-version>/drivers/bluetooth
```

Contoh:

```bash
./linux-6.16/drivers/bluetooth
```

Compile:

```bash
make
```

Module yang akan dihasilkan:

```text
btusb.ko
btmtk.ko
```

Install module:

```bash
sudo rmmod btusb
sudo rmmod btmtk

sudo insmod btmtk.ko
sudo insmod btusb.ko
```

---

# 🔄 Rebuild Setelah Kernel Update

Jika kernel diperbarui:

```text
6.17.0-20 -> 6.17.0-21
```

maka module lama tidak akan cocok lagi.

Lakukan langkah berikut:

## 1️⃣ Install Header Baru

```bash
sudo apt install linux-headers-$(uname -r)
```

---

## 2️⃣ Rebuild Driver

```bash
cd ~/dev/mt7902_temp/latest
make clean
make module_compile
```

---

## 3️⃣ Replace Module Lama

```bash
sudo cp *.ko /lib/modules/mt7902_custom/
```

Copy juga file dalam folder mt7921:

```bash
sudo cp mt7921/*.ko /lib/modules/mt7902_custom/
```

---

## 4️⃣ Test Driver

```bash
sudo /usr/local/bin/mt7902-setup.sh
```

Jika berhasil:

- reboot sistem
- atau langsung gunakan WiFi

---

# 📁 Repository

Repository utama:

```bash
https://github.com/OnlineLearningTutorials/mt7902_temp
```

Clone full history:

```bash
git clone https://github.com/OnlineLearningTutorials/mt7902_temp
```

Clone shallow:

```bash
git clone --depth 1 https://github.com/OnlineLearningTutorials/mt7902_temp
```

---

# 💡 Tips

- Gunakan USB tethering saat WiFi mati
- Setelah update kernel biasanya perlu rebuild ulang
- Simpan folder repository agar mudah rebuild
- Jangan overwrite module bawaan kernel secara langsung

---

# 🙌 Credits

Project community MT7902 driver:

- OnlineLearningTutorials
- Linux community contributors
- MediaTek reverse engineering contributors

---

# ⭐ Status

| Feature | Status |
|---|---|
| WiFi | ✅ Working |
| Bluetooth | ✅ Working |
| Ubuntu | ✅ Supported |
| Debian-based distro | ✅ Supported |
| Kernel 6.17+ | ✅ Tested |

---

# 📜 License

Gunakan dengan risiko masing-masing.
Driver ini merupakan hasil modifikasi komunitas dan bukan driver resmi dari MediaTek.
