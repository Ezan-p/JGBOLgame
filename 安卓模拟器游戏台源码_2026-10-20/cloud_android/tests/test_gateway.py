import asyncio,json,sys,unittest
from pathlib import Path
from aiohttp import ClientSession,CookieJar,WSServerHandshakeError
from aiohttp.test_utils import TestServer
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
import server
class Stub:
 def __init__(self):self.touches=[]
 async def getStatus(self,*a,**k):return type('Status',(),{'version':'test'})()
 async def getScreenshot(self,*a,**k):
  return server.pb.Image(format=server.pb.ImageFormat(width=1280,height=720),image=b'fixture')
 async def sendTouch(self,event,**kwargs):self.touches.extend(event.touches)
 async def sendKey(self,event,**kwargs):pass
class GatewayTests(unittest.IsolatedAsyncioTestCase):
 async def asyncSetUp(self):
  app=server.make_app();app.cleanup_ctx.clear();self.stub=Stub();app['stub']=self.stub
  self.server=TestServer(app);await self.server.start_server();self.url=str(self.server.make_url('')).rstrip('/')
  self.client=ClientSession(cookie_jar=CookieJar(unsafe=True));await self.client.get(self.url+'/')
 async def asyncTearDown(self):await self.client.close();await self.server.close()
 async def test_requires_session(self):
  async with ClientSession() as c:
   async with c.get(self.url+'/api/status') as r:self.assertEqual(r.status,401)
 async def test_unavailable_screen_reports_recovery_and_releases_controller(self):
  class Unavailable(server.grpc.RpcError):
   def code(self):return server.grpc.StatusCode.UNAVAILABLE
  async def failed(*args,**kwargs):raise Unavailable()
  self.stub.getScreenshot=failed
  ws=await self.client.ws_connect(self.url+'/ws/screen')
  message=await ws.receive_json()
  self.assertEqual(message['type'],'error')
  self.assertIn('manage.py start',message['message'])
  await ws.receive()
  await ws.close()
  for _ in range(100):
   if self.server.app['controller'] is None:break
   await asyncio.sleep(.01)
  self.assertIsNone(self.server.app['controller'])
 async def test_rejects_cross_origin(self):
  async with self.client.post(self.url+'/api/action',headers={'Origin':'https://other.example'},json={'action':'home'}) as r:self.assertEqual(r.status,403)
 async def test_rejects_rebinding_host(self):
  async with self.client.get(self.url+'/',headers={'Host':'attacker.example'}) as r:self.assertEqual(r.status,403)
 async def test_backpressure_single_controller_and_release(self):
  ws=await self.client.ws_connect(self.url+'/ws/screen')
  self.assertEqual((await ws.receive_json())['width'],1280);self.assertEqual((await ws.receive()).data,b'fixture')
  with self.assertRaises(asyncio.TimeoutError):await asyncio.wait_for(ws.receive(),.12)
  with self.assertRaises(WSServerHandshakeError) as ex:await self.client.ws_connect(self.url+'/ws/screen')
  self.assertEqual(ex.exception.status,409)
  await ws.send_json({'type':'touch','id':2,'x':1,'y':1,'down':True});await asyncio.sleep(.05)
  self.assertEqual((self.stub.touches[-1].x,self.stub.touches[-1].y),(1279,719))
  await ws.close()
  for _ in range(100):
   if self.stub.touches[-1].pressure==0:break
   await asyncio.sleep(.01)
  self.assertEqual(self.stub.touches[-1].pressure,0)
  ws2=await self.client.ws_connect(self.url+'/ws/screen');await ws2.close()
 async def test_invalid_touch_is_not_injected(self):
  ws=await self.client.ws_connect(self.url+'/ws/screen');await ws.receive();await ws.receive()
  await ws.send_json({'type':'touch','id':0,'x':2,'y':0,'down':True})
  self.assertEqual((await ws.receive_json())['type'],'error');self.assertEqual(self.stub.touches,[]);await ws.close()
if __name__=='__main__':unittest.main()
