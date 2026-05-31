# SAT Miner — VPS + NVIDIA GPU (Linux)

`gpu_miner.py` jalan headless, gak butuh GUI/desktop. Yang dipakai cuma OpenCL kernel
(udah built-in di file itu). C extension (`keccak_pow.c`) cuma buat path CPU — **gak perlu**
buat GPU, jadi gak usah compile apa-apa.

## 0. VPS yang dibutuhkan
- VPS dengan **NVIDIA GPU** (RunPod / Vast.ai / TensorDock / dll).
- Ubuntu 22.04/24.04.
- **NVIDIA driver kepasang** (`nvidia-smi` harus jalan). Provider GPU biasanya udah pasang.

## 1. Pasang OpenCL runtime + tools
PyOpenCL butuh ICD loader + ICD-nya NVIDIA (driver NVIDIA udah nyediain OpenCL).

```bash
sudo apt update
sudo apt install -y python3-pip ocl-icd-libopencl1 ocl-icd-opencl-dev clinfo screen

# cek GPU kebaca OpenCL — harus muncul kartu NVIDIA-mu:
clinfo | grep -i -E "platform name|device name"
```

Kalau `clinfo` gak nemu device NVIDIA, biasanya ICD file-nya hilang. Bikin manual:
```bash
sudo mkdir -p /etc/OpenCL/vendors
echo "libnvidia-opencl.so.1" | sudo tee /etc/OpenCL/vendors/nvidia.icd
sudo ldconfig
clinfo | grep -i "device name"   # cek lagi
```

## 2. Pasang miner
```bash
cd ~                      # taruh foldernya di sini
# upload/unzip SatMiner-main ke ~/SatMiner-main
cd SatMiner-main
pip install -r requirements-gpu.txt --break-system-packages
```

## 3. Isi config
Edit `config.yaml`:
- `gpu_device`: biarin `"NVIDIA"`, atau ganti ke型号 spesifik (mis. `"4090"`) kalau ada banyak device.
- `rpc_urls`: udah ada beberapa public BSC RPC. **Sangat disarankan** tambah 1 node berbayar
  (QuickNode/Ankr/dRPC) buat latency rendah — ini lomba kecepatan, RPC lemot = kalah.
- **Private key: JANGAN ditulis di config.** Pakai env var (langkah 4).

## 4. Tes dulu pakai DRY_RUN (WAJIB sebelum buang gas)
`dry_run: true` udah default di config. Ini cuma ngitung solusi + ukur waktu, **gak submit, gak keluar gas**.

```bash
export PRIVATE_KEY=0xKEY_BURNER_KAMU      # pakai wallet kecil khusus, isi BNB sedikit aja
python3 gpu_miner.py
```
Lihat baris `[DRY_RUN] 找到解 ... 耗时 X.XXs 算力 ... ` →
- "耗时" (waktu solve) idealnya jauh **di bawah ~3 detik**. Kalau tiap solve > beberapa detik,
  turunin `gpu_batch_size` (mis. 8000000) biar lebih responsif, atau GPU-nya emang kekecilan.
- Tuning `gpu_batch_size` sambil lihat angka ini.

## 5. Jalan beneran
Kalau algoritma + algoritma OK, matiin dry run:
- Set `dry_run: false` di `config.yaml`, **dan** pastikan wallet ada **BNB** buat gas.

### Opsi A — screen (paling gampang)
```bash
export PRIVATE_KEY=0x...
./run.sh
screen -r satminer        # lihat log (keluar tanpa stop: Ctrl+A lalu D)
```

### Opsi B — systemd (auto-restart kalau VPS reboot / crash)
```bash
# edit satminer.service: isi PRIVATE_KEY + WorkingDirectory yang bener
sudo cp satminer.service /etc/systemd/system/satminer.service
sudo systemctl daemon-reload
sudo systemctl enable --now satminer
journalctl -u satminer -f     # lihat log
sudo systemctl stop satminer  # stop
```

## Catatan penting
- **Pakai wallet burner**, isi BNB secukupnya. Private key nyimpen di VPS = ada risiko;
  jangan taruh wallet utama.
- Ini **competitive PoW mint** — kamu bayar gas tiap submit, dan cuma 1 yang menang per challenge.
  README aslinya nyebut jalur GPU **belum diverifikasi on-chain**; makanya dry_run dulu, terus
  pantau "胜率" (win rate) di statistik. Kalau win rate 0% terus tapi gas kebakar, kemungkinan
  kalah cepat sama miner lain — pertimbangin RPC lebih cepat / GPU lebih kenceng / berhenti.
- Multi-GPU: jalanin 1 proses per GPU, masing-masing set `gpu_device` ke kartu beda (atau
  pakai env `CUDA_VISIBLE_DEVICES` / OpenCL device index per proses).

## Multi-wallet
```bash
export PRIVATE_KEYS=0xaaa...,0xbbb...,0xccc...
```
Miner rotasi otomatis tiap berhasil mint.
