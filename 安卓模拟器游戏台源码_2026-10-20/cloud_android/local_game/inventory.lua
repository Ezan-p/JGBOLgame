-- Original packageUI art and proportions; persistent local inventory actions.
local data=require("local_inventory_data")
local enhance=require("local_enhance")
local stoneOK,stone=pcall(require,"local_stone")
if not stoneOK then CCLuaLog("LOCAL_STONE_LOAD_ERROR: "..tostring(stone));stone=nil end
local upgradeOK,stoneUpgrade=pcall(require,"local_stone_upgrade")
if not upgradeOK then CCLuaLog("LOCAL_STONE_UPGRADE_LOAD_ERROR: "..tostring(stoneUpgrade));stoneUpgrade=nil end
local M={tab=1,offset=0,page=1,catalog=false,intro=nil,introScroll=nil,socketPos=1,alert=nil,
    spellIntro=nil,spellScroll=nil,spellHits={},buttons={},hoverKey=nil,pressKey=nil,
    overlayFrom=nil,overlayEntry=nil}
local VIEW_X,VIEW_Y=235,121
local ui,state,root,scroll,gesture
local GOLD={255,224,164}
local MUTED={204,180,148}
local OWNER={186,169,157}
local names={"武器","防具","法宝","法术","灵石","道具"}
local tabs={"Label_weapon","Label_armor","Label_magic-item","Label_spell","stone","Label_props"}

local function image(file,x,y,w,h,parent)
    local n=CCSprite:create(file)
    if not n then return end
    local s=n:getContentSize()
    n:setScaleX(w/s.width); n:setScaleY((h or w*s.height/s.width)/s.height)
    n:setPosition(CCPointMake(x,y)); (parent or root):addChild(n)
    return n
end
local function label(value,x,y,size,color,parent,center,width)
    local n
    if width then n=CCLabelTTF:create(tostring(value),"Arial",size,CCSizeMake(width,0),kCCTextAlignmentLeft)
    else n=CCLabelTTF:create(tostring(value),"Arial",size) end
    n:setAnchorPoint(CCPointMake(center and .5 or 0,width and 1 or .5))
    n:setPosition(CCPointMake(x,y)); n:setColor(ccc3(unpack(color or GOLD)))
    local target=parent or root
    target:addChild(n)
    return n
end
local function fill(x,y,w,h,color,parent)
    local n=CCLayerColor:create(ccc4(unpack(color)))
    n:setContentSize(CCSizeMake(w,h)); n:setPosition(CCPointMake(x,y)); (parent or root):addChild(n)
    return n
end
local function anchoredImage(file,x,y,w,h,ax,ay,parent)
    local n=image(file,x,y,w,h,parent)
    if n then n:setAnchorPoint(CCPointMake(ax or .5,ay or .5)); n:setPosition(CCPointMake(x,y)) end
    return n
end
local function button(title,x,y,w,action,enabled,file)
    if enabled==nil then enabled=true end
    local n=image(file or "v2/soulExchangeUI/btn_bkg1.png",x+w/2,y+17,w,34)
    if not enabled then n:setColor(ccc3(110,110,110)) end
    if title then label(title,x+w/2,y+17,17,enabled and GOLD or MUTED,nil,true) end
    ui.hit(x,y,w,34,action,enabled,n)
end
local function icon(item,x,y,w,parent,level)
    local info=item.icon
    if not info then
        fill(x-w/2,y-w/2,w,w,{61,43,35,255},parent)
        label("暂无图",x,y,13,MUTED,parent,true)
        return
    end
    local n=CCSprite:create(info.file)
    local s=n:getContentSize()
    local sw,sh=s.width,s.height
    if info.index then
        sw,sh=sw/info.columns,sh/info.rows
        local i=info.index+(item.category==5 and (level or 1)-1 or 0)
        n:setTextureRect(CCRectMake((i-1)%info.columns*sw,math.floor((i-1)/info.columns)*sh,sw,sh))
    end
    n:setScale(w/sw); n:setPosition(CCPointMake(x,y)); (parent or root):addChild(n)
    for _,o in ipairs(info.overlays or {}) do
        local overlay=CCSprite:create(o.file)
        overlay:setPosition(CCPointMake(sw*o.x,sh*o.y));overlay:setScale(o.scale);n:addChild(overlay)
    end
    if info.text then label(info.text,sw/2,sh/2,38,{0,0,0},n,true) end
    if item.main_type==19 then label(level or 1,sw*.8,sh*.2,26,GOLD,n,true) end
    if item.main_type==14 then image("map/parts.png",x,y,w,w,parent) end
    -- data.getStoneSprite appends "+level" at the top-right of every stone cell.
    if item.category==5 then
        local value="+"..(level or 1)
        local shadow=CCLabelTTF:create(value,"Arial",26)
        shadow:setAnchorPoint(CCPointMake(1,1));shadow:setPosition(CCPointMake(sw*.9+1,sh*.9-1))
        shadow:setColor(ccc3(0,0,0));n:addChild(shadow,1)
        local text=CCLabelTTF:create(value,"Arial",26)
        text:setAnchorPoint(CCPointMake(1,1));text:setPosition(CCPointMake(sw*.9,sh*.9))
        text:setColor(ccc3(255,128,0));n:addChild(text,2)
    end
    return n
end
local function own(uid)
    if type(uid)~="number" then return end
    for _,e in ipairs(state.inventory.entries) do if e.uid==uid then return e end end
end
local function heroName(id)
    for _,h in ipairs(state.heroes) do if h.id==id then return h.name end end
    return "未装备"
end
local SLOTS={[1]=1,[2]=1,[3]=1,[4]=2,[5]=3}
local STAT_ICON={[1]="damage",[2]="defence",[3]="health"}
local STAT_FIELD={[1]="gongji_plus",[2]="fangyu_plus",[3]="maxhp_plus"}
local STAT_NAME={[1]="攻击",[2]="防御",[3]="生命"}
local STONE_STAT_ICON={[1]="CHAR_gong",[2]="CHAR_fang",[3]="CHAR_ming"}
local function stoneBase(category,level)
    local row=(data.stones or {})[tostring(category)..":"..tostring(level or 1)]
    return tonumber(row and row.base or 0) or 0
end
local function stoneAt(entry,pos)
    for _,s in ipairs(entry and entry.stones or {}) do
        if (s.pos or 0)==pos then return s end
    end
end
local function stoneSum(entry,category)
    local total=0
    for i=1,3 do local s=stoneAt(entry,i);if s then total=total+stoneBase(category,s.level) end end
    return total
end
local function baseValue(item,level)
    local b=item.original or {}
    local field=STAT_FIELD[item.category]
    if not field then return 0 end
    return math.floor((tonumber(b[field]) or 0)+(tonumber(level or 1)-1)*(tonumber(b.upgrade_plus) or 0))
