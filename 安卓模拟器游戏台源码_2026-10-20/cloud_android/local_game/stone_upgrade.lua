-- Original stoneUpgradeUI: preview, silver cost, 250-stone multi-select and
-- stone_cost_worth success rate. Local canvas 960x540.
local data=require("local_inventory_data")
local M={hits={}}
local ui,state,root
local CREAM={255,255,224}
local GREEN={0,255,0}
local PALE={254,235,192}
local function image(file,x,y,w,h,parent)
    local n=CCSprite:create(file)
    if not n then return end
    local s=n:getContentSize()
    n:setScaleX(w/s.width); n:setScaleY((h or w*s.height/s.width)/s.height)
    n:setPosition(CCPointMake(x,y)); (parent or root):addChild(n)
    return n
end
local function anchored(file,x,y,w,h,ax,ay,parent)
    local n=image(file,x,y,w,h,parent)
    if n then n:setAnchorPoint(CCPointMake(ax or .5,ay or .5)); n:setPosition(CCPointMake(x,y)) end
    return n
end
local function label(value,x,y,size,color,parent,center,width)
    local n
    if width then n=CCLabelTTF:create(tostring(value),"Arial",size,CCSizeMake(width,0),kCCTextAlignmentLeft)
    else n=CCLabelTTF:create(tostring(value),"Arial",size) end
    n:setAnchorPoint(CCPointMake(center and .5 or 0,width and 1 or .5))
    n:setPosition(CCPointMake(x,y)); n:setColor(ccc3(unpack(color or PALE)))
    local target=parent or root; target:addChild(n)
    return n
end
local function fill(x,y,w,h,color,parent)
    local n=CCLayerColor:create(ccc4(unpack(color)))
    n:setContentSize(CCSizeMake(w,h)); n:setPosition(CCPointMake(x,y)); (parent or root):addChild(n)
    return n
end
local function commas(value)
    local text=tostring(math.floor(tonumber(value) or 0)):reverse():gsub("(%d%d%d)","%1,")
    text=text:reverse(); return (text:gsub("^,",""))
end
local function hit(x,y,w,h,action) table.insert(M.hits,{x=x,y=y,w=w,h=h,action=action}) end
local function entryOf(uid)
    for _,e in ipairs(state.inventory.entries) do if e.uid==uid then return e end end
end
local function itemOf(e) return e and data.items[e.key] end
local function stoneBase(sub,level)
    local row=(data.stones or {})[tostring(sub)..":"..tostring(level)]
    return tonumber(row and row.base or 0) or 0
end
local function stoneWorth(sub,level)
    local row=(data.stones or {})[tostring(sub)..":"..tostring(level)]
    return tonumber(row and row.worth or 0) or 0
end
local function stoneIcon(e,x,y,w,parent)
    local item=itemOf(e); local info=item and item.icon
    if not info then return end
    local n=CCSprite:create(info.file); local s=n:getContentSize()
    local cw,ch=s.width/info.columns,s.height/info.rows
    local idx=info.index+(tonumber(e.level) or 1)-1
    n:setTextureRect(CCRectMake((idx-1)%info.columns*cw,math.floor((idx-1)/info.columns)*ch,cw,ch))
    n:setScale(w/cw); n:setPosition(CCPointMake(x,y)); (parent or root):addChild(n)
    local text="+"..(e.level or 1)
    local shadow=CCLabelTTF:create(text,"Arial",26);shadow:setAnchorPoint(CCPointMake(1,1))
    shadow:setPosition(CCPointMake(cw*.9+1,ch*.9-1));shadow:setColor(ccc3(0,0,0));n:addChild(shadow,1)
    local front=CCLabelTTF:create(text,"Arial",26);front:setAnchorPoint(CCPointMake(1,1))
    front:setPosition(CCPointMake(cw*.9,ch*.9));front:setColor(ccc3(255,128,0));n:addChild(front,2)
end
local STAT_ICON={[1]="CHAR_gong",[2]="CHAR_fang",[3]="CHAR_ming"}
local function maxLevel(sub)
    local maximum=1
    for key in pairs(data.stones or {}) do
        local s,l=string.match(key,"^(%d+):(%d+)$")
        if tonumber(s)==sub then maximum=math.max(maximum,tonumber(l)) end
    end
    return maximum
