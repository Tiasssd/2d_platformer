# АРПО. Лабораторная работа №4 — Автоматизация тестирования (Unity Test Runner) в CI/CD

**Студент:** Шех М.И., группа 23-СТ
**Дисциплина:** Автоматизация разработки программного обеспечения
**Преподаватель:** Бровко Н.В.
**Репозиторий:** https://github.com/Tiasssd/2d_platformer (рабочая ветка `LR4`)
**Индивидуальный вариант:** 18
**Механика варианта:** `PlayerSpawn` + `SpawnPoint`
**Тип теста:** PlayMode
**Проверяемое поведение:** после смерти игрок появляется в точке спавна

## Цель работы

Настроить автоматический запуск Unity-тестов (EditMode и PlayMode) в облачном пайплайне так, чтобы компиляция игры и сборка Docker-образа выполнялись только после успешного прохождения всех тестов.

## Задание

1. Разделить кодовую базу с помощью Assembly Definition: создать `GameAssembly` для игровых скриптов и отдельные тестовые сборки для EditMode и PlayMode.
2. Написать базовый EditMode-тест `PlayerTests.cs`, проверяющий тег и компоненты игрока на сцене.
3. Написать базовый PlayMode-тест `PlayerHealthTests.cs`, проверяющий уменьшение здоровья.
4. Написать дополнительный PlayMode-тест по варианту 18: после смерти игрок появляется в точке спавна.
5. Прогнать тесты локально в Test Runner и убедиться, что все они зелёные.
6. Добавить в GitHub Actions задачу `run_tests`, запускающую EditMode и PlayMode в контейнере `unityci/editor`.
7. Сделать задачи `build_docker_image` и `mirror_repo` зависимыми от `run_tests`.
8. Продемонстрировать защиту пайплайна: сломанный тест должен остановить сборку и публикацию.
9. Создать файл `LR4.md`, обновить `README.md` и таблицу лабораторных работ.

## Решение

### Assembly Definitions

Игровые скрипты вынесены в сборку `GameAssembly`: файл `Assets/Scripts/GameAssembly.asmdef` со ссылками на пакеты `Unity.InputSystem` и `Unity.Cinemachine`. Без этих ссылок пользовательская сборка не видит `InputAction` и `CinemachineCamera`, потому что ранее скрипты лежали в общем `Assembly-CSharp` и получали ссылки на пакеты автоматически.

Тестовые сборки размещены отдельно, потому что режим запуска определяется настройкой `includePlatforms`. Сборка `Tests` с `"includePlatforms": ["Editor"]` запускается только в EditMode, сборка `PlayModeTests` без этого ограничения — только в PlayMode. Обе тестовые сборки ссылаются на `GameAssembly`, `UnityEngine.TestRunner` и `UnityEditor.TestRunner`, поэтому видят игровые классы, но сами не попадают в финальную сборку игры.

### Базовые тесты

EditMode-тест `PlayerTests.cs` открывает сцену `Assets/Scenes/SampleScene.unity`, находит объект `Player`, проверяет тег `Player` и наличие компонентов `PlayerController` и `Health`.

PlayMode-тест `PlayerHealthTests.cs` создаёт временный объект с компонентом `Health`, задаёт `maxHP = 3` и последовательно вызывает `Decrement()`. После первого удара персонаж остаётся жив, после третьего — `IsAlive` становится `false`.

### Тест по варианту 18

Вариант 18 требует проверить механику `PlayerSpawn + SpawnPoint`: после смерти игрок должен появиться в точке спавна. Тест `PlayerRespawnTests.cs` загружает реальную сцену `SampleScene`, находит `GameController` и его модель, запоминает позицию `model.spawnPoint`, уводит игрока на 8 метров в сторону и вверх, затем планирует событие `PlayerDeath`.

Через две секунды `PlayerDeath` планирует `PlayerSpawn`, который вызывает `player.Teleport(model.spawnPoint.transform.position)` и возвращает здоровье. Тест ждёт 2,5 секунды и проверяет, что расстояние от игрока до точки спавна меньше одного метра. Допуск в один метр нужен потому, что после телепорта игрок успевает немного сместиться под действием физики, пока тест ждёт завершения события. Текст теста приведён в листинге 1.

