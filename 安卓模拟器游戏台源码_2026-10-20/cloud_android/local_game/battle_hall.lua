-- Battle mode selection and actual persistent training/trait loadouts.
local D=require('local_combat_rules')
local items=require('local_inventory_data').items
local M={tab='modes',hero=1,page=1}
local ui,state,root
local function image(path,x,y,w,h)
    local n=CCSprite:create(path);local s=n:getContentSize()
    n:setScaleX(w/s.width);n:setScaleY(h/s.height);n:setPosition(CCPointMake(x,y));root:addChild(n);return n
end
local function text(t,x,y,size,width,color)
    local n=CCLabelTTF:create(tostring(t),'Arial',size or 19,CCSizeMake(width or 760,0),kCCTextAlignmentLeft)
    n:setAnchorPoint(CCPointMake(0,1));n:setPosition(CCPointMake(x,y));n:setColor(ccc3(unpack(color or {244,221,173})));root:addChild(n);return n
end
local function button(t,x,y,w,fn,enabled)
    local n=image('v2/soulExchangeUI/btn_bkg1.png',x+w/2,y+18,w,36)
    text(t,x+10,y+29,17,w-15,enabled==false and {125,115,105} or nil)
    ui.hit(x,y,w,36,fn,enabled~=false,n)
end
local function request(title,op,args)
    M.confirm={title=title,op=op,args=args};ui.render()
