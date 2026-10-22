-- Original cheerSquadUI.lua layout (1061 reference geometry + 1263 refine panel).
-- All visible art, labels and percentages come from the original APK resources.
local data=require('local_lineup_data')
local inventoryData=require('local_inventory_data')
local M={slot=1,panel=nil,page=1,targetPage=1,tab='position'}
local ui,state,root
local GOLD={244,221,173}
local BROWN={250,172,90}
local GRAY={240,220,196}
local GREEN={178,255,63}
local RED={241,67,21}
local MUTED={112,112,112}
local WHITE={255,255,255}
local STATS={'hp','attack','defense','magic'}
local PIC={hp='health',attack='damage',defense='defence',magic='mana'}
local SHORT={hp='命',attack='攻',defense='防',magic='法'}
local LONG={hp='生命',attack='攻击',defense='防御',magic='法力'}
local NAMES={'乾','坤','震','巽','坎','离','艮','兑'}

local function image(file,x,y,w,h,parent)
    local n=CCSprite:create(file);if not n then return nil end
    local s=n:getContentSize()
    n:setScaleX(w/s.width);n:setScaleY((h or w*s.height/s.width)/s.height)
    n:setPosition(CCPointMake(x,y));(parent or root):addChild(n);return n
end
local function label(t,x,y,size,color,parent,center,width)
    local n
    if width then n=CCLabelTTF:create(tostring(t),'Arial',size,CCSizeMake(width,0),kCCTextAlignmentLeft)
    else n=CCLabelTTF:create(tostring(t),'Arial',size) end
    n:setAnchorPoint(CCPointMake(center and .5 or 0,width and 1 or .5))
    n:setPosition(CCPointMake(x,y));n:setColor(ccc3(unpack(color or GOLD)))
    ;(parent or root):addChild(n);return n
end
local function atlas(info,x,y,w,h,parent)
    if not info then return nil end
    local n=CCSprite:create(info.file);if not n then return nil end
    local s=n:getContentSize();local cw,ch=s.width/info.columns,s.height/info.rows
    n:setTextureRect(CCRectMake((info.index-1)%info.columns*cw,math.floor((info.index-1)/info.columns)*ch,cw,ch))
    n:setScaleX(w/cw);n:setScaleY((h or w*ch/cw)/ch)
    n:setPosition(CCPointMake(x,y));(parent or root):addChild(n);return n
end
local function hit(x,y,w,h,fn,node,enabled)
    ui.hit(x-w/2,y-h/2,w,h,fn,enabled~=false,node)
end
local function control(t,x,y,w,fn,enabled)
    local n=image('v2/soulExchangeUI/btn_bkg1.png',x,y,w,40)
    label(t,x,y,17,enabled==false and {125,115,105} or GOLD,nil,true)
    hit(x,y,w,42,fn,n,enabled~=false)
end
local function owned(id)
    for _,h in ipairs(state.heroes or {}) do if h.id==id then return h end end
end
local function entry(id) return data.heroes[tostring(id)] end
local function slot() return (state.support and state.support.slots or {})[M.slot] end
local function supportHero() local s=slot();return s and owned(s.hero) end
local function targetHero() local s=slot();return s and owned(s.target_hero) end
local function panelClose() M.panel=nil;M.confirm=nil;ui.render() end
local function buyMaterial(back)
    local item=inventoryData.items.i1015
    M.confirm={text='花费'..(item.price*25)..'银两兑换25张乾坤符箓？\n当前银两：'..(state.silver or 0),
        back=back, action=function()
            M.panel=back;M.confirm=nil;ui.send('support_buy_material',{slot=M.slot,count=25})
        end}
    M.panel='confirm';ui.render()
end
local function vertical(value,x,top,size,active)
    local chars={}
    for ch in string.gmatch(value,"[%z\1-\127\194-\244][\128-\191]*") do table.insert(chars,ch) end
    local step=24
    for i,ch in ipairs(chars) do
        label(ch,x,top-(i-1)*step,size,active and WHITE or MUTED,nil,true)
    end
