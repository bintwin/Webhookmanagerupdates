local env = _G
pcall(function()
    if type(getgenv) == "function" then
        local fetched = getgenv()
        if type(fetched) == "table" then
            env = fetched
        end
    elseif type(getgenv) == "table" then
        env = getgenv
    end
end)

if game.PlaceId ~= 9391468976 and game.GameId ~= 9391468976 then
    return
end

local enablecustomconfig = env.enablecustomconfig
if enablecustomconfig == nil then
    enablecustomconfig = true
end

local premiumvalue = env.premium_mode
local premium_mode = premiumvalue == true
    or premiumvalue == 1
    or string.lower(tostring(premiumvalue)) == "true"

local customconfig = env.Config or env.config or env.customconfig or ""

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
local inputman = game:GetService("UserInputService")
local guiservice = game:GetService("GuiService")
local touchmode = inputman.TouchEnabled

local function gettouchcoords(guiobj, x, y)
    if not touchmode then
        return math.floor(x + 0.5), math.floor(y + 0.5)
    end

    local addInset = true
    local screenGui = guiobj

    while screenGui and screenGui ~= game do
        if screenGui:IsA("ScreenGui") then
            pcall(function()
                addInset = not screenGui.IgnoreGuiInset
            end)
            break
        end
        screenGui = screenGui.Parent
    end

    if addInset then
        pcall(function()
            local topLeftInset = guiservice:GetGuiInset()
            x = x + topLeftInset.X
            y = y + topLeftInset.Y
        end)
    end

    return math.floor(x + 0.5), math.floor(y + 0.5)
end

local function getguicenter(guiobj)
    if not guiobj or not guiobj:IsA("GuiObject") then return nil, nil end

    local x = guiobj.AbsolutePosition.X + (guiobj.AbsoluteSize.X / 2)
    local y = guiobj.AbsolutePosition.Y + (guiobj.AbsoluteSize.Y / 2)

    return math.floor(x + 0.5), math.floor(y + 0.5)
end

local function getclicktarget(obj)
    if not obj then return nil end
    if obj:IsA("GuiButton") then return obj end

    for _, child in pairs(obj:GetDescendants()) do
        if child:IsA("GuiButton") and child.Visible then
            return child
        end
    end

    local current = obj.Parent
    while current and current ~= game do
        if current:IsA("GuiButton") then return current end
        current = current.Parent
    end

    return obj
end

local function clickybtn(b)
    b = getclicktarget(b)
    if not b then return end

    local function fireconnections(signal)
        if type(getconnections) ~= "function" or not signal then return false end

        local connections = nil
        pcall(function() connections = getconnections(signal) end)
        if type(connections) ~= "table" or #connections == 0 then return false end

        for _, connection in pairs(connections) do
            pcall(function() connection:Fire() end)
        end

        return true
    end

    local worked = false

    if b:IsA("GuiButton") then
        worked = fireconnections(b.Activated)
        if not worked then worked = fireconnections(b.MouseButton1Click) end
    end

    if not worked then
        worked = fireconnections(b.TouchTap)
    end

    if not worked and type(firesignal) == "function" then
        pcall(function()
            if b:IsA("GuiButton") then
                firesignal(b.Activated)
            else
                firesignal(b.TouchTap)
            end
            worked = true
        end)
    end

    if worked then return end

    local x, y = getguicenter(b)
    if not x or not y then return end

    if touchmode then
        pcall(function()
            local touchX, touchY = gettouchcoords(b, x, y)
            vman:SendTouchEvent(0, 0, touchX, touchY)
            task.wait(0.04)
            vman:SendTouchEvent(0, 2, touchX, touchY)
            worked = true
        end)
    end

    if not worked then
        pcall(function()
            vman:SendMouseMoveEvent(x, y, game)
            vman:SendMouseButtonEvent(x, y, 0, true, game, 1)
            task.wait(0.04)
            vman:SendMouseButtonEvent(x, y, 0, false, game, 1)
            worked = true
        end)
    end

    if not worked then
        pcall(function()
            game:GetService("VirtualUser"):ClickButton1(Vector2.new(x, y))
        end)
    end
end

