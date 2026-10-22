-- Original ui/expbookUI.lua: feed 仙佛密卷/培元丹 to one 神仙.
-- g_self.lvLimit = {{lv=0,rate=1},{lv=2.5,rate=0.2},{lv=3,rate=0}}:
-- below floor(主角等级*2.5) 100%, up to floor(主角等级*3) 20%, above 0.
-- Overshoot carries to the next level; the hard cap is min(主角*3, 品质最高级).
local data=require("local_inventory_data")
local expData=require("local_exp_data")
local M={uid=nil,hero=nil,page=1,bookPage=1,selection={},hits={}}
local ui,state,root
local GOLD={255,224,164}
local PALE={238,226,202}
local MUTED={186,169,157}
local GREEN={178,255,63}
local RED={241,67,21}

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
local function hit(x,y,w,h,action) table.insert(M.hits,{x=x,y=y,w=w,h=h,action=action}) end
local function button(title,x,y,w,action,enabled)
    local n=image("v2/soulExchangeUI/btn_bkg1.png",x+w/2,y+17,w,34)
    if not enabled then n:setColor(ccc3(110,110,110)) end
    label(title,x+w/2,y+17,17,enabled and GOLD or MUTED,nil,true)
    hit(x,y,w,34,action)
end
local function expTable(quality)
    local tables=expData.exp_table or {}
    return tables[tostring(quality)] or tables[quality] or {}
end
local function topLevel(quality)
    local top=0
    for k in pairs(expTable(quality)) do
        local n=tonumber(k)
        if n and n>top then top=n end
    end
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
local function capInfo(quality)
    local role=roleLevel()
    local normal=math.floor(role*2.5)
    local maximum=role*3
    local top=topLevel(quality)
    local cap=maximum
    if top>0 and top<cap then cap=top end
    return cap,normal,maximum
end
local function preview(quality,level,cur,amount)
    local cap,normal,maximum=capInfo(quality)
    local rest=tonumber(amount) or 0
    local added=0
    level=tonumber(level) or 1
    cur=tonumber(cur) or 0
    while rest>1e-9 and level<cap do
        local rate=1
        if level>=maximum then rate=0 elseif level>=normal then rate=0.2 end
        if rate<=0 then break end
        local need=needExp(quality,level)
        if need<=0 then break end
        local gap=need-cur
        if gap<=0 then
            cur=0
            level=level+1
        else
            local raw=gap/rate
            if rest+1e-9>=raw then
                added=added+gap
                cur=0
                rest=rest-raw
                level=level+1
            else
                local gain=rest*rate
                cur=cur+gain
                added=added+gain
                rest=0
            end
        end
    end
    return level,math.floor(cur),math.floor(added),math.floor(rest),cap
end
local function heroById(id)
    for _,h in ipairs(state.heroes or {}) do if h.id==id then return h end end
end
local function entryByUid(uid)
    for _,e in ipairs(((state.inventory or {}).entries) or {}) do if e.uid==uid then return e end end
end
local function itemOf(entry) return entry and data.items[entry.key] end
local function isBook(entry)
    local item=itemOf(entry)
    return item and item.action=="experience"
        and (tonumber(item.original and item.original.experience_plus) or 0)>0
end
local function bookExp(entry)
    local item=itemOf(entry)
    return tonumber(item and item.original and item.original.experience_plus) or 0
end
local function books()
    local list={}
    for _,e in ipairs(((state.inventory or {}).entries) or {}) do
        if isBook(e) then table.insert(list,e) end
    end
    table.sort(list,function(a,b)
        local ea,eb=bookExp(a),bookExp(b)
        if ea~=eb then return ea<eb end
        return a.uid<b.uid
    end)
    return list
end
local function eligibleHeroes()
    local list={}
    for _,h in ipairs(state.heroes or {}) do
        local cap=capInfo(h.quality)
        if (tonumber(h.level) or 1)<cap or h.id==M.hero then table.insert(list,h) end
    end
    table.sort(list,function(a,b)
        if (a.level or 1)~=(b.level or 1) then return (a.level or 1)<(b.level or 1) end
        return a.id<b.id
    end)
    return list
end
local function selectedAmount()
    local total=0
    for uid,count in pairs(M.selection) do
        local entry=entryByUid(uid)
        if entry and count>0 then total=total+bookExp(entry)*count end
    end
    return total
end

function M.open(ctx,player,uid)
    ui,state,root=ctx,player,ctx.root
    M.uid=uid;M.selection={};M.page=1;M.bookPage=1;M.hits={}
    if not isBook(entryByUid(uid)) then M.close();return end
    M.selection[uid]=1
    local list=eligibleHeroes()
    M.hero=M.hero and heroById(M.hero) and M.hero or (list[1] and list[1].id)
    ui.render()
end
function M.close()
    M.uid=nil;M.hero=nil;M.selection={};M.hits={}
end
function M.isOpen() return M.uid~=nil end
function M.afterUpdate(newState)
    state=newState
    if not isBook(entryByUid(M.uid)) then M.close();return end
    if M.hero and not heroById(M.hero) then M.hero=nil end
    for uid,_ in pairs(M.selection) do
        local entry=entryByUid(uid)
        if not entry then
            M.selection[uid]=nil
        elseif (M.selection[uid] or 0)>entry.count then
            M.selection[uid]=entry.count
        end
    end