end
local function maxSockets(item) return SLOTS[item.quality] or 1 end
local function fateLines(item)
    local rows=(data.fates or {})[tostring(item.id)] or {}
    if #rows==0 then return "无仙缘" end
    local names,seen={},{}
    for _,f in ipairs(rows) do
        if not seen[f.hero] then seen[f.hero]=true;table.insert(names,f.hero_name or tostring(f.hero)) end
    end
    local effect=rows[1] and (rows[1].description or "") or ""
    return "羁绊："..table.concat(names,"、").."\n羁绊效果："..effect
end
local function perform(op,args)
    M.confirm=nil; M.choice=nil
    ui.send(op,args)
end
local function replaceSpell(e)
    M.equipPending=true
    perform("bag_equip",{uid=e.uid,hero=M.equipHero,equip_pos=M.equipPos})
end
local function confirm(message,op,args)
    M.confirm={message=message,op=op,args=args}; ui.render()
end
local function notify(message)
    M.alert=message; ui.render()
end
local function reset()
    M.selected=nil; M.choice=nil; M.confirm=nil; M.reading=false; M.offset=0; M.page=1; M.preview=nil; gesture=nil
    M.intro=nil; M.introScroll=nil; M.alert=nil; M.introHits={}
    M.spellIntro=nil; M.spellScroll=nil; M.spellHits={}
    M.overlayFrom=nil;M.overlayEntry=nil
    M.buttons={};M.hoverKey=nil;M.pressKey=nil
    if stone then stone.close() end
    if stoneUpgrade then stoneUpgrade.close() end
end
local upgrade
local function registerButton(key,kind,uid,x,y,w,h,node)
    local rect={key=key,kind=kind,uid=uid,
        x=VIEW_X+x-w/2,y=VIEW_Y+M.offset+y-h/2,w=w,h=h}
    table.insert(M.buttons,rect)
    if node then
        if M.pressKey==key then node:setColor(ccc3(255,213,145))
        elseif M.hoverKey==key then node:setColor(ccc3(255,238,185)) end
    end
    return rect
end
local function buttonAt(x,y)
    for i=#M.buttons,1,-1 do
        local b=M.buttons[i]
        if x>=b.x and x<=b.x+b.w and y>=b.y and y<=b.y+b.h then return b end
    end
end
local function performButton(b)
    if not b then return end
    if b.kind=="stone" then
        if stone then stone.open(ui,state,b.uid) end
    elseif b.kind=="stoneupgrade" then
        if stoneUpgrade then stoneUpgrade.open(ui,state,b.uid) end
    else
        local e=own(b.uid)
        if e then
            local item=data.items[e.key]
            if M.equipHero and item and item.category==4 then replaceSpell(e)
            else upgrade(e) end
        end
    end
end
function upgrade(e)
    local item=data.items[e.key]
    if e.level>=item.top_level then return end
    if item.category<=3 then enhance.open(ui,state,e.uid);ui.render();return end
    confirm("花费 "..e.upgrade_cost.." 银两，将「"..item.name.."」升至 "..(e.level+1).." 级？",
        "bag_upgrade",{uid=e.uid})
end
local function setOffset(v)
    if not scroll then return end
    M.offset=math.max(0,math.min(scroll.max,v)); scroll.node:setPositionY(M.offset)
end
local function area(total,onTap)
    local c=CCLayer:create(); c:setContentSize(CCSizeMake(684,math.max(370,total)))
    local v=CCScrollView:create(CCSizeMake(684*root:getScaleX(),370*root:getScaleY()),c)
    v:setTouchEnabled(false); v:setPosition(CCPointMake(235,121)); root:addChild(v)
    scroll={node=c,max=math.max(0,total-370),tap=onTap}
    setOffset(M.offset)
    return c
end
local function frame()
    fill(24,86,912,432,{40,25,20,255})
    image("v2/packageUI/board_bkg.png",480,302,912,432)
    image("v2/packageUI/board_leftBkg.png",121,302,194,432)
    image("v2/packageUI/board_mid_edge.png",221,302,19,432)
    image("v2/packageUI/board_edge1.png",24,302,15,432)
    image("v2/packageUI/board_edge1.png",936,302,15,432)
    image("v2/packageUI/board_edge2.png",480,514,930,37)
    image("v2/packageUI/board_edge2.png",480,91,930,37):setFlipY(true)
    local close=image("v2/introUI/close1.png",921,513,63,60)
    ui.hit(891,483,63,57,function() M.back() end,true,close)
    for i,t in ipairs(tabs) do
        local target=i
        local y=475-(i-1)*59.4
        local n=image("v2/packageUI/"..t..(M.tab==i and "2" or "1")..".png",115,y,174)
        ui.hit(28,y-28,174,56,function() M.tab=target;if target~=4 then M.equipHero=nil;M.equipPos=nil end;reset();ui.render() end,true,n)
    end
    button(nil,57,109,116,function()
        M.equipHero=nil;M.equipPos=nil;M.smelt=not M.smelt;M.catalog=false;reset();ui.render()
    end,true,"v2/smithUI/smith1.png")
end
local function rule(item)
    local a=item.action
    if a=="equip" then
        return "装备强化提升基础属性。孔位由品质决定（1/1/1/2/3）；打孔消耗1颗金刚钻，镶嵌同类灵石后按灵石等级百分比提升该装备属性。"
    end
    if a=="spell" then
        return "自带法术不可替换。第2、3格可装配法术，不限主动或被动；同一神仙不可重复装备同名法术。"
    end
    if a=="star" then return "原生法术觉醒后可在演武堂装备，最多五颗，同类不重复。" end
    if a=="trait" then return "每位神仙最多四项特技，同类不能重复；前往阵容的演武堂可兑换、装备和升级。" end
    if a=="cheer_material" then return "在演武堂修炼页，用于助阵法术进修。" end
    if a=="gem" then
        return "灵石1至13级，数值读取stone_cost_worth。升级需同名同类灵石作材料并消耗银两，成功率=材料价值/需求+补偿；失败消耗材料。"
    end
    if a=="fragment" then return "10个同名碎片合成1件对应装备。" end
    if a=="energy" then return "使用恢复 "..item.original.strength_plus.." 点体力，上限60。体力已满时不消耗。" end
    if a=="experience" then return "使用增加行者经验 "..item.original.experience_plus.."。" end
    if a=="train" then return "选择一名神仙提升1级，最高20级。" end
    if a=="material" then return "熔炼装备或法术获得；每颗可兑换20银两。" end
    if a=="support_material" then return "在阵容的助阵页面消耗乾坤符箓，为八卦阵位进阶。" end
    return "所属系统尚未接入。可查阅原版资料，暂不提供兑换和使用。"
