-- Native Cocos2d-x battle report player. Art and CCBI tracks come from the APK.
local D = require('local_battle_data')
local M = {active=false}
local W,H=960,540
local P={{.1,.2,1200},{.35,.2,1200},{.23,.35,1100},{.22,.05,1300}}
local E={{.9,.2,1200},{.65,.2,1200},{.77,.35,1100},{.78,.05,1300}}
local root,world,fx,passiveLayer,overlay,hud,ui,report,actors,teamBars,controls
local time,index,current,clock,finished,paused,muted=0,0,nil,0,false,false,false
local transient,soundQueue,effects={},{},{}
local PT=D.passiveTiming
local passiveLength=PT.grow+PT.hold+PT.fade
local openingUntil=0
-- 1x / 2x speeds follow the original fightUI speed_1 / speed_2 buttons.
local SPEED_STEPS={1,2}
local speedIndex,speed=1,1
local speedBkg,speedIcon1,speedIcon2,speedLabel
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
-- Original skill_22: center on the body, not the feet or the name/blood row.
-- Each unit owns a serial queue; units on opposite sides may animate together.
local function passiveList(a)
    local list={}
    for _,buff in ipairs(a.unit.passives or {}) do
        if (D.skills[buff.id] or {}).passive_effect then table.insert(list,buff) end
    end
    return list
end
local function queuePassives(a,enteredAt)
    if a.buffsShown then return end
    a.buffsShown=true;a.passiveList=passiveList(a);a.passiveIndex=0
    if #a.passiveList>0 then a.nextPassive=enteredAt+PT.delay end
end
local function castPassive(a,buff)
    local spec=D.skills[buff.id]
    local effect=ccbi(spec.passive_effect,a.x,a.y,spec.passive_scale*a.height/H,PT.effect,passiveLayer,false)
    if effect then
        -- CCBI roots are 1280x752 CCLayers here. Their unscaled anchor offset
        -- is NOT our logical 960x540 canvas; compensate with the actual size.
        local es,ea=effect:getContentSize(),effect:getAnchorPoint()
        local k=effect:getScale()
        effect:setPosition(CCPointMake(a.x-es.width*(ea.x+(.5-ea.x)*k),
                                       a.y-es.height*(ea.y+(.5-ea.y)*k)))
        passiveLayer:reorderChild(effect,a.z+1)
    end
    local n
    if spec.title then n=sprite(spec.title,passiveLayer,a.x,a.y,1,a.z+2)
    else n=label(buff.name,passiveLayer,a.x,a.y,60,{255,0,0},a.z+2) end
    local scale=PT.width*W/math.max(1,n:getContentSize().width)
    n:setScale(scale)
    a.passiveID=buff.id
    table.insert(transient,{node=n,untilTime=clock+passiveLength,born=clock,passiveScale=scale})
end
local function updatePassives(a)
    if not a.nextPassive or clock<a.nextPassive then return end
    a.passiveIndex=a.passiveIndex+1
    local buff=a.passiveList[a.passiveIndex]
    if buff then
        castPassive(a,buff);a.nextPassive=clock+passiveLength
    else a.nextPassive=nil;a.passiveID=nil end
end
local function passivesPending()
    for _,a in pairs(actors) do if a.nextPassive then return true end end
    return false
end
local function updateHP()
    local totals={{0,0},{0,0}}
    for _,a in pairs(actors) do
        local hp=math.max(0,a.hp)
        a.hpLabel:setString(tostring(hp))
        a.statusLabel:setString((a.shield>0 and ('盾'..a.shield..' ') or '')..((a.poison or 0)>0 and ('毒×'..a.poison..' ') or '')..((a.armor or 0)>0 and '破甲' or ''))
        a.bar:setScaleX(a.barScale*hp/a.maxHp)
        totals[a.unit.side+1][1]=totals[a.unit.side+1][1]+hp
        totals[a.unit.side+1][2]=totals[a.unit.side+1][2]+a.maxHp
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
local function applyChanges(event)
    for _,change in ipairs(event.changes or {}) do
        local a=actors[change.target]
        if a then
            a.hp=change.hp or a.hp;a.maxHp=change.max_hp or a.maxHp;a.shield=change.shield or 0
            a.poison=change.poison_stacks or 0;a.armor=change.armor_loss or 0
            if change.in_field~=nil then a.inField=change.in_field end
        end
    end