end
local function availableMaterials()
    local target=entryOf(M.uid); local item=itemOf(target)
    if not item then return {} end
    local list={}
    for _,e in ipairs(state.inventory.entries) do
        local base=data.items[e.key]
        if e.uid~=target.uid and base.category==5 and base.sub_type==item.sub_type
                and (tonumber(e.owner_uid) or 0)==0 then
            local level=tonumber(e.level) or 1
            local ranges={{1,2},{3,4},{5,6},{7,99}}
            local ok=false
            for i,range in ipairs(ranges) do
                if M.filterOn[i] and level>=range[1] and level<=range[2] then ok=true;break end
            end
            if ok then table.insert(list,{entry=e,level=level,worth=stoneWorth(item.sub_type,level)}) end
        end
    end
    table.sort(list,function(a,b)
        if a.level~=b.level then return a.level<b.level end
        return (tonumber(a.entry.prob_compen) or 0)<(tonumber(b.entry.prob_compen) or 0)
    end)
    return list
end
local function checkedMaterials()
    local list={}
    for _,m in ipairs(availableMaterials()) do
        if M.checked[m.entry.uid] then table.insert(list,m) end
    end
    return list
end
local function rate()
    local target=entryOf(M.uid)
    local list=checkedMaterials(); local worth=0
    for _,m in ipairs(list) do worth=worth+m.worth end
    local cost=tonumber(target and target.cost) or 0
    local base=cost>0 and worth/cost or 0
    local comp=(tonumber(target and target.prob_compen) or 0)/100
    return base+comp,comp,#list,worth,cost
end
local function setOffset(v)
    M.scroll=math.max(0,math.min(M.maxScroll or 0,v))
    return M.scroll
end
function M.open(ctx,player,uid)
    ui,state,root=ctx,player,ctx.root
    M.uid=uid;M.mode="preview";M.checked={};M.scroll=0;M.maxScroll=0;M.hits={}
    M.filterOn={true,true,true,true};M.filterOpen=false;M.selectAllMode=true
    ui.render()
end
function M.close() M.uid=nil;M.mode=nil;M.checked={};M.hits={} end
function M.isOpen() return M.uid~=nil end

local function drawPreview()
    local target=entryOf(M.uid); local item=itemOf(target)
    if not target or not item then M.close();return end
    fill(0,0,960,540,{0,0,0,120})
    image("v2/common/frame1.png",480,297,652,448.2)
    image("v2/common/frame2.png",480,313.2,615,399)
    image("v2/common/small_label.png",480,483.3,408.6,54)
    image("v2/stoneUI/title_stone_up.png",480,483.3,150,54)
    stoneIcon(target,355.2,345.6,172.8)
    label(item.name,355.2,248.4,24,PALE,nil,true)
    label("强化预览",566.4,405,30,PALE)
    local level=tonumber(target.level) or 1
    local maximum=maxLevel(item.sub_type)
    image("v2/introUI/level.png",499.2,367.2,41,41)
    label(tostring(level),528,367.2,22,PALE)
    image("v2/packageUI/"..STAT_ICON[item.sub_type]..".png",499.2,313.2,41,41)
    label(string.format("%.1f%%",stoneBase(item.sub_type,level)*100),528,313.2,22,PALE)
    label(level<maximum and "(可提升+1)" or "(可提升+0)",585.6,367.2,22,GREEN)
    local delta=level<maximum and (stoneBase(item.sub_type,level+1)-stoneBase(item.sub_type,level))*100 or 0
    label(string.format("(可提升+%.1f%%)",delta),585.6,313.2,22,GREEN)
    local moneyY=135.3
    image("v2/enhanceUI/mid2.png",480,moneyY,615,37.8)
    local cost=tonumber(target.silver_cost) or 0
    label("银两需求：",268.8,moneyY,23,{255,140,0})
    label("消耗:",403.2,moneyY,20,CREAM)
    label(commas(cost),451.2,moneyY,22,(state.silver>=cost) and GREEN or {255,0,0})
    label("现有:",547.2,moneyY,20,CREAM)
    label(commas(state.silver),595.2,moneyY,22,{189,183,107})
    local per1,per2,count=rate()
    if count>0 then
        label(string.format("已选 %d 颗   成功率 %d%%（补偿 +%d%%）",
            count,math.floor(math.min(1,per1+per2)*100),math.floor(per2*100)),
            355.2,190,19,GREEN)
    end
    image("v2/enhanceUI/pick1.png",360,97,110,48)
    hit(305,73,110,48,function()
        if #availableMaterials()==0 then M.message="没有可用于升级的同类灵石";ui.render();return end
        M.mode="select";M.scroll=0;M.hits={};ui.render()
    end)
    local confirm=image("v2/soulExchangeUI/btn_bkg1.png",600,97,132,44)
    if confirm and (count==0 or level>=maximum) then confirm:setColor(ccc3(120,110,100)) end
    label("确认升级",600,97,18,(count>0 and level<maximum) and PALE or {170,160,150},nil,true)
    hit(534,75,132,44,function()
        if count==0 then M.message="请先选择材料灵石";ui.render();return end
        if level>=maximum then M.message="已达最高等级";ui.render();return end
        local picked=checkedMaterials()
        local ids={}
        for _,m in ipairs(picked) do table.insert(ids,m.entry.uid) end
        M.message=nil;ui.send("bag_stone_upgrade",{uid=target.uid,materials=ids})
    end)
    image("v2/common/close1.png",700.8,502.2,76.8,73.2)
    hit(662.4,465.6,76.8,73.2,function() M.close();ui.render() end)
    if M.message then label(M.message,355.2,218,17,{255,96,72},nil,false,400) end
