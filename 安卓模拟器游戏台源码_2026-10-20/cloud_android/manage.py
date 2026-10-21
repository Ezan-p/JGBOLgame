#!/usr/bin/env python3
"""Manage this game's local emulator, or attach to an explicitly selected ADB device."""
import argparse
import json
import os
import signal
import socket
import subprocess
import sys
import time
from pathlib import Path
from game_config import APK, ROOT as R, RUNTIME as RT, SDK, abi_error, device_environment, load_config
from runtime_profiles import PROFILES, emulator_command, emulator_environment, profile_for

STATE = RT / 'processes.json'


def environment():
    for name in ('android-user', 'logs', 'pycache'):
        (RT / name).mkdir(parents=True, exist_ok=True)
    return device_environment()


def listening(port):
    with socket.socket() as sock:
        sock.settimeout(.3)
        return sock.connect_ex(('127.0.0.1', port)) == 0


def run(args, **kwargs):
    return subprocess.run(list(map(str, args)), env=environment(), check=True, **kwargs)


def adb(config, *args, timeout=15):
    return run([config['adb_path'], '-s', config['serial'], *args],
               timeout=timeout, capture_output=True, text=True).stdout.strip()


def inspect_device(config):
    if not config['adb_path'].is_file():
        raise RuntimeError('未找到 ADB：' + str(config['adb_path']) + '。请部署 SDK 或配置 adb_path。')
    if adb(config, 'get-state') != 'device':
        raise RuntimeError('指定设备尚未连接或授权：' + config['serial'])
    if config['mode'] == 'emulator':
        names = adb(config, 'emu', 'avd', 'name').splitlines()
        if not names or names[0] != config['avd_name']:
            raise RuntimeError('设备不是本项目的 ' + config['avd_name'] + ' AVD，拒绝操作。')
    def prop(key):
        return adb(config, 'shell', 'getprop', key)
    abis = prop('ro.product.cpu.abilist')
    abis32 = prop('ro.product.cpu.abilist32')
    if not abis:  # Android before API 21 uses cpu.abi / cpu.abi2.
        abis = ','.join(filter(None, (prop('ro.product.cpu.abi'), prop('ro.product.cpu.abi2'))))
    booted = prop('sys.boot_completed') == '1'
    error = abi_error(abis, abis32)
    return dict(serial=config['serial'], android=prop('ro.build.version.release'),
                abis=abis, abis32=abis32, booted=booted, compatible=error is None,
                issue=error if booted else '安卓尚未完成启动，请稍后重试。')


def ready_device(config):
    device = inspect_device(config)
    if device['issue']:
        raise RuntimeError(device['issue'])
    return device


def wait_for_port(port, process, timeout=60):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if process.poll() is not None:
            raise RuntimeError(f'服务退出（端口 {port}），请检查 {RT}/logs/')
        if listening(port):
            return
        time.sleep(.25)
    raise RuntimeError(f'等待端口 {port} 超时，请检查 {RT}/logs/')


def owned_pid(name, pid):
    if name == 'emulator':
        expected = [str(p['emulator'].parent) + '/' for p in PROFILES.values()]
    elif name == 'local_game':
        expected = [str(R / 'local_game/service.py')]
    else:
        expected = [str(R / 'server.py')]
    result = subprocess.run(['ps', '-p', str(pid), '-o', 'command='], capture_output=True, text=True)
    return any(path in result.stdout for path in expected)


