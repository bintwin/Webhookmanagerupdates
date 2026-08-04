local isran = false
pcall(function()
    if _G.jjsconfigran == true then isran = true end
    _G.jjsconfigran = true
end)
pcall(function()
    local g = (type(getgenv) == "function" and getgenv()) or (type(getgenv) == "table" and getgenv())
    if g then
        if g.jjsconfigran == true then isran = true end
        g.jjsconfigran = true
    end
end)
if isran then return end
pcall(function()
    if game.PlaceId ~= 9391468976 and game.GameId ~= 9391468976 then
        isran = true
    end
end)
if isran then return end

enablecustomconfig = true
pcall(function()
    local g = (type(getgenv) == "function" and getgenv()) or (type(getgenv) == "table" and getgenv())
    if g and g.enablecustomconfig ~= nil then
        enablecustomconfig = g.enablecustomconfig
    end
end)

premium_mode = false
pcall(function()
    local g = (type(getgenv) == "function" and getgenv()) or (type(getgenv) == "table" and getgenv())
    if g and g.premium_mode ~= nil then
        premium_mode = g.premium_mode
    end
end)

customconfig = ""
pcall(function()
    local g = (type(getgenv) == "function" and getgenv()) or (type(getgenv) == "table" and getgenv())
    if g then
        customconfig = g.Config or g.config or g.customconfig or ""
    end
end)

local httpman = game:GetService("HttpService")
local parsedcfg = nil
if enablecustomconfig then
    pcall(function()
        local dec = httpman:JSONDecode(customconfig)
        if dec and dec.CONFIG then
            parsedcfg = dec.CONFIG
        else
            parsedcfg = dec
        end
    end)
end

local function chkdo(nm)
    if not enablecustomconfig or not parsedcfg then return true end
    if parsedcfg[nm] ~= nil then
        return parsedcfg[nm] == true
    end
    local clean = string.gsub(nm, " Only$", "")
    if parsedcfg[clean] ~= nil then
        return parsedcfg[clean] == true
    end
    for k, v in pairs(parsedcfg) do
        if string.lower(k) == string.lower(nm) or string.lower(k) == string.lower(clean) then
            return v == true
        end
    end
    return false
end

local function getcfgnum(nm, defnum)
    if not enablecustomconfig or not parsedcfg then return defnum end
    if type(parsedcfg[nm]) == "number" then return parsedcfg[nm] end
    for k, v in pairs(parsedcfg) do
        if string.lower(k) == string.lower(nm) and type(v) == "number" then
            return v
        end
    end
    return defnum
end

local function chklockmethod(mname)
    if not enablecustomconfig or not parsedcfg then return true end
    local lm = parsedcfg["Lock On Method"]
    if type(lm) == "table" then
        for _, v in pairs(lm) do
            if string.lower(tostring(v)) == string.lower(mname) then
                return true
            end
        end
        return false
    end
    return false
end

local playerstuff = game:GetService("Players")
local localboy = playerstuff.LocalPlayer
local guis = localboy.PlayerGui
local vman = game:GetService("VirtualInputManager")