Листинг 1 — Тест варианта 18 `PlayerRespawnTests.cs`

```csharp
using System.Collections;
using NUnit.Framework;
using Platformer.Core;
using Platformer.Gameplay;
using Platformer.Mechanics;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.TestTools;

public class PlayerRespawnTests
{
    [UnityTest]
    public IEnumerator PlayMode_PlayerRespawnsAtSpawnPoint_AfterDeath()
    {
        Simulation.Clear();

        SceneManager.LoadScene("SampleScene");
        yield return null;
        yield return null;

        var controller = Object.FindFirstObjectByType<GameController>();
        Assert.IsNotNull(controller, "Ошибка: на сцене SampleScene не найден GameController!");

        var model = controller.model;
        Assert.IsNotNull(model.player, "Ошибка: в модели игры не назначен игрок!");
        Assert.IsNotNull(model.spawnPoint, "Ошибка: в модели игры не назначена точка спавна!");

        Vector3 spawnPosition = model.spawnPoint.position;

        model.player.Teleport(spawnPosition + new Vector3(8f, 4f, 0f));
        yield return new WaitForFixedUpdate();

        float distanceBeforeDeath = Vector3.Distance(model.player.transform.position, spawnPosition);
        Assert.Greater(distanceBeforeDeath, 1f,
            "Ошибка: перед смертью игрок должен быть далеко от точки спавна!");

        Simulation.Schedule<PlayerDeath>();

        yield return new WaitForSeconds(2.5f);

        float distanceAfterRespawn = Vector3.Distance(model.player.transform.position, spawnPosition);
        Assert.Less(distanceAfterRespawn, 1.0f,
            $"Ошибка: после смерти игрок должен появиться в точке спавна, расстояние = {distanceAfterRespawn:F2}");

        Simulation.Clear();
    }
}
```

### Локальный прогон тестов

Тесты запущены из командной строки Unity в batchmode. EditMode: один тест, результат `Passed`. PlayMode: два теста, оба `Passed` — базовый тест здоровья и тест варианта 18. Сводка результатов приведена в таблице 1.

Таблица 1 — Результаты локального прогона

| Режим | Тест | Результат |
|---|---|---|
| EditMode | `EditMode_PlayerTag_IsCorrect` | Passed |
| PlayMode | `PlayMode_PlayerTakesDamage_HealthDecreases` | Passed |
| PlayMode | `PlayMode_PlayerRespawnsAtSpawnPoint_AfterDeath` | Passed |

### Пайплайн GitHub Actions

В `.github/workflows/main.yml` добавлена задача `run_tests`. Она устанавливает официальный CLI GameCI, кэширует папку `Library` и запускает тесты в контейнере `unityci/editor` сразу в двух режимах: `playmode` и `editmode`. Результаты объединяются параметром `COMBINE_RESULTS` и сохраняются артефактом `test-results` даже при падении. Coverage отключён параметром `coverageEnabled=false`: инструментирование кода роняет Unity 6 в контейнере с ошибкой SIGSEGV.

Для активации Unity Personal используются секреты `UNITY_EMAIL` и `UNITY_PASSWORD`. Версия Unity передаётся явно (`--engineVersion=6000.3.10f1`), потому что она должна совпадать с версией проекта; `ProjectVersion.txt` теперь хранится в репозитории и дополнительно фиксирует эту версию.

Задачи `build_docker_image` и `mirror_repo` объявлены с `needs: run_tests`. Если хотя бы один тест падает, GitHub Actions не запускает зависимые задачи: сломанный коммит не доходит ни до сборки Docker-образа, ни до зеркалирования. Фрагмент пайплайна с задачей `run_tests` приведён в листинге 2.

Листинг 2 — Задача `run_tests`