end
local function picked()
    M.hero=math.max(1,math.min(M.hero,#state.heroes));return state.heroes[M.hero]
end
local function heroSelect()
    local h=picked();text(h.name..'  Lv.'..h.level..(h.supporting and ' · 助阵中' or ''),300,427,23,400)
    button('上一位',110,390,125,function() M.hero=(M.hero-2)%#state.heroes+1;ui.render() end)
    button('下一位',730,390,125,function() M.hero=M.hero%#state.heroes+1;ui.render() end)
    return h
end
local function materials(raw)
    local parts={}
    for token in string.gmatch(raw or '', '[^/]+') do
        local kind,id,level,count=string.match(token,'(%d+)|(%d+)|(%d+)|(%d+)')
        if id then local item=items[(kind=='6' and 's' or 'i')..id];table.insert(parts,(item and item.name or id)..' ×'..count..'（'..level..'级）') end
    end
    return table.concat(parts,'、')
end
local function modes()
    text('本地演武 · 体力与奖励会保存',95,429,20)
    for i,m in ipairs(state.combat_modes) do
        local y=345-(i-1)*76;image('v2/packageUI/xinxilan.png',480,y+22,790,68)
        text(m.name,105,y+46,23,210);text(m.description,305,y+43,17,400)
        local rec=(state.battle_modes or {})[m.id] or {}
        text('胜场 '..(rec.wins or 0)..'  积分 '..(rec.score or 0),305,y+16,15,400)
        button('挑战 · '..m.energy..'体力',690,y+4,170,function() request('消耗 '..m.energy..' 点体力开始'..m.name..'？','battle_mode',{mode=m.id}) end,state.energy>=m.energy)
    end
end
local function training()
    local h=heroSelect();local learned=h.battle_training or {};local level=learned.native_level or 1
    text('原生法术：'..h.skill_name..'  Lv.'..level,110,369,24,620)
    text('觉醒需要神仙20级、原生法术10级；材料只消耗未装备法术。',110,331,17,750)
    local cost=100*h.quality*level
    button('升级 · '..cost..'银两',110,269,225,function() request('将'..h.skill_name..'提升一级，消耗 '..cost..' 银两？','battle_native_upgrade',{hero=h.id}) end,level<10 and state.silver>=cost)
    local names={'攻击','守御','法力'}
    for i=1,3 do
        local row=D.awaken[tostring(i)];local kind=i
        button(names[i]..'觉醒 +'..row.plus_value,110+(i-1)*260,207,245,function()
            request(names[kind]..'觉醒，消耗：'..materials(row.material_list),'battle_awaken',{hero=h.id,kind=kind})
        end,level>=10 and h.level>=20 and (learned.awaken or 0)==0 and D.awaken_rates[tostring(h.skill_id)]~=nil)
    end
    text((learned.awaken or 0)>0 and ('已觉醒：'..names[learned.awaken]) or '觉醒同时提升原生法术效果，三种方向只能选择一种。',110,192,17,760)
    local cheer=learned.cheer_level or 0;local row=D.cheer[tostring(cheer)]
    text('助阵额外被动法术效能：'..string.format('%.1f',tonumber(row.plus_rate)*100)..'%  · '..cheer..'阶',110,168,18,670)
    local needed=math.min(999,tonumber(string.match(row.consume_list,'|(%d+)$')) or 600)
    local material=items['i1206'];local price=needed*material.price
    button('购材料×'..needed..' · '..price,110,109,265,function() request('花费 '..price..' 银两兑换进修材料 ×'..needed..'？','bag_buy',{key='i1206',count=needed}) end,state.silver>=price)
    button('助阵法术进修',680,109,175,function() request('消耗：'..materials(row.consume_list),'battle_cheer_upgrade',{hero=h.id}) end,h.supporting and cheer<500)
end
local function traits()
    local h=heroSelect();local list={};for _,t in pairs(M.tab=='stars' and D.stars or D.traits) do table.insert(list,t) end
    table.sort(list,function(a,b)return a.id<b.id end)
    local max=math.ceil(#list/3);M.page=math.max(1,math.min(M.page,max))
    for i=(M.page-1)*3+1,math.min(#list,M.page*3) do
        local t=list[i];local item=items['i'..t.id];local y=302-((i-1)%3)*88
        image('v2/packageUI/xinxilan.png',480,y+28,790,81)
        local own
        for _,e in ipairs(state.inventory.entries) do
            if e.key==item.key and (not own or e.hero==h.id or own.hero~=h.id and e.level>own.level) then own=e end
        end
        text(t.name..(M.tab=='stars' and '' or t.id>=10200 and ' · 高阶' or ' · 基础')..(own and ' Lv.'..own.level or ''),105,y+60,21,430)
        local desc=t.description;local level=own and own.level or 1
        if t.values then
            local value=t.values[level];local pct=t.family%2==1 or t.family>=11
            desc=string.gsub(desc,'%%s',string.format('%.2f',pct and value*100 or value)..(pct and '%%' or ''),1)
        else for _,values in ipairs(t.levels) do desc=string.gsub(desc,'%%s',string.format('%.1f',values[level]*100)..'%%',1) end end
        text(desc,105,y+31,15,480)
        if M.tab~='stars' then
            text('阵容下方可打开精魄铭刻',610,y+48,14,225)
        elseif own then
            local e=own
            button(e.hero==h.id and '卸下' or '装备',610,y+25,105,function() request((e.hero==h.id and '卸下' or '装备')..t.name..'？','bag_equip',{uid=e.uid,hero=e.hero==h.id and 0 or h.id}) end)
            button('升级',730,y+25,105,function() request('花费 '..e.upgrade_cost..' 银两升级'..t.name..'？','bag_upgrade',{uid=e.uid}) end,e.level<t.max_level and state.silver>=e.upgrade_cost)
            text(e.hero==h.id and '已装备于当前神仙' or e.hero==0 and '未装备' or '装备于其他神仙',610,y+17,13,245)
        else
            button('兑换 '..item.price..'银两',610,y+25,225,function() request('花费 '..item.price..' 银两兑换'..t.name..'？','bag_buy',{key=item.key}) end,state.silver>=item.price)
        end
    end
    button('上一页',110,94,130,function() M.page=M.page-1;ui.render() end,M.page>1)
    text(M.page..' / '..max..(M.tab=='stars' and '  · 觉醒后最多五颗，同类不重复' or '  · 每位神仙最多四项，同类不重复'),270,121,17,430)
    button('下一页',730,94,130,function() M.page=M.page+1;ui.render() end,M.page<max)
end
function M.draw(context,player)
    ui,state,root=context,player,context.root
    image('v2/introUI/intro_bkg.png',480,270,960,540)
    text('演武堂',52,522,29,210)
    text('银两 '..state.silver..'  体力 '..state.energy,500,515,19,330)
    button('返回阵容',800,476,130,function() ui.navigate('lineup') end)
    for i,p in ipairs({{'modes','挑战'},{'training','修炼'},{'traits','特技'},{'stars','星宿'}}) do
        local tab=p[1];button((M.tab==tab and '◆ ' or '')..p[2],90+(i-1)*195,440,185,function() M.tab=tab;ui.render() end)
    end
    if M.tab=='modes' then modes() elseif M.tab=='training' then training() else traits() end
    text(ui.busy and '正在保存…' or ui.error or ui.notice or '',70,55,16,820)
    if ui.failed then button('重试连接',740,18,150,function() ui.send('state',{}) end) end
    if M.confirm then
        ui.clearHits();local n=CCLayerColor:create(ccc4(0,0,0,190));root:addChild(n)
        image('v2/packageUI/board_bkg.png',480,290,750,300)
        text(M.confirm.title,150,388,23,660)
        button('取消',200,175,170,function() M.confirm=nil;ui.render() end)
        button('确定',580,175,170,function() local c=M.confirm;M.confirm=nil;ui.send(c.op,c.args) end)
    end
end
function M.back() if M.confirm then M.confirm=nil;ui.render() else ui.navigate('lineup') end end
return M