end
local function stars(x,y,quality)
    local n=CCSprite:create('v2/introUI/stars.png');if not n then return end
    local s=n:getContentSize();n:setTextureRect(CCRectMake(0,0,s.width*quality/5,s.height))
    n:setScale(110/s.width);n:setPosition(CCPointMake(x,y));root:addChild(n)
end
local function drawTabs()
    for i=1,8 do
        local x=98+(i-1)*107.4
        local selected=i==M.slot
        local n=image('v2/cheerUI/'..i..(selected and '3.png' or '1.png'),x,498,82,69)
        hit(x,498,90,76,function() M.slot=i;M.panel=nil;ui.render() end,n)
    end
end

local function drawLeft()
    local s=slot();local h=supportHero()
    if h then
        atlas(entry(h.id) and entry(h.id).icon,312,345.6,88)
        local fates=h.fates or {}
        for i,f in ipairs(fates) do
            if i<=7 then
                local x=i>3 and 420+(i-4)*23 or 80+(i-1)*20
                image('v2/CharaterUI/hongdian.png',x,399,7,7)
                vertical(f.name,x,386,18,f.active)
            end
        end
        local values={h.hp or 0,h.attack or 0,h.defense or 0,h.magic or 0}
        for i,stat in ipairs(STATS) do
            local x=154+(i-1)*80
            image('v2/introUI/'..PIC[stat]..'.png',x,280,22,22)
            label(values[i],x+15,280,17,GRAY)
        end
        image('v2/charPositionUI/level_bkg.png',170,248,44,27)
        label(h.level or 1,170,248,18,GOLD,nil,true)
        image('v2/CharaterUI/expbar1.png',328,248,238,16)
        label('等级 '..(h.level or 1)..' / 20',328,248,11,GOLD,nil,true)
        hit(312,345.6,190,190,function() M.panel='hero';M.tab='position';ui.render() end)
    else
        image('v2/cheerUI/head_bkg.png',298,345.6,100,102)
        label('选择助阵神仙',298,266,18,BROWN,nil,true)
        local n=image('v2/charPositionUI/a_change1.png',298,215,142,40)
        hit(298,215,150,44,function() M.panel='choose';M.page=1;ui.render() end,n)
    end
end

local function drawPosition()
    local s=slot();if not s then return end
    label(s.name..'位进阶：'..s.level..'阶',140,200,17,BROWN,nil,true)
    local file=s.level>=s.max_level and 'succinct1.png' or 'upgrade1.png'
    local btn=image('v2/cheerUI/'..file,300,196,96,50)
    hit(300,196,100,54,function()
        if s.level>=s.max_level then M.panel='refine';M.tab='position' else M.panel='upgrade' end
        ui.render()
    end,btn)
    if s.level<s.max_level then
        label('消耗:',360,200,18,BROWN)
        image('v2/cheerUI/material.png',432,200,22,22)
        local enough=(state.support.material or 0)>=s.next_cost
        label((state.support.material or 0)..'/'..s.next_cost,448,200,18,enough and GREEN or RED)
    else
        label('消耗:',360,200,18,BROWN)
        image('v2/cheerUI/material.png',432,200,22,22)
        local enough=(state.support.material or 0)>=s.refine_cost.material
        label(s.refine_cost.material,448,200,18,enough and GREEN or RED)
        image('v2/money_gold.png',498,200,24,16)
        local goldOk=(state.gold or 0)>=s.refine_cost.gold
        label(s.refine_cost.gold,514,200,18,goldOk and GREEN or RED)
    end
    image('v2/common/small_label.png',302,148,460,60)
    for i,stat in ipairs(STATS) do
        local x=130+(i-1)*92
        image('v2/introUI/'..PIC[stat]..'.png',x,148,26,26)
        label(string.format('%.1f%%',(s.ratios[stat] or 0)*100),x+22,148,22,GRAY)
    end
    hit(300,200,240,30,function() buyMaterial(nil) end)
end

