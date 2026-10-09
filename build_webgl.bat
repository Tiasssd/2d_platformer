@echo off
rem ============================================================
rem  Automated WebGL build (Lab #1).
rem  Put this file in the Unity project root, next to
rem  Assets, ProjectSettings and Packages folders.
rem  If your Unity version differs, fix UNITY_EXE below.
rem ============================================================
setlocal

set "UNITY_EXE=C:\Program Files\Unity\Hub\Editor\6000.3.10f1\Editor\Unity.exe"

if not exist "%UNITY_EXE%" (
    echo [ERROR] Unity.exe was not found at:
    echo         %UNITY_EXE%
    echo         Open this file and fix UNITY_EXE to match your installed version.
    exit /b 1
)

pushd "%~dp0"

"%UNITY_EXE%" -batchmode -nographics -executeMethod BuildManager.BuildWebGL -quit -logFile build_webgl.log
set "EXIT_CODE=%ERRORLEVEL%"

popd

echo Unity exit code: %EXIT_CODE%
echo Details: build_webgl.log
exit /b %EXIT_CODE%