end
local INTRO_TOTAL=760
local INTRO_W,INTRO_H=524,420
local function introHit(x,y,w,h,action)
    table.insert(M.introHits,{x=x,y=y,w=w,h=h,action=action})
end
local function setIntroOffset(value)
    local s=M.introScroll
    if not s then return end
    s.offset=math.max(0,math.min(s.max,value))
    s.node:setPositionY(INTRO_H-INTRO_TOTAL+s.offset)
end
local function drawIntro(item,e)
    M.introHits={}
    fill(0,0,960,540,{0,0,0,180})
    image("v2/introUI/introBkg.png",480,270,560,486)
    image("v2/introUI/intro_label.png",480,487,90,50)
    image("v2/introUI/close1.png",732,489,50,47)
    local c=CCLayer:create(); c:setContentSize(CCSizeMake(INTRO_W,INTRO_TOTAL))
    local v=CCScrollView:create(CCSizeMake(INTRO_W*root:getScaleX(),INTRO_H*root:getScaleY()),c)
    v:setTouchEnabled(false); v:setPosition(CCPointMake(218,48)); root:addChild(v)
    local key=tostring(M.selected or M.preview or "")
    if not M.introScroll or M.introScroll.key~=key then
        M.introScroll={node=c,key=key,max=INTRO_TOTAL-INTRO_H}
        setIntroOffset(0)
    else
        M.introScroll.node=c; setIntroOffset(M.introScroll.offset)
    end
    local panelW,panelH=500,275
    local left,bottom=(INTRO_W-panelW)/2,INTRO_TOTAL-panelH
    image("v2/newIntroUI/big_bkg.png",left+panelW/2,bottom+panelH/2,panelW,panelH,c)
    local level=e and e.level or 1
    local node=icon(item,left+0.207*panelW,bottom+0.703*panelH,0.49*panelH,c,level)
    if node and item.category~=5 then
        local size=node:getContentSize()
        local empty=CCSprite:create("v2/newIntroUI/star_bkg.png")
        local es=empty:getContentSize()
        empty:setAnchorPoint(CCPointMake(0,0));empty:setPosition(CCPointMake(size.width*.1,size.height*.1))
        empty:setScale(.8*size.width/es.width);node:addChild(empty)
        local quality=tonumber(item.quality) or 0
        if quality>0 then
            local stars=CCSprite:create("v2/introUI/stars.png")
            local ss=stars:getContentSize()
            stars:setTextureRect(CCRectMake(0,0,ss.width*math.min(1,quality/5),ss.height))
            stars:setAnchorPoint(CCPointMake(0,0));stars:setPosition(CCPointMake(size.width*.1,size.height*.1))
            stars:setScale(.8*size.width/ss.width);node:addChild(stars)
        end
    end
    label(item.name,left+0.716*panelW,bottom+0.888*panelH,25,PALE,c)
    local attrX=left+0.552*panelW
    local attrY=bottom+0.774*panelH
    anchoredImage("v2/introUI/"..STAT_ICON[item.category]..".png",attrX,attrY,28,28,1,.5,c)
    local base=e and tonumber(e.base_value) or baseValue(item,level)
    local percent=e and tonumber(e.stone_percent) or 0
    local power=" "..math.floor(base)
    if percent>0 then
        power=power.." + "..math.floor(base*percent).." ("..string.format("%.1f",percent*100).."%)"
    end
    label(power,attrX,attrY,17,PALE,c)
    local levelY=bottom+0.58*panelH
    anchoredImage("v2/introUI/level.png",attrX,levelY,28,28,1,.5,c)
    label(" "..level,attrX,levelY,17,PALE,c)
    local curY=bottom+0.25*panelH
    local valueY=bottom+0.085*panelH
    local leftX=left+0.113*panelW
    local offsetX=0.2*panelW
    local valueOffset=0.03*panelW
    local drill=e and tonumber(e.drill) or 0
    local maximum=e and tonumber(e.max_sockets) or maxSockets(item)
    local stoneItem=data.items["i"..tostring(1089+item.category)]
    for i=1,3 do
        local x=leftX+(i-1)*offsetX
        if i<=maximum then
            image("v2/stoneUI/unsee.png",x,curY,0.2*panelH,0.2*panelH*137/135,c)
            local stone=stoneAt(e,i)
            if stone then
                icon(stoneItem,x,curY,0.2*panelH,c,stone.level)
                image("v2/newIntroUI/stone_value_bkg.png",x,valueY,98,39,c)
                anchoredImage("v2/introUI/"..STAT_ICON[item.category]..".png",x-valueOffset,valueY,20,20,1,.5,c)
                label(string.format(" %.1f%%",stoneBase(item.category,stone.level)*100),x-valueOffset,valueY,15,PALE,c)
            elseif i>drill then
                image("v2/stoneUI/lock.png",x,curY,0.2*panelH,0.2*panelH*110/131,c)
            end
        end
    end
    local descTop=bottom-16
    if e and stone then
        local bx=218+left+0.825*panelW
        local by=48+(INTRO_H-INTRO_TOTAL+M.introScroll.offset)+bottom+0.2*panelH
        image("v2/stoneUI/putin1.png",left+0.825*panelW,bottom+0.2*panelH,90,50,c)
        introHit(bx-45,by-25,90,50,function()
            M.intro=nil;M.introScroll=nil
            stone.open(ui,state,e.uid)
        end)
    end
    local desc=label(item.description or "",12,descTop,17,MUTED,c,false,500)
    local descHeight=desc:getContentSize().height
    local headTop=descTop-descHeight-14
    anchoredImage("v2/newIntroUI/head_bkg.png",panelW/2,headTop,panelW,panelW*100/600,.5,1,c)
    image("v2/introUI/yuanfen_label.png",panelW/2,headTop-52,100,61,c)
    local innerTop=headTop-panelW*100/600
    local innerHeight=132
    local capHeight=panelW*59/609
    image("v2/newIntroUI/big_bkg1.png",panelW/2,innerTop-capHeight/2,panelW,capHeight,c)
    image("v2/newIntroUI/big_bkg2.png",panelW/2,innerTop-capHeight-(innerHeight-2*capHeight)/2,
        panelW,innerHeight-2*capHeight,c)
    local bottomCap=image("v2/newIntroUI/big_bkg1.png",panelW/2,innerTop-innerHeight+capHeight/2,panelW,capHeight,c)
    if bottomCap then bottomCap:setFlipY(true) end
    label(fateLines(item),24,innerTop-18,16,MUTED,c,false,476)
