# АРПО. Лабораторная работа №3 — Контейнеризация веб-сервера в Docker и раздача сжатых файлов через Nginx

**Студент:** Шех М.И., группа 23-СТ
**Дисциплина:** Автоматизация разработки программного обеспечения
**Преподаватель:** Бровко Н.В.
**Репозиторий:** https://github.com/Tiasssd/2d_platformer (рабочая ветка `LR3`)
**Образ:** `ghcr.io/tiasssd/platformer-game`

## Цель работы

Упаковать WebGL-сборку Unity 6 в Docker-образ с веб-сервером Nginx, настроить корректную раздачу Gzip-архивов через заголовок `Content-Encoding: gzip` и автоматизировать сборку образа в GitHub Actions с публикацией в GitHub Container Registry (GHCR).

## Задание

1. Включить в Unity 6 сжатие WebGL в формат Gzip и отключить Decompression Fallback.
2. Пересобрать проект через командную строку и получить файлы `.js.gz`, `.wasm.gz`, `.data.gz`.
3. Создать конфигурацию `nginx.conf` с правилами `Content-Encoding: gzip` для сжатых файлов Unity.
4. Создать `Dockerfile` на базе `nginx:alpine`, который заменяет стандартный конфиг Nginx и копирует сборку игры.
5. Собрать и запустить контейнер локально, проверить заголовок `Content-Encoding: gzip` в DevTools.
6. Добавить в пайплайн GitHub Actions задачу `build_docker_image` с публикацией образа в GHCR под тегами `latest` и `${{ github.sha }}`.
7. Создать файлы `LR1.md`, `LR2.md`, `LR3.md` и таблицу лабораторных работ в `README.md`.

## Решение

### Настройка сжатия Unity и пересборка

В окне `File → Build Profiles → Player Settings → WebGL → Publishing Settings` формат сжатия переключён с `Disabled` на `Gzip`, галочка `Decompression Fallback` снята. В файле `ProjectSettings/ProjectSettings.asset` это соответствует значениям `webGLCompressionFormat: 1` и `webGLDecompressionFallback: 0`.

Значение `webGLCompressionFormat` в Unity 6 имеет порядок `Brotli = 0`, `Gzip = 1`, `Disabled = 2`, поэтому для Gzip используется `1`, а не `0`, как указано в устаревшем примере методички. Проверка настроек выполнена командой:

```
grep -n "webGLCompressionFormat\|webGLDecompressionFallback" ProjectSettings/ProjectSettings.asset
```

Сборка запущена из командной строки методом `BuildManager.BuildWebGL` из ЛР №1. В журнале сборки появилась строка об успешном завершении, а в папке `Builds/WebGL/Build/` — три сжатых файла: `WebGL.framework.js.gz`, `WebGL.wasm.gz`, `WebGL.data.gz`. Фрагмент журнала приведён в листинге 1.

Листинг 1 — Фрагмент журнала сборки WebGL

```
[CI/CD] Запущен автоматический процесс сборки WebGL...
[CI/CD] УСПЕХ! WebGL билд успешно создан.
[CI/CD] Время сборки: 68,82 сек. Размер: 24320083 байт.
```

### Конфигурация Nginx

Файл `nginx.conf` содержит три location-блока: для `.js.gz`, `.wasm.gz` и `.data.gz`. Каждый блок добавляет заголовок `Content-Encoding: gzip` и задаёт правильный MIME-тип, иначе браузер пытается распаковать файл повторно или отказывается его выполнять. Текст конфигурации приведён в листинге 2.

Листинг 2 — Файл `nginx.conf`

```
server {
    listen 80;
    server_name localhost;

    location / {
        root /usr/share/nginx/html;
        index index.html;
        try_files $uri $uri/ /index.html;

        location ~* \.js\.gz$ {
            add_header Content-Encoding gzip;
            default_type application/javascript;
        }

        location ~* \.wasm\.gz$ {
            add_header Content-Encoding gzip;
            default_type application/wasm;
        }

        location ~* \.data\.gz$ {
            add_header Content-Encoding gzip;
            default_type application/octet-stream;
        }
    }
}
```

### Dockerfile

Образ собирается на базе `nginx:alpine`. Стандартный конфиг Nginx удаляется, вместо него копируется `nginx.conf`; содержимое `/usr/share/nginx/html` очищается и заменяется файлами сборки `Builds/WebGL`. Порт 80 объявлен через `EXPOSE`, Nginx запускается в foreground-режиме, чтобы контейнер не завершался сразу. Текст Dockerfile приведён в листинге 3.

Листинг 3 — Файл `Dockerfile`

```
FROM nginx:alpine

RUN rm /etc/nginx/conf.d/default.conf

COPY nginx.conf /etc/nginx/conf.d/

RUN rm -rf /usr/share/nginx/html/*
COPY Builds/WebGL/ /usr/share/nginx/html/

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

### Локальная проверка контейнера

Образ собран командой `docker build -t platformer-compressed:v1 .` и запущен с пробросом порта:

```
docker run -d -p 8080:80 --name unity_compressed_container platformer-compressed:v1
```

Игра открыта по адресу `http://localhost:8080`; в DevTools на вкладке Network у файла `WebGL.wasm.gz` присутствует заголовок `Content-Encoding: gzip`. После проверки контейнер остановлен и удалён:

```
docker stop unity_compressed_container && docker rm unity_compressed_container
```

### Пайплайн GitHub Actions

В `.github/workflows/main.yml` добавлена задача `build_docker_image`, которая запускается после `sanity_check`. Так как папка `Builds/WebGL` исключена через `.gitignore`, задача создаёт временные файлы-заглушки `.gz`, собирает образ и публикует его в GHCR. Для публикации задаче выданы права `packages: write`, вход в реестр выполняется через системный `GITHUB_TOKEN`. Фрагмент пайплайна приведён в листинге 4.

Листинг 4 — Задача `build_docker_image`

```yaml
  build_docker_image:
    needs: sanity_check
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      - name: Create Compressed Placeholders for Docker
        run: |
          mkdir -p Builds/WebGL/Build
          if [ -z "$(ls -A Builds/WebGL/Build)" ]; then
            echo "<h3>Unity 6 Compressed Game Cloud Layer</h3>" > Builds/WebGL/index.html
            touch Builds/WebGL/Build/game.framework.js.gz
            touch Builds/WebGL/Build/game.wasm.gz
            touch Builds/WebGL/Build/game.data.gz
          fi
      - name: Log in to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - name: Build and Push Compressed Docker Image
        uses: docker/build-push-action@v5
        with:
          context: .
          file: ./Dockerfile
          push: true
          tags: |
            ghcr.io/tiasssd/platformer-game:latest
            ghcr.io/tiasssd/platformer-game:${{ github.sha }}
```

### Результаты

После объединения pull request с веткой `main` пайплайн запустился автоматически. Все три задачи — `sanity_check`, `build_docker_image` и `mirror_repo` — завершились успешно. В профиле GitHub появился пакет `platformer-game` с тегами `latest` и тегом коммита.

## Вывод

WebGL-сборка Unity 6 упакована в Docker-образ с Nginx. Кастомный `nginx.conf` добавляет заголовок `Content-Encoding: gzip` для файлов `.js.gz`, `.wasm.gz` и `.data.gz`, поэтому браузер корректно запускает сжатую игру. Docker-образ собирается автоматически в GitHub Actions и публикуется в GHCR под тегами `latest` и `${{ github.sha }}`, что позволяет развернуть игру одной командой `docker run` и откатиться на любую предыдущую сборку. Папка `Builds/WebGL` остаётся вне Git, а на этапе ЛР №3 вместо реальной сборки в образ попадают файлы-заглушки — это готовит пайплайн к подключению облачной компиляции Unity в ЛР №5.

## Контрольные вопросы

**Вопрос 1. Какую техническую проблему решает добавление строки `add_header Content-Encoding gzip;` в конфигурацию Nginx?**

Nginx отдаёт предсжатые файлы `.gz` как обычные бинарные файлы и не сообщает браузеру, что внутри лежит Gzip-поток. Браузер пытается интерпретировать `.wasm.gz` как WebAssembly или JavaScript и завершает загрузку ошибкой «Unable to parse…». Заголовок `Content-Encoding: gzip` явно указывает, что содержимое ответа сжато алгоритмом gzip и его нужно распаковать перед использованием. Дополнительно `default_type` задаёт правильный MIME-тип, чтобы браузер выбрал подходящий обработчик.

**Вопрос 2. Почему в облачном пайплайне пришлось использовать генерацию временных файлов через `touch Builds/WebGL/Build/game.wasm.gz`?**

Папка `Builds/WebGL` исключена из Git через `.gitignore`: она содержит результаты сборки и не должна храниться в репозитории. На облачном раннере этой папки нет, а инструкция `COPY Builds/WebGL/ /usr/share/nginx/html/` в Dockerfile требует существования каталога и хотя бы одного файла. Команда `touch` создаёт пустые файлы-заглушки, чтобы `docker build` завершился успешно и можно было проверить сам механизм упаковки и публикации образа. В ЛР №5 заглушки заменяются реальной сборкой, которую задача `build_game` передаёт через артефакт.

**Вопрос 3. В какую директорию внутри контейнера Nginx нужно копировать финальные файлы WebGL-игры?**

В `/usr/share/nginx/html/` — это стандартный корневой каталог статики официального образа `nginx:alpine`, на который указывает директива `root` в `nginx.conf`. Файл `index.html` и папки `Build`, `StreamingAssets`, `TemplateData` копируются туда целиком, чтобы Nginx отдавал их по адресу `http://localhost:8080/`.

**Вопрос 4. Зачем публиковать образ в GHCR под двумя тегами — `latest` и `github.sha`?**

Тег `latest` удобен для быстрого запуска последней версии: `docker run -p 8080:80 ghcr.io/tiasssd/platformer-game:latest`. Тег с SHA коммита привязывает конкретный образ к конкретному состоянию исходного кода, поэтому можно откатиться на любую предыдущую сборку, сравнить поведение версий и точно воспроизвести проблему. Без такого тега после нового `push` старый образ было бы невозможно однозначно идентифицировать.
