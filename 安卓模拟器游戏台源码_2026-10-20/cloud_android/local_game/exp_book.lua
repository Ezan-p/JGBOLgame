-- Original ui/expbookUI.lua layout, mapped from the 1280x720 design to the
-- local 960x540 canvas (exactly 0.75x).  Sources:
--   addExpbookFrameUI / createExpbookMutilSelectLayer / createExpBookCell /
--   refreshCortege (setCharacter*) / refreshExpLabels / createFreshYesNo.
local inventoryData=require("local_inventory_data")
local lineupData=require("local_lineup_data")
local expData=require("local_exp_data")
local M={uid=nil,hero=nil,books={},selection={},offset=0,press=nil,hits={},
    picker=false,pickerPage=1,pickerPick=nil,confirm=nil,notice=nil}
local ui,state,root
local GOLD={255,223,166}
local PALE={254,235,192}
local YELLOW={254,188,39}
local MUTED={186,169,157}
local RED={241,67,21}
local GREEN={178,255,63}
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
local function atlas(info,x,y,w,parent)
    if not info then return end
    local n=CCSprite:create(info.file)
    if not n then return end
    local s=n:getContentSize()
    local cw,ch=s.width/info.columns,s.height/info.rows
    n:setTextureRect(CCRectMake((info.index-1)%info.columns*cw,math.floor((info.index-1)/info.columns)*ch,cw,ch))
    n:setScale(w/cw); n:setPosition(CCPointMake(x,y)); (parent or root):addChild(n)
    return n
end
local function hit(x,y,w,h,action) table.insert(M.hits,{x=x,y=y,w=w,h=h,action=action}) end

-- 1280x720 design coordinates x 0.75 (960x540 canvas).
local BKG={480,270,935.25,507.75}
local CLOSE={912.75,491.25,78.75,75}
local USE={480,60.75,136.5,67.5}
local ALL={750,60.75,120,67.5}
local CARD={217.5,273.75,365.25,331.5}
local PORTRAIT={217.5,294.75,292.5,244.5}
local STAR={217.5,180,144.5,30}
local NAME={82.5,294.75,48}
local STATS={217.5,150,296.5,30}
local EXPBAR={217.5,120.75,290.25,24.75}
local LIST={417.6,99.9,508.8,351}
local CELL_H=105.3
local SUM={164.25,75}
local LVLINE={164.25,47.25}
local sendUse

local function expTable(quality)
    local tables=expData.exp_table or {}
    return tables[tostring(quality)] or tables[quality] or {}
end
local function topLevel(quality)
    local top=0
    for k in pairs(expTable(quality)) do local n=tonumber(k); if n and n>top then top=n end end
    return top
end
local function needExp(quality,level)
    local t=expTable(quality)
    local v=t[level]
    if v==nil then v=t[tostring(level)] end
    if v~=nil then return tonumber(v) or 0 end
    local top=topLevel(quality)
    return tonumber(t[top] or t[tostring(top)] or 0) or 0
end
local function roleLevel()
    return math.max(1,tonumber(state.level) or (1+math.floor((tonumber(state.experience) or 0)/200)))
end
local function normalLevel() return math.floor(roleLevel()*2.5) end
local function capLevel(quality)
    local role=roleLevel(); local top=topLevel(quality); local cap=role*3
    if top>0 and top<cap then cap=top end
    return cap
end
local function preview(quality,level,cur,amount)
    local cap=capLevel(quality); local normal=normalLevel(); local maximum=roleLevel()*3
    local rest=tonumber(amount) or 0; local added=0
    level=tonumber(level) or 1; cur=tonumber(cur) or 0
    while rest>1e-9 and level<cap do
        local rate=1
        if level>=maximum then rate=0 elseif level>=normal then rate=0.2 end
        if rate<=0 then break end
        local need=needExp(quality,level)
        if need<=0 then break end
        local gap=need-cur
        if gap<=0 then
            cur=0; level=level+1
        else
            local raw=gap/rate
            if rest+1e-9>=raw then
                added=added+gap; cur=0; rest=rest-raw; level=level+1
            else
                local gain=rest*rate; cur=cur+gain; added=added+gain; rest=0
            end
        end
    end
    return level,math.floor(cur),math.floor(added),math.floor(rest)
end
local function heroById(id)
    for _,h in ipairs(state.heroes or {}) do if h.id==id then return h end end
