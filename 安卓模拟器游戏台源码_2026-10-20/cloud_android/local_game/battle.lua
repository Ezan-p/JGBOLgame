-- Native Cocos2d-x battle report player. Art and CCBI tracks come from the APK.
local D = require('local_battle_data')
local M = {active=false}
local W,H=960,540
local P={{.1,.2,1200},{.35,.2,1200},{.23,.35,1100},{.22,.05,1300}}
local E={{.9,.2,1200},{.65,.2,1200},{.77,.35,1100},{.78,.05,1300}}
local root,world,fx,overlay,hud,ui,report,actors,teamBars,controls
local time,index,current,clock,finished,paused,muted=0,0,nil,0,false,false,false
local transient,soundQueue,effects={},{},{}
local function clamp(x,a,b) return math.max(a,math.min(b,x)) end
local function mix(a,b,t) return a+(b-a)*clamp(t,0,1) end
local function node(parent,z)
    local n=CCNode:create();parent:addChild(n,z or 0);return n
end
local function sprite(path,parent,x,y,scale,z)
    local n=CCSprite:create(path)
    if not n then CCLuaLog('BATTLE_MISSING_ASSET '..tostring(path)); return nil end
    n:setPosition(CCPointMake(x,y));if scale then n:setScale(scale) end
    parent:addChild(n,z or 0);return n
end
local function label(value,parent,x,y,size,color,z)
    local n=CCLabelTTF:create(tostring(value),'Arial',size or 18)
    n:setPosition(CCPointMake(x,y));n:setColor(ccc3(unpack(color or {250,235,215})))
    parent:addChild(n,z or 0);return n
end
local function shade(parent,alpha,z)
    local n=CCLayerColor:create(ccc4(0,0,0,alpha));n:setContentSize(CCSizeMake(W,H));parent:addChild(n,z or 0);return n
end
local function remove(n) if n and n:getParent() then n:removeFromParentAndCleanup(true) end end
local function sound(file)
    if muted or not SimpleAudioEngine then return end
    table.insert(effects,SimpleAudioEngine:sharedEngine():playEffect(main_server.get_real_path(file),false))
end
local function stopEffects()
    if SimpleAudioEngine then for _,id in ipairs(effects) do SimpleAudioEngine:sharedEngine():stopEffect(id) end end
    effects={}
end
local function soundEvent(key)
    for _,s in ipairs(D.sounds[key] or {}) do table.insert(soundQueue,{at=clock+s.time,file=s.file}) end
end
-- The original utils.createAnimation[_new] anchors a screen-sized CCB root.
local function ccbi(file,x,y,scale,lifetime,parent,modern,flip)
    if not file then return end
    local reader=CCBReader:new(CCNodeLoaderLibrary:newDefaultCCNodeLoaderLibrary())
    local n,manager=reader:readNodeGraphFromFile(file,parent or fx,nil)
    reader:autorelease()
    if not n then CCLuaLog('BATTLE_CCBI_ERROR '..file);return end
    local size=n:getContentSize();local anchor=n:getAnchorPoint()
    local k=scale or 1
    n:setScale(k*W/math.max(1,size.width))
    if modern then n:setPosition(CCPointMake(x-W*.5,y-H*.5))
    else n:setPosition(CCPointMake(x-W*(anchor.x+(.5-anchor.x)*k),y-H*(anchor.y+(.5-anchor.y)*k))) end
    if flip then n:setScaleX(-n:getScaleX()) end
    (parent or fx):addChild(n,10)
    table.insert(transient,{node=n,untilTime=clock+(lifetime or 2)})
    soundEvent(file)
    return n
end
local function updateHP()
    local totals={{0,0},{0,0}}
    for _,a in pairs(actors) do
        local hp=math.max(0,a.hp)
        a.hpLabel:setString(tostring(hp))
        a.bar:setScaleX(a.barScale*hp/a.unit.max_hp)
        totals[a.unit.side+1][1]=totals[a.unit.side+1][1]+hp
        totals[a.unit.side+1][2]=totals[a.unit.side+1][2]+a.unit.max_hp
    end
    for side=1,2 do
        teamBars[side].sprite:setScaleX(teamBars[side].baseScale*totals[side][1]/math.max(1,totals[side][2]))
    end