end
local function applyHits(event)
    for _,hit in ipairs(event.hits or {{target=event.target,damage=event.damage,hp=event.hp}}) do
        local a=actors[hit.target]
        if a then
            a.hp=hit.hp;a.maxHp=hit.max_hp or a.maxHp;a.shield=hit.shield or a.shield
            if hit.revive then a.deadAt=nil;a.inField=true;a.body:setVisible(true);a.info:setVisible(true);pose(a) end
            if hit.damage>0 then a.hitAt=clock end
            if hit.damage~=0 then hpFloat(a,hit) end
            if hit.prevented or hit.dodged or (hit.absorbed or 0)>0 then
                local n=label(hit.prevented and '免死' or hit.dodged and '闪避' or ('护盾 -'..hit.absorbed),fx,a.x,a.y+35,18,{100,225,255},40)
                table.insert(transient,{node=n,untilTime=clock+1})
            end
            if hit.hp<=0 then
                a.deadAt=clock
                ccbi('106_1.ccbi',a.x+W*.05,a.y+H*.12,2,1.3)
            end
        end
    end
    applyChanges(event);updateHP()
end
local function control(title,x,y,w,action)
    local n=label(title,controls,x+w/2,y+14,17,{255,225,177},1)
    ui.hit(x,y,w,30,action,true,n)
    return n
end
local function refreshSpeed()
    if speedBkg then speedBkg:setVisible(speed>1) end
    if speedIcon1 then speedIcon1:setVisible(speed<=1) end
    if speedIcon2 then speedIcon2:setVisible(speed>1) end
    if speedLabel then speedLabel:setString('×'..speed) end
end
local function cycleSpeed()
    speedIndex=speedIndex%#SPEED_STEPS+1
    speed=SPEED_STEPS[speedIndex]
    refreshSpeed()
end
local function clearEffects()
    fx:removeAllChildrenWithCleanup(true);passiveLayer:removeAllChildrenWithCleanup(true);overlay:removeAllChildrenWithCleanup(true)
    transient={};soundQueue={};current=nil;stopEffects()
    for _,a in pairs(actors) do a.nextPassive=nil;a.passiveID=nil end
    world:setPosition(CCPointMake(0,0))
