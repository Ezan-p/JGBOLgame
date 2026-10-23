-- Reconstructed from ui/filterLayer.lua and ui/batchSaleUI.lua (1061/1263).
-- Display filters are local; sale eligibility and proceeds come from the server.
local data=require("local_inventory_data")
local M={filters={}}
local ui,state,root,H
local GOLD={254,235,192}
local YELLOW={253,190,37}
local function copyFilter(f)
    local result={stars={},hideEquipped=f and f.hideEquipped or false,hideHigh=f and f.hideHigh or false}
    for i=1,5 do result.stars[i]=not f or f.stars[i] end
    return result
end
function M.matches(e,f)
    if not f then return true end
    local item=data.items[e.key]
    return f.stars[item.quality] and (not f.hideEquipped or (e.hero or 0)==0)
        and (not f.hideHigh or (e.level or 1)<=1)
end
function M.matchesTab(e,tab) return M.matches(e,M.filters[tab]) end
function M.reset() M.filters={};M.sale=nil;M.filter=nil;M.confirm=nil;M.message=nil;M.gesture=nil;M.pending=nil end
function M.isOpen() return M.sale~=nil or M.filter~=nil or M.message~=nil end
function M.openFilter(tab,callback)
    local old
    if M.sale then old=M.sale.filter else old=M.filters[tab] end
    M.filter={tab=tab,draft=copyFilter(old),callback=callback};M.gesture=nil
    ui.render()
end
local function eligible(category)
    local rows={}
    for _,e in ipairs(state.inventory.entries) do
        if data.items[e.key].category==category and e.sale_eligible then table.insert(rows,e) end
    end
    table.sort(rows,function(a,b)
        local x,y=data.items[a.key],data.items[b.key]
        if x.quality~=y.quality then return x.quality<y.quality end
        if a.level~=b.level then return a.level<b.level end
        if x.name~=y.name then return x.name>y.name end
        return a.uid<b.uid
    end)
    return rows
end
function M.openSale(tab)
    if #eligible(tab)==0 then M.message="没有可以出售的物品"
    else M.sale={tab=tab,selected={},offset=0,chooseAll=true} end
    M.gesture=nil;ui.render()
end
local function addHit(x,y,w,h,fn,scrolled)
    table.insert(M.hits,{x=x,y=y,w=w,h=h,fn=fn,scrolled=scrolled})
end
local function artButton(file,x,y,w,h,fn,parent,scrolled)
    local n=H.image(file,x,y,w,h,parent)
    addHit(x-w/2,y-h/2,w,h,fn,scrolled)
    return n
end
local function check(x,y,h,selected,fn,parent,scrolled)
    H.image("v2/multi-selectUI/check_frame.png",x,y,h,h,parent)
    if selected then H.image("v2/multi-selectUI/check.png",x,y,h*65/77,h*66/77,parent) end
    if fn then addHit(x-h/2,y-h/2,h,h,fn,scrolled) end
end
local function closeSale() M.sale=nil;M.confirm=nil;M.pending=nil;M.gesture=nil;ui.render() end
local function setOffset(v)
    local s=M.scroll
    if not s or not M.sale then return end
    M.sale.offset=math.max(0,math.min(s.max,v));s.node:setPositionY(M.sale.offset)
end
local function selectCount()
    local n=0
    for _,selected in pairs(M.sale.selected) do if selected then n=n+1 end end
    return n
end
local function toggle(e)
    if M.sale.selected[e.uid] then M.sale.selected[e.uid]=nil
    elseif selectCount()>=500 then M.message="每次最多出售500件装备"
    else M.sale.selected[e.uid]=true end
    ui.render()
end
local function ensureSale()
    local ids,total,stones={},0,false
    for _,e in ipairs(eligible(M.sale.tab)) do
        if M.sale.selected[e.uid] then
            table.insert(ids,e.uid);total=total+e.sale_price_cents
            if #(e.stones or {})>0 then stones=true end
        end
    end
    if #ids==0 then M.message="没有选择出售装备"
    else M.confirm={uids=ids,total=math.floor(total/100),stones=stones} end
    ui.render()
end
local function saleFrame()
    H.fill(0,0,960,540,{0,0,0,100})
    H.fill(24,13.5,912,513,{40,25,20,255})
    H.image("v2/introUI/intro_bkg.png",480,270,912,513)
    H.image("v2/packageUI/board_edge1.png",24,270,15,513)
    H.image("v2/packageUI/board_edge1.png",936,270,15,513)
    H.image("v2/packageUI/board_edge2.png",480,522,930,37)
    H.image("v2/packageUI/board_edge2.png",480,18,930,37):setFlipY(true)
    artButton("v2/introUI/close1.png",931,518,63,60,closeSale)
    artButton("v2/multi-selectUI/back1.png",336,54,145,51,closeSale)
    artButton("v2/introUI/sale1.png",624,54,154,72,ensureSale)
    if ui.busy or ui.error then H.label(ui.busy and "正在保存…" or ui.error,480,92,16,GOLD,nil,true) end
    if ui.failed then addHit(250,76,460,30,function() ui.send("state",{}) end) end