end
local function pose(a,x,y,scale,rotation,opacity)
    a.body:setPosition(CCPointMake(x or a.x,y or a.y))
    a.body:setScale(a.scale*(scale or 1));a.body:setRotation(rotation or 0)
    a.body:setOpacity(opacity or 255)
end
local function ghost(a,scale,life)
    local n=sprite(a.unit.sprite,fx,a.x,a.y,a.scale,5);n:setFlipX(a.unit.side==1)
    table.insert(transient,{node=n,untilTime=clock+life,born=clock,life=life,ghostScale=a.scale,expand=scale})
end
local function hpFloat(a,hit)
    local n=CCLabelBMFont:create((hit.damage<0 and '+' or '-')..math.abs(hit.damage),'number/all_number_white.fnt')
    n:setPosition(CCPointMake(a.x,a.y+a.height*.1));n:setColor(hit.damage<0 and ccc3(91,255,115) or ccc3(255,65,30))
    n:setScale(.68);fx:addChild(n,40)
    table.insert(transient,{node=n,untilTime=clock+1,born=clock,life=1,floatY=a.y+a.height*.1,floatX=a.x})
end
local function applyHits(event)
    for _,hit in ipairs(event.hits or {{target=event.target,damage=event.damage,hp=event.hp}}) do
        local a=actors[hit.target]
        if a then
            a.hp=hit.hp;a.hitAt=clock;hpFloat(a,hit)
            if hit.hp<=0 then
                a.deadAt=clock
                ccbi('106_1.ccbi',a.x+W*.05,a.y+H*.12,2,1.3)
            end
        end
    end
    updateHP()
end
local function control(title,x,y,w,action)
    local n=label(title,controls,x+w/2,y+14,17,{255,225,177},1)
    ui.hit(x,y,w,30,action,true,n)
    return n
end
local function clearEffects()
    fx:removeAllChildrenWithCleanup(true);overlay:removeAllChildrenWithCleanup(true)
    transient={};soundQueue={};current=nil;stopEffects()
    world:setPosition(CCPointMake(0,0))
end
local function finish()
    if finished then return end
    finished=true;paused=false;CCDirector:sharedDirector():resume();clearEffects();ui.clearButtons();controls:removeAllChildrenWithCleanup(true)
    for _,event in ipairs(report.events) do
        for _,hit in ipairs(event.hits or {{target=event.target,hp=event.hp}}) do actors[hit.target].hp=hit.hp end
    end
    for _,a in pairs(actors) do pose(a);a.body:setColor(ccc3(255,255,255));a.body:setVisible(a.hp>0);a.info:setVisible(a.hp>0) end
    updateHP();shade(overlay,150)
    local result=sprite(report.won and 'v2/fightUI/succ2.png' or 'v2/fightUI/fail2.png',overlay,480,340,.7,1)
    if result then result:setScale(math.min(420/result:getContentSize().width,190/result:getContentSize().height)) end
    label(report.preview and '演武结束' or report.won and '战斗胜利' or '战斗结束',overlay,480,232,30,{255,219,146},3)
    label(report.preview and '演示不消耗体力，不改变存档' or ('银两 +'..report.silver..'    经验 +'..report.experience),overlay,480,190,21,nil,3)
    if not report.preview then label(report.first_clear and '首通奖励已保存' or '战斗结果已保存',overlay,480,157,16,nil,3) end
    control('重放战报',240,100,140,function() M.show(ui,report) end)
    control('返回关卡',580,100,140,function() ui.navigate('stages') end)
    if report.preview then control('龙腾滔天',410,100,140,function() M.show(ui,D.skill_demo) end) end
end
function M.stop()
    M.active=false
    CCDirector:sharedDirector():resume()
    if SimpleAudioEngine then SimpleAudioEngine:sharedEngine():stopBackgroundMusic(true);stopEffects() end
