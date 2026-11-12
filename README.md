# АРПО. Лабораторные работы

**Студент:** Шех М.И., группа 23-СТ
**Дисциплина:** Автоматизация разработки программного обеспечения
**Преподаватель:** Бровко Н.В.
**Репозиторий:** https://github.com/Tiasssd/2d_platformer

Проект — 2D-платформер на Unity 6. В репозитории настроен сквозной пайплайн CI/CD на GitHub Actions: проверка структуры, тесты Unity, облачная сборка WebGL, публикация игры на GitHub Pages, Docker-образ в GHCR и Telegram-уведомления.

## Лабораторные работы

| № | Тема | Отчёт |
|---|---|---|
| 1 | Автоматизация сборки 2D-игры через командную строку (CLI) | [LR1.md](LR1.md) |
| 2 | Настройка репозиториев на GitHub и Sanity Check, зеркалирование | [LR2.md](LR2.md) |
| 3 | Контейнеризация веб-сервера в Docker и раздача сжатых файлов через Nginx | [LR3.md](LR3.md) |
| 4 | Автоматизация тестирования Unity Test Runner в CI/CD | [LR4.md](LR4.md) |
| 5 | Облачная компиляция WebGL и деплой на GitHub Pages | [LR5.md](LR5.md) |
| 6 | Мониторинг пайплайна, Webhooks и Telegram-оповещения | [LR6.md](LR6.md) |

## Быстрый доступ

- Пайплайн: [.github/workflows/main.yml](.github/workflows/main.yml)
- Docker-образ: `ghcr.io/tiasssd/platformer-game`
- Игра на GitHub Pages: https://tiasssd.github.io/2d_platformer/
