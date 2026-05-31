#!/usr/bin/env bash
# 用 screen 跑, 断 SSH 也不停. 私钥用环境变量传 (不写文件).
set -e
cd "$(dirname "$0")"
: "${PRIVATE_KEY:?set PRIVATE_KEY first:  export PRIVATE_KEY=0x...}"
screen -dmS satminer python3 gpu_miner.py
echo "miner started in screen session 'satminer'"
echo "看日志:  screen -r satminer    (退出但不停:  Ctrl+A 然后 D)"
echo "停止:    screen -X -S satminer quit"
