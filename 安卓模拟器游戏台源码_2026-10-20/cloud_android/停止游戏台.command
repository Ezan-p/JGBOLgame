#!/bin/bash
set -e
cd "$(dirname "$0")"
/usr/bin/python3 manage.py stop
