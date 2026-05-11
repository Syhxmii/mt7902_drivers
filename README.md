# 🚀 MT7902 WiFi 6E Driver Guide for Linux (Ubuntu / Debian)

Panduan lengkap untuk memperbaiki dan mengaktifkan kembali driver **MediaTek MT7902 WiFi 6E** pada Linux, terutama setelah pembaruan kernel yang menyebabkan WiFi atau Bluetooth tidak berfungsi.

Dokumentasi ini menggabungkan:

- ✅ Metode **otomatis** menggunakan script installer
- ✅ Metode **manual build & install driver**
- ✅ Konfigurasi persistensi setelah reboot
- ✅ Dukungan Bluetooth
- ✅ Langkah rebuild setelah update kernel

---

# 🙌 Credits

Project community MT7902 driver:

- OnlineLearningTutorials
- Linux community contributors
- MediaTek reverse engineering contributors

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
| Kernel | 6.17.0.20|
| BIOS | E1504FA.308 |
| Compiler | GCC 15.2.0 |

> [!NOTE]
> Pengguna dengan spesifikasi serupa memiliki peluang keberhasilan yang lebih tinggi.

---

# ⚡ Wifi Support

Metode paling mudah untuk memperbaiki WiFi.

```bash
sudo apt update
sudo apt install -y build-essential linux-headers-$(uname -r) bc
```

## 1️⃣ Clone Repository

```bash
git clone --depth 1 https://github.com/Syhxmii/mt7902_drivers
cd mt7902_drivers
```

## 2️⃣ Jalankan Script Otomatis Wifi

```bash
sudo bash fix_my_wifi.sh
```

---

# 🔵 Bluetooth Support

Bluetooth juga dapat diperbaiki menggunakan module custom.

---

## 1️⃣ Jalankan Script Otomatis Bluetooth

Jika Anda ingin menjalankan proses ini secara otomatis, gunakan skrip baru:

```bash
sudo bash fix_my_bluetooth.sh
```

> [!TIP]
> Script `fix_my_bluetooth.sh` telah diperbarui untuk menggunakan metode `insmod` secara langsung (berdasarkan temuan Anda), sehingga seharusnya sekarang sudah bisa berjalan otomatis.

### 🛠️ Manual Fix (Jika Script Gagal)

Jika script di atas tetap tidak berhasil, Anda bisa mencoba memuat module secara manual langsung dari folder source:

```bash
# Ganti 'linux-6.17' dengan versi kernel Anda yang ada di repository ini
cd linux-6.17/drivers/bluetooth

# Unload module bawaan
sudo rmmod btusb 2>/dev/null || true
sudo rmmod btmtk 2>/dev/null || true

# Load module custom secara langsung
sudo insmod btmtk.ko
sudo insmod btusb.ko

# Restart service bluetooth
sudo systemctl restart bluetooth
```


# 📁 Repository

Repository utama:

```bash
https://github.com/OnlineLearningTutorials/mt7902_temp
```

Clone:

```bash
git clone --depth 1 https://github.com/Syhxmii/mt7902_drivers
```

---

# 💡 Tips

- Gunakan USB tethering saat WiFi mati
- Setelah update kernel biasanya perlu rebuild ulang
- Simpan folder repository agar mudah rebuild
- Jangan overwrite module bawaan kernel secara langsung

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
