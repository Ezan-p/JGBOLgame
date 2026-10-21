-- Original charPositionUI.lua geometry and art; local roster mutations are atomic.
local data=require('local_lineup_data')
local heroDetail=require('local_hero_detail')
local M={mode='main',slot=1,offset=0}
local inventoryData=require("local_inventory_data")
local ui,state,root
local P='v2/charPositionUI/'
local GOLD={244,221,173}
local function image(file,x,y,w,h,parent)
    local n=CCSprite:create(file); local s=n:getContentSize()
    n:setScaleX(w/s.width); n:setScaleY((h or w*s.height/s.width)/s.height)
    n:setPosition(CCPointMake(x,y)); (parent or root):addChild(n); return n
end
local function label(t,x,y,size,color,parent,center,width)
    local n
    if width then n=CCLabelTTF:create(tostring(t),'Arial',size,CCSizeMake(width,0),kCCTextAlignmentLeft)
    else n=CCLabelTTF:create(tostring(t),'Arial',size) end
    n:setAnchorPoint(CCPointMake(center and .5 or 0,width and 1 or .5))
    n:setPosition(CCPointMake(x,y)); n:setColor(ccc3(unpack(color or GOLD)))
    local target=parent or root;target:addChild(n); return n
end
local function atlas(info,x,y,w,h,parent)
    local n=CCSprite:create(info.file); local s=n:getContentSize()
    local cw,ch=s.width/info.columns,s.height/info.rows
    n:setTextureRect(CCRectMake((info.index-1)%info.columns*cw,math.floor((info.index-1)/info.columns)*ch,cw,ch))
    n:setScaleX(w/cw); n:setScaleY((h or w*ch/cw)/ch)
    n:setPosition(CCPointMake(x,y)); (parent or root):addChild(n); return n
end
local function hit(x,y,w,h,f,n) ui.hit(x-w/2,y-h/2,w,h,f,true,n) end
local function owned(id) for _,h in ipairs(state.heroes) do if h.id==id then return h end end end
local function entry(id) return data.heroes[tostring(id)] end
local function popup(title,body) M.info={title,body}; ui.render() end
local function openDetail(h)
    if not h then return end
    M.detailHero=h; M.mode='detail'; M.pick=nil; M.info=nil
    heroDetail.reset()
    ui.render()
end
local function vertical(value,x,top,active)
    local chars={}
    for ch in string.gmatch(value,"[%z\1-\127\194-\244][\128-\191]*") do table.insert(chars,ch) end
    local n=label(table.concat(chars,"\n"),x,top,14,active and {255,235,177} or {140,120,103},nil,true)
    n:setAnchorPoint(CCPointMake(.5,1))
end
local function frame()
    image('v2/introUI/intro_bkg.png',480,302.4,931.2,442.8)
end
local function edges()
    image('v2/packageUI/board_edge1.png',14.4,302.4,15,442.8)
    image('v2/packageUI/board_edge1.png',945.6,302.4,15,442.8):setFlipX(true)
    image('v2/packageUI/board_edge2.png',480,519,945,37)
    image('v2/packageUI/board_edge2.png',480,86,945,37):setFlipY(true)
    if M.mode=='main' then
        local n=image('v2/introUI/close1.png',925,510,60,58)
        hit(925,510,60,58,function() M.back() end,n)
    end
end
local function side(x,reverse,title,action)
    local n=image(P..'arrow.png',x,302,100,432);n:setFlipX(reverse)
    image(P..title..'.png',x,302,60,105)
    hit(x,302,95,390,action)
end
local function square(x,y,w,locked)
    image(P..'square_bkg.png',x,y,w,w);image(P..'frame1.png',x,y,w,w)
    if locked then image(P..'lock.png',x,y,w*1.1,w*.94) end