end
local function drawStoneIntro(item,e)
    M.introHits={};M.introScroll=nil
    fill(0,0,960,540,{0,0,0,180})
    image("v2/messageUI/frame1.png",480,297,652,469)
    image("v2/introUI/intro_label.png",480,486,116,65)
    image("v2/introUI/close1.png",700.8,502.2,63,60)
    icon(item,345.6,367.2,172.8,nil,e.level)
    image("v2/newIntroUI/bkg1.png",556.8,367.2,400,212)
    label(item.name,556.8,415.8,30,PALE,nil,true)
    image("v2/introUI/level.png",499.2,378,41,41)
    label(tostring(e.level or 1),518.4,378,26,PALE)
    image("v2/packageUI/"..STAT_ICON[item.sub_type]..".png",595.2,378,41,41)
    label(string.format("%.1f%%",stoneBase(item.sub_type,e.level)*100),614.4,378,26,PALE)
    label(item.description or "",480,247,26,{254,235,192},nil,true,384)
    local upgradeX,upgradeY=556.8,324
    local node=image("v2/newIntroUI/upgrade1.png",upgradeX,upgradeY,120,67)
    local enabled=tonumber(e.level or 1)<tonumber(e.max_level or 13) and (tonumber(state.level) or 1)>=10
    if not enabled and node then node:setColor(ccc3(120,110,100)) end
    introHit(upgradeX-60,upgradeY-33.5,120,67,function()
        if not enabled then
            M.alert=(tonumber(e.level or 1)>=tonumber(e.max_level or 13)) and "灵石已达最高等级" or "灵石系统需要行者等级达到 10 级"
            ui.render();return
        end
        M.intro=nil;M.introScroll=nil
        if stoneUpgrade then stoneUpgrade.open(ui,state,e.uid) end
    end)
end

-- Original packageUI.createItemIntroLayer skill branch, redrawn on the
-- 仙缘 (fate) artwork used by the client's 法术详情 page.
local SPELL_TEXT={254,235,192}
local SPELL_STAT={[1]="生命",[2]="法力",[3]="攻击",[4]="防御"}
local function spellFateData(item)
    local rows=(data.fates or {})[tostring(item.id)] or {}
    local names,seen={},{}
    for _,f in ipairs(rows) do
        if not seen[f.hero] then
            seen[f.hero]=true
            table.insert(names,f.hero_name or tostring(f.hero))
        end
    end
    local effect=""
    local first=rows[1]
    if first then
        effect=(SPELL_STAT[tonumber(first.effect_field)] or "属性").."提升"..
            (tonumber(first.percent) or 0).."%"
    end
    return table.concat(names,"、"),effect
end
local function spellPower(item,level)
    local o=item.original or {}
    local base=tonumber(o.intensity) or 0
    local plus=tonumber(o.upgrade_plus) or 0
    return math.floor(base+plus*((tonumber(level) or 1)-1))
end
local function spellPanel(x,top,w,h,parent)
    local cap=w*59/609
    image("v2/newIntroUI/big_bkg1.png",x,top-cap/2,w,cap,parent)
    image("v2/newIntroUI/big_bkg2.png",x,top-cap-(h-2*cap)/2,w,h-2*cap,parent)
    local down=image("v2/newIntroUI/big_bkg1.png",x,top-h+cap/2,w,cap,parent)
    if down then down:setFlipY(true) end
end
local function drawSpellIntro(item,e)
    M.spellHits={};M.introHits={};M.introScroll=nil
    local level=tonumber(e and e.level) or 1
    local entry=(e and e.uid) and e or nil
    local owns=entry~=nil
    local top=tonumber(item.top_level) or 10
    local advance=require('local_combat_rules').advance[tostring(item.id)]
    local canAdvance=owns and advance and tonumber(item.quality)==5 and not e.advanced
    local canUpgrade=owns and not canAdvance and level<top
    local function close()
        M.spellIntro=nil;M.spellScroll=nil;M.spellHits={}
        M.selected=nil
        if M.preview then
            M.preview=nil;ui.navigate(M.returnPage or "home");return
        end
        ui.render()
    end
    local function hit(x,y,w,h,action)
        table.insert(M.spellHits,{x=x,y=y,w=w,h=h,action=action})
    end

    fill(0,0,960,540,{0,0,0,180})
    image("v2/messageUI/frame1.png",480,275,600,520)

    image("v2/introUI/close1.png",747,500,52,50)
    hit(721,474,52,50,close)

    label(item.name,480,498,30,SPELL_TEXT,nil,true)

    local node=icon(item,280,412,120,nil,level)
    if node then
        local size=node:getContentSize()
        local empty=CCSprite:create("v2/newIntroUI/star_bkg.png")
        local es=empty:getContentSize()
        empty:setAnchorPoint(CCPointMake(0,0))
        empty:setPosition(CCPointMake(size.width*.1,size.height*.1))
        empty:setScale(.8*size.width/es.width)
        node:addChild(empty)
        local quality=tonumber(item.quality) or 0
        if quality>0 then
            local stars=CCSprite:create("v2/introUI/stars.png")
            local ss=stars:getContentSize()
            stars:setTextureRect(CCRectMake(0,0,ss.width*math.min(1,quality/5),ss.height))
            stars:setAnchorPoint(CCPointMake(0,0))
            stars:setPosition(CCPointMake(size.width*.1,size.height*.1))
            stars:setScale(.8*size.width/ss.width)
            node:addChild(stars)
        end
    end

    image("v2/introUI/level.png",390,450,36,36)
    label(tostring(level),411,450,24,SPELL_TEXT)
    image("v2/introUI/skill_strong.png",480,450,36,36)
    label(tostring(spellPower(item,level)),501,450,24,SPELL_TEXT)

    local buttonPic=canAdvance and "v2/enhanceUI/up_2.png" or "v2/newIntroUI/upgrade1.png"
    local buttonNode=image(buttonPic,680,410,140,70)
    local advanceReady=canAdvance and level>=tonumber(advance.min_level)
    if (canAdvance and not advanceReady) or (not canAdvance and not canUpgrade) then
        if buttonNode then buttonNode:setColor(ccc3(120,110,100)) end
    end
    hit(610,375,140,70,function()
        if canAdvance then
            if not advanceReady then
                M.alert="法术达到"..advance.min_level.."级后才能进阶。"
                ui.render();return
            end
            confirm("进阶将消耗未装备材料："..advance.material_list.."。装备后增加 "..
                advance.hp_plus.."%生命。","bag_advance",{uid=entry.uid})
            return
        end
        if not canUpgrade then
            M.alert=not owns and "拥有该法术后才能升级。" or "该法术已满级。"
            ui.render();return
        end
        upgrade(entry)
    end)

    local descLabel=label(item.description or "",210,345,22,SPELL_TEXT,nil,false,560)
    local descHeight=descLabel and descLabel:getContentSize().height or 26

    local bandTop=345-descHeight-6
    image("v2/newIntroUI/head_bkg.png",480,bandTop-34,560,68)
    image("v2/introUI/yuanfen_label.png",480,bandTop-35,100,61)
    local panelTop=bandTop-73
    spellPanel(480,panelTop,545,panelTop-16,nil)

    local names,effect=spellFateData(item)
    if names=="" then
        label("暂无仙缘",225,panelTop-11,22,{253,190,37})
    else
        local namesTop=panelTop-30
        label("与以下神仙有缘：",225,panelTop-11,22,{253,190,37})
        local nameLabel=label(names,225,namesTop,21,SPELL_TEXT,nil,false,500)
        local used=nameLabel and nameLabel:getContentSize().height or 24
        local effectTop=namesTop-used-16
        label("配缘效果：",225,effectTop,22,{253,190,37})
        label(effect~="" and effect or "无",225,effectTop-28,21,SPELL_TEXT)
    end