local function clickybtn(b)
    if not b then return end
    local wrk = false
    pcall(function()
        if type(getconnections) == "function" then
            for _, c in pairs(getconnections(b.MouseButton1Click)) do pcall(function() c:Fire() end); wrk = true end
            for _, c in pairs(getconnections(b.Activated)) do pcall(function() c:Fire() end); wrk = true end
            for _, c in pairs(getconnections(b.MouseButton1Down)) do pcall(function() c:Fire() end); wrk = true end
            for _, c in pairs(getconnections(b.MouseButton1Up)) do pcall(function() c:Fire() end); wrk = true end
            for _, c in pairs(getconnections(b.TouchTap)) do pcall(function() c:Fire() end); wrk = true end
        end
    end)
    if not wrk then
        pcall(function()
            local px = b.AbsolutePosition.X + (b.AbsoluteSize.X / 2)
            local py = b.AbsolutePosition.Y + (b.AbsoluteSize.Y / 2) + 36
            vman:SendMouseButtonEvent(px, py, 0, true, game, 1)
            task.wait(0.02)
            vman:SendMouseButtonEvent(px, py, 0, false, game, 1)
        end)
        pcall(function()
            local vu = game:GetService("VirtualUser")
            vu:ClickButton1(Vector2.new(b.AbsolutePosition.X + (b.AbsoluteSize.X / 2), b.AbsolutePosition.Y + (b.AbsoluteSize.Y / 2)))
        end)
        pcall(function()
            local px = b.AbsolutePosition.X + (b.AbsoluteSize.X / 2)
            local py = b.AbsolutePosition.Y + (b.AbsoluteSize.Y / 2) + 36
            vman:SendTouchEvent(0, 0, px, py)
            task.wait(0.01)
            vman:SendTouchEvent(0, 2, px, py)
        end)
    end
end

local function normalizetext(value)
    local txt = tostring(value or "")
    txt = string.gsub(txt, "^%s+", "")
    txt = string.gsub(txt, "%s+$", "")
    return string.lower(txt)
end

local function hastextproperty(obj)
    return obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")
end

local function gettextobject(txt, mode)
    local wanted = normalizetext(txt)
    local best = nil

    for _, obj in pairs(guis:GetDescendants()) do
        if hastextproperty(obj) then
            local current = normalizetext(obj.Text)
            local matches = false

            if mode == "prefix" then
                matches = string.sub(current, 1, #wanted) == wanted
            elseif mode == "contains" then
                matches = string.find(current, wanted, 1, true) ~= nil
            else
                matches = current == wanted
            end

            if matches then
                if obj.Visible then
                    return obj
                end
                best = best or obj
            end
        end
    end

    return best
end

local function getclicktarget(obj)
    if not obj then return nil end
    if obj:IsA("TextButton") or obj:IsA("ImageButton") then
        return obj
    end

    local current = obj.Parent
    local depth = 0
    while current and current ~= guis and depth < 5 do
        if current:IsA("TextButton") or current:IsA("ImageButton") then
            return current
        end
        current = current.Parent
        depth = depth + 1
    end

    return obj.Parent or obj
end

local function premiumfallback(fbackfunc)
    if not premium_mode or type(fbackfunc) ~= "function" then
        return nil
    end

    local result = nil
    pcall(function()
        result = fbackfunc()
    end)
    return result
end

local function getlblparent(txt, fbackfunc)
    local obj = gettextobject(txt, "exact")
    if obj then
        return getclicktarget(obj)
    end
    return premiumfallback(fbackfunc)
end

local function getbtntxt(txt, fbackfunc)
    local obj = gettextobject(txt, "exact")
    if obj then
        return getclicktarget(obj)
    end
    return premiumfallback(fbackfunc)
end

local function getbtnany(nm, fbackfunc)
    local obj = gettextobject(nm, "exact")
    if obj then
        return getclicktarget(obj)
    end

    if premium_mode then
        for _, item in pairs(guis:GetDescendants()) do
            if (item:IsA("TextButton") or item:IsA("ImageButton")) and item.Name == nm then
                return item
            end
        end
    end

    return premiumfallback(fbackfunc)
end

local guiready = false
local attempts = 0
while not guiready and attempts < 120 do
    if premium_mode then
        pcall(function()
            if guis.ScreenGui.Frame.Frame.ScrollingFrame then
                guiready = true
            end
        end)
    else
        guiready = gettextobject("Lock On", "exact") ~= nil
            or gettextobject("Auto Counter", "exact") ~= nil
            or gettextobject("Auto", "exact") ~= nil
    end

    if guiready then break end
    attempts = attempts + 1
    task.wait(1)
end

if not guiready then return end

pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Config Loader",
        Text = "Config loading started",
        Duration = 4
    })
end)
task.wait(4)

