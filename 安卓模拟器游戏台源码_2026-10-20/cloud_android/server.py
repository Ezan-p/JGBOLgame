"""Loopback-only Android emulator browser gateway. Use SSH for remote access."""
import asyncio, contextlib, json, os, secrets, sys, time
from pathlib import Path
from aiohttp import web, WSMsgType
import grpc
from google.protobuf.empty_pb2 import Empty
from game_config import load_config, device_environment
from adb_backend import AdbBackend, execute
from manage import inspect_device, error_text
ROOT=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT/'proto'))
import emulator_controller_pb2 as pb
import emulator_controller_pb2_grpc as rpc
COOKIE='jgb_session'
NOT_READY='模拟器画面服务未就绪或已退出。请在项目根目录运行 python3 cloud_android/manage.py start，等待启动后重新连接；若仍失败，请查看 cloud_android/.runtime/logs/emulator.log。'

def connection_error(exc):
    if isinstance(exc,grpc.RpcError):
        if exc.code() in (grpc.StatusCode.UNAVAILABLE,grpc.StatusCode.DEADLINE_EXCEEDED):
            return NOT_READY
        if exc.code() in (grpc.StatusCode.UNAUTHENTICATED,grpc.StatusCode.PERMISSION_DENIED):
            return '模拟器认证失败。请运行 python3 cloud_android/manage.py restart-web 后重新连接。'
    if isinstance(exc,(FileNotFoundError,KeyError,RuntimeError)):return NOT_READY
    return str(exc)[:200]

def point(value,limit):
    n=float(value)
    if not 0<=n<=1: raise ValueError('Coordinate out of bounds')
    return min(limit-1,round(n*(limit-1)))

@web.middleware
async def guard(request,handler):
    host=request.host.split(':')[0]
    if host not in ('127.0.0.1','localhost','[::1]'):raise web.HTTPForbidden(text='Loopback host required')
    origin=request.headers.get('Origin')
    if origin and origin != f'{request.scheme}://{request.host}':raise web.HTTPForbidden(text='Cross-origin requests denied')
    if request.path.startswith(('/api/','/ws/')) and not secrets.compare_digest(request.cookies.get(COOKIE,''),request.app['session']):raise web.HTTPUnauthorized()
    response=await handler(request)
    response.headers['X-Content-Type-Options']='nosniff'
    response.headers['Referrer-Policy']='no-referrer'
    response.headers['Cache-Control']='no-store'
    response.headers['Content-Security-Policy']="default-src 'self'; connect-src 'self'; img-src 'self' blob:; media-src 'self'; script-src 'self'; style-src 'self'; frame-ancestors 'none'"
    return response

async def adb(app,*args,timeout=15):
    return await execute(app,*args,timeout=timeout)

async def device_info(app):
    try:return await asyncio.to_thread(inspect_device,app['config'])
    except Exception as exc:raise RuntimeError(error_text(exc)) from exc

async def index(request):
    response=web.FileResponse(ROOT/'web/index.html')
    response.set_cookie(COOKIE,request.app['session'],httponly=True,samesite='Strict')
    return response

async def status(request):
    app=request.app
    try:
        s=await app['stub'].getStatus(Empty(),timeout=3)
        device=await device_info(app)
        return web.json_response({'emulator':True,'version':s.version,'control_busy':app['controller'] is not None,'frames':app['frames'],'audio_packets':app['audio_packets'],'package':app['config']['package'],'mode':app['config']['mode'],'runtime_profile':app['config']['runtime_profile'],'local_game':app['config'].get('local_game',False),'audio':app['config']['mode']=='emulator','device':device})
    except (grpc.RpcError,RuntimeError,OSError,KeyError) as exc:
        return web.json_response({'emulator':False,'message':connection_error(exc),'mode':app['config']['mode'],'audio':app['config']['mode']=='emulator'})

async def action(request):
    data=await request.json();name=data.get('action')
    if request.app['controller'] is not None:raise web.HTTPConflict(text='Close the active screen before a separate control request')
    return await perform_action(request.app,name)

