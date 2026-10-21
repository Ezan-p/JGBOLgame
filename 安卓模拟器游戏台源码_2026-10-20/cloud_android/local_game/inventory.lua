-- Original packageUI art and proportions; persistent local inventory actions.
local data=require("local_inventory_data")
local enhance=require("local_enhance")
local M={tab=1,offset=0,page=1,catalog=false}
local ui,state,root,scroll,gesture
local GOLD={255,224,164}
local MUTED={204,180,148}
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
end
local function own(uid)
    if type(uid)~="number" then return end
    for _,e in ipairs(state.inventory.entries) do if e.uid==uid then return e end end
end
local function heroName(id)
    for _,h in ipairs(state.heroes) do if h.id==id then return h.name end end
    return "未装备"
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
local function reset()
    M.selected=nil; M.choice=nil; M.confirm=nil; M.reading=false; M.offset=0; M.page=1; M.preview=nil; gesture=nil
end
local function upgrade(e)
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
    if a=="equip" then return "强化增加装备属性；每件装备可镶嵌1颗同类灵石。装备后参与战斗。" end
    if a=="spell" then
        return "自带法术不可替换。第2、3格可装配法术，不限主动或被动；同一神仙不可重复装备同名法术。"
    end
    if a=="star" then return "原生法术觉醒后可在演武堂装备，最多五颗，同类不重复。" end
    if a=="trait" then return "每位神仙最多四项特技，同类不能重复；前往阵容的演武堂可兑换、装备和升级。" end
    if a=="cheer_material" then return "在演武堂修炼页，用于助阵法术进修。" end
    if a=="gem" then return "3颗同类同级灵石合成1颗高一级灵石，最高10级。镶嵌提升对应装备属性，卸下完整归还。" end
    if a=="fragment" then return "10个同名碎片合成1件对应装备。" end
    if a=="energy" then return "使用恢复 "..item.original.strength_plus.." 点体力，上限60。体力已满时不消耗。" end
    if a=="experience" then return "使用增加行者经验 "..item.original.experience_plus.."。" end
    if a=="train" then return "选择一名神仙提升1级，最高20级。" end
    if a=="material" then return "熔炼装备或法术获得；每颗可兑换20银两。" end
    if a=="support_material" then return "在阵容的助阵页面消耗乾坤符箓，为八卦阵位进阶。" end
    return "所属系统尚未接入。可查阅原版资料，暂不提供兑换和使用。"
