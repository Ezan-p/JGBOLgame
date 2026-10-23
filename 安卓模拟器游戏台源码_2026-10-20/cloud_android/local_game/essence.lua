-- Original jpmkUI geometry on the shared 960x540 canvas.
local D=require('local_inventory_data')
local M={}
local ui,state,root
local P='v2/jpmkUI/'
local GOLD={224,174,111}
local COST={500,1000,1500,3000}
local function image(file,x,y,w,h)
    local n=CCSprite:create(file);if not n then return end
    local s=n:getContentSize();n:setScaleX(w/s.width);n:setScaleY((h or w*s.height/s.width)/s.height)
    n:setPosition(CCPointMake(x,y));root:addChild(n);return n
end
local function text(t,x,y,size,color,width)
    local n
    if width then n=CCLabelTTF:create(tostring(t),'Arial',size,CCSizeMake(width,0),kCCTextAlignmentLeft)
    else n=CCLabelTTF:create(tostring(t),'Arial',size) end
    n:setAnchorPoint(CCPointMake(0,width and 1 or .5));n:setPosition(CCPointMake(x,y));n:setColor(ccc3(unpack(color or GOLD)));root:addChild(n)
end
local function button(file,x,y,w,h,action,enabled)
    local n=image(file,x,y,w,h);if n and enabled==false then n:setColor(ccc3(135,125,110)) end
    ui.hit(x-w/2,y-h/2,w,h,action,enabled~=false,n)