async def perform_action(app,name):
    try:
        if name=='launch':
            device=await device_info(app)
            if device['issue']:raise RuntimeError(device['issue'])
            result=await adb(app,'shell','am','start','-W','-n',app['config']['component'],timeout=120)
            if 'Error:' in result or 'Error type' in result or 'Exception' in result:raise RuntimeError(result)
        elif name in ('back','home','volume_up','volume_down'):
            key={'back':'GoBack','home':'GoHome','volume_up':'AudioVolumeUp','volume_down':'AudioVolumeDown'}[name]
            await app['stub'].sendKey(pb.KeyboardEvent(key=key,eventType=pb.KeyboardEvent.keypress),timeout=3);result='OK'
        else:raise web.HTTPBadRequest(text='Unknown action')
        return web.json_response({'ok':True,'result':result})
    except (RuntimeError,grpc.RpcError,OSError,asyncio.TimeoutError,KeyError) as exc:return web.json_response({'ok':False,'error':connection_error(exc)},status=503)

async def screen(request):
    app=request.app
    if app['controller'] is not None:raise web.HTTPConflict(text='另一个窗口正在控制模拟器，请先断开。')
    ws=web.WebSocketResponse(heartbeat=20,max_msg_size=8192);app['controller']=ws
    try:await ws.prepare(request)
    except BaseException:app['controller']=None;raise
    touches={};ready=asyncio.Event();ready.set();dimensions=[1280,720]
    async def frames():
        while not ws.closed:
            await ready.wait();ready.clear();start=time.monotonic()
            img=await app['stub'].getScreenshot(pb.ImageFormat(format=pb.ImageFormat.PNG),timeout=10)
            if not img.image:await asyncio.sleep(.2);ready.set();continue
            w=img.format.width or img.width;h=img.format.height or img.height
            if not w or not h:raise RuntimeError('Invalid frame dimensions')
            dimensions[:]=[w,h]
            await ws.send_json({'type':'frame','width':w,'height':h})
            await ws.send_bytes(img.image);app['frames']+=1
            await asyncio.sleep(max(0,1/(5 if app['config']['mode']=='adb' else 20)-(time.monotonic()-start)))
    task=asyncio.create_task(frames())
    async def watch():
        try:await task
        except asyncio.CancelledError:pass
        except Exception as exc:
            if not ws.closed:await ws.send_json({'type':'error','message':connection_error(exc)});await ws.close(code=1011)
    watcher=asyncio.create_task(watch())
    try:
        async for msg in ws:
            if msg.type!=WSMsgType.TEXT:continue
            try:
                d=json.loads(msg.data);kind=d.get('type')
                if kind=='ack':ready.set()
                elif kind=='touch':
                    ident=int(d['id'])
                    if not 0<=ident<100000:raise ValueError('Invalid touch id')
                    down=bool(d['down']);x=point(d['x'],dimensions[0]);y=point(d['y'],dimensions[1])
                    if down and ident not in touches and len(touches)>=10:raise ValueError('Maximum 10 touches')
                    touch=pb.Touch(x=x,y=y,identifier=ident,pressure=1 if down else 0)
                    await app['stub'].sendTouch(pb.TouchEvent(touches=[touch]),timeout=3)
                    if down:touches[ident]=touch
                    else:touches.pop(ident,None)
                elif kind=='action':
                    response=await perform_action(app,d.get('action'));await ws.send_json({'type':'action_result',**json.loads(response.text)})
                elif kind=='key':
                    key=d.get('key','')
                    if key not in ['Enter','Backspace','ArrowLeft','ArrowRight','ArrowUp','ArrowDown','Tab'] and not (len(key)==1 and 32<=ord(key)<127):raise ValueError('Unsupported key')
                    await app['stub'].sendKey(pb.KeyboardEvent(key=key,eventType=pb.KeyboardEvent.keypress),timeout=3)
                else:raise ValueError('Unknown command')
            except (ValueError,KeyError,TypeError,RuntimeError,OSError,asyncio.TimeoutError,grpc.RpcError) as exc:await ws.send_json({'type':'error','message':str(exc)[:200]})
    finally:
        task.cancel();watcher.cancel()
        async def cleanup():
            if app['config']['mode']=='adb':
                app['stub'].cancel_touches()
            elif touches:
                with contextlib.suppress(grpc.RpcError):await app['stub'].sendTouch(pb.TouchEvent(touches=[pb.Touch(x=t.x,y=t.y,identifier=i,pressure=0) for i,t in touches.items()]),timeout=2)
            await asyncio.gather(task,watcher,return_exceptions=True)
        try:await asyncio.shield(cleanup())
        finally:
            if app['controller'] is ws:app['controller']=None
    return ws