end
local function eligibleHeroes()
    local list={}
    for _,h in ipairs(state.heroes or {}) do
        if (tonumber(h.level) or 1)<capLevel(h.quality) then table.insert(list,h) end
    end
    table.sort(list,function(a,b)
        local qa,qb=tonumber(a.quality) or 0,tonumber(b.quality) or 0
        if qa~=qb then return qa>qb end
        local la,lb=tonumber(a.level) or 1,tonumber(b.level) or 1
        if la~=lb then return la>lb end
        return a.id<b.id
    end)
    return list
end
local function buildBooks()
    local list={}
    for _,e in ipairs(((state.inventory or {}).entries) or {}) do
        local item=inventoryData.items[e.key]
        if item and item.action=="experience" then
            local exp=tonumber(item.original and item.original.experience_plus) or 0
            for i=1,e.count do
                list[#list+1]={uid=e.uid,key=e.key,exp=exp,level=item.original.show_level or 1,name=item.name,idx=i}
            end
        end
    end
    table.sort(list,function(a,b)
        if a.exp~=b.exp then return a.exp<b.exp end
        if a.uid~=b.uid then return a.uid<b.uid end
        return a.idx<b.idx
    end)
    return list
end
local function selectionTotal()
    local total=0
    for i,_ in pairs(M.selection) do local b=M.books[i]; if b then total=total+b.exp end end
    return total
end
local function clampOffset(v)
    local max=math.max(0,#M.books*CELL_H-LIST[4])
    return math.max(0,math.min(max,tonumber(v) or 0))
end


local ICONS={"health","damage","defence","mana"}
local function statValues(h,plus)
    local g=h.growth or {}
    return {h.hp+(g.hp or 0)*plus,h.attack+(g.attack or 0)*plus,
            h.defense+(g.defense or 0)*plus,h.magic+(g.magic or 0)*plus}
end
local function drawStats(h,plus)
    local sw=STATS[3]; local bs=sw/514
    image("v2/trainingUI/stats_bkg.png",STATS[1],STATS[2],sw,52*bs)
    local left=STATS[1]-sw/2
    local start,step,isz=514*0.04*bs,514*0.23*bs,41*bs
    local vals=statValues(h,plus)
    for i=1,4 do
        local xx=left+start+step*(i-1)
        image("v2/introUI/"..ICONS[i]..".png",xx+isz/2,STATS[2],isz,isz)
        label(math.floor(vals[i]),xx+isz+0.01*sw,STATS[2],14,GOLD)
    end
end
local function drawExp(h,level,cur,nextv)
    image("v2/expbookUI/exp_bkg.png",EXPBAR[1],EXPBAR[2],EXPBAR[3],EXPBAR[4])
    local w=EXPBAR[3]; local lx=EXPBAR[1]-w*0.41343669
    local str=tostring(level); local digits,total={},0
    for i=1,#str do
        local n=CCSprite:create("v2/vip/"..str:sub(i,i)..".png")
        if n then
            local s=n:getContentSize(); local sc=15.75/s.height
            n:setScale(sc); n:setAnchorPoint(CCPointMake(0,.5))
            digits[#digits+1]=n; total=total+s.width*sc
        end
    end
    local x=lx-total/2
    for _,n in ipairs(digits) do
        n:setPosition(CCPointMake(x,EXPBAR[2])); root:addChild(n)
        x=x+n:getContentSize().width*n:getScale()
    end
    local ratio=nextv>0 and math.min(1,cur/nextv) or 0
    if ratio>0 then
        local f=CCSprite:create("v2/expbookUI/exp.png")
        if f then
            local s=f:getContentSize()
            f:setTextureRect(CCRectMake(0,0,s.width*ratio,s.height))
            f:setAnchorPoint(CCPointMake(0,.5)); f:setScale(14.25/s.height)
            f:setPosition(CCPointMake(EXPBAR[1]-w*0.32558139,EXPBAR[2]))
            root:addChild(f)
        end
    end
    label(cur.."/"..nextv,EXPBAR[1],EXPBAR[2],20,GOLD,nil,true)
end
local function drawCharacter(h,level,cur,nextv,plus)
    local info=lineupData.heroes[tostring(h.id)] or {}
    local light=(h.quality==3 and "v2/inheritUI/three_star.jpg")
        or (h.quality==4 and "v2/inheritUI/four_star.jpg")
        or (h.quality==5 and "v2/inheritUI/five_star.jpg")
    if light then image(light,CARD[1],CARD[2],CARD[3],CARD[4]) end
    local node=h.sprite and CCSprite:create(h.sprite)
    if node then
        local s=node:getContentSize()
        node:setScale(math.min(PORTRAIT[3]/s.width,PORTRAIT[4]/s.height))
        node:setPosition(CCPointMake(PORTRAIT[1],PORTRAIT[2])); root:addChild(node)
    end
    local stars=CCSprite:create("v2/introUI/stars.png")
    if stars then
        local s=stars:getContentSize()
        stars:setTextureRect(CCRectMake(0,0,s.width*(h.quality or 1)/5,s.height))
        stars:setScale(STAR[4]/s.height)
        stars:setPosition(CCPointMake(STAR[1],STAR[2])); root:addChild(stars)
    end
    if info.name_icon then atlas(info.name_icon,NAME[1],NAME[2],NAME[3])
    else label(h.name,NAME[1],NAME[2],16,PALE,nil,true) end
    drawStats(h,plus or 0)
    drawExp(h,level,cur,nextv)
end
local function itemIcon(key,x,y,w,parent)
    local item=inventoryData.items[key]
    local info=item and item.icon
    if not info then return end
    if info.index then atlas(info,x,y,w,parent) return end
    local n=CCSprite:create(info.file)
    if n then
        local s=n:getContentSize(); n:setScale(w/s.width)
        n:setPosition(CCPointMake(x,y)); parent:addChild(n)
    end
end
local function drawCell(book,index,parent,cx,cy)
    local cw,ch=LIST[3],CELL_H; local left=cx-cw/2
    image("v2/expbookUI/item_bkg.png",cx,cy,cw,ch*0.9,parent)
    itemIcon(book.key,left+cw*0.15,cy,58,parent)
    label(book.name,left+cw*166/685,cy+ch*0.25,22,PALE,parent)
    image("v2/introUI/level.png",left+cw*186/685,cy-ch*0.25,24,24,parent)
    label(book.level,left+cw*216/685,cy-ch*0.25,18,YELLOW,parent)
    label("经验: "..book.exp,left+cw*280/685,cy-ch*0.25,18,YELLOW,parent)
    image("v2/multi-selectUI/check_frame.png",left+cw*0.85,cy,52,52,parent)
    if M.selection[index] then
        image("v2/multi-selectUI/check.png",left+cw*0.85,cy,44,44,parent)
    end
end
local function drawList()
    local lw,lh=LIST[3],LIST[4]
    if #M.books==0 then
        label("暂无仙佛密卷",LIST[1]+lw/2,LIST[2]+lh/2,22,YELLOW,nil,true)
        return
    end
    local contentH=math.max(lh,#M.books*CELL_H)
    local container=CCLayer:create()
    container:setContentSize(CCSizeMake(lw,contentH))
    local view=CCScrollView:create(CCSizeMake(lw*root:getScaleX(),lh*root:getScaleY()),container)
    view:setTouchEnabled(false)
    view:setPosition(CCPointMake(LIST[1],LIST[2]))
    root:addChild(view)
    for i,b in ipairs(M.books) do
        local cy=lh-(i-0.5)*CELL_H
        if cy>-CELL_H and cy<lh+CELL_H then drawCell(b,i,container,lw/2,cy) end
    end
    container:setPositionY(M.offset)
end
local function drawSummary(hero,total)
    local lv1=hero.level
    local lv2,cur2,added,wasted=preview(hero.quality,lv1,hero.cur_exp,total)
    label(added,SUM[1],SUM[2],22,GOLD)
    local n1=label(" "..lv1.." ",LVLINE[1],LVLINE[2],22,GOLD)
    local w1=n1:getContentSize().width
    local arrow=image("v2/expbookUI/arrow.png",LVLINE[1]+w1+6,LVLINE[2],20,11)
    if arrow then
        arrow:setAnchorPoint(CCPointMake(0,.5))
        arrow:setPosition(CCPointMake(LVLINE[1]+w1+6,LVLINE[2]))
    end
    label(" "..lv2,LVLINE[1]+w1+6+20,LVLINE[2],22,GOLD)
    return lv2,cur2,added,wasted
end
local function drawConfirm()
    M.hits={}
    fill(0,0,960,540,{0,0,0,150})
    image("v2/rechargeUI/tip.png",480,270,455.25,286.5)
    local c=M.confirm
    label(string.format("消耗仙佛密卷经验: %d",c.total),298,304,20,GOLD)
    label(string.format("神仙实际获得经验: %d(%d%%)",c.added,math.floor(c.added*100/c.total)),298,270,20,GOLD)
    label("是否继续？",298,230,20,GOLD)
    image("v2/batchBuyUI/cancel1.png",366,163,127.4,63)
    hit(366-63.7,163-31.5,127.4,63,function() M.confirm=nil;ui.render() end)
    image("v2/batchBuyUI/ensure1.png",594,163,127.4,63)
    hit(594-63.7,163-31.5,127.4,63,function() sendUse() end)
end


local function drawPicker()
    M.hits={}
    fill(0,0,960,540,{0,0,0,180})
    image("v2/common/frame3.png",480,297,576,448.2)
    label("选择神仙",480,500,22,PALE,nil,true)
    local list=eligibleHeroes()
    local per=8
    local maxPage=math.max(1,math.ceil(#list/per))
    if M.pickerPage>maxPage then M.pickerPage=maxPage end
    for i=(M.pickerPage-1)*per+1,math.min(#list,M.pickerPage*per) do
        local h=list[i]; local slot=(i-1)%per
        local x=260+(slot%4)*140
        local y=414-math.floor(slot/4)*118
        local info=lineupData.heroes[tostring(h.id)] or {}
        fill(x-64,y-54,128,108,{52,34,26,210})
        if info.icon then atlas(info.icon,x,y+16,60)
        else image("v2/common/frame1.png",x,y+16,60,60) end
        label(h.name,x,y-28,14,PALE,nil,true)
        label("Lv."..(h.level or 1).."  "..(h.cur_exp or 0).."/"..(h.next_exp or 0),x,y-44,12,MUTED,nil,true)
        if M.pickerPick==h.id then image("v2/multi-selectUI/check_frame.png",x,y,132,112) end
        hit(x-64,y-54,128,108,function() M.pickerPick=h.id;ui.render() end)
    end
    if maxPage>1 then
        image("v2/soulExchangeUI/btn_bkg1.png",300,200,90,34)
        label("上一页",300,200,14,GOLD,nil,true)
        hit(255,183,90,34,function() M.pickerPage=math.max(1,M.pickerPage-1);ui.render() end)
        label(M.pickerPage.."/"..maxPage,480,200,14,MUTED,nil,true)
        image("v2/soulExchangeUI/btn_bkg1.png",660,200,90,34)
        label("下一页",660,200,14,GOLD,nil,true)
        hit(615,183,90,34,function() M.pickerPage=math.min(maxPage,M.pickerPage+1);ui.render() end)
    end
    image("v2/introUI/close1.png",768,513,76.8,73.2)
    hit(768-38.4,513-36.6,76.8,73.2,function() M.picker=false;ui.render() end)
    image("v2/buttons/ensure1.png",480,110,115.2,64.8)
    hit(480-57.6,110-32.4,115.2,64.8,function()
        if M.pickerPick then
            M.hero=M.pickerPick;M.selection={};M.offset=0;M.picker=false
            ui.render()
        end
    end)
end

sendUse=function()
    local grouped={}
    for i,_ in pairs(M.selection) do
        local b=M.books[i]
        if b then grouped[b.uid]=(grouped[b.uid] or 0)+1 end
    end
    local items={}
    for uid,count in pairs(grouped) do items[#items+1]={uid=uid,count=count} end
    if #items==0 then M.notice="请选择仙佛密卷";ui.render();return end
    M.selection={};M.confirm=nil
    ui.send("use_exp_book",{hero=M.hero,items=items})
end

local function eat()
    local hero=M.hero and heroById(M.hero)
    if not hero then M.notice="请选择一位神仙";ui.render();return end
    local total=selectionTotal()
    if total<=0 then M.notice="请选择仙佛密卷";ui.render();return end
    local lv2,cur2,added,wasted=preview(hero.quality,hero.level,hero.cur_exp,total)
    if added<total then
        M.confirm={total=total,added=added}
        ui.render()
        return
    end
    sendUse()
end

local function selectAll()
    local hero=M.hero and heroById(M.hero)
    if not hero then M.notice="请选择一位神仙";ui.render();return end
    local any=false
    for _ in pairs(M.selection) do any=true;break end
    if any then M.selection={};ui.render();return end
    local normal=normalLevel(); local total=0
    for i,b in ipairs(M.books) do
        local lv2=preview(hero.quality,hero.level,hero.cur_exp,total+b.exp)
        if lv2>normal then break end
        M.selection[i]=true; total=total+b.exp
    end
    if total<=0 and M.books[1] then M.selection[1]=true end
    ui.render()
end


function M.draw(ctx,player)
    if not M.uid then return end
    ui,state,root=ctx,player,ctx.root
    M.books=buildBooks()
    M.hits={}
    fill(0,0,960,540,{0,0,0,190})
    image("v2/expbookUI/bkg.png",BKG[1],BKG[2],BKG[3],BKG[4])
    local hero=M.hero and heroById(M.hero)
    local total=selectionTotal()
    if hero then
        local level=hero.level
        local cur=hero.cur_exp or 0
        local nextv=hero.next_exp or needExp(hero.quality,level)
        local plus=0
        if total>0 then
            local lv2,cur2=preview(hero.quality,level,cur,total)
            level=lv2; cur=cur2; nextv=needExp(hero.quality,level); plus=lv2-(hero.level or 1)
        end
        drawCharacter(hero,level,cur,nextv,plus)
    else
        image("v2/expbookUI/choose.png",217.5,273.75,247.5,60)
    end
    hit(CARD[1]-CARD[3]/2,CARD[2]-CARD[4]/2,CARD[3],CARD[4],function()
        M.picker=true;M.pickerPage=1;M.pickerPick=M.hero;ui.render()
    end)
    drawList()
    if hero and total>0 then drawSummary(hero,total) end
    image("v2/expbookUI/ensure1.png",USE[1],USE[2],USE[3],USE[4])
    hit(USE[1]-USE[3]/2,USE[2]-USE[4]/2,USE[3],USE[4],function() eat() end)
    image("v2/buttons/choose_all1.png",ALL[1],ALL[2],ALL[3],ALL[4])
    hit(ALL[1]-ALL[3]/2,ALL[2]-ALL[4]/2,ALL[3],ALL[4],function() selectAll() end)
    image("v2/introUI/close1.png",CLOSE[1],CLOSE[2],CLOSE[3],CLOSE[4])
    hit(CLOSE[1]-CLOSE[3]/2,CLOSE[2]-CLOSE[4]/2,CLOSE[3],CLOSE[4],function()
        M.close();ui.render()
    end)
    if M.notice then label(M.notice,480,505,18,RED,nil,true) end
    if M.picker then drawPicker() end
    if M.confirm then drawConfirm() end
end

local function endTouch(x,y)
    for i=#M.hits,1,-1 do
        local h=M.hits[i]
        if x>=h.x and x<=h.x+h.w and y>=h.y and y<=h.y+h.h then h.action();return true end
    end
end
local function inList(x,y)
    return x>=LIST[1] and x<=LIST[1]+LIST[3] and y>=LIST[2] and y<=LIST[2]+LIST[4]
end
local function toggleAt(x,y)
    local idx=math.floor((LIST[4]-(y-LIST[2])+M.offset)/CELL_H)+1
    if M.books[idx] then
        if M.selection[idx] then M.selection[idx]=nil else M.selection[idx]=true end
    end
end

function M.touch(event,x,y)
    if not M.uid then return false end
    local began=event==CCTOUCHBEGAN or event=="began"
    local moved=event==CCTOUCHMOVED or event=="moved"
    local ended=event==CCTOUCHENDED or event=="ended"
    if M.confirm or M.picker then
        if ended then endTouch(x,y);ui.render() end
        return true
    end
    if began then
        M.notice=nil
        if inList(x,y) then
            M.press={x=x,y=y,offset=M.offset,dragged=false}
            return true
        end
        return true
    elseif moved and M.press then
        if math.abs(y-M.press.y)>6 then
            M.press.dragged=true
            M.offset=clampOffset(M.press.offset+(y-M.press.y))
            ui.render()
        end
        return true
    elseif ended then
        if M.press then
            local p=M.press;M.press=nil
            if not p.dragged and inList(x,y) then toggleAt(x,y) end
            ui.render()
            return true
        end
        endTouch(x,y);ui.render();return true
    end
    return true
end

function M.open(ctx,player,uid)
    ui,state,root=ctx,player,ctx.root
    M.uid=uid;M.selection={};M.offset=0;M.press=nil
    M.picker=false;M.confirm=nil;M.notice=nil;M.hits={}
    M.books=buildBooks()
    if M.hero and not heroById(M.hero) then M.hero=nil end
    M.pickerPick=M.hero;M.pickerPage=1
    ui.render()
end
function M.close()
    M.uid=nil;M.books={};M.selection={};M.press=nil
    M.picker=false;M.confirm=nil;M.notice=nil;M.hits={}
end
function M.isOpen() return M.uid~=nil end
function M.afterUpdate(newState)
    state=newState
    M.books=buildBooks()
    if M.hero and not heroById(M.hero) then M.hero=nil end
    M.selection={}
    M.offset=clampOffset(M.offset)
end
function M.back()
    if not M.uid then return false end
    if M.confirm then M.confirm=nil;ui.render();return true end
    if M.picker then M.picker=false;ui.render();return true end
    M.close();return true
end
return M

