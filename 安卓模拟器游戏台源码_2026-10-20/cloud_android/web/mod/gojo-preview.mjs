const $=id=>document.getElementById(id);
export const gojoPack=fetch('/mod/gojo/manifest.json').then(r=>{if(!r.ok)throw Error('五条悟素材包未就绪');return r.json();});
let pack,images={},visible=false,frame=0,state='idle',started=0,storyIndex=-1,currentLine=null;
const audio=$('gojoAudio'),canvas=$('gojoCanvas'),ctx=canvas.getContext('2d');
const reduced=matchMedia('(prefers-reduced-motion: reduce)');
function notice(text){$('gojoStatus').textContent=text;}
function stop(){audio.pause();audio.removeAttribute('src');audio.load();}
async function voice(id){stop();const v=pack.voices.find(x=>x.voice_id===id);if(!v)return;audio.src=v.url;$('gojoLine').textContent=v.text;try{await audio.play();}catch(e){notice('音频未能播放，请点击播放器重试：'+e.message);}}
function setState(name){state=name;started=performance.now();storyIndex=-1;$('gojoDialogue').hidden=true;canvas.dataset.animation=name;notice({idle:'待机 · 整图呼吸与粒子循环',attack:'普攻 · 0.45 秒命中特效',skill:'虚式·茈 · 1.20 秒命中特效',hurt:'受击 · 整图偏移反馈',victory:'胜利 · 光环与立绘升起'}[name]);if(name==='skill')voice('GOJO_VO_SkillCast');else if(name==='attack')voice('GOJO_VO_Attack01');else if(name==='hurt')voice('GOJO_VO_Hurt');else if(name==='victory')voice('GOJO_VO_Win');else stop();}
function renderStory(){if(storyIndex<0)return;currentLine=pack.story[storyIndex];$('gojoDialogue').hidden=false;$('gojoSpeaker').textContent=currentLine.speaker;$('gojoStoryText').textContent=currentLine.text;$('gojoProgress').textContent=`${storyIndex+1} / ${pack.story.length}`;canvas.dataset.animation='story';notice('G03《最强之外》 · 选择“陪你坐着”的预览分支');if(currentLine.voice_id)voice(currentLine.voice_id);else{stop();$('gojoLine').textContent='玩家台词仅字幕';}}
function imgContain(im,x,y,w,h){const k=Math.min(w/im.width,h/im.height);ctx.drawImage(im,x+(w-im.width*k)/2,y+(h-im.height*k)/2,im.width*k,im.height*k);}
function orb(x,y,r,color){const g=ctx.createRadialGradient(x,y,0,x,y,r);g.addColorStop(0,'#fff');g.addColorStop(.12,color);g.addColorStop(1,'transparent');ctx.fillStyle=g;ctx.beginPath();ctx.arc(x,y,r,0,Math.PI*2);ctx.fill();}
function paint(now){if(!visible)return;frame=requestAnimationFrame(paint);if(document.hidden)return;const w=canvas.width,h=canvas.height,t=(now-started)/1000;ctx.clearRect(0,0,w,h);
 if(storyIndex>=0){const im=images.cg;const k=Math.max(w/im.width,h/im.height)*(1+(reduced.matches?0:.012*Math.sin(now/9000)));ctx.drawImage(im,(w-im.width*k)/2,(h-im.height*k)/2,im.width*k,im.height*k);return;}
 const bg=ctx.createLinearGradient(0,0,w,h);bg.addColorStop(0,'#101932');bg.addColorStop(1,'#080d1c');ctx.fillStyle=bg;ctx.fillRect(0,0,w,h);
 for(let i=0;i<35;i++){const x=(i*137.3)%w,y=((i*71+(reduced.matches?0:now*.008))%(h+20));ctx.fillStyle='rgba(143,190,255,.35)';ctx.fillRect(x,y,2,2);}
 ctx.strokeStyle='#5c73ad';ctx.lineWidth=2;ctx.beginPath();ctx.ellipse(w*.48,h*.89,160,23,0,0,Math.PI*2);ctx.stroke();
 const duration=pack.animations[state]?.duration||4;if(state!=='idle'&&t>duration){state='idle';started=now;canvas.dataset.animation='idle';}
 let dx=0,dy=reduced.matches?0:Math.sin(now/950)*3,scale=1;
 if(state==='attack')dx=Math.sin(Math.min(t/.9,1)*Math.PI)*30;
 if(state==='hurt')dx=Math.sin(t*50)*9*Math.max(0,1-t/.5);
 if(state==='skill')scale=1+.02*Math.sin(Math.min(t/2.2,1)*Math.PI);
 if(state==='victory')dy-=Math.sin(Math.min(t/1.2,1)*Math.PI)*13;
 ctx.save();ctx.translate(w*.48+dx,h*.50+dy);ctx.scale(scale,scale);imgContain(images.standing,-w*.24,-h*.49,w*.48,h*.91);ctx.restore();
 ctx.fillStyle='#bcd8ff';ctx.font='18px system-ui';ctx.fillText('五条悟',32,42);ctx.fillStyle='#8295bb';ctx.font='12px system-ui';ctx.fillText('无下限的旅人 / 浏览器演出原型',32,66);
 const x=w*.70,y=h*.45;
 if(state==='attack'&&t>.2&&t<.8){orb(x+(t-.2)*170,y,45,'#40bfff');}
 if(state==='skill'){
  const p=Math.min(t/1.2,1);orb(x-80*(1-p),y,45,'#40bfff');orb(x+80*(1-p),y,45,'#ee5e76');
  if(t>.9){const r=Math.max(0,Math.sin((t-.9)/1.3*Math.PI))*115;orb(x+Math.max(0,t-1.2)*150,y,r,'#ac75ff');ctx.strokeStyle='#ba9aff';ctx.lineWidth=3;ctx.beginPath();ctx.arc(x,y,35+(t-.9)*120,0,Math.PI*2);ctx.stroke();}
 }
 if(state==='victory'){ctx.strokeStyle='#d0b8ff';ctx.beginPath();ctx.ellipse(w*.48,h*.89,160+t*55,23+t*10,0,0,Math.PI*2);ctx.stroke();}
}
const ready=gojoPack.then(async p=>{pack=p;for(const [name,url]of Object.entries(p.art)){images[name]=new Image();images[name].src=url;await images[name].decode();}
 for(const v of pack.voices){const o=document.createElement('option');o.value=v.voice_id;o.textContent=v.trigger+' · '+v.text;$('gojoVoice').append(o);}
 for(const button of document.querySelectorAll('[data-gojo-action]'))button.onclick=()=>setState(button.dataset.gojoAction);
 $('gojoPlay').onclick=()=>voice($('gojoVoice').value);$('gojoStop').onclick=()=>{stop();notice('语音已停止');};
 $('gojoStory').onclick=()=>{state='idle';storyIndex=0;renderStory();};
 $('gojoNext').onclick=()=>{if(storyIndex<pack.story.length-1){storyIndex++;renderStory();}else{stop();storyIndex=-1;$('gojoDialogue').hidden=true;setState('idle');notice('剧情预览结束，不写入好感或游戏存档');}};
 $('gojoPrev').onclick=()=>{storyIndex=Math.max(0,storyIndex-1);renderStory();};
 $('gojoExit').onclick=()=>setState('idle');$('gojoStatus').textContent='4 张美术 / 5 种动画状态 / '+pack.voices.length+' 条合成样音已加载';
});
export async function updateGojoPreview(id){const shouldShow=String(id)==='900002';$('gojoPreview').hidden=!shouldShow;if(!shouldShow){visible=false;cancelAnimationFrame(frame);stop();return;}try{await ready;if(visible)return;visible=true;started=performance.now();cancelAnimationFrame(frame);frame=requestAnimationFrame(paint);}catch(e){notice('素材加载失败：'+e.message);}}
document.addEventListener('visibilitychange',()=>{if(document.hidden)stop();});
