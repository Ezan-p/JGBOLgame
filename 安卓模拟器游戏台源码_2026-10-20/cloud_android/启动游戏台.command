#!/bin/bash
set -e
cd "$(dirname "$0")"
/usr/bin/python3 manage.py start
open "$(/usr/bin/python3 -c 'from game_config import load_config; print("http://127.0.0.1:" + str(load_config()["web_port"]))')"