local function drawRight()
    local s=slot();if not s then return end
    local h=supportHero();local t=targetHero()
    local eligible=h and h.quality>=5
    if eligible then
        if t then atlas(entry(t.id) and entry(t.id).icon,846,372,84) end
    else
        image('v2/stoneUI/lock.png',810,372,74,63)
    end
    hit(810,372,130,110,function()
        if eligible then M.panel='target';M.page=1;ui.render() end
    end)
    local bonus=s.bonus or {}
    for i,stat in ipairs(STATS) do
        local y=245-(i-1)*32.4
        image('v2/introUI/'..PIC[stat]..'.png',750,y,24,24)
        label('+'..(bonus[stat] or 0),764,y,22,GREEN)
    end
end

local function drawMain()
    image('v2/cheerUI/bkg.png',480,292.4,960,495.2)
    drawTabs()
    local close=image('v2/introUI/close1.png',931,508,62,59)
    hit(931,508,66,64,function() M.back() end,close)
    local s=slot()
    if s then image('v2/cheerUI/letter'..M.slot..'.png',659,326,95,95) end
    drawLeft();drawPosition();drawRight()
    label('左侧卦位上的神仙，可以为上阵神仙配仙缘，五星神仙还可对指定的上阵神仙属性加成',
        480,104,20,{0,0,0},nil,true)
    if ui.busy or ui.error then label(ui.error or '正在保存…',480,520,15,GOLD,nil,true) end
end


local function beginPanel(alpha)
    drawMain()
    ui.clearHits()
    local mask=CCLayerColor:create(ccc4(0,0,0,alpha or 165));root:addChild(mask)
end
local function closeButton(x,y,fn,size)
    local n=image('v2/introUI/close1.png',x,y,size or 50,size and size*.95 or 47.5)
    hit(x,y,size or 52,size or 50,fn,n)
end

local function drawHeroMenu()
    beginPanel(90)
    local h=supportHero();if not h then M.panel=nil;return drawMain() end
    image('v2/charPositionUI/skill_small_bkg.png',480,300,620,340)
    label(h.name,480,424,25,BROWN,nil,true)
    stars(480,392,h.quality or 1)
    control('详情',330,330,140,function() M.panel='detail';ui.render() end)
    control('更换',480,330,140,function() M.panel='choose';M.page=1;ui.render() end)
    control('卸下',630,330,140,function()
        M.confirm={text='卸下'..h.name..'？相关仙缘与助阵加成将重新计算。',back='hero',action=function()
            M.panel=nil;M.confirm=nil;ui.send('support_assign',{slot=M.slot,hero=0})
        end}
        M.panel='confirm';ui.render()
    end)
    label('点击阵位页签可切换八卦；五星神仙才能指定受助阵位。',480,268,15,GRAY,nil,true)
    closeButton(740,430,panelClose,48)
end

local function drawDetail()
    beginPanel(165)
    local h=supportHero();if not h then M.panel=nil;return drawMain() end
    image('v2/introUI/intro_bkg.png',480,285,880,450)
    image('v2/introUI/small_label.png',480,470,680,50)
    label(h.name..' · 助阵神仙',480,470,24,BROWN,nil,true)
    label('等级 '..(h.level or 1)..'    品质 '..(h.quality or 1)..'星',480,428,20,GRAY,nil,true)
    label('生命 '..(h.hp or 0)..'    攻击 '..(h.attack or 0)..'    防御 '..(h.defense or 0)..'    法力 '..(h.magic or 0),
        480,400,18,GRAY,nil,true)
    label('仙缘',150,370,19,BROWN)
    local fates=h.fates or {}
    for i,f in ipairs(fates) do
        local y=344-math.floor((i-1)/2)*40
        local x=(i%2==1) and 170 or 520
        label((f.active and '已激活' or '未激活')..' · '..f.name,x,y,17,f.active and GREEN or MUTED)
    end
    label('助阵神仙只参与人物与法术仙缘，不激活装备仙缘。',480,170,15,BROWN,nil,true)
    closeButton(740,430,panelClose,48)
end

local function chooseList()
    local list={}
    for _,h in ipairs(state.heroes or {}) do
        if not h.active and not h.supporting then table.insert(list,h) end
    end
    table.sort(list,function(a,b)
        if (a.quality or 0)~=(b.quality or 0) then return (a.quality or 0)>(b.quality or 0) end
        return a.id<b.id
    end)
    return list
end

