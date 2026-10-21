'use strict';
const $=id=>document.getElementById(id),canvas=$('screen'),ctx=canvas.getContext('2d',{alpha:false});
let ws,audioWs,audioContext,scheduled=0,frameCount=0,frameStart=performance.now();const fingers=new Map();
function note(s){$('notice').textContent=s;}
function send(d){if(ws?.readyState===WebSocket.OPEN)ws.send(JSON.stringify(d));}
function socket(path){return new WebSocket(`${location.protocol==='https:'?'wss':'ws'}://${location.host}${path}`);}
let statusPending=false;
async function status(){
 if(statusPending)return;statusPending=true;
 try{
  const r=await fetch('/api/status'),s=await r.json();
  $('edition').textContent=s.local_game?'安卓游戏台 · 本地版 · 免账号':'安卓游戏台 · 联想渠道版 3.75';
  $('game-help').textContent=s.local_game?'本地版包含存档、角色培养和十个 PvE 关卡，使用独立本地规则。原服账号、充值、公会和排行榜未接入。关闭网页不会关闭安卓设备。':'本游戏需要支持 32 位 ARM 的安卓环境。登录、更新和战斗仍依赖原游戏服务。关闭网页不会关闭安卓设备。';
  $('status').textContent=s.emulator?'● 安卓设备已连接':'○ 等待安卓设备';
  $('launch').disabled=!s.emulator||!s.device?.booted||!s.device?.compatible;
  $('sound').disabled=!s.audio;
  if(!s.audio)$('sound').textContent='声音由安卓设备播放';
  $('compatibility').textContent=s.emulator
   ?(s.device.issue||(s.mode==='adb'?'设备支持本游戏 · ADB 模式：单指操作，声音由设备播放':s.runtime_profile.startsWith('arm32-')?'32 位安卓环境已就绪 · 软件仿真，启动和加载较慢':'设备支持本游戏 · 内置模拟器模式'))
   :(s.message||'请启动安卓环境，再重新连接。');
 }catch{
  $('status').textContent='服务连接中断';$('launch').disabled=true;
  $('compatibility').textContent='无法读取设备状态，请检查本机游戏台服务。';
 }finally{statusPending=false;}
}
setInterval(status,5000);status();
$('connect').onclick=()=>{
 if(ws){ws.close();return;}
 ws=socket('/ws/screen');ws.binaryType='arraybuffer';$('connect').textContent='连接中…';
 ws.onopen=()=>{$('connect').textContent='断开画面';note('已连接。点击画面操作游戏。');$('stage').focus();};
 ws.onmessage=async e=>{
  if(typeof e.data==='string'){const d=JSON.parse(e.data);if(d.type==='error')note(d.message);if(d.type==='action_result')note(d.ok?'操作已发送':d.error);return;}
  try{const image=await createImageBitmap(new Blob([e.data],{type:'image/png'}));if(canvas.width!==image.width||canvas.height!==image.height){canvas.width=image.width;canvas.height=image.height;}
   ctx.drawImage(image,0,0);image.close();$('empty').hidden=true;frameCount++;const now=performance.now();if(now-frameStart>1000){$('fps').textContent=`${(frameCount*1000/(now-frameStart)).toFixed(1)} FPS · ${canvas.width} × ${canvas.height}`;frameCount=0;frameStart=now;}
  }catch(err){note('画面解码失败：'+err.message);}finally{send({type:'ack'});}
 };
 ws.onerror=()=>note('无法连接画面。请确认模拟器已启动，且没有其他窗口正在控制。');
 ws.onclose=()=>{ws=null;fingers.clear();$('connect').textContent='连接画面';$('fps').textContent='已断开';};
};
async function action(name){if(ws?.readyState===WebSocket.OPEN){send({type:'action',action:name});return;}try{const r=await fetch('/api/action',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({action:name})});const d=await r.json();note(d.ok?'操作已发送':d.error);}catch(e){note('操作失败：'+e.message);}}
$('launch').onclick=()=>action('launch');document.querySelectorAll('[data-action]').forEach(b=>b.onclick=()=>action(b.dataset.action));
function coords(e){const r=canvas.getBoundingClientRect(),scale=Math.min(r.width/canvas.width,r.height/canvas.height),w=canvas.width*scale,h=canvas.height*scale;return {x:Math.max(0,Math.min(1,(e.clientX-r.left-(r.width-w)/2)/w)),y:Math.max(0,Math.min(1,(e.clientY-r.top-(r.height-h)/2)/h))};}
canvas.onpointerdown=e=>{if(!ws||fingers.size>=10)return;e.preventDefault();canvas.setPointerCapture(e.pointerId);const p=coords(e);fingers.set(e.pointerId,p);send({type:'touch',id:e.pointerId,...p,down:true});};
canvas.onpointermove=e=>{if(!fingers.has(e.pointerId))return;const p=coords(e);fingers.set(e.pointerId,p);send({type:'touch',id:e.pointerId,...p,down:true});};
function release(e){if(!fingers.has(e.pointerId))return;send({type:'touch',id:e.pointerId,...coords(e),down:false});fingers.delete(e.pointerId);}
canvas.onpointerup=release;canvas.onpointercancel=release;canvas.onlostpointercapture=release;
window.addEventListener('blur',()=>{for(const [id,p]of fingers)send({type:'touch',id,...p,down:false});fingers.clear();});
$('stage').onkeydown=e=>{if(e.metaKey||e.ctrlKey||e.altKey)return;if(e.key==='Escape'){action('back');e.preventDefault();}else if(e.key.length===1||['Enter','Backspace','Tab','ArrowLeft','ArrowRight','ArrowUp','ArrowDown'].includes(e.key)){send({type:'key',key:e.key});e.preventDefault();}};
$('fullscreen').onclick=()=>document.fullscreenElement?document.exitFullscreen():$('stage').requestFullscreen();
$('sound').onclick=async()=>{
 if(audioWs){audioWs.close();return;}
 try{audioContext=new AudioContext({sampleRate:44100});await audioContext.resume();scheduled=0;audioWs=socket('/ws/audio');audioWs.binaryType='arraybuffer';
 audioWs.onopen=()=>{$('sound').textContent='♬ 关闭声音';};
 audioWs.onmessage=e=>{if(typeof e.data==='string')return;const pcm=new DataView(e.data),n=Math.floor(pcm.byteLength/4);if(!n)return;const b=audioContext.createBuffer(2,n,44100);for(let ch=0;ch<2;ch++){const out=b.getChannelData(ch);for(let i=0;i<n;i++)out[i]=pcm.getInt16(i*4+ch*2,true)/32768;}
 const now=audioContext.currentTime;if(scheduled>now+.35)return;if(scheduled<now)scheduled=now+.04;const source=audioContext.createBufferSource();source.buffer=b;source.connect(audioContext.destination);source.start(scheduled);scheduled+=n/44100;};
 audioWs.onerror=()=>note('音频连接失败，请检查模拟器音频服务。');audioWs.onclose=()=>{audioWs=null;$('sound').textContent='♬ 开启声音';audioContext?.close();};
 }catch(e){note('无法开启声音：'+e.message);}
};
