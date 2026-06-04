hipset MediaTek MT7902 adalah salah satu kartu jaringan (wireless card) yang paling terkenal "bikin pusing" komunitas Linux.

Alasan utama mengapa Wi-Fi dan Bluetooth (BT) Anda mati total setelah dikunci ke Kernel 6.17 adalah karena MediaTek MT7902 tidak didukung secara resmi oleh kernel bawaan (mainline) Linux. MediaTek baru mulai mengirimkan kode patch resmi untuk kartu ini ke tim pengembang Linux, namun itu pun baru digarap untuk kernel masa depan. Oleh karena itu, di kernel bawaan Fedora 43 (seperti 6.17), driver bawaannya memang belum ada.

Untuk mengaktifkannya di Kernel 6.17, Anda harus memasang driver buatan komunitas (out-of-tree driver) secara manual.
Solusi Pemulihan (Langkah-demi-Langkah)

Karena Wi-Fi Anda mati, Anda memerlukan koneksi internet sementara terlebih dahulu untuk mengunduh alat perkakas instalasi. Anda bisa menggunakan fitur USB Tethering dari HP Android / iPhone menggunakan kabel data ke laptop/PC Fedora Anda.

Setelah Fedora Anda terhubung ke internet lewat tethering HP, buka Terminal dan ikuti instruksi berikut:
Langkah 1: Install Alat Kompilasi (Development Tools)

Fedora membutuhkan perkakas compiler dan kernel headers versi 6.17 yang sedang Anda gunakan untuk membangun driver ini.
Bash

sudo dnf install git build-essential kernel-devel-$(uname -r) kernel-headers-$(uname -r) elfutils-libelf-devel zstd

Langkah 2: Unduh Driver Komunitas MT7902

Kita akan menggunakan repositori komunitas yang sudah disesuaikan agar stabil berjalan di kernel 6.x modern:
Bash

git clone --depth 1 https://github.com/OnlineLearningTutorials/mt7902_temp
cd mt7902_temp

Langkah 3: Suntik File Header yang Hilang

Pada kernel modern (6.17+), ada file internal bernama airoha_offload.h yang sering kali dicari oleh driver MT7902 saat proses kompilasi namun tidak disediakan sistem. Kita perlu mengunduhnya langsung dari pohon kode Linux resmi:
Bash

sudo mkdir -p /usr/src/kernels/$(uname -r)/include/linux/soc/airoha
sudo curl -sL "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain/include/linux/soc/airoha/airoha_offload.h?h=v6.19" -o /usr/src/kernels/$(uname -r)/include/linux/soc/airoha/airoha_offload.h

Langkah 4: Jalankan Script Instalasi Driver

Masih di dalam folder mt7902_temp, jalankan script otomatis untuk melakukan compile dan pemasangan driver Wi-Fi serta Bluetooth:
Bash

sudo chmod +x fix_my_wifi.sh
sudo ./fix_my_wifi.sh

    Catatan Penting: Terkadang di bagian paling akhir script, instalasi Bluetooth memunculkan status error. Jangan panik, abaikan saja karena biasanya file biner driver Wi-Fi (.ko) sudah berhasil dibangun di latar belakang.

Langkah 5: Muat Driver ke Sistem & Reboot

Setelah selesai, lakukan kompresi modul ke format Zstandard (.zst) yang diwajibkan oleh Fedora modern agar bisa dimuat:
Bash

cd latest
zstd -f --rm *.ko
cd mt7921
zstd -f --rm *.ko
cd ../..

Terakhir, salin firmware-nya secara manual ke folder sistem dan lakukan restart:
Bash

sudo cp -r mt7902_firmware/* /lib/firmware/mediatek/
sudo reboot

Cara Eksekusi Langkah 5 yang Benar
Daripada bingung masuk ke folder satu per satu, setelah Anda selesai menjalankan sudo ./fix_my_wifi.sh di Langkah 4, silakan jalankan perintah di bawah ini di Terminal untuk mengompres semua file .ko yang ada di folder kernel 6.17 Anda:

Bash
# Masuk ke folder kernel 6.17
cd ~/mt7902_temp/linux-6.17/drivers/

# Kompres driver Wi-Fi
cd net/wireless/mediatek/mt76/mt7921/
sudo zstd -f --rm *.ko

# Pindah ke folder Bluetooth dan kompres driver BT
cd ../../../../../bluetooth/
sudo zstd -f --rm *.ko
Langkah Terakhir (Modul Kopling & Firmware)
Setelah dikompres, pastikan modul tersebut disalin ke direktori kernel sistem Fedora Anda agar bisa dibaca saat booting:

Bash
# Salin modul Wi-Fi & BT ke sistem kernel Fedora
sudo cp ~/mt7902_temp/linux-6.17/drivers/net/wireless/mediatek/mt76/mt7921/*.ko.zst /lib/modules/$(uname -r)/kernel/drivers/net/wireless/mediatek/mt76/mt7921/
sudo cp ~/mt7902_temp/linux-6.17/drivers/bluetooth/*.ko.zst /lib/modules/$(uname -r)/kernel/drivers/bluetooth/

# Salin firmware (kembali ke folder utama dulu)
cd ~/mt7902_temp
sudo cp -r firmware/* /lib/firmware/mediatek/

# Perbarui dependensi modul sistem, lalu restart
sudo depmod -a
sudo reboot
Catatan: Jika folder firmware di repositori Anda bernama firmware (bukan mt7902_firmware), perintah di atas sudah disesuaikan menggunakan sudo cp -r firmware/*. Periksa kembali dengan ls di folder utama jika ada kendala.
