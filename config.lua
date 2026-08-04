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

local function getlblparent(txt, fbackfunc)
    local ltxt = string.lower(txt)
    for _, obj in pairs(guis:GetDescendants()) do
        if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj.Text and string.lower(obj.Text) == ltxt then
            return obj:IsA("TextLabel") and obj.Parent or obj
        end
    end
    for _, obj in pairs(guis:GetDescendants()) do
        if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj.Text then
            local otxt = string.lower(obj.Text)
            if string.find(otxt, ltxt, 1, true) and not string.find(otxt, "range") and not string.find(otxt, "delay") then
                return obj:IsA("TextLabel") and obj.Parent or obj
            end
        end
    end
    local f = nil
    if fbackfunc then pcall(function() f = fbackfunc() end) end
    return f
end

local function getbtntxt(txt, fbackfunc)
    for _, obj in pairs(guis:GetDescendants()) do
        if (obj:IsA("TextButton") or obj:IsA("TextLabel")) and obj.Text == txt then
            if obj:IsA("TextLabel") then return obj.Parent else return obj end
        end
    end
    local f = nil
    pcall(function() f = fbackfunc() end)
    return f
end

local function getbtnany(nm, fbackfunc)
    for _, obj in pairs(guis:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Text == nm then
            if obj.Parent and (obj.Parent:IsA("TextButton") or obj.Parent:IsA("ImageButton") or obj.Parent:IsA("Frame")) then
                return obj.Parent
            end
        end
        if obj:IsA("TextButton") and (obj.Text == nm or obj.Name == nm) then
            return obj
        end
        if obj:IsA("ImageButton") and obj.Name == nm then
            return obj
        end
    end
    local f = nil
    pcall(function() f = fbackfunc() end)
    return f
end

local guiready = false
local attempts = 0
while not guiready and attempts < 120 do
    pcall(function()
        if guis.ScreenGui.Frame.Frame.ScrollingFrame then
            guiready = true
        end
    end)
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
    if not emotebtn then
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
        for _, obj in pairs(guis.ScreenGui.Frame.ScrollingFrame:GetChildren()) do
            if (obj:IsA("TextButton") or obj:IsA("TextLabel")) and (obj.Text == "  " .. tname or obj.Text == tname or string.find(obj.Text, tname) or obj.Name == tname) then
                clickybtn(obj)
                wrk = true
                break
            end
        end
        if not wrk and idxfallback then
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
        return getlblparent("Auto Counter", function()
            if premium_mode then return guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[9]
            else return guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[9] end
        end)
    end)
    if not cntrbtn then
        pcall(function() cntrbtn = premium_mode and guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[9] or guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[9] end)
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
    {"Locked On Players Only", function() return getlblparent("Locked On Players", function() return guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[11] end) end},
    {"Auto BlackFlash Chain Only", function() return getlblparent("Auto BlackFlash Chain", function() return guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[13] end) end},
    {"Auto QTE Minigame Click Only", function() return getlblparent("Auto QTE Minigame Click", function()
        if premium_mode then return guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[18]
        else return guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[14] end
    end) end},
    {"Auto Hiromi Guess Domain Only", function() return getlblparent("Auto Hiromi Guess Domain", function()
        if premium_mode then return guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[20]
        else return nil end
    end) end}
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

