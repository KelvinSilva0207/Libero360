param(
  [switch]$Stop,
  [switch]$Rebuild
)

$port = 8080
$pidFile = Join-Path $PSScriptRoot ".serve.pid"

function Start-Server {
  if (Test-Path $pidFile) {
    $oldPid = Get-Content $pidFile
    $proc = Get-Process -Id $oldPid -ErrorAction SilentlyContinue
    if ($proc) {
      Write-Host "Ya hay un servidor corriendo (PID $oldPid)." -ForegroundColor Yellow
      Write-Host "Usa: .\serve.ps1 -Stop  para detenerlo" -ForegroundColor Yellow
      return
    }
    Remove-Item $pidFile -ErrorAction SilentlyContinue
  }

  if ($Rebuild -or -not (Test-Path (Join-Path $PSScriptRoot "build\web\index.html"))) {
    Write-Host "Compilando la web..." -ForegroundColor Cyan
    flutter build web
    if (-not $?) {
      Write-Host "Error en la compilación." -ForegroundColor Red
      return
    }
  }

  Write-Host "Iniciando servidor en http://localhost:$port ..." -ForegroundColor Cyan
  $startInfo = New-Object System.Diagnostics.ProcessStartInfo
  $startInfo.FileName = "npx"
  $startInfo.Arguments = "serve build/web -p $port --no-clipboard"
  $startInfo.WorkingDirectory = $PSScriptRoot
  $startInfo.UseShellExecute = $false
  $startInfo.RedirectStandardOutput = $true
  $startInfo.RedirectStandardError = $true
  $startInfo.CreateNoWindow = $true

  $proc = [System.Diagnostics.Process]::Start($startInfo)
  $proc.Id | Out-File -FilePath $pidFile -Encoding ascii

  Start-Sleep 1
  Write-Host ""
  Write-Host "========================================" -ForegroundColor Green
  Write-Host "  App lista en:" -ForegroundColor Green
  Write-Host "  http://localhost:$port" -ForegroundColor Cyan
  Write-Host "========================================" -ForegroundColor Green
  Write-Host ""
  Write-Host "Para detener: .\serve.ps1 -Stop" -ForegroundColor Yellow
  Write-Host ""
}

function Stop-Server {
  if (-not (Test-Path $pidFile)) {
    Write-Host "No hay servidor corriendo." -ForegroundColor Yellow
    return
  }
  $pid = Get-Content $pidFile
  $proc = Get-Process -Id $pid -ErrorAction SilentlyContinue
  if ($proc) {
    $proc.Kill()
    Write-Host "Servidor (PID $pid) detenido." -ForegroundColor Green
  }
  Remove-Item $pidFile -ErrorAction SilentlyContinue
}

if ($Stop) {
  Stop-Server
} else {
  Start-Server
}