end
function M.preview(skill) return skill and D.skill_demo or D.demo end
function M.show(context,data)
    M.stop();ui=context;root=ui.root;report=data
    root:removeAllChildrenWithCleanup(true);ui.clearButtons()
    world=node(root,0);fx=node(root,2);overlay=node(root,3);hud=node(root,4);controls=node(root,5)
    actors={};teamBars={};transient={};soundQueue={}
    time=0;clock=0;index=0;current=nil;finished=false;paused=false;M.active=true
    local stage=D.stages[report.stage.id] or {}
    local bg=sprite(report.stage.background or stage.background or 'map/special/xmz.jpg',world,W/2,H/2,1,-1)
    bg:setScaleX(W/bg:getContentSize().width);bg:setScaleY(H/bg:getContentSize().height)
    sprite('v2/fightUI/gate_name_bkg.png',hud,480,H*.925,.75,2)
    local title=report.stage.title or stage.title
    if title then
        local n=sprite(title,hud,480,H*.925,1,3);n:setScale(math.min(W*.17/n:getContentSize().width,55/n:getContentSize().height))
    else label(report.stage.name,hud,480,H*.925,25,nil,3) end
    for side=0,1 do
        local n=sprite('v2/fightUI/blood_big.png',hud,W*(side==0 and .38203125 or .61796875),H*.925+10.5,.75,3)
        n:setAnchorPoint(CCPointMake(side==0 and 1 or 0,.5));n:setFlipX(side==1)
        -- Keep Lua metadata outside tolua userdata (some engine builds reject fields).
        teamBars[side+1]={sprite=n,baseScale=.75}
    end
    label('我方阵容',hud,290,480,15,nil,4);label('敌方阵容',hud,670,480,15,nil,4)
    for _,unit in ipairs(report.units) do
        local slot=unit.slot or tonumber(string.sub(unit.uid,3))+1
        local p=(unit.side==0 and P or E)[slot]
        local a={unit=unit,hp=unit.hp,x=p[1]*W,foot=p[2]*H}
        a.container=node(world,p[3]);a.body=sprite(unit.sprite,a.container,a.x,0,1)
        a.scale=.57*H/512;a.height=a.body:getContentSize().height*a.scale;a.y=a.foot+a.height/2
        a.body:setFlipX(unit.side==1);pose(a)
        a.info=node(a.container,20)
        label(unit.name,a.info,a.x,a.foot+a.height+H*.06,18,{31,24,18})
        label(unit.name,a.info,a.x-1,a.foot+a.height+H*.06+1,18,nil,1)
        local by=a.foot+a.height+H*.03
        local frame=sprite('v2/fightUI/blood_char1.png',a.info,a.x,by,1,2)
        frame:setScaleX(W*.125/frame:getContentSize().width);frame:setScaleY(.75)
        a.bar=sprite('v2/fightUI/blood_char2.png',a.info,a.x-W*.06,by,1,3)
        a.bar:setAnchorPoint(CCPointMake(0,.5));a.barScale=W*.12/a.bar:getContentSize().width
        a.bar:setScaleY(.75);a.hpLabel=label(unit.hp,a.info,a.x,by-1,14,nil,4)
        actors[unit.uid]=a
    end
    updateHP()
    local pauseLabel
    pauseLabel=control('暂停',18,8,70,function()
        paused=not paused
        if paused then CCDirector:sharedDirector():pause() else CCDirector:sharedDirector():resume() end
        pauseLabel:setString(paused and '继续' or '暂停')
    end)
    control('跳过',866,8,76,finish)
    local audioLabel
    audioLabel=control(muted and '音效关' or '音效开',99,8,88,function()
        muted=not muted;audioLabel:setString(muted and '音效关' or '音效开')
        if SimpleAudioEngine then
            if muted then SimpleAudioEngine:sharedEngine():stopBackgroundMusic(true);stopEffects()
            else SimpleAudioEngine:sharedEngine():playBackgroundMusic(main_server.get_real_path('music/fight.mp3'),true) end
        end
    end)
    if report.preview then
        control('龙腾滔天',698,8,130,function() M.show(ui,D.skill_demo) end)
        label('战斗演示',hud,480,461,15,{255,218,163})
    end
    if not muted and SimpleAudioEngine then SimpleAudioEngine:sharedEngine():playBackgroundMusic(main_server.get_real_path('music/fight.mp3'),true) end
