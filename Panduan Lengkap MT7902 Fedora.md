Berikut adalah versi *raw plaintext* dalam format Markdown asli yang siap Anda salin (`Copy`) dan tempel (`Paste`) langsung ke dalam berkas `README.md` atau `tutorial.md` di repositori GitHub Anda:

# Panduan Perbaikan Wi-Fi & Bluetooth MediaTek MT7902 di Fedora (Kernel 6.17)

Panduan ini ditujukan untuk memperbaiki fungsionalitas Wi-Fi dan Bluetooth pada laptop dengan chipset **MediaTek MT7902** di Fedora Workstation yang mengalami masalah setelah pembaruan kernel sistem (misalnya ke Kernel 7.0+). 

Langkah-langkah di bawah ini akan memandu Anda untuk melakukan *rollback* ke Kernel 6.17 yang stabil, menghapus kernel bermasalah, serta melakukan kompilasi driver secara manual.


## 🛠 Prasyarat & Persiapan

Chipset MT7902 memerlukan driver luar (*out-of-tree driver*). Karena Wi-Fi internal mati, Anda harus menyambungkan HP Android/iPhone menggunakan kabel data ke laptop, lalu aktifkan fitur **USB Tethering** agar laptop mendapatkan koneksi internet sementara.


## 📋 Langkah-Langkah Perbaikan

### Bagian 1: Masuk ke Kernel Lama & Hapus Kernel Bermasalah

1. **Booting ke Kernel 6.17:**
   * Matikan laptop secara paksa (tahan tombol power).
   * Nyalakan kembali. Begitu logo vendor (Asus/Acer/Lenovo/dll) hilang, tekan tombol `Esc` atau `Shift` berulang kali untuk memunculkan menu **GRUB Bootloader**.
   * Gunakan panah bawah pada keyboard, pilih **Fedora Workstation ... 6.17...**, lalu tekan `Enter`.

2. **Hapus Kernel 7.0 yang Bermasalah:**
   Setelah masuk ke desktop, buka Terminal dan jalankan perintah berikut untuk mengecek versi persis kernel Anda:
   ```bash
   rpm -q kernel
   ```



Hapus kernel 7.0 tersebut (ganti `7.0.x-xxx` sesuai dengan versi spesifik yang muncul di terminal Anda, misal: `7.0.1-200.fc43`):

```bash
sudo dnf remove kernel-core-7.0.x-xxx

```

---

### Bagian 2: Persiapan Alat Kompilasi & Source Code

Pastikan internet via USB Tethering sudah aktif, kemudian jalankan perintah di bawah ini secara berurutan:

1. **Install Alat Kompilasi (Development Tools):**
```bash
sudo dnf install git build-essential kernel-devel-$(uname -r) kernel-headers-$(uname -r) elfutils-libelf-devel zstd

```


2. **Unduh Source Code Driver MT7902:**
```bash
git clone --depth 1 https://github.com/OnlineLearningTutorials/mt7902_temp
cd mt7902_temp

```


3. **Suntik File Header `airoha_offload.h` yang Hilang:**
```bash
sudo mkdir -p /usr/src/kernels/$(uname -r)/include/linux/soc/airoha
sudo curl -sL "[https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain/include/linux/soc/airoha/airoha_offload.h?h=v6.19](https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain/include/linux/soc/airoha/airoha_offload.h?h=v6.19)" -o /usr/src/kernels/$(uname -r)/include/linux/soc/airoha/airoha_offload.h

```



---

### Bagian 3: Kompilasi Driver

Sekarang kita akan menjalankan script utama untuk membangun (*compile*) file driver Wi-Fi dan Bluetooth.

```bash
sudo chmod +x fix_my_wifi.sh
sudo ./fix_my_wifi.sh

```

> ⚠️ **Catatan:** Jika di akhir script muncul error terkait Bluetooth, abaikan saja. Proses compile file utamanya biasanya sudah berhasil selesai di latar belakang.

---

### Bagian 4: Kompresi Modul Driver (.ko ke .ko.zst)

Fedora modern mewajibkan semua modul kernel dikompresi menggunakan format Zstandard (`.zst`).

1. **Kompres Driver Wi-Fi:**
```bash
cd ~/mt7902_temp/linux-6.17/drivers/net/wireless/mediatek/mt76/mt7921/
sudo zstd -f --rm *.ko

```


2. **Kompres Driver Bluetooth:**
```bash
cd ~/mt7902_temp/linux-6.17/drivers/bluetooth/
sudo zstd -f --rm *.ko

```



---

### Bagian 5: Penyalinan Modul, Firmware, dan Aktivasi

Langkah terakhir adalah memindahkan file yang sudah siap ke dalam direktori sistem Fedora Anda.

1. **Salin Modul Driver ke Sistem:**
```bash
sudo cp ~/mt7902_temp/linux-6.17/drivers/net/wireless/mediatek/mt76/mt7921/*.ko.zst /lib/modules/$(uname -r)/kernel/drivers/net/wireless/mediatek/mt76/mt7921/

sudo cp ~/mt7902_temp/linux-6.17/drivers/bluetooth/*.ko.zst /lib/modules/$(uname -r)/kernel/drivers/bluetooth/

```


2. **Salin Firmware Modul:**
```bash
cd ~/mt7902_temp
sudo cp -r firmware/* /lib/firmware/mediatek/

```


*(Catatan: Jika setelah di-`ls` folder tersebut bernama `mt7902_firmware`, ganti perintah menjadi: `sudo cp -r mt7902_firmware/* /lib/firmware/mediatek/`)*
3. **Perbarui Dependensi Modul & Restart Laptop:**
```bash
sudo depmod -a

```

---

### Bagian 6: Mengunci Versi Kernel (Kernel Lock)

Agar sistem Fedora tidak otomatis memperbarui kernel ke versi yang lebih baru (yang bisa merusak driver MT7902 ini kembali), Anda wajib mengunci versi kernel 6.17 yang saat ini digunakan menggunakan plugin versionlock.
Install Plugin Versionlock:

```bash
sudo dnf install 'dnf-command(versionlock)'
```

Kunci Kernel Saat Ini:
Jalankan perintah berikut untuk mengunci paket kernel, kernel-core, kernel-devel, dan kernel-headers yang sedang aktif:

```bash
sudo dnf versionlock add kernel-$(uname -r) kernel-core-$(uname -r) kernel-modules-$(uname -r) kernel-devel-$(uname -r) kernel-headers-$(uname -r)
```
Verifikasi Kunci:
Untuk memastikan kernel sudah berhasil dikunci, Anda bisa mengecek daftarnya dengan perintah:

```bash
sudo dnf versionlock list
```
(Catatan: Jika di masa depan Anda ingin membuka kunci kernel ini kembali, Anda cukup menjalankan perintah: sudo dnf versionlock clear)

```bash
reboot
```
---

### 🎉 Selesai

Setelah laptop menyala kembali, lepas kabel tethering HP Anda. Wi-Fi dan Bluetooth MediaTek MT7902 seharusnya sudah aktif dan terdeteksi dengan normal di Fedora Anda.

Untuk memverifikasi perangkat, Anda bisa menggunakan perintah:

```bash
nmcli device status
# atau
rfkill list all
