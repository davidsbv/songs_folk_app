param(
    [string]$VersionName = "v1",
    [string]$AppName = "songs_folk"
)

$ErrorActionPreference = "Stop"

Write-Host "==> Descargando dependencias..."
flutter pub get

Write-Host "==> Compilando APK release..."
flutter build apk --release

$outputDir = "build\app\outputs\flutter-apk"
$sourceApk = Join-Path $outputDir "app-release.apk"

if (!(Test-Path $sourceApk)) {
    throw "No se encontró el APK generado en: $sourceApk"
}

$date = Get-Date -Format "yyyyMMdd"
$targetFileName = "${AppName}_${VersionName}_${date}.apk"
$targetApk = Join-Path $outputDir $targetFileName

if (Test-Path $targetApk) {
    Remove-Item $targetApk -Force
}

Move-Item $sourceApk $targetApk

Write-Host "==> APK generado:"
Write-Host $targetApk
