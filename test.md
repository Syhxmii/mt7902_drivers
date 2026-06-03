Sekarang, mari kita gunakan metode dari repositori yang Anda sebutkan:

Clone repositori tersebut ke laptop Anda:

Bash
git clone --depth 1 https://github.com/OnlineLearningTutorials/mt7902_temp
Masuk ke dalam foldernya:

Bash
cd mt7902_temp
Suntikkan Header Pendukung (Airoha) jika menggunakan Kernel Baru:
Berdasarkan dokumentasi terbaru untuk penanganan kartu ini di kernel modern, jalankan perintah ini untuk memastikan berkas header tidak missing saat kompilasi:

Bash
sudo mkdir -p /usr/src/linux-headers-$(uname -r)/include/linux/soc/airoha
curl -sL "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain/include/linux/soc/airoha/airoha_offload.h?h=v6.19" | sudo tee /usr/src/linux-headers-$(uname -r)/include/linux/soc/airoha/airoha_offload.h > /dev/null
Jalankan skrip otomatis bawaan repositori:
Di dalam folder tersebut biasanya disediakan skrip eksekusi utama, jalankan dengan perintah:

Bash
sudo bash fix_my_wifi.sh
