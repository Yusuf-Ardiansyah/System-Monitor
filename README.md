<h1 align="center"> 
  🚀 S-CM (System Monitor)
</h1>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Windows%2011%20(64--bit)-blue?style=for-the-badge&logo=windows" alt="Platform">
  <img src="https://img.shields.io/badge/Built_with-Flutter-02569B?style=for-the-badge&logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Native-C++%20(FFI)-f34b7d?style=for-the-badge&logo=c%2B%2B" alt="C++">
  <img src="https://img.shields.io/badge/Status-Completed-success?style=for-the-badge" alt="Status">
</p>

<p align="center">
  <b>A Lightweight, Frameless, and Always-on-Top System Monitor Widget for Windows.</b><br>
  <i>Developed by <b>Yusuf Ardiansyah</b></i>
</p>

---

## 👁️ Preview

<img width="212" height="39" alt="S-CM" src="https://github.com/user-attachments/assets/c0d000f2-ac2e-414b-be72-bd55c5a81f27" />


---

## ✨ Features

S-CM didesain untuk memberikan pantauan performa PC secara *real-time* tanpa mengganggu produktivitas atau tampilan *desktop* Anda.

*   🟢 **Real-Time Tracking:** Memantau kecepatan Network (Upload `↑` / Download `↓`), persentase CPU, dan Memory (RAM) secara presisi.
*   🥷 **Stealth & Frameless UI:** Tampilan transparan tanpa *border* (bingkai) yang menyatu sempurna dengan *taskbar* atau *desktop*.
*   🎨 **Emerald Bright Aesthetic:** Menggunakan tipografi *Consolas Bold* dengan warna *Emerald Bright* ala *hacker/sultan* untuk keterbacaan tingkat tinggi.
*   📌 **Always on Top:** Widget akan selalu terlihat di atas aplikasi lain.
*   🎮 **Smart Fullscreen Radar:** Dilengkapi radar cerdas yang otomatis menyembunyikan widget saat ada aplikasi atau *game* yang berjalan secara *Fullscreen*, sehingga tidak mengganggu layar.
*   ⚡ **Ultra-Low Resource:** Menggunakan Native C++ DLL (`sys_metrics.dll`) via FFI (*Foreign Function Interface*) untuk menarik data langsung dari kernel Windows tanpa membebani sistem.

---

## 🛠️ Tech Stack & Architecture

Aplikasi ini dibangun menggunakan arsitektur gabungan untuk mencapai efisiensi maksimal:
*   **Frontend:** Flutter (Dart) untuk UI rendering dan state management.
*   **Backend / System Bridge:** C++ (`sys_metrics.dll`) yang berkomunikasi langsung dengan Windows API (`win32`).
*   **Window Management:** `window_manager` & `screen_retriever` untuk kontrol posisi *pixel-perfect*.
*   **Installer:** Dibungkus rapi menggunakan **Inno Setup** menjadi *single executable installer*.
*   **Architecture:** Optimized for `x64` (64-bit).

---

## 🚀 Getting Started (Development)

Jika Anda ingin menjalankan proyek ini dari *source code*:

### Prerequisites
1.  **Flutter SDK** terinstal dengan dukungan *Windows Desktop* diaktifkan.
2.  **Visual Studio** (dengan *Desktop development with C++*) untuk meng- *compile* native code.
3.  Pastikan file `sys_metrics.dll` berada di folder yang sejajar dengan eksekusi *build*.

### Build Instructions
```bash
# Bersihkan cache project
flutter clean

# Tarik semua dependencies
flutter pub get

# Build untuk Windows Release (64-bit)
flutter build windows
