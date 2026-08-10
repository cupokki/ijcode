#!/bin/bash

msg_pwsh_error() {
    echo "[ERROR] Cannot call Windows PowerShell (powershell.exe)." >&2
    echo "        Please check WSL interop settings." >&2
}

msg_idea_error() {
    echo "[ERROR] Cannot execute IntelliJ IDEA (idea64.exe / idea.exe)." >&2
    echo "How to fix:" >&2
    echo "  Make sure IntelliJ IDEA is properly installed on Windows." >&2
}

if ! command -v powershell.exe &>/dev/null; then
    msg_pwsh_error
    exit 1
fi

TARGET_DIR="${1:-.}"
if [ ! -d "$TARGET_DIR" ]; then
    mkdir -p "$TARGET_DIR"
fi

ABS_PATH=$(realpath "$TARGET_DIR" 2>/dev/null)
WIN_PATH=$(wslpath -w "$ABS_PATH" 2>/dev/null)

WIN_LOCAL_APP_DATA=$(powershell.exe -Command "echo \$env:LOCALAPPDATA" 2>/dev/null | tr -d '\r')
WIN_PROG_FILES=$(powershell.exe -Command "echo \$env:ProgramFiles" 2>/dev/null | tr -d '\r')

WSL_LOCAL_APP_DATA=$(wslpath -u "$WIN_LOCAL_APP_DATA" 2>/dev/null)
WSL_PROG_FILES=$(wslpath -u "$WIN_PROG_FILES" 2>/dev/null)

POSSIBLE_PATHS=(
    "$WSL_LOCAL_APP_DATA/Programs/IntelliJ IDEA Ultimate*/bin/idea64.exe"
    "$WSL_LOCAL_APP_DATA/Programs/IntelliJ IDEA Ultimate*/bin/idea.exe"
    "$WSL_LOCAL_APP_DATA/Programs/IntelliJ IDEA Community*/bin/idea64.exe"
    "$WSL_LOCAL_APP_DATA/Programs/IntelliJ IDEA Community*/bin/idea.exe"
    "$WSL_PROG_FILES/JetBrains/IntelliJ IDEA */bin/idea64.exe"
    "$WSL_PROG_FILES/JetBrains/IntelliJ IDEA */bin/idea.exe"
)

FOUND_EXE_PATH=""

SAVED_IFS=$IFS
IFS=$'\n'
for path_pattern in "${POSSIBLE_PATHS[@]}"; do
    if compgen -G "$path_pattern" &>/dev/null; then
        matched_file=$(ls -dt $path_pattern 2>/dev/null | head -n 1)
        if [ -n "$matched_file" ] && [ -z "$FOUND_EXE_PATH" ]; then
            FOUND_EXE_PATH="$matched_file"
        fi
    fi
done
IFS=$SAVED_IFS

if [ -z "$FOUND_EXE_PATH" ]; then
    FOUND_EXE_PATH=$(powershell.exe -Command "(Get-Command idea64.exe, idea.exe -ErrorAction SilentlyContinue | Select-Object -First 1).Source" 2>/dev/null | tr -d '\r')
fi

if [ -z "$FOUND_EXE_PATH" ]; then
    msg_idea_error
    exit 1
fi

WIN_EXE_PATH=$(wslpath -w "$FOUND_EXE_PATH" 2>/dev/null)

powershell.exe -Command "
try {
    Start-Process '$WIN_EXE_PATH' -ArgumentList '$WIN_PATH' -ErrorAction Stop
} catch {
    exit 100
}" &>/dev/null

PWSH_EXIT_CODE=$?
if [ $PWSH_EXIT_CODE -eq 100 ]; then
    msg_idea_error
    exit 1
elif [ $PWSH_EXIT_CODE -ne 0 ]; then
    msg_pwsh_error
    exit 1
fi