end
local function drawSale()
    saleFrame()
    local rows={}
    for _,e in ipairs(eligible(M.sale.tab)) do
        if M.matches(e,M.sale.filter) then table.insert(rows,e) end
    end
    -- Original .1/.19/.83/.71 touch area, header .7w/.1h and .8w/.21h cells.
    local x,y,w,h=96,102.6,796.8,383.4
    local pitch,header=113.4,54
    local c=CCLayer:create();c:setContentSize(CCSizeMake(w,math.max(h,header+#rows*pitch)))
    local view=CCScrollView:create(CCSizeMake(w*root:getScaleX(),h*root:getScaleY()),c)
    view:setTouchEnabled(false);view:setPosition(CCPointMake(x,y));root:addChild(view)
    M.scroll={node=c,x=x,y=y,w=w,h=h,max=math.max(0,header+#rows*pitch-h)}
    setOffset(M.sale.offset)
    H.label("每次最多出售500件装备",201.6,h-header/2,24,GOLD,c,true)
    local all=not M.sale.chooseAll
    artButton(all and "v2/buttons/cancel_choose1.png" or "v2/buttons/choose_all1.png",537.6,h-27,125,58,function()
        if all then for _,e in ipairs(rows) do M.sale.selected[e.uid]=nil end
        else
            local count=selectCount()
            for _,e in ipairs(rows) do
                if not M.sale.selected[e.uid] and count<500 then M.sale.selected[e.uid]=true;count=count+1 end
            end
        end
        M.sale.chooseAll=all
        ui.render()
    end,c,true)
    artButton("v2/buttons/filter21.png",672,h-27,118,66,function() M.openFilter(M.sale.tab) end,c,true)
    for i,e in ipairs(rows) do
        local item=data.items[e.key];local cy=h-header-(i-.5)*pitch
        H.image("v2/packageUI/xinxilan.png",384,cy,768,108,c)
        H.icon(item,77,cy,80,c,e.level)
        H.label(item.name,153.6,cy+pitch*.2,25,GOLD,c)
        H.label(string.rep("★",item.quality),384,cy+pitch*.2,21,YELLOW,c)
        H.image("v2/packageUI/level.png",168,cy-pitch*.2,30,30,c)
        H.label(e.level,192,cy-pitch*.2,25,YELLOW,c)
        H.image("v2/packageUI/"..({"CHAR_gong","CHAR_fang","CHAR_ming"})[item.category]..".png",307,cy-pitch*.2,30,30,c)
        H.label(e.value,332,cy-pitch*.2,25,YELLOW,c)
        check(614.4,cy,79.4,M.sale.selected[e.uid],nil,c,true)
        addHit(0,cy-pitch/2,768,pitch,function() toggle(e) end,true)
    end
    if #rows==0 then H.label("没有可以出售的物品",480,280,25,GOLD,nil,true) end
end
local function drawFilter()
    M.hits={};M.scroll=nil
    H.fill(0,0,960,540,{0,0,0,180})
    H.image("v2/messageUI/frame1.png",480,297,480,405)
    H.image("v2/messageUI/frame2.png",480,317.25,446.4,324)
    local f=M.filter.draft
    for i=1,5 do
        local star=i;local col=(i-1)%2;local row=math.floor((i-1)/2)
        local x=col==0 and 412.8 or 609.6
        local y=459-(row+.5)*66.825
        local n=H.label("显示"..i.."星 ",x,y,26,GOLD)
        n:setAnchorPoint(CCPointMake(1,.5))
        check(x+26.73,y,53.46,f.stars[i],nil)
        addHit(x-125,y-29,180,58,function() f.stars[star]=not f.stars[star];M.filter.error=nil;ui.render() end)
    end
    local y=207.9
    for i,text in ipairs({"隐藏已装备 ","隐藏等级>1 "}) do
        local key=i==1 and "hideEquipped" or "hideHigh"
        local x=i==1 and 412.8 or 609.6
        local n=H.label(text,x,y,23,GOLD);n:setAnchorPoint(CCPointMake(1,.5))
        check(x+26.73,y,53.46,f[key],nil)
        addHit(x-142,y-29,197,58,function() f[key]=not f[key];ui.render() end)
    end
    artButton("v2/batchBuyUI/cancel1.png",360,130.95,130,56.7,function() M.filter=nil;ui.render() end)
    artButton("v2/batchBuyUI/ensure1.png",600,130.95,130,56.7,function()
        local any=false;for i=1,5 do if f.stars[i] then any=true end end
        if not any then M.filter.error="请至少选择一个星级";ui.render();return end
        local callback=M.filter.callback
        if M.sale then
            M.sale.filter=copyFilter(f);M.sale.offset=0
            for _,e in ipairs(eligible(M.sale.tab)) do
                if not M.matches(e,f) then M.sale.selected[e.uid]=nil end
            end
        else M.filters[M.filter.tab]=copyFilter(f) end
        M.filter=nil
        if callback then callback() end
        ui.render()
    end)
    if M.filter.error then H.label(M.filter.error,480,174,18,YELLOW,nil,true) end
end
local function drawConfirm()
    M.hits={};M.scroll=nil
    H.fill(0,0,960,540,{0,0,0,100})
    H.image("v2/rechargeUI/tip.png",480,270,607,382)
    local c=M.confirm
    H.label("出售这些道具将获得"..c.total.."银两",480,c.stones and 302 or 270,25,GOLD,nil,true)
    if c.stones then H.label("(装备上已镶嵌的灵石会自动卸下)",480,238,22,GOLD,nil,true) end
    artButton("v2/multi-selectUI/back1.png",340.4,124.8,145,51,function() M.confirm=nil;ui.render() end)
    artButton("v2/multi-selectUI/ensure1.png",619.6,124.8,145,51,function()
        local args={category=M.sale.tab,uids=c.uids};M.pending=c.uids;M.confirm=nil
        ui.send("bag_sell_batch",args)
    end)
end
function M.bind(context,player,helpers) ui,state,root,H=context,player,context.root,helpers end
function M.draw()
    M.hits={};M.scroll=nil
    if not M.isOpen() then return end
    ui.clearHits()
    if M.sale then drawSale() end
    if M.filter then drawFilter() end
    if M.confirm then drawConfirm() end
    if M.message then
        M.hits={};M.scroll=nil
        H.fill(0,0,960,540,{0,0,0,100})
        H.image("v2/rechargeUI/tip.png",480,270,607,382)
        H.label(M.message,480,270,26,GOLD,nil,true)
        artButton("v2/batchBuyUI/ensure1.png",480,125,130,57,function() M.message=nil;ui.render() end)
    end
end
function M.afterUpdate(player)
    state=player
    if not M.sale or not M.pending then return end
    local exists={};for _,e in ipairs(state.inventory.entries) do exists[e.uid]=true end
    for _,uid in ipairs(M.pending) do if exists[uid] then return end end
    M.pending=nil;M.sale.selected={};M.sale.filter=nil;M.sale.offset=0;M.sale.chooseAll=true
    if #eligible(M.sale.tab)==0 then M.sale=nil end
end
function M.back()
    if not M.isOpen() then return false end
    M.gesture=nil
    if M.message then M.message=nil
    elseif M.confirm then M.confirm=nil
    elseif M.filter then M.filter=nil
    else M.sale=nil;M.pending=nil end
    ui.render();return true
end
local function hitAt(x,y)
    for i=#M.hits,1,-1 do
        local b=M.hits[i];local bx,by=x,y
        if b.scrolled then
            local s=M.scroll
            if not s or x<s.x or x>s.x+s.w or y<s.y or y>s.y+s.h then bx=-10000
            else bx=x-s.x;by=y-s.y-M.sale.offset end
        end
        if bx>=b.x and bx<=b.x+b.w and by>=b.y and by<=b.y+b.h then return b end
    end
end
function M.touch(event,x,y)
    if not M.isOpen() then return false end
    if event==CCTOUCHBEGAN or event=="began" then
        local s=M.scroll
        M.gesture={x=x,y=y,hit=hitAt(x,y),offset=M.sale and M.sale.offset or 0,
            scroll=s and x>=s.x and x<=s.x+s.w and y>=s.y and y<=s.y+s.h}
    elseif M.gesture then
        local g=M.gesture
        if event==CCTOUCHMOVED or event=="moved" then
            if math.abs(x-g.x)>7 or math.abs(y-g.y)>7 then g.dragged=true end
            if g.scroll and g.dragged then setOffset(g.offset+y-g.y) end
        elseif event==CCTOUCHENDED or event=="ended" then
            M.gesture=nil
            if not g.dragged and g.hit and hitAt(x,y)==g.hit then g.hit.fn() end
        else M.gesture=nil end
    end
    return true
end
return M