end
local function detail()
    local e=M.catalog and nil or own(M.selected)
    local item=M.catalog and data.items[M.selected] or e and data.items[e.key] or M.preview and data.items[M.preview]
    if not item then return end
    if M.reading then
        local textBody=item.name.."\n\n"..item.description.."\n\n原版获取途径\n"..(item.obtain or "")..(item.category==4 and "\n\n装配规则\n" or "\n\n本地玩法\n")..rule(item)
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
        or M.preview and "自带法术 · 已装配" or "原版资源图录",345,403,18)
    local c=area(370,nil)
    -- Detail body uses the lower portion, keeping controls and heading unobstructed.
    local preview={};local count=0
    for ch in string.gmatch(item.description,"[%z\1-\127\194-\244][\128-\191]*") do
        count=count+1;if count>65 then table.insert(preview,"…");break end
        table.insert(preview,ch)
    end
    label(table.concat(preview),12,268,18,MUTED,c,false,650)
    label(item.category==4 and "装配规则" or "本地玩法",12,185,20,GOLD,c)
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
    if item.category<=4 or (item.action=="trait" or item.action=="star") then
        button("装备 / 更换",250,135,145,function()
            if M.equipHero and item.category==4 then replaceSpell(e)
            else M.choice="hero";M.page=1;ui.render() end
        end)
        button("卸下",405,135,100,function() perform("bag_equip",{uid=e.uid,hero=0}) end,e.hero~=0)
        button(item.category==4 and "升级" or "强化",515,135,112,function() upgrade(e) end,e.level<item.top_level)
        if item.category<=3 then
            button(e.gem>0 and ("卸石 · "..e.gem.."级") or "镶嵌",637,135,130,function()
                if e.gem>0 then perform("bag_unsocket",{uid=e.uid})
                else M.choice="gem";M.page=1;ui.render() end
            end)
        end
        if item.category==4 then
            local rule=require('local_combat_rules').advance[tostring(item.id)]
            if rule then button(e.advanced and '已进阶' or '进阶',637,135,130,function()
                confirm('进阶将消耗未装备材料：'..rule.material_list..'。装备后增加 '..rule.hp_plus..'%生命。','bag_advance',{uid=e.uid})
            end,not e.advanced and e.level>=tonumber(rule.min_level)) end
        end
        button("熔炼",777,135,115,function()
            confirm("熔炼将移除「"..item.name.."」，获得 "..math.max(1,item.quality)*e.level.." 颗精魄石。",
                "bag_smelt",{uid=e.uid})
        end,item.category<=4 and e.hero==0 and e.gem==0)
    elseif item.category==5 or item.action=="fragment" then
        button("合成",260,135,220,function()
            confirm(item.category==5 and "消耗3颗同类同级灵石，合成1颗高一级灵石？"
                or "消耗10个同名碎片，合成对应装备？","bag_compose",{uid=e.uid})
        end,e.count>=(item.category==5 and 3 or 10) and (item.category~=5 or e.level<10))
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
            if M.choice=="gem" then perform("bag_socket",{uid=e.uid,gem=choice.uid})
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
            if allowed and b.category==M.tab and (not M.smelt or b.category<=4 and e.hero==0 and e.gem==0) then table.insert(list,e) end
        end
    end
    table.sort(list,function(a,b)
        local x,y=data.items[a.key],data.items[b.key]
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
    local c=area(#shown*98,function(x,y,offset)
        local i=math.floor((370-(y-121-offset))/98)+1
        local e=shown[i];if not e then return end
        local item=data.items[e.key]
        local rowY=370-(i-1)*98
        local localY=y-121-offset
        if not M.catalog and not M.smelt and item.category<=4 and x>764 and localY<rowY-42 then
            if M.equipHero and item.category==4 then
                replaceSpell(e)
            else upgrade(e) end
        elseif not M.catalog and not M.smelt and item.category<=3 and x>624 and localY<rowY-42 then
            M.selected=e.uid;M.choice="gem";M.page=1;M.offset=0;ui.render()
        else
            M.selected=M.catalog and e.key or e.uid;M.offset=0;M.reading=false;ui.render()
        end
    end)
    for i,e in ipairs(shown) do
        local item=data.items[e.key];local y=370-(i-1)*98-46
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
                if item.category<=3 then image("v2/stoneUI/putin_btn1.png",452,y-20,125,33,c) end
                image(M.equipHero and item.category==4 and "v2/charPositionUI/change1.png" or item.category==4 and "v2/enhanceUI/up1.png" or "v2/packageUI/enhance1.png",594,y-20,125,33,c)
            end
        else
            label(M.catalog and (item.action=="reference" and "原版资料" or "可兑换") or ("数量: "..e.count..(item.category==5 and ("    "..e.level.."级") or "")),108,y-20,21,{242,191,49},c)
            label(item.category==5 and "合成 / 镶嵌" or item.action=="fragment" and "合成" or "查看",550,y,19,GOLD,c)
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
function M.draw(context,player)
    ui,state,root=context,player,context.root;scroll=nil
    if M.selected and not M.catalog and type(M.selected)=="number" and not own(M.selected) then
        M.selected=nil;M.choice=nil;M.offset=0
    end
    frame()
    if M.choice then choices() elseif M.selected or M.preview then detail() else listView() end
    label("银两 "..state.silver.."    "..(ui.busy and "正在保存…" or ui.error or ui.notice or ""),241,103,13,MUTED)
    if ui.failed then
        ui.hit(235,90,650,28,function() ui.send("state",{}) end,true,nil,true)
    end
    if M.confirm then
        scroll=nil;ui.clearHits()
        fill(0,0,960,540,{0,0,0,170})
        image("v2/packageUI/board_bkg.png",480,295,650,270)
        label(M.confirm.message,190,385,23,GOLD,nil,false,580)
        label("银两 "..state.silver,190,235,18,MUTED)
        button("取消",220,170,180,function() M.confirm=nil;ui.render() end)
        button("确定",560,170,180,function() perform(M.confirm.op,M.confirm.args) end)
    end
    if enhance.isOpen() then enhance.draw(ui,state) end
end
function M.open()
    M.returnPage=nil;M.equipHero=nil;M.equipPos=nil;M.equipPending=nil;M.tab=1;M.catalog=false;M.smelt=false;M.reading=false;reset()
end
function M.back()
    gesture=nil
    if enhance.isOpen() then enhance.close();ui.render();return end
    if M.confirm then M.confirm=nil
    elseif M.reading then M.reading=false;M.offset=0
    elseif M.choice then M.choice=nil
    elseif M.preview then M.preview=nil;ui.navigate(M.returnPage or "home");return
    elseif M.selected then M.selected=nil;M.offset=0
    else ui.navigate(M.returnPage or "home");return end
    ui.render()
end
function M.touch(event,x,y)
    if enhance.isOpen() then return false end
    if not scroll then return false end
    if event==CCTOUCHBEGAN or event=="began" then
        -- Detail controls are outside the draggable text region.
        local minY=M.selected and not M.reading and 190 or 121
        local maxY=M.selected and not M.reading and 390 or 490
        if x>=235 and x<=919 and y>=minY and y<=maxY then
            gesture={x=x,y=y,offset=M.offset,dragged=false};return true
        end
    elseif gesture then
        local g=gesture
        if event==CCTOUCHMOVED or event=="moved" then
            if math.abs(y-g.y)>7 or math.abs(x-g.x)>7 then g.dragged=true end
            if g.dragged then setOffset(g.offset+y-g.y) end
        elseif event==CCTOUCHENDED or event=="ended" then
            gesture=nil
            if not g.dragged and y>=121 and y<=491 and x>=235 and x<=919 and scroll.tap then scroll.tap(x,y,M.offset) end
        else gesture=nil end
        return true
    end
    return false
end
return M
