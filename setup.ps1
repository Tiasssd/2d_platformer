# Требуется PowerShell 5.1+ и права пользователя (не администратора).
# Скрипт проверяет окружение и клонирует репозиторий. Установку Unity/Docker
# он не выполняет автоматически: эти шаги требуют GUI/прав администратора.

$ErrorActionPreference = "Stop"

function Test-Tool($name, $command) {
    $cmd = Get-Command $command -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-Host ("[OK]   {0}: {1}" -f $name, $cmd.Source) -ForegroundColor Green
        return $true
    } else {
        Write-Host ("[НЕТ]  {0}" -f $name) -ForegroundColor Yellow
        return $false
    }
}

Write-Host "=== Проверка инструментов ==="
$gitOk = Test-Tool "Git" "git"
$ghOk = Test-Tool "GitHub CLI" "gh"
$dockerOk = Test-Tool "Docker" "docker"
$unityPath = "C:\Program Files\Unity\Hub\Editor\6000.3.10f1\Editor\Unity.exe"
if (Test-Path $unityPath) { Write-Host ("[OK]   Unity 6000.3.10f1: " + $unityPath) -ForegroundColor Green }
else { Write-Host "[НЕТ]  Unity 6000.3.10f1 (нужен Unity Hub + WebGL Build Support)" -ForegroundColor Yellow }

if ($dockerOk) {
    try {
        docker info | Out-Null
        Write-Host "[OK]   Docker Engine запущен" -ForegroundColor Green
    } catch {
        Write-Host "[НЕТ]  Docker Engine не запущен. Запусти Docker Desktop." -ForegroundColor Yellow
    }
}

Write-Host "`n=== Клонирование репозитория ==="
$root = Join-Path $HOME "Desktop\Learn\АРПО"
$repo = Join-Path $root "2d_platformer"
New-Item -ItemType Directory -Force -Path $root | Out-Null
if (Test-Path (Join-Path $repo ".git")) {
    Write-Host ("[OK]   Репозиторий уже существует: " + $repo) -ForegroundColor Green
    Push-Location $repo
    git pull --ff-only
    Pop-Location
} else {
    git clone https://github.com/Tiasssd/2d_platformer.git $repo
}

Write-Host "`n=== Следующие шаги ==="
Write-Host "1. Установи Unity 6000.3.10f1 + WebGL Build Support через Unity Hub."
Write-Host "2. Активируй Unity Personal: Hub -> Preferences -> Licenses -> Add."
Write-Host "3. Войди в GitHub CLI: gh auth login"
Write-Host "4. Проверь секреты: gh secret list -R Tiasssd/2d_platformer"
Write-Host "5. Запусти пайплайн: gh workflow run main.yml -R Tiasssd/2d_platformer"
Write-Host ("Проект: " + $repo)