local function fastslider(frmfunc, lblfunc, wanttxt, wantnum)
    local dfrm = nil
    local dlbl = nil
    pcall(function()
        dfrm = frmfunc()
        dlbl = lblfunc()
    end)
    if not dfrm or not dlbl then return end

    local sf = nil
    pcall(function()
        local curr = dfrm
        while curr and curr ~= game do
            if curr:IsA("ScrollingFrame") then
                sf = curr
                break
            end
            curr = curr.Parent
        end
    end)
    if not sf then return end
    if sf and sf:IsA("ScrollingFrame") then
        local tgY = dfrm.AbsolutePosition.Y - sf.AbsolutePosition.Y + sf.CanvasPosition.Y - (sf.AbsoluteWindowSize.Y / 2)
        if tgY < 0 then tgY = 0 end
        sf.CanvasPosition = Vector2.new(0, tgY)
        task.wait(0.15)
    end

    local insetY = 36
    
    local barParent = dfrm.Parent
    if not barParent or not barParent:IsA("Frame") then barParent = dfrm end
    local barX = barParent.AbsolutePosition.X
    local barW = barParent.AbsoluteSize.X
    local sy = barParent.AbsolutePosition.Y + (barParent.AbsoluteSize.Y / 2) + insetY

    local function smartDragToValue()
        local startX = dfrm.AbsolutePosition.X + dfrm.AbsoluteSize.X
        if startX < barX then startX = barX end
        if startX > barX + barW then startX = barX + barW end

        pcall(function() if mousemoveabs then mousemoveabs(startX, sy) end end)
        task.wait(0.01)
        vman:SendMouseButtonEvent(startX, sy, 0, true, game, 1)
        pcall(function() vman:SendTouchEvent(0, 0, startX, sy) end)
        task.wait(0.05)

        local lim = 0
        local ratio = (startX - barX) / barW
        if ratio < 0 then ratio = 0 end
        if ratio > 1 then ratio = 1 end

        while dlbl.Text ~= wanttxt and lim < 50 do
            local cstr = string.match(dlbl.Text, "%d+")
            local cnum = cstr and tonumber(cstr) or 0
            if cnum == wantnum then break end
            
            local diff = wantnum - cnum
            local step = 0.02
            if math.abs(diff) > 10 then step = 0.06 end
            
            if diff > 0 then ratio = ratio + step else ratio = ratio - step end
            if ratio < 0 then ratio = 0 end
            if ratio > 1 then ratio = 1 end
            
            local tx = barX + (barW * ratio)
            
            pcall(function() if mousemoveabs then mousemoveabs(tx, sy) end end)
            vman:SendMouseMoveEvent(tx, sy, game)
            pcall(function() vman:SendTouchEvent(0, 1, tx, sy) end)
            
            task.wait(0.03)
            lim = lim + 1
        end
        
        local finaltx = barX + (barW * ratio)
        vman:SendMouseButtonEvent(finaltx, sy, 0, false, game, 1)
        pcall(function() vman:SendTouchEvent(0, 2, finaltx, sy) end)
    end
    
    smartDragToValue()
    task.wait(0.05)
end

local function getSliderFrameAndLabel(prefix)
    local f, l = nil, nil
    pcall(function()
        for _, obj in pairs(guis.ScreenGui:GetDescendants()) do
            if obj:IsA("TextLabel") and obj.Text and string.sub(obj.Text, 1, #prefix) == prefix then
                l = obj
                if obj.Parent then
                    local bg = obj.Parent:FindFirstChildWhichIsA("Frame")
                    if bg then f = bg:FindFirstChildWhichIsA("Frame") or bg end
                end
                break
            end
        end
    end)
    return function() return f end, function() return l end
end

opentab("Auto", 5)

local blkrange = getcfgnum("Auto Block Range", 19)
if premium_mode then
    fastslider(
        function() return guis.ScreenGui.Frame.Frame:GetChildren()[4].Frame.Frame.Frame end,
        function() return guis.ScreenGui.Frame.Frame:GetChildren()[4].Frame.TextLabel end,
        "Auto Block Range: " .. tostring(blkrange),
        blkrange
    )
    fastslider(
        function() return guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[10].Frame end,
        function() return guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[10].TextLabel end,
        "Auto Counter Range: " .. tostring(cntrrange),
        cntrrange
    )
    fastslider(
        function() return guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[19].Frame end,
        function() return guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[19].TextLabel end,
        "Click Delay: " .. tostring(dlyval),
        dlyval
    )
else
    fastslider(
        function() return guis.ScreenGui.Frame.Frame:GetChildren()[4].Frame.Frame end,
        function() return guis.ScreenGui.Frame.Frame:GetChildren()[4].Frame.TextLabel end,
        "Auto Block Range: " .. tostring(blkrange),
        blkrange
    )
    fastslider(
        function() return guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[10].Frame end,
        function() return guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[10].TextLabel end,
        "Auto Counter Range: " .. tostring(cntrrange),
        cntrrange
    )
    fastslider(
        function() return guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[15].Frame end,
        function() return guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[15].TextLabel end,
        "Click Delay: " .. tostring(dlyval),
        dlyval
    )
end