end

local function spellTouch(event,x,y)
    if not M.spellIntro then return false end
    if event==CCTOUCHBEGAN or event=="began" then
        for i=#(M.spellHits or {}),1,-1 do
            local h=M.spellHits[i]
            if x>=h.x and x<=h.x+h.w and y>=h.y and y<=h.y+h.h then h.action();return true end
        end
        if x<180 or x>780 or y<15 or y>535 then
            M.spellIntro=nil;M.spellScroll=nil;M.spellHits={};M.selected=nil
            if M.preview then M.preview=nil;ui.navigate(M.returnPage or "home");return true end
            ui.render()
        end
        return true
    elseif event==CCTOUCHMOVED or event=="moved" then
        return true
    elseif event==CCTOUCHENDED or event=="ended" then
        return true
    end
    return true
end

local function introTouch(event,x,y)
    if not M.intro then return false end
    if event==CCTOUCHBEGAN or event=="began" then
        for i=#(M.introHits or {}),1,-1 do
            local h=M.introHits[i]
            if x>=h.x and x<=h.x+h.w and y>=h.y and y<=h.y+h.h then h.action();return true end
        end
        if x<200 or x>760 or y<27 or y>513 then
            M.intro=nil;M.selected=nil;M.introScroll=nil;M.introGesture=nil;M.introClosePressed=nil
            ui.render();return true
        end
        if x>=700 and x<=765 and y>=455 and y<=520 then
            M.intro=nil;M.selected=nil;M.introScroll=nil;M.introGesture=nil;M.introClosePressed=nil
            ui.render();return true
        end
        if x>=218 and x<=742 and y>=48 and y<=468 then
            M.introGesture={x=x,y=y,offset=M.introScroll and M.introScroll.offset or 0,dragged=false}
        end
        return true
    elseif event==CCTOUCHMOVED or event=="moved" then
        local g=M.introGesture
        if g then
            if math.abs(y-g.y)>4 or math.abs(x-g.x)>4 then g.dragged=true end
            if g.dragged then setIntroOffset(g.offset+y-g.y) end
        end
        return true
    elseif event==CCTOUCHENDED or event=="ended" then
        if M.introClosePressed and x>=705 and x<=760 and y>=462 and y<=515 then
            M.intro=nil;M.selected=nil;M.introScroll=nil;M.introGesture=nil;M.introClosePressed=nil
        else
            M.introGesture=nil;M.introClosePressed=nil
        end
        ui.render();return true
    end
    return true