if chkdo("Lock On") then
    local lockbtn = getbtnany("Lock On", function()
        return getlblparent("Lock On", function() return guis.ScreenGui.Frame.Frame.ScrollingFrame:GetChildren()[14] end)
    end)
    if lockbtn then
        clickybtn(lockbtn)
        task.wait(0.05)
    end
    local b1 = getbtntxt("Lock On Keybind: F", function() return guis.ScreenGui.Frame.Frame.ScrollingFrame:GetChildren()[15] end)
    clickybtn(b1)
    task.wait(0.05)
    local keytohit = Enum.KeyCode.C
    if enablecustomconfig and parsedcfg and parsedcfg["Lock On Keybind"] then
        pcall(function()
            keytohit = Enum.KeyCode[tostring(parsedcfg["Lock On Keybind"])]
        end)
    end
    vman:SendKeyEvent(true, keytohit, false, game)
    task.wait(0.02)
    vman:SendKeyEvent(false, keytohit, false, game)
    task.wait(0.05)
end

if chklockmethod("Character") then
    local charbtn = getbtnany("Character", function()
        for _, ch in pairs(guis.ScreenGui.Frame.Frame.ScrollingFrame:GetChildren()[13].Frame.ScrollingFrame:GetChildren()) do
            if ch:IsA("TextButton") and (ch.Name == "Character" or ch.Text == "Character") then return ch end
        end
        return guis.ScreenGui.Frame.Frame.ScrollingFrame:GetChildren()[13].Frame.ScrollingFrame:GetChildren()[3]
    end)
    clickybtn(charbtn)
    task.wait(0.15)
end

if not chklockmethod("Camera") then
    local cambtn = getbtnany("Camera", function()
        for _, ch in pairs(guis.ScreenGui.Frame.Frame.ScrollingFrame:GetChildren()[13].Frame.ScrollingFrame:GetChildren()) do
            if ch:IsA("TextButton") and (ch.Name == "Camera" or ch.Text == "Camera") then return ch end
        end
        return nil
    end)
    clickybtn(cambtn)
    task.wait(0.1)
end

if chkdo("Unlock Extra Emote slot") then
    local emotebtn = getlblparent("Unlock Extra Emote Slot", function() return guis.ScreenGui.Frame.Frame:GetChildren()[7]:GetChildren()[25] end)
    if not emotebtn and premium_mode then
        pcall(function() emotebtn = guis.ScreenGui.Frame.Frame:GetChildren()[7]:GetChildren()[25] end)
    end
    clickybtn(emotebtn)
    task.wait(0.05)
end

if chkdo("M1 Assist") then
    local m1btn = getlblparent("M1 Assist Only", function() return guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[22] end)
    if not m1btn then m1btn = getbtntxt("M1 Assist", function() return nil end) end
    clickybtn(m1btn)
    task.wait(0.02)
    local m1m = "UpperCut"
    if enablecustomconfig and parsedcfg and parsedcfg["M1 Method"] then
        m1m = tostring(parsedcfg["M1 Method"])
    end
    clickybtn(getbtnany(m1m, function() return nil end))
    task.wait(0.02)
end

local function isbtnenabled(btn)
    if not btn then return false end
    local checkcol = function(c)
        if not c then return false end
        local r = math.floor(c.R * 255 + 0.5)
        local g = math.floor(c.G * 255 + 0.5)
        local b = math.floor(c.B * 255 + 0.5)
        return (g == 170 and b == 127) or (g > 150 and b > 100 and r < 50)
    end
    if checkcol(btn.BackgroundColor3) then return true end
    for _, ch in pairs(btn:GetChildren()) do
        if ch:IsA("Frame") and checkcol(ch.BackgroundColor3) then
            return true
        end
    end
    return false
end