end
local function beginEvent(event)
    local a=actors[event.actor];local target=actors[event.target]
    local skill=event.skill_id and event.skill_id~=1
    current={event=event,actor=a,target=target,t=0,skill=skill,impact=false,cast=false,ink=false,hit=false}
    time=0
    if skill then
        current.spec=D.skills[event.skill_id] or {}
        current.cinematic=current.spec.quality and (current.spec.quality>=4 or current.spec.multi)
        current.duration=current.cinematic and 4.8 or 3.3
        current.strike=current.cinematic and 3.2 or 1.7
        if event.skill_id==104 then current.duration=6.2;current.strike=4.3;current.wave=0 end
        current.mask=shade(overlay,180)
        current.portrait=sprite(a.unit.sprite,overlay,a.x,a.y,a.scale,20)
        current.portrait:setFlipX(a.unit.side==1)
        soundEvent('fight_splasheye')
    else current.duration=1.95;current.strike=.98;ghost(a,1.4,.8) end
end
local function playEvent(dt)
    local c=current;local e=c.event;local a=c.actor;local target=c.target
    c.t=c.t+dt;local t=c.t;local direction=a.unit.side==0 and 1 or -1
    if c.skill then
        local intro=c.cinematic and 2.35 or .95
        if t<intro then
            local q=clamp(t/.16,0,1)
            local x=mix(a.x,a.unit.side==0 and 215 or 745,q)
            local y=mix(a.y,260,q)
            c.portrait:setPosition(CCPointMake(x,y));c.portrait:setScale(a.scale*mix(1,1.6,q))
            if c.cinematic and t>=.14 and not c.ink then
                c.ink=true
                ccbi(a.unit.side==0 and 'blood_5.ccbi' or 'blood_5_inv.ccbi',a.unit.side==0 and 672 or 288,270,1,2.2,overlay,true)
                ccbi('splash_eye.ccbi',480,324,1,2.2,overlay,false,a.unit.side==1)
                if c.spec.title then
                    c.title=sprite(c.spec.title,overlay,a.unit.side==0 and 700 or 260,270,1,30)
                    c.titleScale=H*.7/c.title:getContentSize().height
                else c.title=label(e.skill_name,overlay,a.unit.side==0 and 700 or 260,270,56,{255,239,198},30);c.titleScale=1 end
                ghost(a,2.4,.5)
            end
            if c.title then
                c.title:setScale(c.titleScale*mix(1.85,1,clamp((t-.14)/.22,0,1)))
                c.title:setOpacity(math.floor(255*clamp((intro-t)/.25,0,1)))
            elseif not c.cinematic and not c.name then
                c.name=label(e.skill_name,overlay,480,350,38,{255,224,156},30)
            end
        elseif not c.cast then
            c.cast=true
            -- Discard handles before releasing their native parent.
            local keep={};for _,v in ipairs(transient) do if v.node:getParent()==fx then table.insert(keep,v) end end;transient=keep
            overlay:removeAllChildrenWithCleanup(true)
            soundQueue={}
            ccbi(c.spec.cast,a.x+W*.03,a.y,c.event.skill_id==104 and 1 or 1.3,1.2)
        end
        if e.skill_id==104 and t>=3.55+(c.wave or 0)*.6 and (c.wave or 0)<3 then
            c.wave=c.wave+1
            for _,hit in ipairs(e.hits) do
                local b=actors[hit.target]
                ccbi(a.unit.side==1 and '123_2_1.ccbi' or '123_2.ccbi',b.x+(a.unit.side==0 and W*.13 or 0)+(c.wave-2)*19,b.y+H*.05,1.6+c.wave*.35,1.5)
                if c.wave>1 and b.hp>0 then b.hitAt=clock end
            end
            c.impact=true
        end
        if e.skill_id~=104 and t>=c.strike-.25 and not c.impact then
            c.impact=true
            for _,hit in ipairs(e.hits or {{target=e.target}}) do
                local b=actors[hit.target]
                local effect=c.spec.impact
                if e.skill_id==104 and a.unit.side==1 then effect='123_2_1.ccbi' end
                ccbi(effect,b.x+(e.skill_id==104 and W*.13 or 0),b.y+H*.05,e.skill_id==104 and 2 or 1.5,1.5)
            end
        end
    else
        local approach=clamp((t-.65)/.3,0,1)
        local back=clamp((t-1.45)/.25,0,1)
        local x=mix(a.x,target.x-direction*125,approach)
        local foot=mix(a.foot,target.foot,approach)
        pose(a,mix(x,a.x,back),mix(foot,a.foot,back)+a.height/2,1+.08*math.sin(math.pi*approach)*(1-back),-direction*12*math.sin(math.pi*clamp((t-.65)/.8,0,1)))
        a.info:setVisible(t<.65 or t>1.7)
        if t>=.85 and not c.impact then
            c.impact=true
            ccbi(direction==1 and '204_1.ccbi' or '204_2.ccbi',target.x+W*(direction==1 and -.12 or .62),target.foot+H*.45,.8,1.1,fx,true)
        end
    end
    if t>=c.strike and not c.hit then c.hit=true;applyHits(e) end
    if t>=c.duration then
        pose(a);a.info:setVisible(a.hp>0);current=nil
        if index>=#report.events then finish() end
    end
