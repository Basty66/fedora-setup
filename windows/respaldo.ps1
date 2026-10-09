<#
.SYNOPSIS
  Respaldo de Windows antes de formatear para pasar a Fedora.

.DESCRIPTION
  1. Regenera las listas de ..\listas (extensiones de VS Code, npm global, pip).
  2. Avisa qué repos de Git tienen trabajo que NO está en GitHub y qué proyectos no usan Git.
  3. Con -Destino (ej. un disco externo) copia ahí:
       secretos\   .env, .pem, .key, credentials.json, ~/.ssh, ~/.aws, ~/.kube, ~/.gitconfig
       vscode\     settings.json, keybindings.json y snippets de VS Code
       Desktop\ y Documents\   todo, sin node_modules, target, dist, etc.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\windows\respaldo.ps1
  powershell -ExecutionPolicy Bypass -File .\windows\respaldo.ps1 -Destino "E:\respaldo-windows"
#>
param([string]$Destino)

$repo = Split-Path $PSScriptRoot -Parent
$listas = Join-Path $repo "listas"
$escritorio = [Environment]::GetFolderPath("Desktop")
$documentos = [Environment]::GetFolderPath("MyDocuments")
$carpetas = @($escritorio, $documentos, (Join-Path $env:USERPROFILE "Downloads")) | Where-Object { Test-Path $_ }
$excluir = "node_modules", ".venv", "venv", "target", "dist", "build", ".next", ".gradle", "__pycache__"

function Escribir-Lista($nombre, $encabezado, $lineas) {
  # UTF-8 sin BOM y saltos de línea LF, para que bash en Fedora los lea bien
  $lineas = @($lineas | Where-Object { $_ })
  $texto = (@($encabezado) + $lineas) -join "`n"
  [IO.File]::WriteAllText((Join-Path $listas $nombre), $texto + "`n", (New-Object Text.UTF8Encoding $false))
  Write-Host ("  {0}: {1} elementos" -f $nombre, $lineas.Count)
}

function Relativa($ruta) { $ruta.Substring($env:USERPROFILE.Length + 1) }

# ─── 1. Listas ───────────────────────────────────────────────────────────────
Write-Host "1) Generando listas en $listas" -ForegroundColor Cyan
New-Item -ItemType Directory -Force $listas | Out-Null

if (Get-Command code -ErrorAction SilentlyContinue) {
  Escribir-Lista "vscode-extensions.txt" "# Extensiones de VS Code (code --list-extensions)" (code --list-extensions)
}
if (Get-Command npm -ErrorAction SilentlyContinue) {
  $npm = (npm ls -g --depth=0 --json | Out-String | ConvertFrom-Json).dependencies.PSObject.Properties.Name |
    Where-Object { $_ -notin "npm", "corepack" }
  Escribir-Lista "npm-global.txt" "# Paquetes globales de npm (npm ls -g --depth=0)" $npm
}
if (Get-Command python -ErrorAction SilentlyContinue) {
  $pip = python -m pip list --not-required --format=freeze --disable-pip-version-check | Where-Object { $_ -notmatch "^pip==" }
  Escribir-Lista "pip-packages.txt" "# Paquetes de Python en Windows. SOLO REFERENCIA: en Fedora instálalos en un venv por proyecto." $pip
}

# ─── 2. Trabajo que no está en GitHub ────────────────────────────────────────
Write-Host "`n2) Buscando trabajo que NO está en GitHub..." -ForegroundColor Cyan

$repos = foreach ($carpeta in $carpetas) {
  Get-ChildItem $carpeta -Directory -Recurse -Depth 5 -Force -Filter ".git" -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch "node_modules" } |
    ForEach-Object { $_.Parent.FullName }
}
$pendientes = foreach ($r in ($repos | Sort-Object -Unique)) {
  $remoto = git -C $r remote get-url origin 2>$null
  $sinCommit = @(git -C $r status --porcelain 2>$null).Count
  $sinPush = @(git -C $r log --branches --not --remotes --oneline 2>$null).Count
  if (-not $remoto -or $sinCommit -or $sinPush) {
    [PSCustomObject]@{
      Repo           = Relativa $r
      EnGitHub       = if ($remoto) { "si" } else { "NO" }
      ArchivosSinCommit = $sinCommit
      CommitsSinPush = $sinPush
    }
  }
}
if ($pendientes) {
  Write-Host "Repos con trabajo pendiente:" -ForegroundColor Yellow
  $pendientes | Format-Table -AutoSize | Out-String -Width 200 | Write-Host
} else {
  Write-Host "  Todos tus repos están al día con GitHub." -ForegroundColor Green
}