local function opentab(tname, idxfallback)
    pcall(function()
        local wrk = false
        local exact = gettextobject(tname, "exact")
        local found = exact or gettextobject(tname, "contains")

        if found then
            clickybtn(getclicktarget(found))
            wrk = true
        end

        if not wrk and premium_mode and idxfallback then
            pcall(function()
                clickybtn(guis.ScreenGui.Frame.ScrollingFrame:GetChildren()[idxfallback])
            end)
        end

        task.wait(0.35)
    end)
end

opentab("Auto", 5)

if chkdo("Auto Counter") then
    local cntrbtn = getbtnany("Auto Counter", function()
        return getlblparent("Auto Counter", function() return guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[9] end)
    end)
    if not cntrbtn and premium_mode then
        pcall(function() cntrbtn = guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[9] end)
    end
    if cntrbtn and not isbtnenabled(cntrbtn) then
        clickybtn(cntrbtn)
        task.wait(0.05)
    end
end

local fastbtnlist = {
    {"Side Dash Assist", function() return getlblparent("Side Dash Assist", function() return guis.ScreenGui.Frame.Frame:GetChildren()[3]:GetChildren()[7] end) end},
    {"Auto Block", function() return getlblparent("Auto Block", function() return guis.ScreenGui.Frame.Frame:GetChildren()[4].TextButton end) end},
    {"Auto Punish", function() return getlblparent("Auto Punish", function() return guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[7] end) end},
    {"Locked On Players Only", function() return getlblparent("Locked On Players Only", function() return guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[11] end) end},
    {"Auto BlackFlash Chain Only", function() return getlblparent("Auto BlackFlash Chain Only", function() return guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[13] end) end},
    {"Auto QTE Minigame Click Only", function() return getlblparent("Auto QTE Minigame Click Only", function() return guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[18] end) end},
    {"Auto Hiromi Guess Domain Only", function() return getlblparent("Auto Hiromi Guess Domain Only", function() return guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[20] end) end}
}

for _, item in pairs(fastbtnlist) do
    if chkdo(item[1]) then
        local btn = item[2]()
        if btn and not isbtnenabled(btn) then
            clickybtn(btn)
            task.wait(0.02)
        end
    end
end

local morenames = {
    "Auto Counter",
    "Auto Adapt",
    "Auto Air Variant",
    "Auto Ambush",
    "Auto BlackFlash V2 100% accuracy (yuji only)",
    "Auto Blackflash",
    "Auto Block/Counter",
    "Auto Burst",
    "Auto Earth Quake",
    "Auto Feint",
    "Auto Frog variant",
    "Auto Garuda Rebound",
    "Auto Legit",
    "Auto Lock On",
    "Auto Lock On When You",
    "Auto Naoya Tech",
    "Auto Nue variant",
    "Auto Parkour",
    "Auto Perfect Swap",
    "Auto Pick Up",
    "Auto Play",
    "Auto Play On Kill",
    "Auto Ratio",
    "Auto Reversal Red Teleport",
    "Auto ShutUp",
    "Auto Spawn Train",
    "Auto Swap Players",
    "Auto Todo BlackFlash",
    "Auto Todo Blackflash",
    "Auto Variants",
    "Auto World Slash",
    "Auto Yuta BlackFlash",
    "Auto Yuta Teleport Kill Backflash",
    "Auto Yuta Teleport Kill Blackflash",
    "Aim Assist",
    "Anti BlackHole",
    "Anti Build Lag",
    "Anti Counter",
    "Anti Domain",
    "Anti Domain Method",
    "Anti Kill",
    "Anti Ragdoll",
    "Anti Stun",
    "Anti Stun Methods",
    "Combat Defense",
    "Domain Check",
    "Hit And Tp Back",
    "Hitbox (Only Works On Some Movements)",
    "Instant Blackhole",
    "Invisibility",
    "KnockBackForce",
    "No Parkour Cooldown",
    "NoJump",
    "NoSprint",
    "Safe Place",
    "Silent animations",
    "Spam dash noises",
    "Spawn Train Button",
    "Stun",
    "Todo Bring (Swift Kick)",
    "Walk into Domains",
    "Yuki Instant Charge",
    "Gojo 0.2 domain Kill All",
    "Set Low Hp",
    "Bird Control",
    "Cooldown Viewer"
}