end
function M.update(dt)
    if not M.active or finished or paused then return end
    clock=clock+dt
    for i=#soundQueue,1,-1 do
        if clock>=soundQueue[i].at then sound(soundQueue[i].file);table.remove(soundQueue,i) end
    end
    for i=#transient,1,-1 do
        local v=transient[i]
        if clock>=v.untilTime then remove(v.node);table.remove(transient,i)
        elseif v.ghostScale then
            local q=(clock-v.born)/v.life;v.node:setScale(v.ghostScale*mix(1,v.expand,q));v.node:setOpacity(math.floor(170*(1-q)))
        elseif v.floatY then
            local q=(clock-v.born)/v.life;v.node:setPosition(CCPointMake(v.floatX,v.floatY+65*q));v.node:setScale(.68+math.sin(math.pi*q)*.2);v.node:setOpacity(math.floor(255*clamp((1-q)*2,0,1)))
        end
    end
    world:setPosition(CCPointMake(0,0))
    for _,a in pairs(actors) do
        if a.deadAt then
            local q=clamp((clock-a.deadAt)/.65,0,1);pose(a,a.x+(a.unit.side==0 and -28 or 28)*q,a.y,1,0,math.floor(255*(1-q)));a.info:setVisible(false)
        elseif a.hitAt and clock-a.hitAt<.55 then
            local q=(clock-a.hitAt)/.55;local d=a.unit.side==0 and -1 or 1
            pose(a,a.x+math.sin(q*math.pi)*17*d,a.y+math.sin(q*math.pi)*12,1,math.sin(q*math.pi)*14*d)
            a.body:setColor(ccc3(255,math.floor(mix(110,255,q)),math.floor(mix(100,255,q))))
            world:setPosition(CCPointMake(math.sin(q*45)*4*(1-q),math.cos(q*40)*2*(1-q)))
        elseif not current or current.actor~=a then
            a.body:setColor(ccc3(255,255,255));pose(a,a.x,a.y+math.sin(clock*2+a.x)*1.6,1+math.sin(clock*2+a.x)*.008)
        end
    end
    if current then playEvent(dt)
    else
        time=time+dt
        local entryDelay=report.preview and report.stage.background=='map/special/xmz.jpg' and 2.6 or 1.1
        if time>(index==0 and entryDelay or .12) then
            index=index+1
            if report.events[index] then beginEvent(report.events[index]) else finish() end
        end
    end
end
return M
