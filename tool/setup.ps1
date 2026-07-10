$ErrorActionPreference = "Stop"

function Invoke-Flutter {
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Arguments
  )

  & flutter @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "flutter $($Arguments -join ' ') failed with exit code $LASTEXITCODE."
  }
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw "Flutter was not found. Install Flutter 3.38 or newer and add it to PATH."
}

if (-not (Test-Path "android")) {
  Write-Host "Generating the Android platform project..."
  Invoke-Flutter @("create", "--platforms=android", "--org", "com.tan15hacks", "--project-name", "one_bit_game", "--no-pub", ".")
}

Write-Host "Resolving compatible Flutter and Flame dependencies..."
Invoke-Flutter @("pub", "get")

Write-Host "Checking the Flutter installation..."
& flutter doctor

Write-Host "Setup complete. Run: flutter run"
