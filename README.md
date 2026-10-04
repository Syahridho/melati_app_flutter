# Melati

Aplikasi pelaporan masyarakat Flutter untuk Android.

## Menjalankan aplikasi

`API_KEY` dibaca Flutter sebagai compile-time define dan dikirim melalui header `X-API-KEY`. Di PowerShell, tetapkan environment variable lalu teruskan nilainya ke Flutter:

```powershell
$env:API_KEY = 'melati-secret-api-key'
flutter run --dart-define=API_KEY=$env:API_KEY
```

Untuk membuat APK release:

```powershell
$env:API_KEY = 'melati-secret-api-key'
flutter build apk --release --dart-define=API_KEY=$env:API_KEY
```

Tanpa `API_KEY`, request API mengirim header key kosong. API key yang ditanam saat build dapat diekstrak dari aplikasi klien.
