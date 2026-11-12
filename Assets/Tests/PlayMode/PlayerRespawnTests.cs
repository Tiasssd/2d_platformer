using System.Collections;
using NUnit.Framework;
using Platformer.Core;
using Platformer.Gameplay;
using Platformer.Mechanics;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.TestTools;

// Вариант 18: PlayerSpawn + SpawnPoint.
// PlayMode-тест проверяет, что после смерти игрок появляется в точке спавна.
public class PlayerRespawnTests
{
    [UnityTest]
    public IEnumerator PlayMode_PlayerRespawnsAtSpawnPoint_AfterDeath()
    {
        // Очищаем очередь событий, чтобы на результат не влияли предыдущие тесты
        Simulation.Clear();

        // Загружаем реальную сцену игры: в ней уже настроены GameController,
        // игрок, точка спавна и виртуальная камера
        SceneManager.LoadScene("SampleScene");
        yield return null;
        yield return null;

        var controller = Object.FindFirstObjectByType<GameController>();
        Assert.IsNotNull(controller, "Ошибка: на сцене SampleScene не найден GameController!");

        var model = controller.model;
        Assert.IsNotNull(model.player, "Ошибка: в модели игры не назначен игрок!");
        Assert.IsNotNull(model.spawnPoint, "Ошибка: в модели игры не назначена точка спавна!");

        Vector3 spawnPosition = model.spawnPoint.position;

        // Уводим игрока далеко от точки спавна, чтобы результат нельзя было
        // объяснить тем, что он там и стоял
        model.player.Teleport(spawnPosition + new Vector3(8f, 4f, 0f));
        yield return new WaitForFixedUpdate();

        float distanceBeforeDeath = Vector3.Distance(model.player.transform.position, spawnPosition);
        Assert.Greater(distanceBeforeDeath, 1f,
            "Ошибка: перед смертью игрок должен быть далеко от точки спавна!");

        // Запускаем смерть игрока. PlayerDeath через 2 секунды запланирует PlayerSpawn
        Simulation.Schedule<PlayerDeath>();

        // Ждём больше двух секунд: PlayerDeath -> PlayerSpawn -> Teleport
        yield return new WaitForSeconds(2.5f);

        float distanceAfterRespawn = Vector3.Distance(model.player.transform.position, spawnPosition);
        // Допуск 1 метр: после телепорта игрок успевает немного сместиться
        // под действием физики, пока тест ждёт завершения события.
        Assert.Less(distanceAfterRespawn, 1.0f,
            $"Ошибка: после смерти игрок должен появиться в точке спавна, расстояние = {distanceAfterRespawn:F2}");

        // Убираем за собой очередь событий
        Simulation.Clear();
    }
}