local function drawChoose()
    beginPanel(175)
    image('v2/introUI/intro_bkg.png',480,285,900,460)
    image('v2/introUI/small_label.png',480,482,720,50)
    label('选择助阵神仙',480,482,24,BROWN,nil,true)
    local list=chooseList();local maxpage=math.max(1,math.ceil(#list/8))
    M.page=math.max(1,math.min(M.page or 1,maxpage))
    for j=1,8 do
        local item=list[(M.page-1)*8+j]
        local y=445-(j-1)*44
        image('v2/charPositionUI/char_info.png',480,y,700,40)
        if item then
            atlas(entry(item.id) and entry(item.id).icon,156,y,38)
            label(item.name,190,y,19,BROWN)
            label((item.quality or 1)..'星 · '..(item.level or 1)..'级',380,y,17,GRAY)
            label(item.active and '出战中' or item.supporting and '助阵中' or '空闲',520,y,16,MUTED)
            control('选择',660,y,88,function()
                M.panel=nil;ui.send('support_assign',{slot=M.slot,hero=item.id})
            end)
        end
    end
    if #list==0 then label('暂无可助阵的神仙',480,300,22,GRAY,nil,true) end
    control('上一页',190,86,110,function() M.page=M.page-1;ui.render() end,M.page>1)
    label(M.page..' / '..maxpage,480,86,18,GRAY,nil,true)
    control('下一页',770,86,110,function() M.page=M.page+1;ui.render() end,M.page<maxpage)
    if #list==0 then control('前往召唤',480,150,160,function() M.panel=nil;ui.navigate('summon') end) end
    closeButton(842,486,panelClose,46)
end

local function drawTarget()
    beginPanel(175)
    image('v2/introUI/intro_bkg.png',480,285,900,460)
    image('v2/introUI/small_label.png',480,482,720,50)
    label('选择加成对象 · 每个出战阵位接受一位助阵',480,482,22,BROWN,nil,true)
    for i,id in ipairs(state.lineup or {}) do
        local h=owned(id)
        local y=448-(i-1)*44
        image('v2/charPositionUI/char_info.png',480,y,700,40)
        if h then
            atlas(entry(h.id) and entry(h.id).icon,156,y,38)
            label(h.name,190,y+6,19,BROWN)
            label('第'..i..'阵位 · '..(h.quality or 1)..'星',190,y-12,14,GRAY)
            local linked
            for _,s in ipairs(state.support.slots or {}) do
                if s.target==i then linked=s end
            end
            label(linked and (linked.name..'位助阵') or (slot().target==i and '当前加成对象' or '未关联'),520,y+2,16,linked and MUTED or GREEN)
            control(slot().target==i and '已选择' or '选择',670,y,110,function()
                M.panel=nil;ui.send('support_target',{slot=M.slot,target=i})
            end,slot().target~=i)
        end
    end
    control('取消关联',330,70,140,function() M.panel=nil;ui.send('support_target',{slot=M.slot,target=0}) end,slot().target~=0)
    closeButton(842,486,panelClose,46)
end

local function drawUpgrade()
    local s=slot();if not s or s.level>=s.max_level then M.panel='refine';return end
    beginPanel(170)
    image('v2/cheerUI/bkg_frame.png',480,300,500,515)
    image('v2/cheerUI/title_up.png',480,528,110,68)
    image('v2/cheerUI/'..M.slot..'4.png',380,440,80,80)
    image('v2/cheerUI/bkg_lv.png',600,447,210,43)
    label(s.name..'位阶数：',520,447,21,BROWN,nil,true)
    label(s.level..'阶',650,447,23,GRAY,nil,true)
    image('v2/cheerUI/inner_bkg.png',480,300,430,216)
    for i,stat in ipairs(STATS) do
        local y=380-(i-1)*29
        image('v2/introUI/'..PIC[stat]..'.png',300,y,26,26)
        label(string.format('%.1f%%',(s.ratios[stat] or 0)*100),332,y,20,BROWN)
        label(string.format('+%.1f%%',(s.next_increments[stat] or 0)*100),430,y,20,GREEN)
        label(string.format('%.1f%%',((s.ratios[stat] or 0)+(s.next_increments[stat] or 0))*100),518,y,20,BROWN)
    end
    label('提示: 阵法达到10阶后即可进行洗练，实现各属性转换',480,266,17,GRAY,nil,true)
    label('消耗:',350,232,21,BROWN)
    image('v2/cheerUI/material.png',408,232,24,24)
    local enough=(state.support.material or 0)>=s.next_cost
    label((state.support.material or 0)..'/'..s.next_cost,424,232,21,enough and GREEN or RED)
    hit(470,232,180,32,function() buyMaterial('upgrade') end)
    local up=image('v2/cheerUI/up1.png',480,148,200,66)
    hit(480,148,206,70,function() ui.send('support_upgrade',{slot=M.slot}) end,up,enough)
    closeButton(682,534,panelClose,48)
end

local function drawRefine()
    local s=slot();if not s then M.panel=nil;return end
    beginPanel(170)
    image('v2/cheerUI/bkg_frame2.png',480,300,540,492)
    image('v2/cheerUI/title_su.png',480,526,110,68)
    image('v2/cheerUI/'..M.slot..'4.png',330,444,80,80)
    image('v2/cheerUI/bkg_lv.png',560,450,210,43)
    label(s.name..'位阶数：',470,450,20,BROWN,nil,true)
    label(s.level..'阶',610,450,22,GRAY,nil,true)
    local positionTab=M.tab~='passive'
    local zw=image('v2/cheerUI/'..(positionTab and 'zw2.png' or 'zw1.png'),245,378,52,120)
    hit(245,378,56,124,function() M.tab='position';ui.render() end,zw)
    local bdo=image('v2/cheerUI/'..(positionTab and 'bdo1.png' or 'bdo2.png'),245,252,52,120)
    hit(245,252,56,124,function() M.tab='passive';ui.render() end,bdo)
    if positionTab then
        image('v2/cheerUI/inner_bkg.png',520,320,430,230)
        for i,stat in ipairs(STATS) do
            local y=398-(i-1)*36
            image('v2/introUI/'..PIC[stat]..'.png',330,y,26,26)
            label(string.format('%.1f%% (%.1f%%)',(s.ratios[stat] or 0)*100,(s.dynamic_pct[stat] or 0)),
                360,y,20,BROWN)
        end
        label('提示: 阵法达到10阶后即可进行洗练，实现各属性转换',520,253,17,GRAY,nil,true)
        label('消耗:',390,220,20,BROWN)
        image('v2/cheerUI/material.png',446,220,22,22)
        local enough=(state.support.material or 0)>=s.refine_cost.material
        label(s.refine_cost.material,461,220,20,enough and GREEN or RED)
        image('v2/money_gold.png',506,220,24,16)
        local goldOk=(state.gold or 0)>=s.refine_cost.gold
        label(s.refine_cost.gold,522,220,20,goldOk and GREEN or RED)
        hit(438,220,170,32,function() buyMaterial('refine') end)
        local su=image('v2/cheerUI/su1.png',520,154,190,63)
        hit(520,154,196,67,function() ui.send('support_refine',{slot=M.slot}) end,su,enough and goldOk and not s.refine)
    else
        image('v2/cheerUI/inner_bkg.png',520,320,430,230)
        local rate=(s.cheer_rate or .5)*100
        label(string.format('助阵额外被动法术效能：%.1f%%',rate),520,400,20,BROWN,nil,true)
        image('v2/cheerUI/a11.png',430,330,92,92)
        image('v2/cheerUI/a21.png',610,330,92,92)
        label('助阵被动一',430,276,16,GRAY,nil,true)
        label('助阵被动二',610,276,16,GRAY,nil,true)
        label('两项额外被动按效能参与属性，再沿八卦阵位传递。',520,236,16,GRAY,nil,true)
        control('前往演武堂进修',520,180,200,function() M.panel=nil;ui.navigate('battle_hall') end)
    end
    closeButton(742,524,panelClose,46)
end

local function drawOffer()
    local s=slot();if not s or not s.refine then M.panel='refine';return end
    beginPanel(185)
    image('v2/cheerUI/bkg_frame2.png',480,300,540,492)
    image('v2/cheerUI/title_su.png',480,526,110,68)
    image('v2/cheerUI/'..M.slot..'4.png',330,444,80,80)
    image('v2/cheerUI/bkg_lv.png',560,450,210,43)
    label(s.name..'位阶数：',470,450,20,BROWN,nil,true)
    label(s.level..'阶',610,450,22,GRAY,nil,true)
    image('v2/cheerUI/inner_bkg.png',520,330,440,240)
    local pending=s.refine;local rate=pending.rate/100000
    for i,stat in ipairs(STATS) do
        local y=410-(i-1)*38
        image('v2/introUI/'..PIC[stat]..'.png',330,y,26,26)
        label(string.format('%.1f%% (%.1f%%)',(s.ratios[stat] or 0)*100,(s.dynamic_pct[stat] or 0)),360,y,19,BROWN)
        local gain=stat==pending.gain;local lose=stat==pending.lose
        if gain or lose then
            label(string.format('%s%.1f%%',gain and '+' or '-',rate*100),520,y,19,gain and GREEN or RED)
        end
        local nxt=(s.ratios[stat] or 0)+(gain and rate or lose and -rate or 0)
        local dyn=(s.dynamic_pct[stat] or 0)+(gain and rate*100 or lose and -rate*100 or 0)
        label(string.format('%.1f%% (%.1f%%)',nxt*100,dyn),585,y,19,gain and GREEN or lose and RED or GRAY)
    end
    label('提示: 接受后各属性转换比例立即生效；放弃则保留原比例。',520,238,16,GRAY,nil,true)
    local reject=image('v2/cheerUI/reject1.png',390,160,180,63)
    hit(390,160,186,67,function() M.panel='refine';ui.send('support_refine_cancel',{slot=M.slot}) end,reject)
    local accept=image('v2/cheerUI/accept1.png',610,160,180,63)
    hit(610,160,186,67,function() M.panel='refine';ui.send('support_refine_accept',{slot=M.slot}) end,accept)
    closeButton(742,524,function()
        M.panel='refine';ui.send('support_refine_cancel',{slot=M.slot})
    end,46)
end

local function drawConfirm()
    beginPanel(190)
    image('v2/cheerUI/bkg1.png',480,300,560,320)
    label(M.confirm and M.confirm.text or '',480,370,20,GRAY,nil,true)
    control('取消',380,205,150,function()
        local back=M.confirm and M.confirm.back
        M.confirm=nil;M.panel=back or nil;ui.render()
    end)
    control('确定',580,205,150,function()
        local c=M.confirm;if not c then return end
        M.confirm=nil;c.action()
    end)
end

function M.draw(context,player)
    ui,state,root=context,player,context.root
    if not state.support then return end
    M.slot=math.max(1,math.min(M.slot or 1,8))
    local s=slot()
    if s and s.refine and M.panel~='offer' then M.panel='offer' end
    if M.panel=='upgrade' and s and s.level>=s.max_level then M.panel='refine' end
    if M.panel=='hero' then drawHeroMenu()
    elseif M.panel=='detail' then drawDetail()
    elseif M.panel=='choose' then drawChoose()
    elseif M.panel=='target' then drawTarget()
    elseif M.panel=='upgrade' then drawUpgrade()
    elseif M.panel=='refine' then drawRefine()
    elseif M.panel=='offer' then drawOffer()
    elseif M.panel=='confirm' then drawConfirm()
    else drawMain() end
    if M.panel and (ui.busy or ui.error) then
        label(ui.error or '正在保存…',480,26,14,GOLD,nil,true)
    end
end

function M.open()
    M.panel=nil;M.page=1;M.confirm=nil;M.tab='position'
end

function M.isPanelOpen()
    return M.panel~=nil
end

function M.back()
    if ui.busy then return end
    if M.panel=='offer' then
        M.panel='refine';ui.send('support_refine_cancel',{slot=M.slot});return
    end
    if M.confirm then
        local back=M.confirm.back
        M.confirm=nil;M.panel=back or nil;ui.render();return
    end
    if M.panel then M.panel=nil;ui.render();return end
    ui.navigate('lineup')
end

return M