```yaml
  run_tests:
    needs: sanity_check
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          lfs: true
      - name: Cache Library
        uses: actions/cache@v4
        with:
          path: Library
          key: Library-${{ hashFiles('Packages/packages-lock.json', 'Assets/**/*.asmdef') }}
      - name: Install GameCI CLI
        run: |
          curl -sL -o game-ci.tar.gz https://github.com/game-ci/cli/releases/download/v0.1.72/game-ci-linux-x64.tar.gz
          tar xzf game-ci.tar.gz ./game-ci
          echo "$PWD" >> $GITHUB_PATH
      - name: Run Unity Tests
        run: |
          game-ci test --docker --dockerShmSize=1025m \
            --engine=unity --testPlatforms='playmode;editmode;COMBINE_RESULTS' \
            --engineVersion=6000.3.10f1 --coverageEnabled=false \
            --artifactsPath=artifacts --dockerIsolationMode=default \
            --containerRegistryRepository=unityci/editor \
            --containerRegistryImageVersion=3
        env:
          UNITY_EMAIL: ${{ secrets.UNITY_EMAIL }}
          UNITY_PASSWORD: ${{ secrets.UNITY_PASSWORD }}
      - name: Upload test artifacts
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: test-results
          path: artifacts/
```

### Проверка защиты пайплайна

Для демонстрации защиты в тест варианта 18 временно внесено заведомо ложное условие `Assert.AreEqual(1, 2)`. После отправки изменений задача `run_tests` завершилась ошибкой, а задачи `build_docker_image` и `mirror_repo` остались в состоянии `Skipped` — они не запускались. После проверки тест возвращён в рабочее состояние, и следующий прогон снова стал зелёным.

## Вывод

В проекте настроена автоматическая проверка качества: EditMode-тест проверяет конфигурацию сцены, PlayMode-тесты проверяют здоровье персонажа и механику возрождения по варианту 18. Assembly Definitions разделяют игровой код и тесты, поэтому тестовые библиотеки не попадают в финальную сборку. В GitHub Actions задача `run_tests` запускает оба режима в контейнере Unity, а задачи сборки Docker-образа и зеркалирования зависят от неё через `needs`. Падение любого теста останавливает пайплайн, что и было продемонстрировано намеренно сломанным тестом.

## Контрольные вопросы

**Вопрос 1. В чём принципиальное различие между EditMode и PlayMode тестами в Unity?**

EditMode-тесты выполняются в редакторе без запуска игры. Они проверяют конфигурацию сцен, наличие объектов и компонентов, значения полей и другие данные, для которых не нужна симуляция. PlayMode-тесты запускают игровой цикл: работают `Awake`, `Start`, `Update`, физика и корутины, поэтому ими проверяют поведение механик во времени — урон, смерть, возрождение, столкновения. EditMode-тесты быстрее, PlayMode-тесты ближе к реальной игре.

**Вопрос 2. Какую роль играет файл Assembly Definition (.asmdef) при создании тестовой структуры проекта?**

`.asmdef` выделяет часть кода в отдельную сборку и явно задаёт её зависимости. Благодаря этому тестовая сборка может ссылаться на `GameAssembly` и видеть игровые классы, но сама не попадает в сборку игры. Кроме того, настройка `includePlatforms` определяет режим: сборка с `"Editor"` запускается только в EditMode, сборка без этого ограничения — в PlayMode. Без разделения на asmdef тесты либо не видят игровой код, либо попадают в билд и вызывают ошибки.

**Вопрос 3. Почему задача `build_docker_image` теперь зависит от `needs: run_tests`?**

`needs` задаёт порядок и условие запуска. Docker-образ собирается только после успешных тестов, поэтому в GHCR не может попасть образ с заведомо сломанной игрой. Если `run_tests` падает, GitHub Actions не запускает `build_docker_image` и `mirror_repo`: они остаются в состоянии `Skipped`. Это реализует принцип «тесты как гейт качества»: сборка и публикация начинаются только после проверки.

**Вопрос 4. Как настройка `includePlatforms` в тестовой сборке влияет на выбор режима запуска тестов?**

Unity Test Framework определяет режим по платформам, для которых собрана тестовая сборка. Если в `includePlatforms` указан только `Editor`, сборка существует только в редакторе и её тесты запускаются в EditMode. Если ограничение снято, сборка компилируется и для плеера, поэтому её тесты запускаются в PlayMode. Именно поэтому EditMode- и PlayMode-тесты размещают в разных папках с разными `.asmdef`: иначе Unity попытается запустить их не в том режиме, и тесты упадут.
