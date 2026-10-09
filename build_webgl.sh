#!/usr/bin/env bash
# ============================================================
#  Automated WebGL build (Lab #1), Linux/macOS.
#  Put this file in the Unity project root, next to
#  Assets, ProjectSettings and Packages folders.
#  Override the editor path if needed:
#     UNITY_EXE=/path/to/Unity ./build_webgl.sh
# ============================================================
set -uo pipefail

UNITY_EXE="${UNITY_EXE:-$HOME/Unity/Hub/Editor/6000.3.10f1/Editor/Unity}"
PROJECT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -x "$UNITY_EXE" ]; then
    echo "[ERROR] Unity not found or not executable: $UNITY_EXE"
    echo "        Set UNITY_EXE=/path/to/Unity before running this script."
    exit 1
fi

cd "$PROJECT_PATH"

"$UNITY_EXE" -batchmode -nographics -executeMethod BuildManager.BuildWebGL -quit -logFile build_webgl.log
EXIT_CODE=$?

echo "Unity exit code: $EXIT_CODE"
echo "Details: build_webgl.log"
exit $EXIT_CODE
