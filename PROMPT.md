# Промт для развёртывания проекта АРПО на новом устройстве

Скопируй текст ниже в чат ИИ-ассистента на новом ПК (Windows 11). Он проверит окружение, установит недостающее, склонирует репозиторий и прогонит проверки.

---

Ты — инженер-ассистент. Нужно полностью развернуть учебный проект по дисциплине «Автоматизация разработки программного обеспечения» на новом ПК с Windows 11 и проверить лабораторные работы 1–6.

**Данные проекта**
- Репозиторий: https://github.com/Tiasssd/2d_platformer
- Владелец GitHub: Tiasssd
- Движок: Unity 6000.3.10f1 (Unity 6.3), модуль сборки WebGL
- Проект: 2D-платформер (Unity 2D Platformer Microgame)
- Docker Desktop уже установлен; нужен работающий Docker Engine (WSL 2 backend)
- Отчёты: `README.md`, `LR1.md` … `LR6.md` в корне репозитория
- Пайплайн: `.github/workflows/main.yml` (GitHub Actions)
- Образ: `ghcr.io/tiasssd/platformer-game`
- Игра: https://tiasssd.github.io/2d_platformer/

**Что нужно сделать**
1. Проверь инструменты и выведи таблицу «есть / нет»: `git`, `gh` (GitHub CLI), Unity Hub, Unity 6000.3.10f1, Docker Desktop, `docker`.
2. Установи недостающее:
   - Git: https://git-scm.com/download/win
   - GitHub CLI: `winget install --id GitHub.cli` (или https://cli.github.com/)
   - Unity Hub: https://unity.com/download
   - Unity 6000.3.10f1 с модулем **WebGL Build Support**: через Unity Hub → Installs → Install Editor → версия 6000.3.10f1 → отметить WebGL Build Support.
   - Docker Desktop уже есть; проверь `docker run --rm hello-world`.
3. Проверь виртуализацию: Диспетчер задач → Производительность → ЦП → «Виртуализация: Включена». Если выключена — скажи пользователю включить SVM/AMD-V в BIOS.
4. Войди в GitHub CLI: `gh auth login` (аккаунт Tiasssd, HTTPS). Проверь `gh auth status`.
5. Подготовь папку проекта. Если рядом с этим промтом есть готовый архив с папкой `2d_platformer`, просто скопируй её в `$HOME\Desktop\Learn\АРПО\2d_platformer`. Иначе склонируй репозиторий:
   ```powershell
   mkdir "$HOME\Desktop\Learn\АРПО" -Force
   cd "$HOME\Desktop\Learn\АРПО"
   git clone https://github.com/Tiasssd/2d_platformer.git
   cd 2d_platformer
   ```
6. Открой проект в Unity 6000.3.10f1 и дождись импорта ассетов. Если Unity просит активировать лицензию: Unity Hub → Preferences → Licenses → Add → Get a free personal license.
7. Проверь настройки WebGL: `ProjectSettings/ProjectSettings.asset` должен содержать `webGLCompressionFormat: 1` и `webGLDecompressionFallback: 1`. Проверка:
   ```powershell
   Select-String -Path ProjectSettings\ProjectSettings.asset -Pattern "webGLCompressionFormat|webGLDecompressionFallback"
   ```
8. Прогони локальные тесты (Unity должна быть закрыта):
   ```powershell
   $unity = "C:\Program Files\Unity\Hub\Editor\6000.3.10f1\Editor\Unity.exe"
   & $unity -batchmode -nographics -projectPath "$PWD" -runTests -testPlatform EditMode -testResults "$PWD\TestResults_EditMode.xml" -logFile "$PWD\test_editmode.log"
   & $unity -batchmode -nographics -projectPath "$PWD" -runTests -testPlatform PlayMode -testResults "$PWD\TestResults_PlayMode.xml" -logFile "$PWD\test_playmode.log"
   ```
   Ожидаемо: EditMode 1/1 Passed, PlayMode 2/2 Passed (включая тест варианта 18 `PlayMode_PlayerRespawnsAtSpawnPoint_AfterDeath`).
9. Собери WebGL локально:
   ```powershell
   & $unity -batchmode -nographics -projectPath "$PWD" -executeMethod BuildManager.BuildWebGL -quit -logFile "$PWD\build_webgl.log"
   ```
   В логе должна быть строка `[CI/CD] УСПЕХ! WebGL билд успешно создан.`, в `Builds\WebGL\Build` — файлы `WebGL.framework.js.gz`, `WebGL.wasm.gz`, `WebGL.data.gz`.
10. Проверь Docker-образ:
    ```powershell
    docker build -t platformer-compressed:v1 .
    docker run -d -p 8080:80 --name unity_compressed_container platformer-compressed:v1
    curl.exe -sI -H "Accept-Encoding: gzip" http://localhost:8080/Build/WebGL.wasm.gz
    ```
    В ответе должен быть `Content-Encoding: gzip`. Останови контейнер:
    ```powershell
    docker stop unity_compressed_container; docker rm unity_compressed_container
    ```
11. Проверь секреты GitHub (только имена, значения не выводи):
    ```powershell
    gh secret list -R Tiasssd/2d_platformer
    ```
    Должны быть: `UNITY_EMAIL`, `UNITY_PASSWORD`, `BACKUP_TOKEN`, `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`. Если секретов нет — не запускай CI, сообщи пользователю, какие секреты добавить (значения не коммить).
12. Проверь пайплайн:
    ```powershell
    gh workflow run main.yml -R Tiasssd/2d_platformer
    gh run list -R Tiasssd/2d_platformer --limit 5
    ```
    Дождись завершения. Ожидаемо: `sanity_check`, `run_tests`, `build_game`, `build_docker_image`, `deploy_to_pages`, `mirror_repo`, `notify` — зелёные (кроме `mirror_repo`, если нет прав на backup-репозиторий).
13. Проверь GitHub Pages: https://tiasssd.github.io/2d_platformer/ — должна загружаться игра. Если 404: Settings → Pages → Deploy from a branch → gh-pages / (root).
14. Проверь пакет: https://github.com/Tiasssd?tab=packages → `platformer-game` с тегами `latest` и SHA.
15. Ничего не коммить в `main` без необходимости. Не добавлять `Library/`, `Builds/`, `*.log`, `TestResults_*.xml` в Git. Секреты не выводить в чат и не записывать в файлы.

**Критерии готовности**
- `docker run --rm hello-world` работает.
- Локальные EditMode и PlayMode тесты зелёные.
- `build_webgl.log` содержит `[CI/CD] УСПЕХ!`.
- `docker build` и `docker run` работают, `curl -I` показывает `Content-Encoding: gzip`.
- Последний прогон GitHub Actions зелёный, игра открывается на GitHub Pages.

Если какой-то шаг требует прав администратора, перезагрузки или ручного действия (BIOS, установка Unity, вход в аккаунт) — остановись и попроси пользователя выполнить шаг, не пытайся обходить его.