def start():
    config = load_config()
    env = environment()
    python = RT / 'venv/bin/python'
    if not python.is_file():
        raise RuntimeError('缺少 Python 环境，请按 README.md 安装 .runtime/venv 和依赖。')
    state = json.loads(STATE.read_text()) if STATE.exists() else {}
    console, grpc_port, web_port = (config[key] for key in ('console_port', 'grpc_port', 'web_port'))
    for port, name in ((grpc_port, 'emulator'), (web_port, 'gateway')):
        if name == 'emulator' and config['mode'] == 'adb':
            continue
        if listening(port) and (name not in state or not owned_pid(name, state[name])):
            raise RuntimeError(f'端口 {port} 属于未跟踪的服务，拒绝接管。')
    if config['mode'] == 'emulator' and not listening(grpc_port):
        emulator = profile_for(config)['emulator']
        if not emulator.is_file() or not (RT / 'avd' / (config['avd_name'] + '.ini')).is_file():
            raise RuntimeError('尚未部署内置模拟器/AVD。请按 README.md 完成安装，或配置 adb 模式连接兼容设备。')
        if listening(console) or listening(console + 1):
            raise RuntimeError(f'端口 {console}/{console+1} 已占用，拒绝替换其他模拟器。')
        cmd = emulator_command(config, env.get('JGB_EMULATOR_DNS', '8.8.8.8,1.1.1.1'))
        with (RT / 'logs/emulator.log').open('ab') as log:
            process = subprocess.Popen(cmd, env=emulator_environment(config), stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
        state['emulator'] = process.pid
        STATE.write_text(json.dumps(state))
        wait_for_port(grpc_port, process)
    if config['mode'] == 'adb':
        ready_device(config)
    if config.get('local_game'):
        if listening(8770):
            if 'local_game' not in state or not owned_pid('local_game', state['local_game']):
                raise RuntimeError('本地游戏服务端口 8770 已被其他程序占用，拒绝接管。')
        else:
            with (RT / 'logs/local-game.log').open('ab') as log:
                process = subprocess.Popen([str(python), str(R / 'local_game/service.py')],
                                           env=env, stdout=log, stderr=subprocess.STDOUT,
                                           start_new_session=True)
            state['local_game'] = process.pid
            STATE.write_text(json.dumps(state))
            wait_for_port(8770, process, 15)
    if not listening(web_port):
        with (RT / 'logs/gateway.log').open('ab') as log:
            process = subprocess.Popen([str(python), str(R / 'server.py')], env=env,
                                       stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
        state['gateway'] = process.pid
        STATE.write_text(json.dumps(state))
        wait_for_port(web_port, process, 15)
    print(f'金箍棒游戏台：http://127.0.0.1:{web_port}；使用 doctor 检查设备兼容性。')


def stop(gateway_only=False):
    state = json.loads(STATE.read_text()) if STATE.exists() else {}
    for name, pid in list(state.items()):
        if gateway_only and name != 'gateway':
            continue
        if owned_pid(name, pid):
            try:
                os.kill(pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
            for _ in range(50):
                if not owned_pid(name, pid):
                    break
                time.sleep(.1)
            if owned_pid(name, pid):
                raise RuntimeError(f'{name} 尚未退出，保留进程记录，请稍后重试。')
        state.pop(name, None)
    if state:
        STATE.write_text(json.dumps(state))
    elif STATE.exists():
        STATE.unlink()
    print('已停止本项目服务。ADB 模式下不会关闭外部设备或模拟器。')


def launch(config=None):
    config = config or load_config()
    ready_device(config)
    output = adb(config, 'shell', 'am', 'start', '-W', '-n', config['component'], timeout=120)
    if 'Error:' in output or 'Error type' in output or 'Exception' in output:
        raise RuntimeError(output)
    print(output)


def install(apk=None):
    config = load_config()
    apk = apk or (RT / 'local_game/jingubang-local.apk' if config.get('local_game') else APK)
    if not apk.is_file():
        raise RuntimeError('未找到 APK：' + str(apk) + '。先运行 scripts/prepare_apk.py，或 install --apk 原始APK路径。')
    ready_device(config)  # Check before touching an installed game's data.
    print(adb(config, 'install', '--no-streaming', '-r', str(apk), timeout=600))
    launch(config)


def doctor():
    config = load_config()
    selected_apk = RT / 'local_game/jingubang-local.apk' if config.get('local_game') else APK
    report = dict(game=config['title'], mode=config['mode'], runtime_profile=config['runtime_profile'], game_root=str(config['game_root']),
                  package=config['package'], component=config['component'], apk_exists=selected_apk.is_file(),
                  ports={str(config[key]): listening(config[key]) for key in ('console_port', 'grpc_port', 'web_port')})
    if config.get('local_game'):
        report['local_game'] = dict(port=8770, listening=listening(8770),
                                   save_exists=(RT / 'local_game/save.sqlite3').is_file())
    try:
        report['device'] = inspect_device(config)
        ok = not report['device']['issue'] and (not config.get('local_game') or report['local_game']['listening'])
    except (RuntimeError, OSError, subprocess.SubprocessError) as exc:
        report['device_error'] = error_text(exc)
        ok = False
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return ok


def error_text(exc):
    if isinstance(exc, subprocess.CalledProcessError):
        return (exc.stderr or exc.stdout or str(exc)).strip()
    return str(exc)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('command', choices=['start', 'stop', 'install', 'launch', 'status', 'doctor', 'restart-web'])
    parser.add_argument('--apk', type=Path, help='install 时使用已有原始 APK，保留其签名')
    args = parser.parse_args()
    try:
        if args.command == 'start': start()
        elif args.command == 'stop': stop()
        elif args.command == 'install': install(args.apk.resolve() if args.apk else None)
        elif args.command == 'launch': launch()
        elif args.command == 'restart-web': stop(gateway_only=True); start()
        else: sys.exit(0 if doctor() else 1)
    except (RuntimeError, ValueError, OSError, subprocess.SubprocessError) as exc:
        sys.exit(error_text(exc))
