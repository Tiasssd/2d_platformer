# Развёртывание проекта АРПО на новом устройстве

## Что понадобится

| Инструмент | Версия / примечание |
|---|---|
| Windows | 10/11 x64 |
| Git | любая актуальная |
| GitHub CLI (`gh`) | для работы с Actions и секретами |
| Unity Hub | https://unity.com/download |
| Unity Editor | **6000.3.10f1** + модуль **WebGL Build Support** |
| Docker Desktop | уже установлен на новом устройстве; нужен WSL 2 backend |
| Виртуализация | включена в BIOS (SVM / AMD-V) |

## Быстрый старт

1. Проверь инструменты:
   ```powershell
   git --version
   gh --version
   docker --version
   docker run --rm hello-world
   ```
2. Войди в GitHub:
   ```powershell
   gh auth login
   ```
3. Склонируй репозиторий:
   ```powershell
   mkdir "$HOME\Desktop\Learn\АРПО" -Force
   cd "$HOME\Desktop\Learn\АРПО"
   git clone https://github.com/Tiasssd/2d_platformer.git
   cd 2d_platformer
   ```
4. Установи Unity 6000.3.10f1 с модулем WebGL Build Support через Unity Hub. Активируй бесплатную лицензию: `Unity Hub → Preferences → Licenses → Add → Get a free personal license`.
5. Открой проект в Unity, дождись импорта.
6. Проверь настройки WebGL:
   ```powershell
   Select-String -Path ProjectSettings\ProjectSettings.asset -Pattern "webGLCompressionFormat|webGLDecompressionFallback"
   ```
   Ожидаемо: `webGLCompressionFormat: 1`, `webGLDecompressionFallback: 1`.
7. Прогони тесты и сборку (Unity должна быть закрыта):
   ```powershell
   $unity = "C:\Program Files\Unity\Hub\Editor\6000.3.10f1\Editor\Unity.exe"
   & $unity -batchmode -nographics -projectPath "$PWD" -runTests -testPlatform EditMode -testResults "$PWD\TestResults_EditMode.xml" -logFile "$PWD\test_editmode.log"
   & $unity -batchmode -nographics -projectPath "$PWD" -runTests -testPlatform PlayMode -testResults "$PWD\TestResults_PlayMode.xml" -logFile "$PWD\test_playmode.log"
   & $unity -batchmode -nographics -projectPath "$PWD" -executeMethod BuildManager.BuildWebGL -quit -logFile "$PWD\build_webgl.log"
   ```
8. Проверь Docker:
   ```powershell
   docker build -t platformer-compressed:v1 .
   docker run -d -p 8080:80 --name unity_compressed_container platformer-compressed:v1
   curl.exe -sI -H "Accept-Encoding: gzip" http://localhost:8080/Build/WebGL.wasm.gz
   ```
9. Секреты GitHub (значения не хранить в файлах):
   - `UNITY_EMAIL`, `UNITY_PASSWORD` — аккаунт Unity;
   - `BACKUP_TOKEN` — PAT для зеркалирования;
   - `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID` — бот ЛР6.
   Проверка имён: `gh secret list -R Tiasssd/2d_platformer`.
10. Запусти пайплайн:
    ```powershell
    gh workflow run main.yml -R Tiasssd/2d_platformer
    gh run list -R Tiasssd/2d_platformer --limit 5
    ```
11. Проверь игру: https://tiasssd.github.io/2d_platformer/ и пакет `platformer-game` в GHCR.

## Важно

- `Library/`, `Builds/`, `Temp/`, `Logs/`, `*.log`, `TestResults_*.xml` — генерируемые файлы, в Git не добавляются.
- `ProjectSettings/ProjectVersion.txt` хранится в репозитории и фиксирует версию Unity.
- Для GitHub Pages нужен один раз включить хостинг: `Settings → Pages → Deploy from a branch → gh-pages / (root)`.
- Если Unity Personal активируется через Google/Apple, для CI нужен пароль в `Account → Security` (или отдельный CI-аккаунт).