end

local function drawFilter()
    fill(0,0,960,540,{0,0,0,130})
    image("v2/messageUI/frame1.png",480,270,480,405)
    image("v2/messageUI/frame2.png",480,297,446,324)
    label("等级筛选",480,455,24,PALE,nil,true)
    hit(0,0,960,540,function() end)
    local names={"1-2级","3-4级","5-6级","7级以上"}
    for i=1,4 do
        local y=390-(i-1)*55
        image("v2/multi-selectUI/check_frame.png",320,y,36,36)
        if M.filterOn[i] then image("v2/multi-selectUI/check.png",320,y,36,36) end
        label(names[i],360,y,22,PALE)
        hit(290,y-25,300,50,function()
            M.filterOn[i]=not M.filterOn[i];ui.render()
        end)
    end
    image("v2/batchBuyUI/cancel1.png",400,140,100,50)
    hit(350,115,100,50,function()
        if M.filterBackup then
            for i=1,4 do M.filterOn[i]=M.filterBackup[i] end
        end
        M.filterOpen=false;ui.render()
    end)
    image("v2/batchBuyUI/ensure1.png",560,140,100,50)
    hit(510,115,100,50,function()
        local any=false
        for i=1,4 do if M.filterOn[i] then any=true end end
        if not any then M.message="至少选择一档等级";ui.render();return end
        M.filterOpen=false;ui.render()
    end)