local function getlblparent(txt, fbackfunc)
    for _, obj in pairs(guis:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Text == txt then
            return obj.Parent
        end
    end
    local f = nil
    pcall(function() f = fbackfunc() end)
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
        Text = premium_mode and "Premium paths selected" or "Free paths selected",
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
    local m1btn = nil
    pcall(function()
        if premium_mode then
            m1btn = guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[22]
        else
            m1btn = guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[17]
        end
    end)
    if not m1btn then
        m1btn = getlblparent("M1 Assist Only", function() return nil end)
    end
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
        return getlblparent("Auto Counter", function() return guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[9] end)
    end)
    if not cntrbtn then
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
    {"Auto QTE Minigame Click Only", function()
        local btn = nil
        pcall(function()
            if premium_mode then
                btn = guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[18]
            else
                btn = guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[14]
            end
        end)
        if btn then return btn end
        return getlblparent("Auto QTE Minigame Click Only", function() return nil end)
    end},
    {"Auto ShutUp", function()
        local btn = nil
        if not premium_mode then
            pcall(function()
                btn = guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[31]
            end)
        end
        if btn then return btn end
        return getlblparent("Auto ShutUp", function() return nil end)
    end},
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

local function readslidernumber(label)
    if not label then return nil end
    local textvalue = tostring(label.Text or "")
    local value = string.match(textvalue, "[-+]?%d+%.?%d*")
    return value and tonumber(value) or nil
end