async def audio(request):
    app=request.app
    if app['config']['mode']=='adb':raise web.HTTPBadRequest(text='ADB 模式声音由安卓设备播放，不支持浏览器音频。')
    if app['audio_client'] is not None:raise web.HTTPConflict(text='Audio stream already active')
    ws=web.WebSocketResponse(heartbeat=20,max_msg_size=1024);app['audio_client']=ws
    try:await ws.prepare(request)
    except BaseException:app['audio_client']=None;raise
    stream=app['stub'].streamAudio(pb.AudioFormat(samplingRate=44100,channels=pb.AudioFormat.Stereo,format=pb.AudioFormat.AUD_FMT_S16))
    async def forward():
        try:
            async for packet in stream:
                await ws.send_bytes(packet.audio);app['audio_packets']+=1
        except (grpc.RpcError,ConnectionError):
            if not ws.closed:await ws.close(code=1011)
    task=asyncio.create_task(forward())
    try:
        async for _ in ws:pass
    finally:
        stream.cancel();task.cancel();await asyncio.gather(task,return_exceptions=True);app['audio_client']=None
    return ws

class AuthorizedStub:
    def __init__(self, channel):self.stub=rpc.EmulatorControllerStub(channel)
    def __getattr__(self, name):
        def call(*args, **kwargs):
            state=json.loads((ROOT/'.runtime/processes.json').read_text())
            pid=state['emulator']
            discovery=Path.home()/f'Library/Caches/TemporaryItems/avd/running/pid_{pid}.ini'
            token=next((line.split('=',1)[1].strip() for line in discovery.read_text().splitlines() if line.startswith('grpc.token=')),None)
            if not token:raise RuntimeError('Emulator authentication token not ready')
            kwargs['metadata']=[('authorization','Bearer '+token)]
            return getattr(self.stub,name)(*args,**kwargs)
        return call

async def lifecycle(app):
    if app['config']['mode']=='adb':
        app['stub']=AdbBackend(app)
    else:
        app['channel']=grpc.aio.insecure_channel(f"127.0.0.1:{app['config']['grpc_port']}",options=[('grpc.max_receive_message_length',16*1024*1024)])
        app['stub']=AuthorizedStub(app['channel'])
    yield
    for k in ['controller','audio_client']:
        if app[k] is not None:await app[k].close(code=1001)
    if 'channel' in app:await app['channel'].close()

async def close_clients(app):
    for key in ('controller','audio_client'):
        if app[key] is not None:
            await app[key].close(code=1001)

def make_app():
    config=load_config()
    app=web.Application(middlewares=[guard],client_max_size=8192)
    app.update(session=secrets.token_urlsafe(32),controller=None,audio_client=None,frames=0,audio_packets=0,config=config,adb=config['adb_path'],env=device_environment())
    app.cleanup_ctx.append(lifecycle)
    app.on_shutdown.append(close_clients)
    app.router.add_get('/',index);app.router.add_get('/api/status',status);app.router.add_post('/api/action',action)
    app.router.add_get('/ws/screen',screen);app.router.add_get('/ws/audio',audio)
    for name in ['app.js','style.css']:app.router.add_get('/'+name,lambda r,n=name:web.FileResponse(ROOT/'web'/n))
    return app
if __name__=='__main__':web.run_app(make_app(),host='127.0.0.1',port=load_config()['web_port'],access_log=None,shutdown_timeout=2)
