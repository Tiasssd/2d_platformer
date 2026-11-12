# Docker: мини-гайд по командам для сдачи

## Проверка

```powershell
docker --version
docker info
docker run --rm hello-world
```

`docker info` показывает, что Docker Engine запущен. `hello-world` — простейший контейнер, проверка установки.

## Образы

```powershell
docker images                  # список локальных образов
docker pull nginx:alpine       # скачать образ из Docker Hub
docker build -t platformer-compressed:v1 .
docker build --no-cache -t platformer-compressed:v1 .
docker rmi platformer-compressed:v1
```

- `docker build` читает `Dockerfile` в текущей папке (`.` — контекст сборки).
- `-t` задаёт имя и тег: `имя:тег`.
- `--no-cache` собирает заново, без кэша слоёв.

## Контейнеры

```powershell
docker run -d -p 8080:80 --name unity_compressed_container platformer-compressed:v1
docker ps                      # запущенные контейнеры
docker ps -a                   # все, включая остановленные
docker logs unity_compressed_container
docker logs -f unity_compressed_container
docker exec -it unity_compressed_container sh
docker stop unity_compressed_container
docker rm unity_compressed_container
docker rm -f unity_compressed_container
```

- `-d` — в фоне.
- `-p 8080:80` — порт хоста 8080 → порт контейнера 80.
- `--name` — имя контейнера.
- `docker exec ... sh` — зайти внутрь; там можно `ls /usr/share/nginx/html`.
- `docker stop` — остановить; `docker rm` — удалить; `-f` — сразу остановить и удалить.

## Проверка заголовков

Для сборки **без** Decompression Fallback (ЛР3, файлы `.gz`):

```powershell
curl.exe -sI -H "Accept-Encoding: gzip" http://localhost:8080/Build/WebGL.wasm.gz
```

Ожидаемо: `HTTP/1.1 200 OK` и `Content-Encoding: gzip`.

Для сборки **с** Decompression Fallback (ЛР5, файлы `.unityweb`):

```powershell
curl.exe -sI http://localhost:8080/Build/WebGL.wasm.unityweb
```

Заголовка `Content-Encoding` тут **не будет** — это нормально: файл распаковывает JS-загрузчик Unity. Не добавляй `Content-Encoding: gzip` для `.unityweb`, иначе будет двойная распаковка и игра не запустится.

## Nginx внутри контейнера

```powershell
docker exec -it unity_compressed_container nginx -t
docker exec -it unity_compressed_container ls -la /usr/share/nginx/html
docker exec -it unity_compressed_container cat /etc/nginx/conf.d/nginx.conf
```

`nginx -t` проверяет синтаксис конфигурации. `ls` показывает, что файлы игры лежат в `/usr/share/nginx/html`.

## GHCR (готовый образ из GitHub)

```powershell
docker login ghcr.io -u Tiasssd
docker pull ghcr.io/tiasssd/platformer-game:latest
docker run -d -p 8080:80 ghcr.io/tiasssd/platformer-game:latest
```

Для `docker login` нужен PAT с правом `read:packages` (или `repo`). Образ можно запустить на любом компьютере с Docker, не собирая заново.

## Диагностика

```powershell
docker inspect unity_compressed_container
docker inspect unity_compressed_container --format "{{json .NetworkSettings.Ports}}"
docker cp unity_compressed_container:/usr/share/nginx/html/index.html .
docker system df
docker container prune
docker image prune
```

- `inspect` — подробная информация: порты, монтирования, IP.
- `docker cp` — скопировать файл из контейнера на хост.
- `prune` — удалить остановленные контейнеры/неиспользуемые образы (осторожно).

## Что показать на защите

1. `docker build -t platformer-compressed:v1 .` — собрали образ.
2. `docker run -d -p 8080:80 --name unity_compressed_container platformer-compressed:v1` — запустили.
3. `docker ps` — контейнер работает.
4. `curl.exe -sI ...` — заголовок (для `.gz`) или файл `.unityweb`.
5. `docker stop ...; docker rm ...` — убрали за собой.

## Что сказать словами

- **Образ** — «чертёж» или «коробка» с приложением и окружением; хранится на диске/в registry.
- **Контейнер** — запущенный экземпляр образа; его можно остановить и удалить, образ останется.
- **Dockerfile** — инструкция, как собрать образ: базовый образ, копирование файлов, команда запуска.
- **Порт** `-p 8080:80` — проброс: снаружи 8080, внутри контейнера 80.
- **Volume** `-v` — монтирование папки с хоста внутрь контейнера (в CI так монтируется проект).