end
local function detail()
    local e=M.catalog and nil or own(M.selected)
    local item=M.catalog and data.items[M.selected] or e and data.items[e.key] or M.preview and data.items[M.preview]
    if not item then return end
    if item.category==4 then
        -- 法术详情完全交给原版独立页面，不再绘制包裹右侧的本地详情。
        M.spellIntro=item.key
        return
    end
    if M.reading then
        local textBody=item.name.."\n\n"..item.description.."\n\n原版获取途径\n"..(item.obtain or "").."\n\n本地玩法\n"..rule(item)
        local temp=label(textBody,12,0,19,MUTED,nil,false,650)
        local height=math.max(370,temp:getContentSize().height+30)
        root:removeChild(temp,true)
        local body=area(height,nil)
        label(textBody,12,355,19,MUTED,body,false,650)
        return
    end
    icon(item,289,445,76,nil,e and e.level)
    label(item.name,345,465,25)
    label(string.rep("★",item.quality),345,431,20,{255,194,51})
    label(e and ("等级 "..e.level.."    数量 "..e.count.."    "..heroName(e.hero))
        or M.preview and "已装备" or "原版资源图录",345,403,18)
    local c=area(370,nil)
    -- Detail body uses the lower portion, keeping controls and heading unobstructed.
    local preview={};local count=0
    for ch in string.gmatch(item.description,"[%z\1-\127\194-\244][\128-\191]*") do
        count=count+1;if count>65 then table.insert(preview,"…");break end
        table.insert(preview,ch)
    end
    label(table.concat(preview),12,268,18,MUTED,c,false,650)
    label("本地玩法",12,185,20,GOLD,c)
    label(rule(item),12,160,17,MUTED,c,false,650)
    button("完整介绍",745,448,154,function() M.reading=true;M.offset=0;ui.render() end)
    if M.catalog then
        button(item.price>0 and ("兑换 · "..item.price.." 银两") or "暂未接入",260,135,240,function()
            confirm("花费 "..item.price.." 银两兑换「"..item.name.."」？","bag_buy",{key=item.key})
        end,item.price>0)
        return
    end
    if not e then
        button("返回阵容",360,135,240,function() M.preview=nil;M.back() end)
        return
    end
    if item.category<=3 or (item.action=="trait" or item.action=="star") then
        button("装备 / 更换",250,135,145,function()
            M.choice="hero";M.page=1;ui.render()
        end)
        button("卸下",405,135,100,function() perform("bag_equip",{uid=e.uid,hero=0}) end,e.hero~=0)
        button("强化",515,135,112,function() upgrade(e) end,e.level<item.top_level)
        if item.category<=3 then
            local worn=#(e.stones or {})
            button(worn>0 and ("灵石 · "..worn.."/"..(e.max_sockets or maxSockets(item))) or "打孔 / 镶嵌",
                637,135,130,function()
                    if stone then stone.open(ui,state,e.uid) end
                end)
        end
        button("熔炼",777,135,115,function()
            confirm("熔炼将移除「"..item.name.."」，获得 "..math.max(1,item.quality)*e.level.." 颗精魄石。",
                "bag_smelt",{uid=e.uid})
        end,e.hero==0 and #(e.stones or {})==0)
    elseif item.action=="fragment" then
        button("合成",260,135,220,function()
            confirm("消耗10个同名碎片，合成对应装备？","bag_compose",{uid=e.uid})
        end,e.count>=10)
    else
        button(item.action=="material" and "兑换20银两" or "使用",260,135,220,function()
            if item.action=="train" then M.choice="train";M.page=1;ui.render()
            else confirm("消耗1个「"..item.name.."」？\n"..rule(item),"bag_use",{uid=e.uid}) end
        end,item.action~="reference" and item.action~="support_material" and item.action~="cheer_material")
    end
end
local function choices()
    local e=own(M.selected)
    if not e then M.choice=nil;return end
    local item=data.items[e.key]
    local list={}
    if M.choice=="gem" then
        for _,g in ipairs(state.inventory.entries) do
            local b=data.items[g.key]
            if b.category==5 and b.sub_type==item.category then table.insert(list,g) end
        end
    elseif M.choice=="spellSlot" then
        list={{id=2,name="第2法术格",level=""},{id=3,name="第3法术格",level=""}}
    else for _,h in ipairs(state.heroes) do table.insert(list,h) end end
    local max=math.max(1,math.ceil(#list/4));M.page=math.min(M.page,max)
    label(M.choice=="gem" and "选择灵石" or M.choice=="spellSlot" and "选择法术格" or "选择神仙",255,471,24)
    for i=(M.page-1)*4+1,math.min(#list,M.page*4) do
        local choice=list[i];local y=400-((i-1)%4)*69
        image("v2/packageUI/xinxilan.png",570,y,640,63)
        local title=M.choice=="gem" and (data.items[choice.key].name.."  "..choice.level.."级  ×"..choice.count) or M.choice=="spellSlot" and choice.name or (choice.name.."  "..choice.level.."级")
        label(title,280,y,22)
        button("选择",740,y-17,130,function()
            if M.choice=="gem" then M.intro=true;perform("bag_socket",{uid=e.uid,gem=choice.uid,pos=M.socketPos or 1})
            elseif M.choice=="train" then confirm("消耗1颗魂缘丹，让"..choice.name.."提升1级？","bag_use",{uid=e.uid,hero=choice.id})
            elseif M.choice=="spellSlot" then perform("bag_equip",{uid=e.uid,hero=M.targetHero,equip_pos=choice.id})
            elseif item.category==4 then M.targetHero=choice.id;M.choice="spellSlot";M.page=1;ui.render()
            else perform("bag_equip",{uid=e.uid,hero=choice.id}) end
        end)
    end
    if #list==0 then label("暂无匹配灵石，可在资源图录中兑换",270,330,22) end
    button("上一页",270,135,130,function() M.page=M.page-1;ui.render() end,M.page>1)
    label(M.page.."/"..max,550,151,18)
    button("下一页",720,135,130,function() M.page=M.page+1;ui.render() end,M.page<max)
end
local function listView()
    M.buttons={}
    local list={}
    if M.catalog then
        for _,item in pairs(data.items) do if item.category==M.tab then table.insert(list,{key=item.key,level=1}) end end
    else
        for _,e in ipairs(state.inventory.entries) do
            local b=data.items[e.key]
            local allowed=true
            if M.equipHero and b.category==4 then
                for _,h in ipairs(state.heroes) do
                    if h.id==M.equipHero and h.skill_id==b.id then allowed=false end
                end
                for _,other in ipairs(state.inventory.entries) do
                    if other.hero==M.equipHero and other.key==e.key and other.equip_pos~=M.equipPos then allowed=false end
                end
                if e.hero==M.equipHero then allowed=false end
            end
            if allowed and b.category==M.tab and (not M.smelt or b.category<=4 and e.hero==0 and #(e.stones or {})==0) then table.insert(list,e) end
        end
    end
    table.sort(list,function(a,b)
        local x,y=data.items[a.key],data.items[b.key]
        if x.category==5 and y.category==5 then
            local ae=(a.owner_uid or 0)>0
            local be=(b.owner_uid or 0)>0
            if ae~=be then return ae end
            if (a.level or 1)~=(b.level or 1) then return (a.level or 1)>(b.level or 1) end
            if x.sub_type~=y.sub_type then return x.sub_type<y.sub_type end
            return (a.uid or 0)<(b.uid or 0)
        end
        if x.quality~=y.quality then return x.quality>y.quality end
        if x.id~=y.id then return x.id<y.id end
        return (a.uid or 0)<(b.uid or 0)
    end)
    local max=math.max(1,math.ceil(#list/20));M.page=math.min(M.page,max)
    label(M.equipHero and (heroName(M.equipHero).." · 第"..M.equipPos.."法术格") or ((M.smelt and "熔炼 · " or "")..(M.catalog and "资源图录" or "我的包裹").."  "..#list.."项"),245,504,15)
    button(M.catalog and "我的包裹" or "资源图录",550,490,120,function()
        M.equipHero=nil;M.equipPos=nil;M.catalog=not M.catalog;M.smelt=false;reset();ui.render()
    end)
    button("‹",688,490,46,function() M.page=M.page-1;M.offset=0;ui.render() end,M.page>1)
    label(M.page.."/"..max,768,506,14,GOLD,nil,true)
    button("›",803,490,46,function() M.page=M.page+1;M.offset=0;ui.render() end,M.page<max)
    local shown={}
    for i=(M.page-1)*20+1,math.min(#list,M.page*20) do table.insert(shown,list[i]) end
    local stoneList=shown[1] and data.items[shown[1].key].category==5 or false
    local pitch=stoneList and 92 or 98
    local top=stoneList and 383 or 370
    local c=area(#shown*pitch,function(x,y,offset)
        local i=math.floor((top-(y-121-offset))/pitch)+1
        local e=shown[i];if not e then return end
        local item=data.items[e.key]
        if item.category==5 then
            M.selected=e.uid;M.offset=0;M.reading=false;M.intro=not M.catalog
            if M.catalog then M.intro=nil end
            M.introScroll=nil
            ui.render();return
        end
        if e.socketed and stone then
            stone.open(ui,state,e.owner_uid);return
        end
        M.selected=M.catalog and e.key or e.uid;M.offset=0;M.reading=false
        if item.category==4 then
            if M.smelt and e.uid then
                -- 熔炼模式不再经过旧法术详情，直接确认，保留原熔炼产出。
                M.selected=e.uid
                confirm("熔炼将移除「"..item.name.."」，获得 "..
                    math.max(1,item.quality)*e.level.." 颗精魄石。","bag_smelt",{uid=e.uid})
                return
            end
            -- 法术使用原版独立详情页，不再进入包裹右侧的本地详情布局。
            M.spellIntro=item.key;M.intro=false;M.introScroll=nil
        else
            M.intro=M.catalog==false and item.category<=3
            if not M.intro then M.introScroll=nil end
        end
        ui.render()
    end)
    for i,e in ipairs(shown) do
        local item=data.items[e.key];local y=top-(i-1)*pitch-46
        if item.category==5 then
            image("v2/packageUI/xinxilan.png",342,y,680,100,c)
            icon(item,64,y,74,c,e.level)
            label(item.name,124,y+18,27,GOLD,c)
            image("v2/packageUI/level.png",124,y-18,34,34,c)
            label(tostring(e.level or 1),156,y-18,26,{242,191,49},c)
            image("v2/packageUI/"..(STONE_STAT_ICON[item.sub_type] or "CHAR_gong")..".png",
                286,y-18,34,34,c)
            label(string.format("%.1f%%",(tonumber(e.percent) or 0)*100),
                318,y-18,26,{242,191,49},c)
            if M.catalog then
                label("点击查看介绍",590,y+18,20,OWNER,c,true)
            else
                if e.owner_hero_name and e.owner_hero_name~="" then
                    label("装备于"..e.owner_hero_name,590,y+22,20,OWNER,c,true)
                end
                local canUpgrade=(e.level or 1)<(e.max_level or 13) and (tonumber(state.level) or 1)>=10
                local n=image("v2/enhanceUI/up1.png",590,y-20,132,56,c)
                if not canUpgrade and n then n:setColor(ccc3(120,110,100)) end
                registerButton("upgrade"..e.uid,"stoneupgrade",e.uid,590,y-20,132,56,n)
            end
        else
            image("v2/packageUI/xinxilan.png",342,y,680,92,c)
            icon(item,49,y,74,c,e.level)
            label(item.name,108,y+23,22,GOLD,c)
            if item.category<=4 then
                label(string.rep("★",item.quality),315,y+25,18,{255,194,51},c)
                label(M.catalog and ("等级上限 "..item.top_level) or (e.hero==0 and "未装备" or "装备于"..heroName(e.hero)),475,y+25,16,MUTED,c)
                label("级 "..e.level,108,y-20,21,{242,191,49},c)
                local attr=({"攻 ","防 ","命 ","效果 "})[item.category]
                label(M.catalog and "点击查看介绍" or (attr..e.value..(item.category==4 and not item.active and "%" or "")),217,y-20,20,{242,191,49},c)
                if not M.catalog then
                    if item.category<=3 then
                        local n=image("v2/stoneUI/putin_btn1.png",452,y-20,125,47,c)
                        registerButton("stone"..e.uid,"stone",e.uid,452,y-20,125,47,n)
                    end
                    local n=image(M.equipHero and item.category==4 and "v2/charPositionUI/change1.png" or item.category==4 and "v2/enhanceUI/up1.png" or "v2/packageUI/enhance1.png",594,y-20,125,33,c)
                    registerButton("enhance"..e.uid,"enhance",e.uid,594,y-20,125,33,n)
                end
            else
                label(M.catalog and (item.action=="reference" and "原版资料" or "可兑换")
                    or (e.socketed and ("已镶嵌于 "..(e.owner_name or "装备"))
                        or ("数量: "..e.count)),
                    108,y-20,21,{242,191,49},c)
                label(item.action=="fragment" and "合成" or "查看",550,y,19,GOLD,c)
            end
        end
    end
    if #list==0 then
        scroll=nil
        label(M.smelt and "暂无可熔炼物品" or "包裹中暂无此类物品",570,340,25,GOLD,nil,true)
        if not state.inventory.claimed then
            button("领取入门包裹",420,245,300,function()
                confirm("领取武器、防具、法宝、法术、灵石与道具各类入门物资，每份存档限领一次。",
                    "bag_claim",{})
            end)
        else label("可在资源图录中使用银两兑换",570,275,20,MUTED,nil,true) end
    end
end
local function drawModal()
    if M.alert then
        scroll=nil;ui.clearHits()
        fill(0,0,960,540,{0,0,0,170})
        image("v2/packageUI/board_bkg.png",480,295,650,250)
        label(M.alert,190,375,22,GOLD,nil,false,580)
        button("确定",390,190,180,function() M.alert=nil;ui.render() end)
    elseif M.confirm then
        scroll=nil;ui.clearHits()
        fill(0,0,960,540,{0,0,0,170})
        image("v2/packageUI/board_bkg.png",480,295,650,270)
        label(M.confirm.message,190,385,23,GOLD,nil,false,580)
        label("银两 "..state.silver,190,235,18,MUTED)
        if M.confirm.op then
            button("取消",220,170,180,function() M.confirm=nil;ui.render() end)
            button("确定",560,170,180,function() perform(M.confirm.op,M.confirm.args) end)
        else
            button("确定",390,170,180,function() M.confirm=nil;ui.render() end)
        end
    end
end
function M.draw(context,player)
    ui,state,root=context,player,context.root;scroll=nil;M.buttons={}
    M.overlayFrom=nil;M.overlayEntry=nil
    if M.selected and not M.catalog and type(M.selected)=="number" and not own(M.selected) then
        M.selected=nil;M.choice=nil;M.offset=0;M.intro=nil;M.introScroll=nil
    end
    if M.preview and data.items[M.preview] and data.items[M.preview].category==4 then
        M.spellIntro=M.preview
    end
    if M.spellIntro and not data.items[M.spellIntro] then M.spellIntro=nil end
    frame()
    local stoneOpen=stone and stone.isOpen()
    if not stoneOpen and M.selected and not M.catalog and type(M.selected)=="number" and not M.choice and not M.reading then
        local selectedEntry=own(M.selected)
        local selectedItem=selectedEntry and data.items[selectedEntry.key]
        if selectedItem and (selectedItem.category<=3 or selectedItem.category==5) then M.intro=true end
    end
    local introEntry=(not stoneOpen) and M.intro and not M.choice and not M.reading and own(M.selected)
    local introItem=introEntry and data.items[introEntry.key]
    if M.choice then choices()
    elseif M.spellIntro then listView()
    elseif introItem then listView()
    elseif M.selected or M.preview then detail()
    else listView() end
    label("银两 "..state.silver.."    "..(ui.busy and "正在保存…" or ui.error or ui.notice or ""),241,103,13,MUTED)
    if ui.failed then
        ui.hit(235,90,650,28,function() ui.send("state",{}) end,true,nil,true)
    end
    if introItem then
        if introItem.category==5 then drawStoneIntro(introItem,introEntry)
        else drawIntro(introItem,introEntry) end
    end
    if M.spellIntro then
        local spellItem=data.items[M.spellIntro]
        local spellEntry
        if M.selected and type(M.selected)=="number" then spellEntry=own(M.selected) end
        if not spellEntry and not M.catalog then
            for _,entry in ipairs(state.inventory.entries) do
                if entry.key==M.spellIntro then spellEntry=entry;break end
            end
        end
        if not spellEntry then
            spellEntry={key=M.spellIntro,level=1,count=0,hero=0}
        end
        drawSpellIntro(spellItem,spellEntry)
    end
    drawModal()
    if enhance.isOpen() then enhance.draw(ui,state) end
    if stone and stone.isOpen() then stone.draw(ui,state) end
    if stoneUpgrade and stoneUpgrade.isOpen() and not (stone and stone.isOpen()) then
        stoneUpgrade.draw(ui,state)
    end
end
function M.openDetailOverlay(context,player,opts)
    ui,state,root=context,player,context.root
    if stone then stone.close() end
    if stoneUpgrade then stoneUpgrade.close() end
    M.overlayFrom="lineup";M.overlayEntry=opts.entry
    M.catalog=false;M.choice=nil;M.confirm=nil;M.alert=nil;M.reading=false;M.offset=0
    M.tab=opts.tab or 1;M.equipHero=nil;M.equipPos=nil
    M.introScroll=nil;M.spellScroll=nil;M.spellHits={};M.introHits={}
    if opts.key then
        M.spellIntro=opts.key;M.selected=opts.uid;M.preview=nil;M.intro=false
    else
        M.spellIntro=nil;M.selected=opts.uid;M.preview=nil;M.intro=true
    end
end
function M.overlayOpen() return M.overlayFrom~=nil end
function M.closeOverlay()
    M.overlayFrom=nil;M.overlayEntry=nil
    M.spellIntro=nil;M.intro=nil;M.selected=nil;M.preview=nil
    M.spellScroll=nil;M.spellHits={};M.introScroll=nil;M.introHits={}
    M.alert=nil;M.confirm=nil;M.choice=nil;M.reading=false
    if stone then stone.close() end
    if stoneUpgrade then stoneUpgrade.close() end
end
function M.backOverlay()
    if stone and stone.isOpen() then stone.back();ui.render();return end
    if stoneUpgrade and stoneUpgrade.isOpen() then stoneUpgrade.back();ui.render();return end
    if M.alert then M.alert=nil
    elseif M.confirm then M.confirm=nil
    else M.closeOverlay();ui.render();return end
    ui.render()
end
function M.drawOverlay(context,player)
    if not M.overlayFrom then return end
    ui,state,root=context,player,context.root;scroll=nil
    local entry=M.selected and own(M.selected)
    if M.spellIntro then
        local item=data.items[M.spellIntro]
        if not item then M.closeOverlay();return end
        local e=entry or M.overlayEntry
        if not e then
            for _,x in ipairs(state.inventory.entries) do
                if x.key==M.spellIntro then e=x;break end
            end
        end
        if not e then e={key=M.spellIntro,level=1,count=0,hero=0} end
        drawSpellIntro(item,e)
    elseif M.intro then
        local item=entry and data.items[entry.key]
        if not item then M.closeOverlay();return end
        if item.category==5 then drawStoneIntro(item,entry) else drawIntro(item,entry) end
    else
        M.overlayFrom=nil;return
    end
    drawModal()
    if stone and stone.isOpen() then stone.draw(ui,state) end
    if stoneUpgrade and stoneUpgrade.isOpen() and not (stone and stone.isOpen()) then
        stoneUpgrade.draw(ui,state)
    end
end
function M.touchOverlay(event,x,y)
    if M.confirm or M.alert then return false end
    if enhance.isOpen() then return false end
    if stone and stone.isOpen() then return stone.touch(event,x,y) end
    if stoneUpgrade and stoneUpgrade.isOpen() then return stoneUpgrade.touch(event,x,y) end
    if M.spellIntro then return spellTouch(event,x,y) end
    if M.intro then return introTouch(event,x,y) end
    return false
end
function M.afterUpdate(player)
    state=player
    if stone and stone.isOpen() then stone.afterUpdate(player) end
    if stoneUpgrade and stoneUpgrade.isOpen() and not (stone and stone.isOpen()) then
        stoneUpgrade.afterUpdate(player)
    end
end
function M.open()
    M.returnPage=nil;M.equipHero=nil;M.equipPos=nil;M.equipPending=nil;M.tab=1;M.catalog=false;M.smelt=false;M.reading=false;reset()
end
function M.back()
    gesture=nil
    if enhance.isOpen() then enhance.close();ui.render();return end
    if stone and stone.isOpen() then stone.back();ui.render();return end
    if stoneUpgrade and stoneUpgrade.isOpen() then stoneUpgrade.back();ui.render();return end
    if M.alert then M.alert=nil
    elseif M.confirm then M.confirm=nil
    elseif M.spellIntro then
        M.spellIntro=nil;M.spellScroll=nil;M.spellHits={};M.selected=nil
        if M.preview then M.preview=nil;ui.navigate(M.returnPage or "home");return end
    elseif M.intro then M.intro=nil;M.selected=nil;M.introScroll=nil
    elseif M.reading then M.reading=false;M.offset=0
    elseif M.choice then M.choice=nil
    elseif M.preview then M.preview=nil;ui.navigate(M.returnPage or "home");return
    elseif M.selected then M.selected=nil;M.offset=0
    else ui.navigate(M.returnPage or "home");return end
    ui.render()
end
function M.touch(event,x,y)
    if M.confirm or M.alert then return false end
    if enhance.isOpen() then return false end
    if stone and stone.isOpen() then return stone.touch(event,x,y) end
    if stoneUpgrade and stoneUpgrade.isOpen() then return stoneUpgrade.touch(event,x,y) end
    if M.spellIntro then return spellTouch(event,x,y) end
    if M.intro then return introTouch(event,x,y) end
    if not scroll then return false end
    local began=event==CCTOUCHBEGAN or event=="began"
    local moved=event==CCTOUCHMOVED or event=="moved"
    local ended=event==CCTOUCHENDED or event=="ended"
    local button=buttonAt(x,y)
    if began then
        if button then
            M.pressKey=button.key;M.hoverKey=button.key;ui.render();return true
        end
        M.hoverKey=nil
        -- Detail controls are outside the draggable text region.
        local minY=M.selected and not M.reading and 190 or 121
        local maxY=M.selected and not M.reading and 390 or 490
        if x>=235 and x<=919 and y>=minY and y<=maxY then
            gesture={x=x,y=y,offset=M.offset,dragged=false};return true
        end
    elseif M.pressKey then
        if moved then
            M.hoverKey=(button and button.key==M.pressKey) and M.pressKey or nil
            ui.render();return true
        elseif ended then
            local key=M.pressKey;M.pressKey=nil;M.hoverKey=nil
            if button and button.key==key then performButton(button) end
            ui.render();return true
        else
            M.pressKey=nil;M.hoverKey=nil;ui.render();return true
        end
    elseif moved and not gesture then
        local key=button and button.key or nil
        if key~=M.hoverKey then M.hoverKey=key;ui.render() end
        return key~=nil
    elseif gesture then
        local g=gesture
        if moved then
            if math.abs(y-g.y)>7 or math.abs(x-g.x)>7 then g.dragged=true end
            if g.dragged then setOffset(g.offset+y-g.y) end
        elseif ended then
            gesture=nil
            if not g.dragged and y>=121 and y<=491 and x>=235 and x<=919 and scroll.tap then scroll.tap(x,y,M.offset) end
        else gesture=nil end
        return true
    end
    return false
end
return M
