# Cipher

Aplikasi Android buat belajar cyber security dari nol, buat umum dan berbasis level. Jalan offline: gak ada akun, gak ada iklan, progres disimpan di HP sendiri.

## Level

| Level | Isi | Status |
|---|---|---|
| LV.00 Aman Digital | Password, 2FA, phishing, update & izin, privasi medsos, Wi-Fi publik, backup & HP hilang, keamanan keluarga | ✅ 8 modul |
| LV.01 Fondasi | Internet, alamat IP, subnet, DNS, port & protokol, Linux & terminal | ✅ 6 modul |
| LV.02 Web | HTTP, cookie & sesi, XSS, SQL injection, kontrol akses & OWASP Top 10 | ✅ 5 modul |
| LV.03 Kriptografi | Encoding/hash/enkripsi, cipher klasik, penyimpanan password, kunci simetris & asimetris, HTTPS & sertifikat | ✅ 5 modul |
| LV.04 Praktek | Etika & hukum, recon & OSINT, baca log & respons insiden, CTF & karier | ✅ 4 modul |

## Fitur

- Onboarding + tes penempatan 8 soal yang ngasih rekomendasi level
- Modul: materi singkat + analogi, kuis dengan pembahasan, lulus minimal 70% buat buka modul berikutnya
- XP dan streak harian
- Toolbox: **Cek Kekuatan Password**, **Tebak Penipuan**, **Mini CTF** (5 flag), **Terminal Simulasi** (plus log buat latihan grep), **Info Jaringan**, **Inspektor URL** (deteksi domain tiruan), **Hash & Encode**, **Cipher Klasik** (Caesar, Vigenère, analisis frekuensi, brute force)
- **Ulasan** berkala buat soal yang pernah salah, **Pencarian** di semua materi
- **Profil** dengan statistik & 11 lencana, **pengingat harian**
- **Cipher Pro** (Google Play Billing, produk `cipher_pro`) + **sertifikat PDF** per level
- Kamus 22 istilah dengan pencarian dan analogi
- Tampilan **Violet Vault** + elemen 3D: brankas kubus berputar di onboarding, peta level isometrik, kartu materi yang miring, tombol tebal yang bisa "ditekan"

## Tema & bahasa

- 4 tema warna: **Violet Vault**, **Amber Terminal**, **Neon Malam**, **Sakura**
- Tiap tema punya mode **gelap** dan **terang**, plus opsi **ikut HP**
- Dua bahasa: **Indonesia** dan **English**. Bahasa awal ikut bahasa HP
- Semua bisa diganti di **Pengaturan** (tombol di pojok kanan atas beranda)

## Progres & backup

- Progres ikut **Auto Backup Android** (Google), jadi balik sendiri pas ganti HP dengan akun Google yang sama
- **Simpan Progres** di Pengaturan bikin kode `CIPHER1.…` buat dipindah manual ke HP lain lewat **Pulihkan Progres**
- Tanpa akun dan tanpa server, sesuai prinsip offline Cipher

## Struktur

```
lib/
  app/            tema + state progres (shared_preferences)
  core/           model & loader materi
  widgets/        komponen UI bersama
  features/
    onboarding/   onboarding + tes penempatan
    home/         navigasi utama
    learn/        daftar level, modul, materi
    quiz/         kuis + logika skor/streak
    tools/        toolbox + password checker
    glossary/     kamus
assets/content/   materi dalam JSON: id/ (Indonesia) dan en/ (Inggris)
test/             unit test logika kuis & password
```

## Nambah materi

1. Bikin `lv1.json` di **dua** folder: `assets/content/id/` dan `assets/content/en/` (id modul & kunci jawaban harus sama)
2. Isi `moduleFile` (`"lv1.json"`) di `levels.json` kedua bahasa
3. Jalankan ulang app

## Download APK

Tiap push ke `main` otomatis nge-build APK lewat GitHub Actions. Ambil file `.apk` terbaru di halaman **Releases** repo ini, buka di HP Android, lalu install.

## Menjalankan

```bash
flutter create . --project-name cipher --org com.nadiapramesti --platforms android
flutter pub get
flutter analyze
flutter test
flutter run
```

Perintah `flutter create .` cuma dibutuhkan sekali buat bikin folder `android/`, dan gak nimpa `lib/`.

## Font

Chakra Petch (judul), Plus Jakarta Sans (isi), dan Martian Mono (label terminal & kode). Semuanya berlisensi SIL Open Font License (lihat `assets/fonts/OFL-*.txt`).

## Prinsip

Semua tools cuma memproses input pengguna sendiri, secara offline. Cipher gak punya fitur buat memindai atau menyerang perangkat dan jaringan orang lain. Latihan menyerang cuma boleh di lab resmi (TryHackMe, HackTheBox) atau perangkat milik sendiri.

---

Dibuat oleh Nadia Pramesti, dibantu Claude (Anthropic) sebagai pair programmer.

## Rilis Play Store
Semua bahan ada di `docs/play-store/`: teks listing ID/EN (`listing.md`), jawaban Data Safety (`data-safety.md`), feature graphic, dan langkah rilis lengkap (`rilis.md`). Kebijakan privasi di `docs/privacy/` (GitHub Pages).

## Edisi pribadi vs edisi Play Store
- Build biasa (APK di Releases) = **edisi pribadi**: semua level, alat, dan sertifikat kebuka tanpa beli Pro.
- Build buat dijual: `flutter build appbundle --release --dart-define=STORE_BUILD=true` → paywall Cipher Pro aktif.

## APK bisa update tanpa uninstall
CI menandatangani APK pakai kunci tetap dari secret `SIDELOAD_KEYSTORE_B64`. Kalau secret kosong, CI pakai kunci acak dan APK gak bisa menimpa versi sebelumnya.
