# Jawaban form Data Safety (Play Console)

Isi form di **Play Console → Kebijakan aplikasi → Keamanan data** pakai jawaban ini.

| Pertanyaan | Jawaban | Alasan |
|---|---|---|
| Apakah app mengumpulkan atau membagikan data pengguna yang wajib dilaporkan? | **Tidak** | Semua data (progres, setelan, nama sertifikat) disimpan lokal dan tidak pernah dikirim ke developer atau pihak ketiga |
| Apakah semua data dienkripsi saat transit? | Tidak berlaku | App tidak mengirim data pengguna |
| Apakah pengguna bisa meminta penghapusan data? | Ya, lewat hapus data app / uninstall | Data cuma ada di HP |

Catatan pendukung:

- **Pembelian**: diproses Google Play Billing. Developer tidak menerima data pembayaran, jadi tidak dilaporkan sebagai pengumpulan data oleh app.
- **Android Auto Backup**: backup dikelola Google untuk pengguna sendiri, bukan dikumpulkan developer.
- **Coba DNS**: nama domain dikirim ke server DNS perangkat hanya saat pengguna menekan tombol, sama seperti membuka situs; developer tidak menerimanya.
- **Notifikasi**: dijadwalkan lokal.

## Izin Android yang dipakai

| Izin | Untuk apa |
|---|---|
| INTERNET | Demo DNS di Info Jaringan + Google Play Billing |
| POST_NOTIFICATIONS | Pengingat harian (Android 13+), diminta saat pengguna menyalakan pengingat |
| RECEIVE_BOOT_COMPLETED | Memasang ulang pengingat setelah HP restart |
| BILLING (otomatis dari plugin) | Pembelian Cipher Pro |

## Deklarasi lain

- **Iklan**: Tidak ada iklan
- **Target audiens**: 13+ (bukan aplikasi untuk anak-anak, jadi tidak masuk program Families)
- **Aplikasi berita / pemerintah / keuangan**: Bukan
- **Kebijakan privasi**: URL GitHub Pages ke `docs/privacy/` (lihat `rilis.md`)
