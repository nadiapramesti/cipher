# Langkah rilis Cipher ke Play Store

## 1. Akun & pembayaran
1. Daftar **Google Play Console** (bayar sekali **$25**): https://play.google.com/console/signup. Pilih akun **Personal**.
2. Selesaikan verifikasi identitas (KTP) dan verifikasi nomor HP.
3. **Setelan → Profil pembayaran → Buat akun merchant** supaya bisa jual produk dalam app. Isi rekening bank buat pencairan.

## 2. Kunci tanda tangan (sekali seumur app, jangan sampai hilang)
```bash
keytool -genkey -v -keystore ~/cipher-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
Simpan file `.jks` dan password-nya di 2 tempat (misal Drive + flashdisk). **Jangan di-commit ke GitHub.**

Buat `android/key.properties` (setelah `flutter create`):
```
storePassword=PASSWORD_KAMU
keyPassword=PASSWORD_KAMU
keyAlias=upload
storeFile=/home/USER/cipher-upload.jks
```
Di `android/app/build.gradle.kts`, tambah di atas blok `android {`:
```kotlin
import java.util.Properties
val keyProps = Properties().apply {
    val f = rootProject.file("key.properties"); if (f.exists()) load(f.inputStream())
}
```
dan di dalam `android { ... }`:
```kotlin
signingConfigs {
    create("release") {
        keyAlias = keyProps["keyAlias"] as String?
        keyPassword = keyProps["keyPassword"] as String?
        storeFile = (keyProps["storeFile"] as String?)?.let { file(it) }
        storePassword = keyProps["storePassword"] as String?
    }
}
```
lalu di `buildTypes { release { ... } }` ganti `signingConfig = signingConfigs.getByName("debug")` jadi `signingConfigs.getByName("release")`.

Build AAB:
```bash
flutter build appbundle --release --dart-define=STORE_BUILD=true
# hasil: build/app/outputs/bundle/release/app-release.aab
```
Aktifkan **Play App Signing** saat upload pertama (default).

## 3. Buat app di Play Console
1. **Buat aplikasi** → nama `Cipher: Belajar Cyber Security`, bahasa default Indonesia, jenis **Aplikasi**, **Gratis** (pembelian Pro lewat in-app).
2. Isi **Kebijakan privasi**: `https://nadiapramesti.github.io/cipher/privacy/`
3. Isi **Keamanan data** sesuai `data-safety.md`.
4. **Rating konten**: isi kuesioner IARC, kategori Pendidikan/Referensi.
5. **Target audiens**: 13–15, 16–17, 18+. Jangan centang di bawah 13.
6. **Iklan**: Tidak.
7. **Listingan toko**: copy dari `listing.md`, upload ikon 512×512, feature graphic, dan minimal 4 screenshot. Tambah terjemahan English (en-US).

## 4. Produk Cipher Pro
1. Upload AAB dulu ke jalur **Pengujian internal** (produk in-app baru bisa dibuat setelah ada build dengan izin BILLING).
2. **Monetisasi → Produk → Produk dalam aplikasi → Buat produk**
   - ID produk: **`cipher_pro`** (harus persis sama, sudah dipakai di kode)
   - Nama: Cipher Pro · Deskripsi: Buka semua level, alat, dan sertifikat
   - Harga: saran **Rp49.000** (atur harga negara lain otomatis)
3. **Aktifkan** produknya.
4. Tambah email kamu di **Setelan → Pengujian lisensi** biar bisa beli tanpa kepotong saldo beneran.

## 5. Pengujian tertutup (wajib untuk akun personal baru)
1. Buat jalur **Pengujian tertutup**, upload AAB yang sama.
2. Undang **minimal 12 penguji** (email Google) lewat daftar email atau Google Group.
3. Penguji harus **opt-in lewat link** dan **tetap terpasang 14 hari berturut-turut**.
4. Setelah 14 hari, klik **Ajukan akses produksi** dan jawab pertanyaan soal pengujian.

## 6. Produksi
1. Buat rilis di **Produksi**, upload AAB (naikkan `version` di `pubspec.yaml` tiap upload, misal `0.6.0+9` → `1.0.0+10`).
2. Review Google biasanya 1–7 hari.

## Checklist sebelum produksi
- [ ] Build pakai `--dart-define=STORE_BUILD=true` (tanpa ini semua fitur Pro gratis!)
- [ ] Ganti `[EMAIL KONTAK]` di `docs/privacy/index.md`
- [ ] Coba beli Pro pakai akun penguji lisensi, cek level terbuka dan sertifikat PDF jalan
- [ ] Cek mode terang di HP asli (peta 3D, kubus, kartu materi)
- [ ] Nyalakan pengingat, tunggu notifikasi muncul di jamnya
- [ ] Coba Simpan Progres → install ulang → Pulihkan
