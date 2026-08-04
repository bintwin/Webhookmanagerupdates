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

local function normalizetext(value)
    local text = string.lower(tostring(value or ""))
    text = string.gsub(text, "[%c]", " ")
    text = string.gsub(text, "%s+", " ")
    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    return text
end

local function striponly(value)
    local text = normalizetext(value)
    text = string.gsub(text, "%s+only$", "")
    return text
end

local function sametext(actual, wanted)
    local a = normalizetext(actual)
    local b = normalizetext(wanted)
    return a == b or striponly(a) == striponly(b)
end

local function textstartswith(actual, wanted)
    local a = striponly(actual)
    local b = striponly(wanted)

    return a == b
        or string.sub(a, 1, #b + 1) == b .. ":"
        or string.sub(a, 1, #b + 1) == b .. " "
end

local function isguivisible(obj)
    if not obj or not obj:IsA("GuiObject") or not obj.Visible then return false end

    local current = obj.Parent
    while current and current ~= game do
        if current:IsA("GuiObject") and not current.Visible then
            return false
        end
        current = current.Parent
    end

    return true
end

local function getrowbuttonfromlabel(label)
    if not label or not label:IsA("GuiObject") then return nil end

    local current = label
    while current and current ~= game do
        if current:IsA("GuiButton") then
            return current
        end
        current = current.Parent
    end

    local labelCenterY = label.AbsolutePosition.Y + (label.AbsoluteSize.Y / 2)
    local labelRight = label.AbsolutePosition.X + label.AbsoluteSize.X
    local ancestor = label.Parent
    local depth = 0
    local best = nil
    local bestScore = -math.huge

    while ancestor and ancestor ~= game and depth < 5 do
        if ancestor:IsA("GuiObject") then
            local ancestorTop = ancestor.AbsolutePosition.Y
            local ancestorBottom = ancestorTop + ancestor.AbsoluteSize.Y

            for _, candidate in pairs(ancestor:GetDescendants()) do
                if candidate:IsA("GuiButton") and isguivisible(candidate) then
                    local centerY = candidate.AbsolutePosition.Y + (candidate.AbsoluteSize.Y / 2)
                    local verticalDistance = math.abs(centerY - labelCenterY)

                    if centerY >= ancestorTop - 2 and centerY <= ancestorBottom + 2 then
                        local score = 0

                        if label:IsDescendantOf(candidate) then score = score + 1000 end
                        score = score - verticalDistance * 4

                        if candidate.AbsolutePosition.X >= labelRight - 8 then
                            score = score + 70
                        end

                        if candidate.Parent == label.Parent then
                            score = score + 45
                        end

                        if candidate:IsA("TextButton") and sametext(candidate.Text, label.Text) then
                            score = score + 500
                        end

                        if score > bestScore then
                            best = candidate
                            bestScore = score
                        end
                    end
                end
            end
        end

        if best and bestScore >= 400 then
            return best
        end

        ancestor = ancestor.Parent
        depth = depth + 1
    end

    return best or label.Parent
end

local function objecthastext(obj, wanted)
    if not obj then return false end

    if (obj:IsA("TextButton") or obj:IsA("TextLabel") or obj:IsA("TextBox"))
        and sametext(obj.Text, wanted) then
        return true
    end

    if obj:IsA("GuiButton") or obj:IsA("GuiObject") then
        for _, child in pairs(obj:GetDescendants()) do
            if (child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox"))
                and sametext(child.Text, wanted) then
                return true
            end
        end
    end

    return false
end

local function findcontrolbytext(wanted)
    local bestButton = nil
    local bestButtonScore = -math.huge
    local matchingLabels = {}

    for _, obj in pairs(guis:GetDescendants()) do
        if isguivisible(obj) then
            if obj:IsA("GuiButton") then
                local score = -math.huge

                if (obj:IsA("TextButton") or obj:IsA("TextBox")) and sametext(obj.Text, wanted) then
                    score = 1200
                elseif objecthastext(obj, wanted) then
                    score = 1050
                elseif sametext(obj.Name, wanted) then
                    score = 700
                end

                if score > -math.huge then
                    if obj.Active then score = score + 20 end
                    if obj.AbsoluteSize.X > 0 and obj.AbsoluteSize.Y > 0 then score = score + 10 end

                    if score > bestButtonScore then
                        bestButton = obj
                        bestButtonScore = score
                    end
                end
            elseif obj:IsA("TextLabel") and sametext(obj.Text, wanted) then
                table.insert(matchingLabels, obj)
            end
        end
    end

    if bestButton then
        return bestButton
    end

    local bestRowButton = nil
    local bestRowScore = -math.huge

    for _, label in pairs(matchingLabels) do
        local button = getrowbuttonfromlabel(label)
        if button then
            local score = 0

            if button:IsA("GuiButton") then score = score + 300 end
            if label:IsDescendantOf(button) then score = score + 500 end

            local labelY = label.AbsolutePosition.Y + (label.AbsoluteSize.Y / 2)
            local buttonY = button.AbsolutePosition.Y + (button.AbsoluteSize.Y / 2)
            score = score - math.abs(labelY - buttonY) * 4

            if button.AbsolutePosition.X >= label.AbsolutePosition.X + label.AbsoluteSize.X - 8 then
                score = score + 80
            end

            if score > bestRowScore then
                bestRowButton = button
                bestRowScore = score
            end
        end
    end

    if bestRowButton then
        return bestRowButton
    end

    for _, obj in pairs(guis:GetDescendants()) do
        if isguivisible(obj) and sametext(obj.Name, wanted) then
            if obj:IsA("GuiButton") then
                return obj
            end

            for _, child in pairs(obj:GetDescendants()) do
                if child:IsA("GuiButton") and isguivisible(child) then
                    return child
                end
            end

            if obj:IsA("GuiObject") then
                return obj
            end
        end
    end

    return nil
end

local function findcontrolbyprefix(wanted)
    local bestButton = nil
    local bestButtonScore = -math.huge
    local labels = {}

    for _, obj in pairs(guis:GetDescendants()) do
        if isguivisible(obj) then
            if obj:IsA("GuiButton") then
                local matched = false
                local score = -math.huge

                if obj:IsA("TextButton") and textstartswith(obj.Text, wanted) then
                    matched = true
                    score = 1100
                else
                    for _, child in pairs(obj:GetDescendants()) do
                        if (child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox"))
                            and textstartswith(child.Text, wanted) then
                            matched = true
                            score = 1000
                            break
                        end
                    end
                end

                if matched and score > bestButtonScore then
                    bestButton = obj
                    bestButtonScore = score
                end
            elseif obj:IsA("TextLabel") and textstartswith(obj.Text, wanted) then
                table.insert(labels, obj)
            end
        end
    end

    if bestButton then return bestButton end

    for _, label in pairs(labels) do
        local button = getrowbuttonfromlabel(label)
        if button then return button end
    end

    return nil
end

local currenttab = nil
local alltabs = {
    "Main",
    "Combat",
    "Auto",
    "Teleports",
    "Target",
    "Extra",
    "Configs",
    "Ai Assistant"
}

local tabfallbacks = {
    ["Auto"] = 5
}

local function findtabbutton(tname)
    local sidebar = nil
    pcall(function()
        sidebar = guis.ScreenGui.Frame.ScrollingFrame
    end)

    if not sidebar then return nil end

    local best = nil
    local bestScore = -math.huge

    for _, obj in pairs(sidebar:GetDescendants()) do
        if obj:IsA("GuiButton") and isguivisible(obj) then
            local score = -math.huge

            if obj:IsA("TextButton") and sametext(obj.Text, tname) then
                score = 1000
            elseif objecthastext(obj, tname) then
                score = 900
            elseif sametext(obj.Name, tname) then
                score = 700
            end

            if score > bestScore then
                best = obj
                bestScore = score
            end
        end
    end

    if best then return best end

    for _, obj in pairs(sidebar:GetDescendants()) do
        if obj:IsA("TextLabel") and isguivisible(obj) and sametext(obj.Text, tname) then
            return getrowbuttonfromlabel(obj)
        end
    end

    return nil
end

local function opentab(tname, idxfallback)
    local worked = false
    local tabbutton = findtabbutton(tname)

    if tabbutton then
        clickybtn(tabbutton)
        worked = true
    end

    if not worked then
        local fallbackIndex = idxfallback or tabfallbacks[tname]
        if fallbackIndex then
            pcall(function()
                clickybtn(guis.ScreenGui.Frame.ScrollingFrame:GetChildren()[fallbackIndex])
                worked = true
            end)
        end
    end

    if worked then
        currenttab = tname
        task.wait(0.35)
    end

    return worked
end

local function gettabhints(wanted)
    local text = normalizetext(wanted)

    if string.find(text, "emote", 1, true)
        or string.find(text, "soundboard", 1, true)
        or string.find(text, "extra", 1, true) then
        return {"Extra"}
    end

    if string.find(text, "lock on", 1, true)
        or text == "character"
        or text == "camera"
        or string.find(text, "target", 1, true) then
        return {"Target", "Main", "Combat"}
    end

    if string.find(text, "m1", 1, true)
        or string.find(text, "dash assist", 1, true)
        or string.find(text, "combat", 1, true) then
        return {"Combat", "Auto"}
    end

    if string.find(text, "auto", 1, true)
        or string.find(text, "anti", 1, true)
        or string.find(text, "delay", 1, true)
        or string.find(text, "range", 1, true)
        or string.find(text, "cooldown", 1, true)
        or string.find(text, "stun", 1, true)
        or string.find(text, "domain", 1, true)
        or string.find(text, "blackflash", 1, true)
        or string.find(text, "black flash", 1, true) then
        return {"Auto", "Combat"}
    end

    return {}
end

local function withfallback(found, fbackfunc)
    if found then return found end

    local fallback = nil
    pcall(function()
        if fbackfunc then
            fallback = fbackfunc()
        end
    end)
    return fallback
end

local function findcontrolalltabs(wanted, fbackfunc, preferredtabs)
    local found = findcontrolbytext(wanted)
    if found then return found end

    local tried = {}
    local hints = preferredtabs or gettabhints(wanted)

    local function trytab(tabname)
        if not tabname or tried[tabname] then return nil end
        tried[tabname] = true

        if currenttab ~= tabname then
            opentab(tabname, tabfallbacks[tabname])
        end

        return findcontrolbytext(wanted)
    end

    for _, tabname in pairs(hints) do
        found = trytab(tabname)
        if found then return found end
    end

    for _, tabname in pairs(alltabs) do
        found = trytab(tabname)
        if found then return found end
    end

    if hints[1] and currenttab ~= hints[1] then
        opentab(hints[1], tabfallbacks[hints[1]])
    end

    return withfallback(nil, fbackfunc)
end

local function findprefixalltabs(wanted, fbackfunc, preferredtabs)
    local found = findcontrolbyprefix(wanted)
    if found then return found end

    local tried = {}
    local hints = preferredtabs or gettabhints(wanted)

    local function trytab(tabname)
        if not tabname or tried[tabname] then return nil end
        tried[tabname] = true

        if currenttab ~= tabname then
            opentab(tabname, tabfallbacks[tabname])
        end

        return findcontrolbyprefix(wanted)
    end

    for _, tabname in pairs(hints) do
        found = trytab(tabname)
        if found then return found end
    end

    for _, tabname in pairs(alltabs) do
        found = trytab(tabname)
        if found then return found end
    end

    if hints[1] and currenttab ~= hints[1] then
        opentab(hints[1], tabfallbacks[hints[1]])
    end

    return withfallback(nil, fbackfunc)
end

local function getlblparent(txt, fbackfunc, preferredtabs)
    return findcontrolalltabs(txt, fbackfunc, preferredtabs)
end

local function getbtntxt(txt, fbackfunc, preferredtabs)
    return findcontrolalltabs(txt, fbackfunc, preferredtabs)
end

local function getbtnany(nm, fbackfunc, preferredtabs)
    return findcontrolalltabs(nm, fbackfunc, preferredtabs)
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
        return getlblparent("Lock On", function() return guis.ScreenGui.Frame.Frame.ScrollingFrame:GetChildren()[14] end, {"Target", "Main", "Combat"})
    end, {"Target", "Main", "Combat"})
    if lockbtn then
        clickybtn(lockbtn)
        task.wait(0.05)
    end
    local b1 = findprefixalltabs("Lock On Keybind", function() return guis.ScreenGui.Frame.Frame.ScrollingFrame:GetChildren()[15] end, {"Target", "Main", "Combat"})
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
    local emotebtn = getlblparent("Unlock Extra Emote Slot", function() return guis.ScreenGui.Frame.Frame:GetChildren()[7]:GetChildren()[25] end, {"Extra"})
    if not emotebtn then
        pcall(function() emotebtn = guis.ScreenGui.Frame.Frame:GetChildren()[7]:GetChildren()[25] end)
    end
    clickybtn(emotebtn)
    task.wait(0.05)
end

if chkdo("M1 Assist") then
    local m1btn = findcontrolalltabs("M1 Assist", nil, {"Combat", "Auto"})
        or findcontrolalltabs("M1 Assist Only", nil, {"Combat", "Auto"})

    if not m1btn then
        pcall(function()
            if premium_mode then
                m1btn = guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[22]
            else
                m1btn = guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[17]
            end
        end)
    end

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
        local btn = findcontrolalltabs("Auto QTE Minigame Click Only", nil, {"Auto"})
            or findcontrolalltabs("Auto QTE Minigame Click", nil, {"Auto"})

        if btn then return btn end

        pcall(function()
            if premium_mode then
                btn = guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[18]
            else
                btn = guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[14]
            end
        end)

        return btn
    end},
    {"Auto ShutUp", function()
        local btn = findcontrolalltabs("Auto ShutUp", nil, {"Auto"})
            or findcontrolalltabs("Auto Shut Up", nil, {"Auto"})

        if btn then return btn end

        if not premium_mode then
            pcall(function()
                btn = guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[31]
            end)
        end

        return btn
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

local alreadyhandled = {
    [normalizetext("Lock On")] = true,
    [normalizetext("Unlock Extra Emote slot")] = true,
    [normalizetext("M1 Assist")] = true,
    [normalizetext("Auto Counter")] = true,
    [normalizetext("Auto Block Range")] = true,
    [normalizetext("Auto Counter Range")] = true,
    [normalizetext("Click Delay")] = true
}

for _, item in pairs(fastbtnlist) do
    alreadyhandled[normalizetext(item[1])] = true
end

for _, nm in pairs(morenames) do
    alreadyhandled[normalizetext(nm)] = true
end

if enablecustomconfig and parsedcfg then
    for configname, configvalue in pairs(parsedcfg) do
        local normalizedName = normalizetext(configname)

        if configvalue == true and not alreadyhandled[normalizedName] then
            local btn = findcontrolalltabs(tostring(configname), nil, gettabhints(configname))

            if btn and not isbtnenabled(btn) then
                clickybtn(btn)
                task.wait(0.02)
            end

            alreadyhandled[normalizedName] = true
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
    local wanted = normalizetext(prefix)
    local best = nil
    local bestScore = -math.huge

    for _, obj in pairs(guis:GetDescendants()) do
        if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and isguivisible(obj) then
            local text = normalizetext(obj.Text)
            local matches = text == wanted
                or string.sub(text, 1, #wanted + 1) == wanted .. ":"
                or string.sub(text, 1, #wanted + 1) == wanted .. " "

            if matches then
                local score = 0
                if obj:IsA("TextLabel") then score = score + 30 end
                if string.find(text, ":", 1, true) then score = score + 20 end
                if string.match(text, "[-+]?%d+%.?%d*") then score = score + 20 end
                if obj.AbsoluteSize.X > 80 then score = score + 10 end

                if score > bestScore then
                    best = obj
                    bestScore = score
                end
            end
        end
    end

    return best
end

local function getslidertrackfromlabel(label, fallbackfunc)
    if not label or not label:IsA("GuiObject") then
        local fallback = nil
        pcall(function() fallback = fallbackfunc and fallbackfunc() end)
        return fallback
    end

    local labelLeft = label.AbsolutePosition.X
    local labelRight = labelLeft + label.AbsoluteSize.X
    local labelBottom = label.AbsolutePosition.Y + label.AbsoluteSize.Y
    local ancestor = label.Parent
    local depth = 0

    while ancestor and ancestor ~= game and depth < 5 do
        if ancestor:IsA("GuiObject") then
            local rowLeft = ancestor.AbsolutePosition.X
            local rowRight = rowLeft + ancestor.AbsoluteSize.X
            local rowBottom = ancestor.AbsolutePosition.Y + ancestor.AbsoluteSize.Y
            local best = nil
            local bestScore = -math.huge

            for _, obj in pairs(ancestor:GetDescendants()) do
                if obj:IsA("GuiObject")
                    and obj ~= label
                    and isguivisible(obj)
                    and not obj:IsA("TextLabel")
                    and not obj:IsA("TextButton") then

                    local width = obj.AbsoluteSize.X
                    local height = obj.AbsoluteSize.Y
                    local left = obj.AbsolutePosition.X
                    local right = left + width
                    local top = obj.AbsolutePosition.Y
                    local centerY = top + (height / 2)
                    local overlap = math.min(right, labelRight) - math.max(left, labelLeft)
                    local belowDistance = centerY - labelBottom

                    local insideRow = left >= rowLeft - 4
                        and right <= rowRight + 4
                        and centerY <= rowBottom + 4

                    if insideRow
                        and width >= 55
                        and height >= 2
                        and height <= 32
                        and overlap >= 20
                        and belowDistance >= -8
                        and belowDistance <= 70 then

                        local name = string.lower(obj.Name)
                        local score = width / 5
                        score = score - math.abs(belowDistance - 16) * 2
                        score = score + math.max(0, 28 - height)

                        if string.find(name, "slider", 1, true) then score = score + 140 end
                        if string.find(name, "track", 1, true) then score = score + 120 end
                        if string.find(name, "bar", 1, true) then score = score + 90 end
                        if string.find(name, "fill", 1, true) then score = score - 35 end
                        if string.find(name, "knob", 1, true) then score = score - 50 end
                        if string.find(name, "thumb", 1, true) then score = score - 50 end
                        if obj:IsA("ImageButton") then score = score + 20 end
                        if obj.Active then score = score + 15 end

                        local hasFill = false
                        for _, child in pairs(obj:GetChildren()) do
                            if child:IsA("GuiObject")
                                and child.AbsoluteSize.X > 0
                                and child.AbsoluteSize.X < width then
                                hasFill = true
                                break
                            end
                        end
                        if hasFill then score = score + 35 end

                        if score > bestScore then
                            best = obj
                            bestScore = score
                        end
                    end
                end
            end

            if best then
                return best
            end
        end

        ancestor = ancestor.Parent
        depth = depth + 1
    end

    local fallback = nil
    pcall(function() fallback = fallbackfunc and fallbackfunc() end)
    return fallback
end

local fastslider

local function fastsliderbylabel(prefix, fallbacksliderfunc, fallbacklabelfunc, wantnum)
    if currenttab ~= "Auto" then
        opentab("Auto", 5)
    end

    local label = findsliderlabel(prefix)

    if not label then
        for _, tabname in pairs(alltabs) do
            if currenttab ~= tabname then
                opentab(tabname, tabfallbacks[tabname])
            end
            label = findsliderlabel(prefix)
            if label then break end
        end
    end

    if not label and currenttab ~= "Auto" then
        opentab("Auto", 5)
    end

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
    fastsliderbylabel(
        "Auto Block Range",
        function() return guis.ScreenGui.Frame.Frame:GetChildren()[4].Frame.Frame.Frame end,
        function() return guis.ScreenGui.Frame.Frame:GetChildren()[4].Frame.TextLabel end,
        blkrange
    )

    fastsliderbylabel(
        "Auto Counter Range",
        function() return guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[10].Frame end,
        function() return guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[10].TextLabel end,
        cntrrange
    )

    fastsliderbylabel(
        "Click Delay",
        function() return guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[19].Frame end,
        function() return guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[19].TextLabel end,
        dlyval
    )
else
    fastsliderbylabel(
        "Auto Block Range",
        function() return guis.ScreenGui.Frame.Frame:GetChildren()[4].Frame.Frame end,
        function() return guis.ScreenGui.Frame.Frame:GetChildren()[4].Frame.TextLabel end,
        blkrange
    )

    fastsliderbylabel(
        "Auto Counter Range",
        function() return guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[10].Frame end,
        function() return guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[10].TextLabel end,
        cntrrange
    )

    fastsliderbylabel(
        "Click Delay",
        function() return guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[15].Frame end,
        function() return guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[15].TextLabel end,
        dlyval
    )
end
