# ============================================================
#  Automated WebGL build (Lab #1).
#  Put this file in the Unity project root, next to
#  Assets, ProjectSettings and Packages folders.
#  If your Unity version differs, fix $UnityExe below.
# ============================================================

$UnityExe = "C:\Program Files\Unity\Hub\Editor\6000.3.10f1\Editor\Unity.exe"

if (-not (Test-Path -LiteralPath $UnityExe)) {
    Write-Host "[ERROR] Unity.exe was not found at: $UnityExe"
    Write-Host "        Open this file and fix `$UnityExe to match your installed version."
    exit 1
}

Push-Location -LiteralPath $PSScriptRoot
try {
    & $UnityExe -batchmode -nographics -executeMethod BuildManager.BuildWebGL -quit -logFile build_webgl.log
    $exitCode = $LASTEXITCODE
}
finally {
    Pop-Location
}

Write-Host "Unity exit code: $exitCode"
Write-Host "Details: build_webgl.log"
exit $exitCode