end

local function drawHeroes(list)
    label("选择神仙",100,462,18,PALE)
    local per=3
    local maxPage=math.max(1,math.ceil(#list/per))
    if M.page>maxPage then M.page=maxPage end
    for i=(M.page-1)*per+1,math.min(#list,M.page*per) do
        local h=list[i]
        local y=420-((i-1)%per)*66
        local cap=capInfo(h.quality)
        image("v2/packageUI/xinxilan.png",255,y,330,56)
        if h.id==M.hero then image("v2/multi-selectUI/check_frame.png",255,y,338,60) end
        label(h.name,100,y+12,17,PALE)
        local tail=(tonumber(h.level) or 1)>=cap and "  已满" or ("  "..(h.cur_exp or 0).."/"..(h.next_exp or 0))
        label("Lv."..(h.level or 1)..tail,100,y-13,14,MUTED)
        hit(90,y-28,330,56,function() M.hero=h.id;ui.render() end)
    end
    if maxPage>1 then
        button("上一页",95,205,90,function() M.page=math.max(1,M.page-1);ui.render() end,M.page>1)
        label(M.page.."/"..maxPage,255,222,15,MUTED,nil,true)
        button("下一页",325,205,90,function() M.page=math.min(maxPage,M.page+1);ui.render() end,M.page<maxPage)
    end
end

local function drawBooks(list)
    label("选择经验书",470,462,18,PALE)
    local per=3
    local maxPage=math.max(1,math.ceil(#list/per))
    if M.bookPage>maxPage then M.bookPage=maxPage end
    for i=(M.bookPage-1)*per+1,math.min(#list,M.bookPage*per) do
        local e=list[i]
        local y=420-((i-1)%per)*66
        local item=itemOf(e)
        local count=M.selection[e.uid] or 0
        image("v2/packageUI/xinxilan.png",675,y,400,56)
        if count>0 then image("v2/multi-selectUI/check_frame.png",675,y,408,60) end
        label(item.name,480,y+12,16,PALE)
        label("每本 +"..bookExp(e).."   拥有×"..e.count,480,y-13,13,MUTED)
        button("-",770,y-14,28,function()
            M.selection[e.uid]=math.max(0,(M.selection[e.uid] or 0)-1)
            ui.render()
        end,(M.selection[e.uid] or 0)>0)
        label(count,812,y,18,GOLD,nil,true)
        button("+",838,y-14,28,function()
            M.selection[e.uid]=math.min(e.count,(M.selection[e.uid] or 0)+1)
            ui.render()
        end,(M.selection[e.uid] or 0)<e.count)
    end
    if maxPage>1 then
        button("上一页",475,205,90,function() M.bookPage=math.max(1,M.bookPage-1);ui.render() end,M.bookPage>1)
        label(M.bookPage.."/"..maxPage,675,222,15,MUTED,nil,true)
        button("下一页",745,205,90,function() M.bookPage=math.min(maxPage,M.bookPage+1);ui.render() end,M.bookPage<maxPage)
    end
end


function M.draw(ctx,player)
    if not M.uid then return end
    ui,state,root=ctx,player,ctx.root
    M.hits={}
    fill(0,0,960,540,{0,0,0,190})
    image("v2/introUI/introBkg.png",480,275,820,461)
    label("神仙经验书",480,488,24,GOLD,nil,true)
    image("v2/introUI/close1.png",862,486,46,44)
    hit(839,464,46,44,function() M.close();ui.render() end)
    drawHeroes(eligibleHeroes())
    drawBooks(books())
    local hero=M.hero and heroById(M.hero)
    local amount=selectedAmount()
    local previewText="请选择神仙与经验书"
    local canUse=false
    if hero and amount>0 then
        local lv,cur,added,wasted,cap=preview(hero.quality,hero.level,hero.cur_exp,amount)
        previewText="预计 Lv."..lv.."   "..cur.."/"..needExp(hero.quality,lv).."   实际获得 +"..added
        canUse=(tonumber(hero.level) or 1)<cap
        if wasted>0 then previewText=previewText.."   （浪费 "..wasted.."）" end
    end
    label(previewText,480,158,16,GOLD,nil,true)
    local role=roleLevel()
    label("主角 Lv."..role.."：低于 "..math.floor(role*2.5).." 级全额，至 "..(role*3).." 级 20%，再高封顶",480,126,13,MUTED,nil,true)
    button("使用",560,62,140,function()
        if not (M.hero and selectedAmount()>0) then return end
        local items={}
        for uid,count in pairs(M.selection) do
            if count>0 then table.insert(items,{uid=uid,count=count}) end
        end
        if #items==0 then return end
        M.selection={}
        ui.send("use_exp_book",{hero=M.hero,items=items})
    end,canUse)
    button("取消",730,62,140,function() M.close();ui.render() end,true)
end

local function endTouch(x,y)
    for i=#M.hits,1,-1 do
        local h=M.hits[i]
        if x>=h.x and x<=h.x+h.w and y>=h.y and y<=h.y+h.h then h.action();return true end
    end
end

function M.touch(event,x,y)
    if not M.uid then return false end
    if event==CCTOUCHENDED or event=="ended" then
        endTouch(x,y)
        ui.render()
        return true
    end
    return true
end
function M.back()
    if not M.uid then return false end
    M.close();return true
end
return M