# Proyectos (package.json, pom.xml, etc.) que no están dentro de ningún repo de Git
$manifiestos = foreach ($carpeta in $carpetas) {
  Get-ChildItem $carpeta -Recurse -Depth 5 -File -ErrorAction SilentlyContinue `
    -Include package.json, pom.xml, build.gradle, build.gradle.kts, requirements.txt, pyproject.toml, manage.py |
    Where-Object { $_.FullName -notmatch "\\(node_modules|\.venv|venv|target|\.git)\\" } |
    ForEach-Object { $_.DirectoryName }
}
$sinGit = $manifiestos | Sort-Object -Unique | Where-Object { -not (git -C $_ rev-parse --is-inside-work-tree 2>$null) }
$raices = @()
foreach ($d in ($sinGit | Sort-Object Length)) {
  if (-not ($raices | Where-Object { $d.StartsWith("$_\") })) { $raices += $d }
}
if ($raices) {
  Write-Host "Proyectos SIN Git (solo existen en este PC):" -ForegroundColor Yellow
  $raices | ForEach-Object { Write-Host "  $(Relativa $_)" }
}

# ─── 3. Copia de respaldo ────────────────────────────────────────────────────
if (-not $Destino) {
  Write-Host "`nPara copiar secretos y proyectos a un disco externo:" -ForegroundColor Cyan
  Write-Host '  powershell -ExecutionPolicy Bypass -File .\windows\respaldo.ps1 -Destino "E:\respaldo-windows"'
  exit 0
}
$Destino = [IO.Path]::GetFullPath($Destino)
if ($Destino.StartsWith($env:USERPROFILE, [StringComparison]::OrdinalIgnoreCase)) {
  Write-Error "El destino debe estar FUERA de tu carpeta de usuario (ej. un disco externo), si no se borrará al formatear."
  exit 1
}

Write-Host "`n3) Copiando respaldo a $Destino" -ForegroundColor Cyan
$secretos = Join-Path $Destino "secretos"
foreach ($carpeta in $carpetas) {
  Get-ChildItem $carpeta -Recurse -Depth 6 -Force -File -ErrorAction SilentlyContinue `
    -Include .env, .env.*, *.pem, *.key, *.p12, *.pfx, *.jks, *.keystore, credentials.json |
    Where-Object { $_.FullName -notmatch "\\(node_modules|\.git)\\" } |
    ForEach-Object {
      $dest = Join-Path $secretos (Relativa $_.FullName)
      New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
      Copy-Item $_.FullName $dest -Force
    }
}
foreach ($f in ".ssh", ".aws", ".kube", ".gitconfig") {
  $p = Join-Path $env:USERPROFILE $f
  if (Test-Path $p) { Copy-Item $p (Join-Path $secretos $f) -Recurse -Force }
}
Write-Host "  Secretos copiados en $secretos"

$vscode = Join-Path $env:APPDATA "Code\User"
New-Item -ItemType Directory -Force (Join-Path $Destino "vscode") | Out-Null
foreach ($f in "settings.json", "keybindings.json", "snippets") {
  $p = Join-Path $vscode $f
  if (Test-Path $p) { Copy-Item $p (Join-Path $Destino "vscode") -Recurse -Force }
}
Write-Host "  Configuración de VS Code copiada."

foreach ($carpeta in $escritorio, $documentos) {
  $nombre = Split-Path $carpeta -Leaf
  Write-Host "  Copiando $nombre (puede tardar)..."
  robocopy $carpeta (Join-Path $Destino $nombre) /E /XJ /XD $excluir /R:1 /W:1 /NFL /NDL /NP /NJH | Out-Null
  if ($LASTEXITCODE -ge 8) { Write-Warning "robocopy tuvo errores copiando $nombre" }
}
Write-Host "`nRespaldo listo en $Destino" -ForegroundColor Green
Write-Host "La carpeta 'secretos' tiene contraseñas y llaves: NUNCA la subas a GitHub." -ForegroundColor Yellow