end
local function header(parent,shift)
    shift=shift or 0
    image(P..'head_bkg.png',466+shift,470,870,90,parent)
    for i=1,8 do
        local x=124+(i-1)*88+shift
        local h=owned(state.lineup[i])
        if h then atlas(entry(h.id).icon,x,470,83,nil,parent)
        else
            image(P..'square_bkg.png',x,470,83,84,parent)
            image(P..'frame1.png',x,470,83,84,parent)
            if i>(state.lineup_capacity or 4) then image(P..'lock.png',x,470,91,78,parent) end
        end
        if i==M.slot then image(P..'choose.png',x,470,91,91,parent) end
        if not parent then
            local slot=i
            hit(x,470,90,90,function()
                if slot>(state.lineup_capacity or 4) then popup('出战阵位','此阵位尚未解锁。')
                elseif slot==M.slot and h then openDetail(h)
                else M.slot=(state.lineup_capacity or 4)>4 and slot or math.min(slot,#state.lineup+1);ui.render() end
            end)
        end
    end
end
local function stats(h,x,y,w,parent)
    image(P..'head_bkg.png',x,y,w,33,parent)
    local keys={'hp','attack','defense','magic'};local pics={'health','damage','defence','mana'}
    for i,k in ipairs(keys) do
        local xx=x-w/2+(i-1)*w/4+14
        image('v2/introUI/'..pics[i]..'.png',xx,y,28,28,parent)
        label(h[k] or 0,xx+17,y,18,GOLD,parent)
    end
    image(P..'level_bkg.png',x-w/2-31,y-27,48,29,parent)
    label(h.level,x-w/2-31,y-27,20,GOLD,parent,true)
    image('v2/CharaterUI/expbar1.png',x,y-27,w,15,parent)
    label('等级 '..h.level..' / 20',x,y-27,11,GOLD,parent,true)
end
local function character(h,compact,parent)
    if not h then return end
    local e=entry(h.id)
    local x=compact and 206 or 480
    local n=CCSprite:create(h.sprite);local s=n:getContentSize()
    n:setScale(math.min((compact and 290 or 400)/s.width,280/s.height))
    n:setAnchorPoint(CCPointMake(.5,0));n:setPosition(CCPointMake(x,158));(parent or root):addChild(n)
    local nx=compact and 46 or 258
    local cat={['神']=1,['妖']=2,['人']=3,['魔']=4,['佛']=5}
    image(P..'type_'..cat[h.category]..'.png',nx,391,34,34,parent)
    atlas(e.name_icon,nx,282,44,176,parent)
    local stars=image('v2/CharaterUI/stars.png',nx+29,282,17,80,parent)
    stars:setTextureRect(CCRectMake(0,0,22,20*h.quality))
    stats(h,compact and 210 or 484,135,compact and 280 or 350,parent)
end
local function main()
    header()
    side(68,false,'position_label',function() M.mode='formation';M.pick=nil;ui.render() end)
    side(875,true,'changeHZ',function() M.mode='replace';M.offset=0;ui.render() end)
    local h=owned(state.lineup[M.slot])
    if not h then
        local n=image(P..'touch_enter.png',480,285,280,85)
        hit(480,285,280,85,function() M.mode='replace';ui.render() end,n)
        return
    end
    character(h)
    local e=entry(h.id)
    local equipped={}
    for _,item in ipairs((state.inventory or {}).entries or {}) do
        if item.hero==h.id then
            local base=inventoryData.items[item.key]
            equipped[base.category==4 and ("spell"..item.equip_pos) or base.category]={base=base,entry=item}
        end
    end
    for i=1,3 do
        local y=374-(i-1)*108
        square(180,y,78,false);square(770,y,78,false)
        if i==1 then
            local spell
            for _,s in ipairs(data.spells) do if s.id==h.skill_id then spell=s end end
            if spell then atlas(spell.icon,180,y,78) end
            label(h.skill_name,180,y-47,16,GOLD,nil,true)
            hit(180,y,84,98,function()
                popup(h.skill_name,e.skill_description..'\n\n自带法术，不可更换或卸下。')
            end)
        else
            local passive=equipped["spell"..i];local spellPos=i
            if passive then
                atlas(passive.base.icon,180,y,78)
                label(passive.base.name,180,y-47,16,GOLD,nil,true)
            else image(P..'skillHZ.png',180,y,78,78) end
            hit(180,y,84,98,function() ui.openBag(4,nil,h.id,spellPos) end)
        end
        local gear=equipped[i];local category=i
        if gear then
            atlas(gear.base.icon,770,y,78)
            label(gear.base.name,770,y-47,16,GOLD,nil,true)
        else image(P..'itemHZ_'..i..'.png',770,y,78,78) end
        hit(770,y,84,98,function() M.gearCategory=category;M.mode='equipment';M.choicePage=1;ui.render() end)
    end
    image('v2/introUI/yuanfen_label.png',672,385,92,38)
    for i,f in ipairs(h.fates or e.fates) do
        if i<=6 then
            vertical(f.name,655+(i%2)*34,350-math.floor((i-1)/2)*87,f.active)
        end
    end
    hit(677,272,115,225,function()
        openDetail(h)
    end)
    hit(480,285,240,270,function() openDetail(h) end)
    label('演武堂',85,111,17,{244,221,173},nil,true)
    hit(85,111,108,30,function() ui.navigate('battle_hall') end)
    label('战斗演示',867,111,14,{178,136,83},nil,true)
    hit(867,111,100,26,ui.demo)
    local cheer=image('v2/cheerUI/cheer_head1.png',867,470,83,83)
    hit(867,470,86,86,function() M.mode='support';M.supportSlot=M.supportSlot or 1;ui.render() end,cheer)
    hit(484,135,350,35,function() openDetail(h) end)
end
local function formation()
    image(P..'max_bkg.png',480,302,925,430)
    image(P..'position.png',460.8,297,600,379.5)
    image(P..'position_intro_label.png',204,485,300,29)
    side(875,true,'backHZ',function() M.back() end)
    M.spots={}
    for i,p in ipairs(data.positions) do
        local x,y=460.8+p[1]*600,297+p[2]*379.5
        local h=owned(state.lineup[i]);local size=i<=4 and 73 or 51
        if i<=4 then image(P..'position_light.png',x,y,145,145) end
        local n
        if h then
            n=atlas(entry(h.id).icon,x,y,size)
            image(P..'char_name_bkg.png',x,y-size*.65,100,23)
            label(h.name,x,y-size*.65,15,GOLD,nil,true)
        else square(x,y,size,i>(state.lineup_capacity or 4)) end
        if M.pick==i then image(P..'choose.png',x,y,size+9,size+9) end
        M.spots[i]={x=x,y=y,node=n}
    end
    label((state.lineup_capacity or 4)>4 and '四位在场 · 后备对应补位 · 拖动头像布阵' or '四位出战 · 拖动头像交换阵位',480,110,15,{168,132,94},nil,true)
end
local function setOffset(value)
    local s=M.scroll;M.offset=math.max(0,math.min(s.max,value));s.node:setPositionY(M.offset)
end
local function replace()
    -- Keep the left portrait clipped under the original sliding panel.
    local container=CCLayer:create()
    local view=CCScrollView:create(CCSizeMake(380*root:getScaleX(),430*root:getScaleY()),container)
    view:setPosition(CCPointMake(15,88));view:setTouchEnabled(false);root:addChild(view)
    local inner=CCNode:create();inner:setPosition(CCPointMake(-15,-88));container:addChild(inner)
    header(inner,-140);character(owned(state.lineup[M.slot]),true,inner)
    image(P..'max_bkg.png',670,302,550,430)
    side(395,true,'backHZ',function() M.back() end)
    local list={}
    for _,h in ipairs(state.heroes) do if not h.active and not h.supporting then table.insert(list,h) end end
    table.sort(list,function(a,b) if a.quality~=b.quality then return a.quality>b.quality end return a.id<b.id end)
    local c=CCLayer:create();c:setContentSize(CCSizeMake(485,math.max(424,#list*108)))
    local v=CCScrollView:create(CCSizeMake(485*root:getScaleX(),424*root:getScaleY()),c)
    v:setPosition(CCPointMake(449,90));v:setTouchEnabled(false);root:addChild(v)
    M.scroll={node=c,max=math.max(0,#list*108-424),list=list}
    for i,h in ipairs(list) do
        local y=424-(i-.5)*108
        image(P..'char_info.png',242,y,485,103,c)
        atlas(entry(h.id).icon,48,y,69,nil,c)
        label(h.name,98,y+26,23,GOLD,c)
        local stars=image('v2/introUI/stars.png',267,y+26,80,17,c)
        stars:setTextureRect(CCRectMake(0,0,106*h.quality/5,22))
        image('v2/introUI/level.png',112,y-18,23,23,c)
        label(h.level,132,y-18,22,{232,188,52},c)
        image(P..'a_change1.png',409,y-26,132,43,c)
    end
    if #list==0 then
        label('暂无可更换的神仙',691,310,25,GOLD,nil,true)
        label('前往召唤，招募新的伙伴',691,268,19,{187,153,113},nil,true)
        local n=image('v2/soulExchangeUI/btn_bkg1.png',691,210,210,46)
        label('前往召唤',691,210,21,GOLD,nil,true)
        hit(691,210,210,46,function() ui.navigate('summon') end,n)
    end
    setOffset(M.offset)
end
local function control(title,x,y,w,action,enabled)
    if enabled==nil then enabled=true end
    local n=image('v2/soulExchangeUI/btn_bkg1.png',x,y,w,38)
    label(title,x,y,17,enabled and GOLD or {132,113,95},nil,true)
    ui.hit(x-w/2,y-19,w,38,action,enabled,n)
end
local function confirm(message,action)
    M.info={'确认',message,action};ui.render()
end
local function panelTitle(title,back)
    image('v2/introUI/small_label.png',480,479,720,50)
    label(title,480,479,25,GOLD,nil,true)
    control('返回',861,480,108,back or function() M.back() end)
end
local function changeMode(mode) M.mode=mode;M.choicePage=1;ui.render() end
local function supportSlot() return state.support.slots[M.supportSlot or 1] end
local function support()
    image('v2/cheerUI/bkg.png',480,300,920,425)
    M.supportSlot=M.supportSlot or 1
    local s=supportSlot()
    for i=1,8 do
        local x=115+(i-1)*101;local index=i
        local n=image('v2/cheerUI/'..i..(i==M.supportSlot and '3.png' or '1.png'),x,478,82,62)
        hit(x,478,84,64,function() M.supportSlot=index;ui.render() end,n)
    end
    control('返回阵容',865,112,120,function() M.back() end)
    local h=owned(s.hero);local target=owned(s.target_hero)
    label(s.name..'位 · '..s.level..'阶',290,416,24,GOLD,nil,true)
    if h then
        local n=CCSprite:create(h.sprite);local sz=n:getContentSize()
        n:setScale(math.min(250/sz.width,172/sz.height));n:setPosition(CCPointMake(280,315));root:addChild(n)
        label(h.name,280,215,23,GOLD,nil,true)
        hit(280,310,260,185,function()
            local lines={h.name,'生命 '..h.hp..'  攻击 '..h.attack..'  防御 '..h.defense..'  法力 '..h.magic}
            for _,f in ipairs(h.fates or {}) do table.insert(lines,(f.active and '已激活 ' or '未激活 ')..f.name) end
            popup('助阵伙伴',table.concat(lines,'\n'))
        end)
    else
        image('v2/cheerUI/head_bkg.png',280,325,100,100)
        label('选择助阵神仙',280,240,22,GOLD,nil,true)
    end
    control(h and '更换助阵' or '选择神仙',214,177,150,function() changeMode('support_choose') end)
    control('卸下',363,177,105,function()
        confirm('卸下'..h.name..'，相关仙缘与助阵加成将重新计算。',function() ui.send('support_assign',{slot=M.supportSlot,hero=0}) end)
    end,h~=nil)
    label('助阵参与人物仙缘 · 五星可传递属性',280,135,15,GOLD,nil,true)
    if target then
        atlas(entry(target.id).icon,787,365,80)
        label(target.name..' · 第'..s.target..'阵位',757,416,20,GOLD,nil,true)
    else
        image('v2/cheerUI/head_bkg.png',787,365,80,80)
        label('尚未指定受助神仙',757,416,20,GOLD,nil,true)
    end
    control('选择受助阵位',735,235,190,function() changeMode('support_target') end,h~=nil and h.quality>=5)
    label('命 +'..s.bonus.hp..'   攻 +'..s.bonus.attack..'   防 +'..s.bonus.defense..'   法 +'..s.bonus.magic,735,195,18,{178,255,100},nil,true)
    label(string.format('传递比例  命 %.1f%% · 攻防法 %.1f%%',s.ratios.hp*100,s.ratios.attack*100),735,159,16,GOLD,nil,true)
    control('进阶',496,260,105,function()
        confirm('消耗'..s.next_cost..'张乾坤符箓，'..s.name..'位提升至'..(s.level+1)..'阶。',function() ui.send('support_upgrade',{slot=M.supportSlot}) end)
    end,s.level<s.max_level and state.support.material>=s.next_cost)
    label('符箓 '..state.support.material..' / '..s.next_cost,496,219,14,GOLD,nil,true)
    control('兑换符箓',496,175,115,function()
        local price=inventoryData.items.i1015.price*25
        confirm('花费'..price..'银两兑换25张乾坤符箓。\n当前银两：'..state.silver,function() ui.send('support_buy_material',{slot=M.supportSlot,count=25}) end)
    end)
    label('银两 '..state.silver,496,136,14,GOLD,nil,true)
end
local function choiceList(list,title,action,isGear)
    panelTitle(title)
    local maxpage=math.max(1,math.ceil(#list/8));M.choicePage=math.max(1,math.min(M.choicePage or 1,maxpage))
    for j=1,8 do
        local item=list[(M.choicePage-1)*8+j]
        if item then
            local x=j%2==1 and 257 or 686;local y=411-math.floor((j-1)/2)*84
            image(P..'char_info.png',x,y,390,78)
            if isGear then
                local base=inventoryData.items[item.key]
                atlas(base.icon,x-150,y,60)
                label(base.name..'  '..item.level..'级',x-108,y+15,19,GOLD)
                local wearer=owned(item.hero)
                label('属性 +'..item.value..' · '..(wearer and wearer.name..'佩戴' or '未装备'),x-108,y-15,15,{225,185,122})
            else
                atlas(entry(item.id).icon,x-150,y,60)
                label(item.name,x-108,y+16,20,GOLD)
                label(item.quality..'星 · '..item.level..'级',x-108,y-15,16,{225,185,122})
            end
            control('选择',x+143,y-5,78,function() action(item) end)
        end
    end
    if #list==0 then label('暂无可选择的'..(isGear and '装备' or '神仙'),480,300,26,GOLD,nil,true) end
    control('上一页',160,108,120,function() M.choicePage=M.choicePage-1;ui.render() end,M.choicePage>1)
    label(M.choicePage..' / '..maxpage,310,108,18,GOLD,nil,true)
    control('下一页',460,108,120,function() M.choicePage=M.choicePage+1;ui.render() end,M.choicePage<maxpage)
end
local function supportChoose()
    local list={}
    for _,h in ipairs(state.heroes) do if not h.active and not h.supporting then table.insert(list,h) end end
    table.sort(list,function(a,b) if a.quality~=b.quality then return a.quality>b.quality end return a.id<b.id end)
    choiceList(list,'选择助阵神仙',function(h)
        M.mode='support';ui.send('support_assign',{slot=M.supportSlot,hero=h.id})
    end)
    control('前往召唤',795,108,160,function() ui.navigate('summon') end)
end
local function supportTarget()
    local list={}
    for i,id in ipairs(state.lineup) do local h=owned(id);if h then list[#list+1]=h end end
    choiceList(list,'选择受助阵位 · 每个出战阵位接受一位助阵',function(h)
        local target
        for i,id in ipairs(state.lineup) do if id==h.id then target=i end end
        M.mode='support';ui.send('support_target',{slot=M.supportSlot,target=target})
    end)
    control('取消关联',795,108,160,function() M.mode='support';ui.send('support_target',{slot=M.supportSlot,target=0}) end)
end
local function equipment()
    local h=owned(state.lineup[M.slot]);local list={};local worn
    for _,e in ipairs(state.inventory.entries) do
        if inventoryData.items[e.key].category==M.gearCategory then
            if e.hero==h.id then worn=e else table.insert(list,e) end
        end
    end
    table.sort(list,function(a,b) if a.value~=b.value then return a.value>b.value end return a.uid<b.uid end)
    choiceList(list,h.name..' · 更换'..({'武器','防具','法宝'})[M.gearCategory],function(e)
        local function equip() M.mode='main';ui.send('bag_equip',{uid=e.uid,hero=h.id}) end
        if e.hero~=0 then confirm('将'..owned(e.hero).name..'的'..inventoryData.items[e.key].name..'转给'..h.name..'？',equip)
        else equip() end
    end,true)
    control('卸下',615,108,95,function() M.mode='main';ui.send('bag_equip',{uid=worn.uid,hero=0}) end,worn~=nil)
    control('包裹 / 强化',808,108,174,function() ui.openBag(M.gearCategory,worn and worn.uid) end)
end
local function fates()
    local h=owned(state.lineup[M.slot]);panelTitle(h.name..' · 仙缘与属性')
    local statName={hp='生命',attack='攻击',defense='防御',magic='法力'}
    for i,f in ipairs(h.fates or {}) do
        local y=435-(i-1)*43
        image(P..'char_info.png',480,y-13,810,40)
        label(f.active and '已激活' or '未激活',100,y-13,17,f.active and {178,255,100} or {148,125,102})
        label(f.name,182,y-13,18,f.active and GOLD or {170,144,115})
        label(f.description,310,y+1,14,f.active and GOLD or {170,144,115},nil,false,535)
    end
    local parts={}
    for _,k in ipairs({'hp','attack','defense','magic'}) do
        table.insert(parts,statName[k]..' '..h[k]..'（仙缘 +'..(h.fate_bonus or {})[k]..' / 助阵 +'..(h.support_bonus or {})[k]..'）')
    end
    label(table.concat(parts,'\n'),103,190,16,GOLD,nil,false,760)
end

function M.draw(context,player)
    ui,state,root=context,player,context.root;M.scroll=nil;M.gesture=nil
    M.slot=math.max(1,math.min(M.slot,(state.lineup_capacity or 4)>4 and state.lineup_capacity or math.min(4,#state.lineup+1)))
    if M.mode=='detail' then
        local h=owned(state.lineup[M.slot])
        if h then
            local e=entry(h.id)
            heroDetail.draw({
                root=root,ui=ui,state=state,entry=e,hero=h,spells=data.spells,
                onClose=function() M.mode='main';M.detailHero=nil;heroDetail.reset();ui.render() end,
                onBack=function() M.mode='main';M.detailHero=nil;heroDetail.reset();ui.render() end,
                onTrain=function() ui.send('upgrade',{hero=h.id}) end,
                onInherit=function()
                    heroDetail.showInfo('传承',
                        '传承可将一名神仙的培养等级转移给另一位神仙。\n'..
                        '本地版暂未开放跨角色传承；当前等级、仙缘与属性不会被扣除。')
                end,
            })
            return
        end
        M.mode='main'
    end
    frame()
    if M.mode=='formation' then formation() elseif M.mode=='replace' then replace()
    elseif M.mode=='support' then support() elseif M.mode=='support_choose' then supportChoose()
    elseif M.mode=='support_target' then supportTarget() elseif M.mode=='equipment' then equipment()
    elseif M.mode=='fates' then fates() else main() end
    edges()
    if ui.failed then
        label('连接中断 · 点击重试',480,95,16,GOLD,nil,true)
        ui.hit(350,82,260,26,function() ui.send('state',{}) end,true,nil,true)
    elseif ui.busy or ui.error then label(ui.error or '正在保存…',480,95,15,GOLD,nil,true) end
    if M.info then
        ui.clearHits();M.scroll=nil
        image(P..'max_bkg.png',480,300,680,360)
        image('v2/introUI/small_label.png',480,450,620,52)
        label(M.info[1],480,451,25,GOLD,nil,true)
        label(M.info[2],175,405,19,GOLD,nil,false,610)
        local n=image(P..'a_change1.png',480,150,160,45)
        image(P..'max_bkg.png',480,150,120,28)
        label('返回',480,150,22,GOLD,nil,true)
        hit(480,150,180,48,function() M.info=nil;ui.render() end,n)
        if M.info[3] then control('确认',680,150,150,function() local action=M.info[3];M.info=nil;action() end) end
    end
end
function M.open() M.mode='main';M.info=nil;M.pick=nil;M.offset=0;M.detailHero=nil;heroDetail.reset() end
function M.back()
    if heroDetail.closeInfo() then ui.render()
    elseif M.mode=='detail' then M.mode='main';M.detailHero=nil;heroDetail.reset()
    elseif M.info then M.info=nil
    elseif M.mode=='support_choose' or M.mode=='support_target' then M.mode='support'
    elseif M.mode~='main' then M.mode='main';M.pick=nil
    else ui.navigate('home');return end
    ui.render()
end
local function spot(x,y)
    for i,p in ipairs(M.spots or {}) do if math.abs(x-p.x)<45 and math.abs(y-p.y)<45 then return i end end
end
function M.touch(event,x,y)
    if M.mode=='detail' then return heroDetail.touch(event,x,y) end
    if M.info then return false end
    local began=event==CCTOUCHBEGAN or event=='began'
    local moved=event==CCTOUCHMOVED or event=='moved'
    local ended=event==CCTOUCHENDED or event=='ended'
    if M.mode=='formation' then
        if began then
            local i=spot(x,y)
            if i and i<=(state.lineup_capacity or 4) then
                M.gesture={slot=i,x=x,y=y};return true
            end
        elseif M.gesture then
            local g=M.gesture;local p=M.spots[g.slot]
            if moved then
                g.dragged=g.dragged or math.abs(x-g.x)+math.abs(y-g.y)>9
                if g.dragged and p.node then p.node:setPosition(CCPointMake(x,y)) end
            elseif ended then
                M.gesture=nil;local target=spot(x,y)
                if target and target<=(state.lineup_capacity or 4) then
                    if not g.dragged and M.pick and M.pick~=target and owned(state.lineup[M.pick]) then
                        local source=M.pick;M.pick=nil;ui.send('lineup_swap',{source=source,target=target})
                    elseif target~=g.slot and owned(state.lineup[g.slot]) then M.pick=nil;ui.send('lineup_swap',{source=g.slot,target=target})
                    elseif not owned(state.lineup[target]) then M.slot=target;M.mode='replace';M.pick=nil;ui.render()
                    else M.pick=target;ui.render() end
                else ui.render() end
            else M.gesture=nil;ui.render() end
            return true
        end
    elseif M.scroll then
        if began and x>=449 and x<=934 and y>=90 and y<=514 then
            -- Empty-state button is handled by normal hit testing.
            if #M.scroll.list==0 then return false end
            M.gesture={x=x,y=y,offset=M.offset};return true
        elseif M.gesture then
            local g=M.gesture
            if moved then
                g.dragged=g.dragged or math.abs(y-g.y)+math.abs(x-g.x)>8
                if g.dragged then setOffset(g.offset+y-g.y) end
            elseif ended then
                M.gesture=nil
                if not g.dragged and x>=449 and x<=934 and y>=90 and y<=514 then
                    local index=math.floor((514-y+M.offset)/108)+1
                    local h=M.scroll.list[index]
                    if h then
                        if x>785 then M.mode='main';ui.send('lineup_replace',{slot=M.slot,hero=h.id})
                        else popup(h.name,entry(h.id).description) end
                    end
                end
            else M.gesture=nil end
            return true
        end
    end
    return false
end
return M