for _, nm in pairs(morenames) do
    if chkdo(nm) then
        local btn = getbtnany(nm, function() return getlblparent(nm, function() return nil end) end)
        if btn and not isbtnenabled(btn) then
            clickybtn(btn)
            task.wait(0.02)
        end
    end
end

local function getnumberfromtext(txt)
    local found = nil
    for number in string.gmatch(tostring(txt or ""), "[-+]?%d*%.?%d+") do
        if number ~= "" and number ~= "." and number ~= "+" and number ~= "-" then
            found = tonumber(number)
        end
    end
    return found
end

local function getscrollingancestor(obj)
    local current = obj
    while current and current ~= game do
        if current:IsA("ScrollingFrame") then
            return current
        end
        current = current.Parent
    end
    return nil
end

local function slidercandidates(label)
    if not label then return {} end

    local scopes = {}
    local current = label.Parent
    for _ = 1, 4 do
        if not current or current == guis then break end
        table.insert(scopes, current)
        current = current.Parent
    end

    local scored = {}
    local added = {}

    local function addcandidate(obj, scopeindex)
        if added[obj] or not obj:IsA("GuiObject") or obj == label then return end
        added[obj] = true

        local size = obj.AbsoluteSize
        if size.X < 24 or size.Y < 2 or size.Y > 55 then return end
        if size.X > 650 then return end
        if obj:IsA("TextLabel") or obj:IsA("TextBox") then return end

        local labelcenter = label.AbsolutePosition.Y + (label.AbsoluteSize.Y / 2)
        local objcenter = obj.AbsolutePosition.Y + (size.Y / 2)
        local ydistance = math.abs(objcenter - labelcenter)
        if ydistance > 110 then return end

        local ratio = size.X / math.max(size.Y, 1)
        local score = (ratio * 10) - ydistance - (scopeindex * 8)

        if obj.Active then score = score + 30 end
        if obj:IsA("TextButton") or obj:IsA("ImageButton") then score = score + 10 end
        if obj.Parent == label.Parent then score = score + 15 end

        table.insert(scored, {
            object = obj,
            score = score
        })
    end

    for scopeindex, scope in ipairs(scopes) do
        addcandidate(scope, scopeindex)
        for _, obj in pairs(scope:GetDescendants()) do
            addcandidate(obj, scopeindex)
        end
    end

    table.sort(scored, function(a, b)
        return a.score > b.score
    end)

    local result = {}
    for _, item in ipairs(scored) do
        table.insert(result, item.object)
    end
    return result
end

local function movecanvasfor(obj)
    local sf = getscrollingancestor(obj)
    if not sf then return end

    local targety = obj.AbsolutePosition.Y - sf.AbsolutePosition.Y + sf.CanvasPosition.Y - (sf.AbsoluteWindowSize.Y / 2)
    if targety < 0 then targety = 0 end

    local maxy = math.max(0, sf.AbsoluteCanvasSize.Y - sf.AbsoluteWindowSize.Y)
    if targety > maxy then targety = maxy end

    sf.CanvasPosition = Vector2.new(sf.CanvasPosition.X, targety)
    task.wait(0.18)
end