end
local function finish()
    if finished then return end
    finished=true;paused=false;CCDirector:sharedDirector():resume();clearEffects();ui.clearButtons();controls:removeAllChildrenWithCleanup(true)
    for _,event in ipairs(report.events) do
        if event.kind=='enter' then actors[event.actor].inField=true end
        for _,hit in ipairs(event.hits or {{target=event.target,hp=event.hp}}) do
            local a=actors[hit.target];if a then a.hp=hit.hp;a.maxHp=hit.max_hp or a.maxHp;a.shield=hit.shield or a.shield end
        end
        applyChanges(event)
    end
    applyChanges({changes=report.final_units or {}})
    for _,a in pairs(actors) do pose(a);a.body:setColor(ccc3(255,255,255));a.body:setVisible(a.hp>0 and a.inField);a.info:setVisible(a.hp>0 and a.inField) end
    updateHP();shade(overlay,150)
    local result=sprite(report.won and ('v2/fightUI/succ'..(report.stars or 2)..'.png') or 'v2/fightUI/fail2.png',overlay,480,340,.7,1)
    if result then result:setScale(math.min(420/result:getContentSize().width,190/result:getContentSize().height)) end
    label(report.preview and '演武结束' or report.result=='draw' and '回合结束 · 平局' or report.won and '战斗胜利' or '战斗结束',overlay,480,232,30,{255,219,146},3)
    label(report.preview and '演示不消耗体力，不改变存档' or ('银两 +'..report.silver..'    修为 +'..report.experience..(report.stars and ('    '..string.rep('★',report.stars)) or '')),overlay,480,190,21,nil,3)
    if not report.preview then
        local message=report.settlement_status and '结算已保存 · 使用客户端推测规则' or '战斗结果已保存'
        label(message,overlay,480,157,16,nil,3)
        local exp={}
        for _,h in ipairs(report.hero_exp or {}) do table.insert(exp,h.name..' +'..h.gained) end
        if #exp>0 then
            local n=label('神仙经验：'..table.concat(exp,' · '),overlay,480,107,15,nil,3)
            if n:getContentSize().width>850 then n:setScale(850/n:getContentSize().width) end
        end
        local rewards={}
        for _,p in ipairs(report.awarded or {}) do table.insert(rewards,p.name..' ×'..p.count) end
        if #rewards>0 then label(table.concat(rewards,' · '),overlay,480,130,15,{255,219,146},3) end
    end
    control('重放战报',240,64,140,function() M.show(ui,report) end)
    control('返回关卡',580,64,140,function() ui.navigate('stages') end)
    if report.preview then control('龙腾滔天',410,64,140,function() M.show(ui,D.skill_demo) end) end
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
    world=node(root,0);fx=node(root,2);overlay=node(root,3);passiveLayer=node(root,3);hud=node(root,4);controls=node(root,5)
    actors={};teamBars={};transient={};soundQueue={}
    time=0;clock=0;index=0;current=nil;finished=false;paused=false;M.active=true
    openingUntil=PT.entry+1
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
        local p=(unit.side==0 and P or E)[(slot-1)%4+1]
        local a={unit=unit,hp=unit.hp,maxHp=unit.max_hp,shield=0,x=p[1]*W,foot=p[2]*H,inField=unit.in_field~=false and slot<=4}
        a.z=p[3];a.container=node(world,p[3]);a.body=sprite(unit.sprite,a.container,a.x,0,1)
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
        a.statusLabel=label('',a.info,a.x,by-19,13,{125,230,255},5)
        a.present=false
        a.body:setVisible(false);a.info:setVisible(false)
        if a.inField then
            a.entryAt=PT.entry
            local count=#passiveList(a)
            if count>0 then openingUntil=math.max(openingUntil,PT.entry+PT.delay+count*passiveLength+PT.after) end
        end
        actors[unit.uid]=a
    end
    updateHP()
    local pauseLabel
    pauseLabel=control('暂停',18,8,70,function()
        paused=not paused
        if paused then CCDirector:sharedDirector():pause() else CCDirector:sharedDirector():resume() end
        pauseLabel:setString(paused and '继续' or '暂停')
    end)
    local skipButton=sprite('v2/skip_fight.png',controls,480,30,.5,1)
    if skipButton then ui.hit(405,8,150,44,finish,true,skipButton)
    else control('跳过战斗',420,8,120,finish) end
    speedBkg=sprite('v2/speed_bkg.png',controls,886,32,.55,1)
    speedIcon1=sprite('v2/speed_1.png',controls,886,32,.5,2)
    speedIcon2=sprite('v2/speed_2.png',controls,886,32,.5,2)
    speedLabel=label('×'..speed,controls,921,32,17,{255,225,177},2)
    ui.hit(856,10,88,44,cycleSpeed,true,speedIcon2 or speedLabel)
    refreshSpeed()
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
    if event.tags and #event.tags>0 then
        local n=label(table.concat(event.tags,' · '),fx,a.x,a.y+55,18,{255,225,145},45)
        table.insert(transient,{node=n,untilTime=clock+1.5})
    end
    if event.kind=='effect' then
        current.duration=.95;current.strike=.2;current.effect=true
        local b=target or a
        local n=label(event.skill_name,fx,b.x,b.y+40,23,{255,228,145},50)
        table.insert(transient,{node=n,untilTime=clock+.95})
        local effect=D.statusEffects and D.statusEffects[event.skill_name]
        ccbi(effect,b.x,b.y,1.4,1.2,fx,true)
    elseif event.kind=='enter' then
        current.duration=1.7;current.strike=99
        local sheet=CCSprite:create('v2/enterSence.png')
        local size=sheet:getContentSize();local fw,fh=size.width/4,size.height/3
        current.fall=CCSprite:create('v2/enterSence.png',CCRectMake(0,0,fw,fh))
        current.fall:setScale(.2*W/fw);current.fall:setFlipX(a.unit.side==1);fx:addChild(current.fall,30)
        current.frameW=fw;current.frameH=fh
        label(a.unit.name..' · 援军入阵',overlay,480,440,22,{255,228,166})
    elseif skill then
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
    if c.effect then
        if t>=c.strike and not c.hit then c.hit=true;applyHits(e) end
        if t>=c.duration then current=nil;if index>=#report.events then finish() end end
        return
    elseif e.kind=='enter' then
        local q=clamp((t-.6)/.4,0,1)
        local frame=math.min(1,math.floor(math.max(0,t-.6)/.2))
        c.fall:setTextureRect(CCRectMake(frame*c.frameW,0,c.frameW,c.frameH))
        c.fall:setPosition(CCPointMake(a.x+direction*W*.4*(1-q),a.foot+H*.8*(1-q)))
        c.fall:setVisible(t>=.6 and t<1)
        if t>=1 and not c.cast then
            c.cast=true;a.inField=true;a.present=true;a.body:setVisible(true);a.info:setVisible(true)
            ccbi('105_1.ccbi',a.x+W*.12,a.foot,4,1.5);queuePassives(a,clock)
            c.duration=math.max(c.duration,t+PT.delay+#a.passiveList*passiveLength+PT.after)
        end
        if t>=c.duration and not a.nextPassive then
            remove(c.fall);overlay:removeAllChildrenWithCleanup(true);current=nil
            if index>=#report.events then finish() end
        end
        return
    elseif c.skill then
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
    dt=dt*speed
    clock=clock+dt
    for i=#soundQueue,1,-1 do
        if clock>=soundQueue[i].at then sound(soundQueue[i].file);table.remove(soundQueue,i) end
    end
    for i=#transient,1,-1 do
        local v=transient[i]
        if clock>=v.untilTime then remove(v.node);table.remove(transient,i)
        elseif v.passiveScale then
            local t=clock-v.born
            local k=t<PT.grow and mix(1,PT.grow_factor,t/PT.grow) or PT.grow_factor
            if t>=PT.grow+PT.hold then
                local q=(t-PT.grow-PT.hold)/PT.fade;k=k*mix(1,PT.fade_factor,q)
                v.node:setOpacity(math.floor(255*(1-clamp(q,0,1))))
            end
            v.node:setScale(v.passiveScale*k)
        elseif v.ghostScale then
            local q=(clock-v.born)/v.life;v.node:setScale(v.ghostScale*mix(1,v.expand,q));v.node:setOpacity(math.floor(170*(1-q)))
        elseif v.floatY then
            local q=(clock-v.born)/v.life;v.node:setPosition(CCPointMake(v.floatX,v.floatY+65*q));v.node:setScale(.68+math.sin(math.pi*q)*.2);v.node:setOpacity(math.floor(255*clamp((1-q)*2,0,1)))
        end
    end
    world:setPosition(CCPointMake(0,0))
    for _,a in pairs(actors) do
        if a.inField and a.hp>0 and a.entryAt and clock>=a.entryAt and not a.present then
            a.present=true;a.body:setVisible(true);a.info:setVisible(true);queuePassives(a,a.entryAt)
        end
        if a.present and a.hp>0 then updatePassives(a) end
        if not a.inField or not a.present then
            a.body:setVisible(false);a.info:setVisible(false)
        elseif a.deadAt then
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
        if (index>0 and time>.12) or (index==0 and clock>=openingUntil and not passivesPending()) then
            index=index+1
            if report.events[index] then beginEvent(report.events[index]) else finish() end
        end
    end
end
function M.inspect()
    local result={clock=clock,index=index,openingUntil=openingUntil,finished=finished,paused=paused,speed=speed,units={}}
    for id,a in pairs(actors or {}) do
        result.units[id]={hp=a.hp,present=a.present,inField=a.inField,passive=a.passiveID,
            passiveIndex=a.passiveIndex or 0,pending=a.nextPassive~=nil}
    end
    return result
end
return M
