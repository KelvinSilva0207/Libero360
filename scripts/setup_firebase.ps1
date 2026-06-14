<#
.SYNOPSIS
  Libero360 - Firebase Setup Script
  Configures Firebase Auth + Cloud Firestore for cloud sync.

.DESCRIPTION
  This script:
  1. Installs required tools (Firebase CLI, FlutterFire CLI)
  2. Logs into Firebase (opens browser)
  3. Configures Firebase for Android & iOS
  4. Integrates the Firebase code into the Flutter app
  5. Enables cloud sync feature

.PREREQUISITES
  - Node.js (for firebase-tools)
  - Dart SDK (for flutterfire_cli)
  - A Google account for Firebase
#>

param(
  [switch]$Force
)

Write-Host "=== Libero360 Firebase Setup ===" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# Step 1: Check prerequisites
# ============================================================
Write-Host "Paso 1: Verificando herramientas..." -ForegroundColor Yellow

$hasNode = Get-Command node -ErrorAction SilentlyContinue
if (-not $hasNode) {
  Write-Host "ERROR: Node.js no instalado." -ForegroundColor Red
  Write-Host "       Instálalo desde https://nodejs.org (v18+) y vuelve a ejecutar este script." -ForegroundColor Red
  exit 1
}

Write-Host "  ✓ Node.js"

# Install Firebase CLI if not present
$hasFirebase = Get-Command firebase -ErrorAction SilentlyContinue
if (-not $hasFirebase) {
  Write-Host "  Instalando Firebase CLI..." -ForegroundColor Yellow
  npm install -g firebase-tools
  if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: No se pudo instalar firebase-tools." -ForegroundColor Red
    exit 1
  }
}
Write-Host "  ✓ Firebase CLI"

# Install FlutterFire CLI if not present
$hasFlutterFire = Get-Command flutterfire -ErrorAction SilentlyContinue
if (-not $hasFlutterFire) {
  Write-Host "  Instalando FlutterFire CLI..." -ForegroundColor Yellow
  dart pub global activate flutterfire_cli
  if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: No se pudo instalar flutterfire_cli." -ForegroundColor Red
    exit 1
  }
}
Write-Host "  ✓ FlutterFire CLI"

Write-Host "Herramientas listas!" -ForegroundColor Green

# ============================================================
# Step 2: Firebase Login
# ============================================================
Write-Host ""
Write-Host "Paso 2: Iniciar sesión en Firebase..." -ForegroundColor Yellow
Write-Host "       Se abrirá una ventana del navegador para autenticarte con Google."
firebase login --no-localhost
if ($LASTEXITCODE -ne 0) {
  Write-Host "ERROR: No se pudo iniciar sesión en Firebase." -ForegroundColor Red
  Write-Host "       Alternativa: ejecuta 'firebase login:ci' para generar un token." -ForegroundColor Yellow
  exit 1
}
Write-Host "  ✓ Sesión iniciada"

# ============================================================
# Step 3: FlutterFire Configure
# ============================================================
Write-Host ""
Write-Host "Paso 3: Configurando Firebase en el proyecto..." -ForegroundColor Yellow
Write-Host "       Selecciona o crea un proyecto Firebase."
Write-Host "       Asegúrate de habilitar:"
Write-Host "         - Authentication (método: Email/Password)"
Write-Host "         - Cloud Firestore (modo: producción o prueba)"
Write-Host ""

$projName = Read-Host "Nombre del proyecto Firebase (ej: libero360-app)"

if ($Force -or (Read-Host "¿Configurar Firebase ahora? (s/n)") -eq "s") {
  # Generate firebase_options.dart, google-services.json, GoogleService-Info.plist
  flutterfire configure --project=$projName --yes --platforms=android,ios

  if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: flutterfire configure falló." -ForegroundColor Red
    exit 1
  }
  Write-Host "  ✓ Firebase configurado!"
} else {
  Write-Host "  Saltando configuración. Puedes ejecutar manualmente:"
  Write-Host "    flutterfire configure --project=$projName --yes --platforms=android,ios"
}

# ============================================================
# Step 4: Integrate Firebase code into app
# ============================================================
Write-Host ""
Write-Host "Paso 4: Integrando módulo Firebase en la app..." -ForegroundColor Yellow

# Add Firebase dependencies to pubspec.yaml
$pubspec = Join-Path (Get-Location) "pubspec.yaml"
$content = Get-Content $pubspec -Raw

if ($content -notmatch "firebase_core") {
  $firebaseDeps = @"

  # Firebase
  firebase_core: ^3.12.1
  firebase_auth: ^5.5.1
  cloud_firestore: ^5.6.5
"@
  $content = $content -replace "(?<=dev_dependencies:)", $firebaseDeps
  Set-Content -Path $pubspec -Value $content
  Write-Host "  ✓ Dependencias Firebase agregadas a pubspec.yaml"
}

# Copy Firebase service files into lib/
$libFirebase = Join-Path (Get-Location) "lib_firebase"
$lib = Join-Path (Get-Location) "lib"

if (Test-Path $libFirebase) {
  Copy-Item -Path "$libFirebase\*" -Destination $lib -Recurse -Force
  Write-Host "  ✓ Código Firebase copiado a lib/"
}

# Update config.dart to enable Firebase
$configPath = Join-Path $lib "core\config.dart"
$configContent = Get-Content $configPath -Raw
$configContent = $configContent -replace "static bool _useFirebase = false;", "static bool _useFirebase = true;"
Set-Content -Path $configPath -Value $configContent
Write-Host "  ✓ Firebase activado en configuración"

# ============================================================
# Step 5: Install dependencies and verify
# ============================================================
Write-Host ""
Write-Host "Paso 5: Instalando dependencias..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
  Write-Host "ERROR: flutter pub get falló." -ForegroundColor Red
  exit 1
}
Write-Host "  ✓ Dependencias instaladas"

Write-Host ""
Write-Host "Paso 6: Verificando análisis..." -ForegroundColor Yellow
flutter analyze --no-fatal-infos --no-fatal-warnings
if ($LASTEXITCODE -ne 0) {
  Write-Host "ADVERTENCIA: Hay problemas de análisis. Revisa los mensajes arriba." -ForegroundColor Yellow
} else {
  Write-Host "  ✓ Análisis limpio"
}

# ============================================================
# Done!
# ============================================================
Write-Host ""
Write-Host "=== Firebase configurado exitosamente! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Pasos adicionales en Firebase Console:"
Write-Host "  1. https://console.firebase.google.com/project/$projName/authentication/providers"
Write-Host "     → Habilita 'Correo electrónico/Contraseña' como método de inicio de sesión"
Write-Host "  2. https://console.firebase.google.com/project/$projName/firestore"
Write-Host "     → Crea la base de datos Firestore (modo prueba para empezar)"
Write-Host "  3. Si usas Android: agrega la huella SHA-1 en Configuración del proyecto"
Write-Host "     (para Google Sign-In)"
Write-Host ""
Write-Host "¡Disfruta de Libero360 con sincronización en la nube!" -ForegroundColor Cyan
Write-Host ""
Write-Host "Para compilar y ejecutar: flutter run"