end
local function entries(hero,unused)
    local list={}
    for _,e in ipairs((state.inventory or {}).entries or {}) do
        local item=D.items[e.key]
        if item and item.main_type==15 and (unused and e.hero==0 or not unused and e.hero==hero) then list[#list+1]=e end
    end
    table.sort(list,function(a,b)
        if not unused and (a.ext_skill_pos or 0)~=(b.ext_skill_pos or 0) then return (a.ext_skill_pos or 0)<(b.ext_skill_pos or 0) end
        local aa,bb=D.items[a.key],D.items[b.key]
        if aa.quality~=bb.quality then return aa.quality>bb.quality end
        if a.level~=b.level then return a.level>b.level end
        if aa.id~=bb.id then return aa.id<bb.id end
        return a.uid<b.uid
    end)
    return list
end
local function description(e)
    if e.essence then return e.essence.description end
    local t=D.combat_rules.traits[tostring(D.items[e.key].id)];local s=t.description
    for _,v in ipairs(t.levels) do s=string.gsub(s,'%%s',function() return string.format('%.8g',v[e.level]*100)..'%' end,1) end
    return s
end
local function icon(e,x,y,w)
    image(D.items[e.key].icon.file,x,y,w,w)
    text('lv'..e.level,x-w*.42,y+w*.33,16,{178,255,63})
end
function M.open(hero) M.hero=hero;M.selecting=false;M.selected=nil;M.page=1;M.message=nil end
function M.close() M.hero=nil;M.selecting=false;M.selected=nil;M.message=nil end
function M.isOpen() return M.hero~=nil end
function M.back()
    if M.selecting then M.selecting=false else M.close() end
end
function M.strip(context,player,hero)
    ui,state,root=context,player,context.root
    local list=entries(hero.id,false)
    -- Reference IMG_3411 shows five positions, including the additional locked position.
    image(P..'bkg3.png',480,165,216,43)
    for i=1,5 do
        local x=398+(i-1)*41
        local e=list[i]
        image(e and D.items[e.key].icon.file or P..'jp_no_open2.png',x,165,39,39)
    end
    ui.hit(372,142,216,46,function() M.open(hero.id);ui.render() end,true)
end
local function selection()
    local list=entries(M.hero,true)
    local installed=entries(M.hero,false);local filtered={}
    for _,e in ipairs(list) do
        local same=false;for _,v in ipairs(installed) do if v.key==e.key then same=true end end
        if not same then filtered[#filtered+1]=e end
    end
    list=filtered
    image('v2/jpUI/bkg.png',480,270,890,500)
    image('v2/jpUI/title.png',480,481,175,56)
    button('v2/common/close1.png',873,492,58,58,function() M.selecting=false;ui.render() end)
    local pages=math.max(1,math.ceil(#list/4));M.page=math.min(M.page or 1,pages)
    for j=1,4 do
        local e=list[(M.page-1)*4+j]
        if e then
            local y=400-(j-1)*79
            icon(e,119,y,61);text(D.items[e.key].name,162,y+24,20)
            text(description(e),162,y+5,16,{180,160,150},410)
            button('v2/jpUI/btn31.png',619,y,96,48,function() M.selected=e.uid;M.selecting=false;ui.render() end)
        end
    end
    if #list==0 then text('暂无可铭刻的精魄',236,285,22) end
    button('v2/soulExchangeUI/btn_bkg1.png',210,78,110,36,function() M.page=M.page-1;ui.render() end,M.page>1)
    text('上一页',180,78,18)
    text(M.page..' / '..pages,357,78,18)
    button('v2/soulExchangeUI/btn_bkg1.png',531,78,110,36,function() M.page=M.page+1;ui.render() end,M.page<pages)
    text('下一页',501,78,18)
end
function M.draw(context,player)
    if not M.hero then return end
    ui,state,root=context,player,context.root
    ui.clearHits()
    local mask=CCLayerColor:create(ccc4(0,0,0,180));mask:setContentSize(CCSizeMake(960,540));root:addChild(mask)
    if M.selecting then selection();return end
    local w,h=834,498
    image(P..'bkg.png',480,270,w,h)
    image(P..'title.png',480,270+h*.42,158.25,45)
    image(P..'bkg2.png',480+w*.355,270+h*.01,186,336.75)
    button('v2/common/close1.png',480+w*.45,270+h*.45,60,60,function() M.close();ui.render() end)
    local hero;for _,v in ipairs(state.heroes) do if v.id==M.hero then hero=v end end
    local luck=hero and hero.next_ext_skill_luck_point
    text('幸运值：'..(luck~=nil and tostring(luck) or '—'),718,270+h*.23,19.5,{154,254,111})
    local list=entries(M.hero,false);local stones=0
    for _,e in ipairs((state.inventory or {}).entries or {}) do if e.key=='i10000' then stones=stones+e.count end end
    for i=1,4 do
        local y=270+h*.26-(i-1)*h*.17;local e=list[i]
        if i<4 then image(P..'inter.png',480-w*.12,y-h*.08,w*.66,3) end
        if e then
            icon(e,480-w*.4,y,63)
            text(D.items[e.key].name,480-w*.35,y+h*.05,19.5)
            text('升级进度:',480-w*.2,y+h*.048,16.5,{224,174,181})
            local target=COST[e.level] or 3000
            local progress=e.level>=5 and target or (e.prob_compen or 0)
            local rate=math.min(1,progress/target)
            local bx=480-w*.1;local bw=w*.18
            image(P..'progress2.png',bx+bw/2,y+h*.048,bw,17.25)
            if rate>0 then
                local n=image(P..'progress1.png',bx+bw*rate/2,y+h*.048,bw*rate,17.25)
                n:setTextureRect(CCRectMake(0,0,224*rate,23));n:setScaleX(bw/224)
            end
            text(progress..'/'..target..'   '..math.floor(rate*100)..'%',bx+6,y+h*.048,13,{224,174,181})
            text(description(e),480-w*.35,y+h*.01,16.5,{180,160,150},w*.42)
            button(P..'up1.png',480+w*.16,y+h*.03,108,51,function()
                ui.send('bag_essence_upgrade',{uid=e.uid,hero=M.hero})
            end,e.level<5 and stones>0)
            local needed=math.min(500,stones,math.max(0,target-progress))
            text('消耗:',548,y-h*.05,16.5,{250,250,150});image(P..'jp4.png',599,y-h*.05,23,24)
            text('x'..needed..'/'..stones,613,y-h*.05,16.5)
        else
            local opened=hero and hero.equiped_ext_skill_limit and i<=hero.equiped_ext_skill_limit
            image(P..(opened and 'jp_bkg.png' or 'jp_no_open.png'),480-w*.4,y,63,64)
            local tip=opened and '尚未铭刻精魄' or ((i==1 or i==4) and '开启条件：铭刻随机开启。' or '开启条件：铭刻随机开启或者神仙飞升'..(i*6-6)..'次自动开启。')
            text(tip,480-w*.35,y+10,19.5,{254,194,111},w*.55)
        end
    end
    local chosen
    for _,e in ipairs(entries(M.hero,true)) do if e.uid==M.selected then chosen=e end end
    if chosen then icon(chosen,780,286,100);text(D.items[chosen.key].name,725,215,19.5)
    else text('选择精魄',737,216,19.5) end
    ui.hit(724,235,112,112,function() M.selecting=true;ui.render() end,true)
    button(P..'mk1.png',480+w*.36,270-h*.21,108,57,function()
        if chosen then ui.send('bag_essence_inscribe',{uid=chosen.uid,hero=M.hero})
        else M.selecting=true;ui.render() end
    end)
    text('每次铭刻会随机顶掉一个已装备的精魄(紫色精魄优先顶掉同类型金色精魄)或开启新的\n格子，开启格子失败会提升幸运值，幸运值越高开启下个格子的概率越高。',480-w*.45,95,18,{210,180,140},w*.9)
    if ui.error then text(ui.error,105,124,15,{255,170,100},740) end
end
return M
