#!/bin/bash

# 첫 번째 매개변수를 디렉터리 이름으로 사용
DIR_NAME="$1"

# 매개변수가 제공되지 않았을 경우
if [ -z "$DIR_NAME" ]; then
    # echo "Usage: $0 <Path>"
    powershell.exe -Command "Start-Process idea64.exe"
    exit 1
fi

# 디렉터리가 없으면 생성
if [ ! -d "$DIR_NAME" ]; then
    mkdir -p "$DIR_NAME"
    powershell.exe -Command "Start-Process idea64.exe $DIR_NAME"
fi