local function dragcandidate(slider, label, wantnum)
    if not slider or not label then return false end

    movecanvasfor(label)

    local sx = slider.AbsolutePosition.X + (slider.AbsoluteSize.X / 2)
    local sy = slider.AbsolutePosition.Y + (slider.AbsoluteSize.Y / 2) + 66
    local phnchk = false
    pcall(function()
        phnchk = game:GetService("UserInputService").TouchEnabled
    end)
    if phnchk then
        sy = sy - 55
    end

    local startingvalue = getnumberfromtext(label.Text)
    local function finished()
        local current = getnumberfromtext(label.Text)
        return current ~= nil and math.abs(current - wantnum) < 0.001
    end

    if finished() then return true end

    local usingmousefunctions = type(mousemoveabs) == "function"
        and type(mouse1press) == "function"
        and type(mouse1release) == "function"

    if usingmousefunctions then
        mousemoveabs(sx, sy)
        task.wait(0.04)
        mouse1press()
    else
        vman:SendMouseButtonEvent(sx, sy, 0, true, game, 1)
        pcall(function()
            vman:SendTouchEvent(0, 0, sx, sy)
        end)
    end

    task.wait(0.04)

    local lim = 0
    local lastvalue = getnumberfromtext(label.Text)
    local unchanged = 0

    while not finished() and lim < 220 do
        local current = getnumberfromtext(label.Text)
        if current == nil then break end

        local difference = math.abs(current - wantnum)
        local step = 1
        if difference >= 20 then
            step = 8
        elseif difference >= 8 then
            step = 4
        elseif difference >= 3 then
            step = 2
        end

        if current > wantnum then
            sx = sx - step
        else
            sx = sx + step
        end

        if usingmousefunctions then
            mousemoveabs(sx, sy)
        else
            vman:SendMouseMoveEvent(sx, sy, game)
            pcall(function()
                vman:SendTouchEvent(0, 1, sx, sy)
            end)
        end

        task.wait(0.012)
        local newvalue = getnumberfromtext(label.Text)
        if newvalue == lastvalue then
            unchanged = unchanged + 1
        else
            unchanged = 0
            lastvalue = newvalue
        end

        if unchanged > 28 then break end
        lim = lim + 1
    end

    if usingmousefunctions then
        mouse1release()
    else
        vman:SendMouseButtonEvent(sx, sy, 0, false, game, 1)
        pcall(function()
            vman:SendTouchEvent(0, 2, sx, sy)
        end)
    end

    task.wait(0.04)

    if finished() then return true end
    local endingvalue = getnumberfromtext(label.Text)
    return startingvalue ~= endingvalue
end

local function fastslider(frmfunc, lblfunc, wanttxt, wantnum)
    local dfrm = nil
    local dlbl = nil

    if premium_mode then
        pcall(function()
            dfrm = frmfunc()
            dlbl = lblfunc()
        end)
    end

    local prefix = string.match(wanttxt, "^(.-:)")
    if not dlbl and prefix then
        dlbl = gettextobject(prefix, "prefix")
    end
    if not dlbl then
        dlbl = gettextobject(wanttxt, "exact")
    end
    if not dlbl then
        return
    end

    movecanvasfor(dlbl)

    if dfrm then
        dragcandidate(dfrm, dlbl, wantnum)
    else
        for _, candidate in ipairs(slidercandidates(dlbl)) do
            local changed = dragcandidate(candidate, dlbl, wantnum)
            local current = getnumberfromtext(dlbl.Text)
            if current ~= nil and math.abs(current - wantnum) < 0.001 then
                break
            end
            if changed then
                task.wait(0.03)
            end
        end
    end

    task.wait(0.05)
end

opentab("Auto", 5)
local blkrange = getcfgnum("Auto Block Range", 19)
fastslider(
    function() return guis.ScreenGui.Frame.Frame:GetChildren()[4].Frame.Frame.Frame end,
    function() return guis.ScreenGui.Frame.Frame:GetChildren()[4].Frame.TextLabel end,
    "Auto Block Range: " .. tostring(blkrange),
    blkrange
)

local cntrrange = getcfgnum("Auto Counter Range", 4)
fastslider(
    function() return guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[10].Frame end,
    function() return guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[10].TextLabel end,
    "Auto Counter Range: " .. tostring(cntrrange),
    cntrrange
)

local dlyval = getcfgnum("Click Delay", 16)
fastslider(
    function() return guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[19].Frame end,
    function() return guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[19].TextLabel end,
    "Click Delay: " .. tostring(dlyval),
    dlyval
)