local function findsliderlabel(prefix)
    local wanted = string.lower(tostring(prefix))

    for _, obj in pairs(guis:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            local txt = string.lower(tostring(obj.Text or ""))
            if string.sub(txt, 1, #wanted) == wanted then
                return obj
            end
        end
    end

    return nil
end

local function getslidertrackfromlabel(label, fallbackfunc)
    if not label or not label:IsA("GuiObject") then
        local fallback = nil
        pcall(function() fallback = fallbackfunc and fallbackfunc() end)
        return fallback
    end

    local fallback = nil
    pcall(function() fallback = fallbackfunc and fallbackfunc() end)

    local labelX = label.AbsolutePosition.X
    local labelY = label.AbsolutePosition.Y
    local labelW = label.AbsoluteSize.X
    local labelH = label.AbsoluteSize.Y
    local labelCenterY = labelY + (labelH / 2)

    local best = nil
    local bestScore = -math.huge
    local ancestor = label.Parent
    local depth = 0

    while ancestor and ancestor ~= game and depth < 5 do
        for _, obj in pairs(ancestor:GetDescendants()) do
            if obj:IsA("GuiObject")
                and obj ~= label
                and obj.Visible
                and not obj:IsA("TextLabel")
                and not obj:IsA("TextButton") then

                local width = obj.AbsoluteSize.X
                local height = obj.AbsoluteSize.Y
                local x = obj.AbsolutePosition.X
                local y = obj.AbsolutePosition.Y
                local centerY = y + (height / 2)

                if width >= 35 and height >= 2 and height <= 42 then
                    local horizontalOverlap = math.min(x + width, labelX + labelW) - math.max(x, labelX)
                    local yDifference = centerY - labelCenterY

                    if horizontalOverlap > 8 and yDifference >= -4 and yDifference <= 85 then
                        local score = 0
                        local lowerName = string.lower(obj.Name)

                        score = score + math.min(width, 300) / 8
                        score = score + math.max(0, 35 - height)
                        score = score - math.abs(yDifference - 24)

                        if string.find(lowerName, "slider", 1, true) then score = score + 100 end
                        if string.find(lowerName, "track", 1, true) then score = score + 90 end
                        if string.find(lowerName, "bar", 1, true) then score = score + 70 end
                        if string.find(lowerName, "fill", 1, true) then score = score - 20 end
                        if string.find(lowerName, "knob", 1, true) then score = score - 30 end
                        if string.find(lowerName, "thumb", 1, true) then score = score - 30 end

                        if obj:IsA("ImageButton") then score = score + 12 end
                        if obj.Active then score = score + 12 end

                        local hasSmallChild = false
                        for _, child in pairs(obj:GetChildren()) do
                            if child:IsA("GuiObject") and child.AbsoluteSize.X < width then
                                hasSmallChild = true
                                break
                            end
                        end
                        if hasSmallChild then score = score + 20 end

                        if fallback and obj == fallback then score = score + 25 end

                        if score > bestScore then
                            best = obj
                            bestScore = score
                        end
                    end
                end
            end
        end

        ancestor = ancestor.Parent
        depth = depth + 1
    end

    return best or fallback
end

local fastslider

local function fastsliderbylabel(prefix, fallbacksliderfunc, fallbacklabelfunc, wantnum)
    local label = findsliderlabel(prefix)

    if not label then
        pcall(function()
            if fallbacklabelfunc then
                label = fallbacklabelfunc()
            end
        end)
    end

    local slider = getslidertrackfromlabel(label, fallbacksliderfunc)
    local wantedText = tostring(prefix) .. ": " .. tostring(wantnum)

    fastslider(
        function() return slider end,
        function() return label end,
        wantedText,
        wantnum
    )
end

fastslider = function(frmfunc, lblfunc, wanttxt, wantnum)
    local slider = nil
    local label = nil

    pcall(function()
        slider = frmfunc()
        label = lblfunc()
    end)

    if not slider or not label or not slider:IsA("GuiObject") then
        task.wait(0.05)
        return
    end

    local scrolling = nil
    pcall(function()
        local current = slider
        while current and current ~= game do
            if current:IsA("ScrollingFrame") then
                scrolling = current
                break
            end
            current = current.Parent
        end
    end)

    if not scrolling then
        pcall(function()
            local possible = guis.ScreenGui.Frame.Frame:GetChildren()[4]
            if possible:IsA("ScrollingFrame") then
                scrolling = possible
            end
        end)
    end

    if scrolling then
        pcall(function()
            local targetY = slider.AbsolutePosition.Y - scrolling.AbsolutePosition.Y + scrolling.CanvasPosition.Y - (scrolling.AbsoluteWindowSize.Y / 2)
            local maxY = math.max(0, scrolling.AbsoluteCanvasSize.Y - scrolling.AbsoluteWindowSize.Y)
            scrolling.CanvasPosition = Vector2.new(scrolling.CanvasPosition.X, math.clamp(targetY, 0, maxY))
        end)
        task.wait(0.2)
    end

    local currentValue = readslidernumber(label)
    if currentValue == wantnum or tostring(label.Text) == wanttxt then
        task.wait(0.05)
        return
    end

    local left = math.floor(slider.AbsolutePosition.X + 2)
    local right = math.floor(slider.AbsolutePosition.X + slider.AbsoluteSize.X - 2)
    local y = math.floor(slider.AbsolutePosition.Y + (slider.AbsoluteSize.Y / 2))

    if right <= left then
        task.wait(0.05)
        return
    end

    local x = math.clamp(math.floor(slider.AbsolutePosition.X + (slider.AbsoluteSize.X / 2)), left, right)
    local touchId = 0

    local function begininput(px)
        if touchmode then
            local touchX, touchY = gettouchcoords(slider, px, y)
            vman:SendTouchEvent(touchId, 0, touchX, touchY)
        else
            vman:SendMouseMoveEvent(px, y, game)
            vman:SendMouseButtonEvent(px, y, 0, true, game, 1)
        end
    end

    local function moveinput(px)
        if touchmode then
            local touchX, touchY = gettouchcoords(slider, px, y)
            vman:SendTouchEvent(touchId, 1, touchX, touchY)
        else
            vman:SendMouseMoveEvent(px, y, game)
        end
    end

    local function endinput(px)
        if touchmode then
            local touchX, touchY = gettouchcoords(slider, px, y)
            vman:SendTouchEvent(touchId, 2, touchX, touchY)
        else
            vman:SendMouseButtonEvent(px, y, 0, false, game, 1)
        end
    end

    local began = false
    pcall(function()
        begininput(x)
        began = true
    end)

    if not began then
        task.wait(0.05)
        return
    end

    task.wait(0.06)

    local lastValue = readslidernumber(label)
    local direction = 1
    local step = math.max(2, math.floor(slider.AbsoluteSize.X / 45))
    local attempts = 0
    local unchanged = 0

    while attempts < 180 do
        currentValue = readslidernumber(label)
        if currentValue == wantnum or tostring(label.Text) == wanttxt then
            break
        end

        if currentValue ~= nil then
            direction = currentValue > wantnum and -1 or 1
        end

        local nextX = math.clamp(x + (step * direction), left, right)

        if nextX == x then
            direction = -direction
            nextX = math.clamp(x + (step * direction), left, right)
        end

        x = nextX
        pcall(function() moveinput(x) end)
        task.wait(touchmode and 0.025 or 0.012)

        local newValue = readslidernumber(label)
        if newValue == lastValue then
            unchanged = unchanged + 1
        else
            unchanged = 0
            lastValue = newValue
        end

        if unchanged >= 10 then
            step = math.min(math.max(step + 1, math.floor(slider.AbsoluteSize.X / 25)), 10)
            unchanged = 0
        end

        attempts = attempts + 1
    end

    pcall(function() endinput(x) end)
    task.wait(0.08)
end

opentab("Auto", 5)

local blkrange = getcfgnum("Auto Block Range", 19)
local cntrrange = getcfgnum("Auto Counter Range", 4)
local dlyval = getcfgnum("Click Delay", 16)

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
