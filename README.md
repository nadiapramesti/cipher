# Cipher

Aplikasi Android buat belajar cyber security dari nol, buat umum dan berbasis level. Jalan offline: gak ada akun, gak ada iklan, progres disimpan di HP sendiri.

## Level

| Level | Isi | Status |
|---|---|---|
| LV.00 Aman Digital | Password, 2FA, phishing & scam WA/SMS, update & izin aplikasi | ✅ 4 modul |
| LV.01 Fondasi | Internet, IP, DNS, port, dasar Linux | segera |
| LV.02 Web | HTTP, cookie, XSS, SQLi, OWASP Top 10 | segera |
| LV.03 Kriptografi | Encoding vs hashing vs enkripsi, cipher klasik | segera |
| LV.04 Praktek | Mini CTF offline | segera |

## Fitur (MVP tahap 1)

- Onboarding + tes penempatan 8 soal yang ngasih rekomendasi level
- Modul: materi singkat + analogi, kuis dengan pembahasan, lulus minimal 70% buat buka modul berikutnya
- XP dan streak harian
- Toolbox yang kebuka sesuai level, sekarang ada **Cek Kekuatan Password** (entropi, estimasi waktu dibobol, checklist, saran)
- Kamus 22 istilah dengan pencarian dan analogi

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
assets/content/   materi dalam JSON (tambah modul cukup edit di sini)
test/             unit test logika kuis & password
```

## Nambah materi

1. Bikin file `assets/content/lv1.json` dengan format sama kayak `lv0.json`
2. Isi `moduleFile` di level terkait pada `assets/content/levels.json`
3. Jalankan ulang app

## Menjalankan

```bash
flutter create . --project-name cipher --org com.nadiapramesti --platforms android
flutter pub get
flutter analyze
flutter test
flutter run
```

Perintah `flutter create .` cuma dibutuhkan sekali buat bikin folder `android/`, dan gak nimpa `lib/`.

## Prinsip

Semua tools cuma memproses input pengguna sendiri, secara offline. Cipher gak punya fitur buat memindai atau menyerang perangkat dan jaringan orang lain. Latihan menyerang cuma boleh di lab resmi (TryHackMe, HackTheBox) atau perangkat milik sendiri.

---

Dibuat oleh Nadia Pramesti, dibantu Claude (Anthropic) sebagai pair programmer.