end
local function drawSelect()
    local target=entryOf(M.uid); local item=itemOf(target)
    if not target or not item then M.close();return end
    fill(0,0,960,540,{0,0,0,110})
    image("v2/common/frame3.png",480,270,591.4,518.4)
    M.listLayer=CCLayer:create();root:addChild(M.listLayer)
    local listLayer=M.listLayer
    local top,headerY=513,481
    local list=availableMaterials()
    if M.selectAllMode then
        image("v2/buttons/choose_all1.png",500,headerY,104,46)
        hit(448,headerY-23,104,46,function()
            local need=(tonumber(target.cost) or 0)-(tonumber(target.prob_compen) or 0)/100*(tonumber(target.cost) or 0)
            local count=0
            for _,m in ipairs(list) do
                if count>=250 or need<0 then M.checked[m.entry.uid]=false
                elseif m.worth<=need then M.checked[m.entry.uid]=true;count=count+1;need=need-m.worth
                else M.checked[m.entry.uid]=false;need=need-m.worth end
            end
            M.selectAllMode=false;ui.render()
        end)
    else
        image("v2/buttons/cancel_choose1.png",500,headerY,104,46)
        hit(448,headerY-23,104,46,function()
            for _,m in ipairs(list) do M.checked[m.entry.uid]=false end
            M.selectAllMode=true;ui.render()
        end)
    end
    image("v2/soulExchangeUI/btn_bkg1.png",650,headerY,132,38)
    label("等级筛选",650,headerY,17,PALE,nil,true)
    hit(584,headerY-19,132,38,function()
        M.filterBackup={M.filterOn[1],M.filterOn[2],M.filterOn[3],M.filterOn[4]}
        M.filterOpen=true;ui.render()
    end)
    local rowH=108
    local viewTop,viewBottom=405,55
    M.maxScroll=math.max(0,#list*rowH-(viewTop-viewBottom))
    local startY=viewTop+M.scroll
    for i,m in ipairs(list) do
        local y=startY-(i-1)*rowH
        if y>=viewBottom-20 and y<=viewTop+20 then
            image("v2/charPositionUI/item_bkg.png",480,y,500,94,listLayer)
            stoneIcon(m.entry,300,y,72,listLayer)
            label(itemOf(m.entry).name,350,y+20,20,PALE,listLayer)
            image("v2/introUI/level.png",350,y-22,22,22,listLayer)
            label(tostring(m.level),372,y-22,17,PALE,listLayer)
            image("v2/packageUI/"..STAT_ICON[item.sub_type]..".png",430,y-22,22,22,listLayer)
            label(string.format("%.1f%%",stoneBase(item.sub_type,m.level)*100),452,y-22,17,PALE,listLayer)
            local checked=M.checked[m.entry.uid]
            image("v2/multi-selectUI/check_frame.png",668,y,38,38,listLayer)
            if checked then image("v2/multi-selectUI/check.png",668,y,38,38,listLayer) end
            hit(240,y-47,480,94,function()
                if checked then M.checked[m.entry.uid]=nil
                else
                    local p=rate()
                    if p>=1 then M.message="成功率已足够，可取消后再选";ui.render();return end
                    M.checked[m.entry.uid]=true
                    local per1,per2=rate()
                    if per1+per2>1.5 then M.checked[m.entry.uid]=nil;M.message="成功率超过150%，已取消";ui.render();return end
                end
                ui.render()
            end)
        end
    end
    local per1,per2,count=rate()
    if count>0 then
        local shown=math.min(1,per1+per2)
        label(string.format("成功率 %d%%(加成: +%d%%)",math.floor(shown*100),math.floor(per2*100)),
            240,43.2,22,PALE)
    end
    image("v2/soulExchangeUI/btn_bkg1.png",650,43.2,132,44)
    label("确认选择",650,43.2,18,PALE,nil,true)
    hit(584,21.2,132,44,function()
        local picked=checkedMaterials()
        if #picked==0 then M.message="请选择至少一颗材料灵石";ui.render();return end
        M.message=nil;M.mode="preview";M.hits={};ui.render()
    end)
    image("v2/introUI/close1.png",768,513,54,51)
    hit(741,487.5,54,51,function() M.mode="preview";M.hits={};ui.render() end)
    if M.message then label(M.message,240,70,16,{255,96,72}) end
    if M.filterOpen then drawFilter() end
end
function M.draw(ctx,player)
    if not M.uid then return end
    ui,state,root=ctx,player,ctx.root;M.hits={};M.listLayer=nil
    if M.mode=="select" then drawSelect() else drawPreview() end
end
local function endTouch(x,y)
    for i=#M.hits,1,-1 do
        local h=M.hits[i]
        if x>=h.x and x<=h.x+h.w and y>=h.y and y<=h.y+h.h then h.action();return true end
    end
end
function M.touch(event,x,y)
    if not M.uid then return false end
    if event==CCTOUCHBEGAN or event=="began" then
        M.press={x=x,y=y,scroll=M.scroll,dragged=false}
        return true
    elseif event==CCTOUCHMOVED or event=="moved" then
        if M.press then
            if math.abs(y-M.press.y)>4 or math.abs(x-M.press.x)>4 then
                if M.mode=="select" and not M.filterOpen and x>=220 and x<=740 and y>=55 and y<=405 then
                    M.press.dragged=true
                    local target=setOffset(M.press.scroll+(y-M.press.y))
                    if M.listLayer then M.listLayer:setPositionY(target-M.press.scroll) end
                    return true
                end
            end
        end
        return true
    elseif event==CCTOUCHENDED or event=="ended" then
        local p=M.press;M.press=nil
        if p and not p.dragged and math.abs(y-p.y)<=6 and math.abs(x-p.x)<=6 then endTouch(x,y) end
        ui.render();return true
    end
    return true
end
function M.afterUpdate(newState)
    state=newState
    if not entryOf(M.uid) then M.close();return end
    if M.mode=="select" then M.mode="preview";M.checked={} end
    M.message=nil
end
function M.back()
    if M.mode=="select" then M.mode="preview";M.hits={};return true end
    M.close();return true
end
return M

