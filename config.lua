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

local function isbtnenabled(btn)
    if not btn then return false end
    local checkcol = function(c)
        if not c then return false end
        local r = math.floor(c.R * 255 + 0.5)
        local g = math.floor(c.G * 255 + 0.5)
        local b = math.floor(c.B * 255 + 0.5)
        return (g == 170 and b == 127) or (g > 150 and b > 100 and r < 50) or (r == 0 and g == 170 and b == 127)
    end
    if checkcol(btn.BackgroundColor3) then return true end
    for _, ch in pairs(btn:GetChildren()) do
        if ch:IsA("Frame") and checkcol(ch.BackgroundColor3) then
            return true
        end
    end
    return false
end

local function clickybtn(b)
    b = getclicktarget(b)
    if not b then return end

    local worked = false

    -- Prioritize firesignal (100% silent, works on PC without crashing)
    if type(firesignal) == "function" then
        pcall(function()
            if b:IsA("GuiButton") then
                firesignal(b.MouseButton1Click)
                firesignal(b.MouseButton1Down)
                firesignal(b.MouseButton1Up)
                firesignal(b.Activated)
            else
                firesignal(b.TouchTap)
            end
            worked = true
        end)
    end

    if worked then return end

    -- Safe getconnections fallback (only for Mobile, avoids PC anti-cheat crashes)
    if touchmode and type(getconnections) == "function" then
        local function fireconn(sig)
            if not sig then return false end
            local cons = nil
            pcall(function() cons = getconnections(sig) end)
            if type(cons) ~= "table" or #cons == 0 then return false end
            for _, c in pairs(cons) do
                pcall(function() c:Fire() end)
            end
            return true
        end

        pcall(function()
            if b:IsA("GuiButton") then
                worked = fireconn(b.Activated)
                if not worked then worked = fireconn(b.MouseButton1Click) end
            else
                worked = fireconn(b.TouchTap)
            end
        end)
    end

    if worked then return end

    -- Last resort: VirtualUser (Silent click on center of UI)
    local x, y = getguicenter(b)
    if x and y then
        pcall(function()
            game:GetService("VirtualUser"):ClickButton1(Vector2.new(x, y))
            game:GetService("VirtualUser"):MoveMouse(Vector2.new(0, 0))
            if vman then vman:SendMouseMoveEvent(0, 0, game) end
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


local function findcontrolbytext(wanted)
    local contentarea = nil
    pcall(function() contentarea = guis.ScreenGui.Frame.Frame end)
    if not contentarea then return nil end
    for _, obj in pairs(contentarea:GetDescendants()) do
        if obj:IsA("TextButton") then
            if sametext(obj.Text, wanted) then
                return obj
            end
            for _, ch in pairs(obj:GetChildren()) do
                if ch:IsA("TextLabel") and sametext(ch.Text, wanted) then
                    return obj
                end
            end
        end
    end
    for _, obj in pairs(contentarea:GetDescendants()) do
        if sametext(obj.Name, wanted) then
            if obj:IsA("TextButton") then
                return obj
            end
            for _, ch in pairs(obj:GetDescendants()) do
                if ch:IsA("TextButton") then
                    return ch
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
    local contentarea = nil
    pcall(function() contentarea = guis.ScreenGui.Frame.Frame end)
    if not contentarea then return nil end
    for _, obj in pairs(contentarea:GetDescendants()) do
        if obj:IsA("TextButton") then
            if obj.Text ~= "" and textstartswith(obj.Text, wanted) then
                return obj
            end
            for _, ch in pairs(obj:GetChildren()) do
                if ch:IsA("TextLabel") and textstartswith(ch.Text, wanted) then
                    return obj
                end
            end
        end
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
    for _, obj in pairs(sidebar:GetDescendants()) do
        if obj:IsA("TextButton") and isguivisible(obj) then
            if sametext(obj.Text, tname) then
                return obj
            end
            for _, ch in pairs(obj:GetChildren()) do
                if ch:IsA("TextLabel") and sametext(ch.Text, tname) then
                    return obj
                end
            end
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
        task.wait(0.03)
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


local function switchtab4obj(obj)
    local contentarea = nil
    pcall(function() contentarea = guis.ScreenGui.Frame.Frame end)
    if not contentarea then return end
    local tabscroll = obj
    while tabscroll and tabscroll ~= game and tabscroll.Parent ~= contentarea do
        tabscroll = tabscroll.Parent
    end
    if tabscroll and tabscroll:IsA("ScrollingFrame") and tabscroll.Parent == contentarea then
        local sfIdx = 0
        for i, ch in ipairs(contentarea:GetChildren()) do
            if ch == tabscroll then sfIdx = i break end
        end
        if sfIdx >= 2 and sfIdx <= #alltabs + 1 then
            local wantedTab = alltabs[sfIdx - 1]
            if currenttab ~= wantedTab then
                opentab(wantedTab)
            end
        end
    end
end

local function findcontrolalltabs(wanted, fbackfunc, preferredtabs)
    local found = findcontrolbytext(wanted)
    if found then
        switchtab4obj(found)
        return found
    end
    return withfallback(nil, fbackfunc)
end

local function findprefixalltabs(wanted, fbackfunc, preferredtabs)
    local found = findcontrolbyprefix(wanted)
    if found then
        switchtab4obj(found)
        return found
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
    if lockbtn and not isbtnenabled(lockbtn) then
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
    if emotebtn and not isbtnenabled(emotebtn) then
        clickybtn(emotebtn)
        task.wait(0.05)
    end
end

if chkdo("M1 Assist") then
    local m1btn = findcontrolalltabs("M1 Assist", nil, {"Combat", "Auto", "Misc", "Main"})
        or findcontrolalltabs("M1 Assist Only", nil, {"Combat", "Auto", "Misc", "Main"})

    clickybtn(m1btn)
    task.wait(0.02)
    local m1m = "UpperCut"
    if enablecustomconfig and parsedcfg and parsedcfg["M1 Method"] then
        m1m = tostring(parsedcfg["M1 Method"])
    end
    clickybtn(getbtnany(m1m, function() return nil end))
    task.wait(0.02)
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
    local contentarea = nil
    pcall(function() contentarea = guis.ScreenGui.Frame.Frame end)
    if not contentarea then return nil end
    
    for _, tab in ipairs(contentarea:GetChildren()) do
        if tab:IsA("ScrollingFrame") then
            for _, container in ipairs(tab:GetChildren()) do
                if container:IsA("Frame") then
                    local has_track = false
                    local has_button = false
                    for _, child in ipairs(container:GetChildren()) do
                        if child:IsA("Frame") then has_track = true end
                        if child:IsA("TextButton") then has_button = true end
                    end
                    
                    if has_track and not has_button then
                        for _, child in ipairs(container:GetChildren()) do
                            if child:IsA("TextLabel") then
                                local text = normalizetext(child.Text)
                                local hasPrefix = (text == wanted) or 
                                                  (string.sub(text, 1, #wanted + 1) == wanted .. ":") or 
                                                  (string.sub(text, 1, #wanted + 1) == wanted .. " ")
                                
                                if hasPrefix and string.match(text, "%d") then
                                    return child
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end

local function getslidertrackfromlabel(label, fallbackfunc)
    if not label or not label.Parent then
        local fb = nil
        pcall(function() fb = fallbackfunc and fallbackfunc() end)
        return fb
    end
    local container = label.Parent
    if container:IsA("Frame") then
        for _, sib in pairs(container:GetChildren()) do
            if sib:IsA("Frame") and sib ~= label then
                return sib
            end
        end
    end
    local fb = nil
    pcall(function() fb = fallbackfunc and fallbackfunc() end)
    return fb
end

local fastslider


local function getFullPath(obj)
    if not obj then return "nil" end
    local path = obj.Name
    local current = obj.Parent
    while current and current ~= game do
        path = current.Name .. "." .. path
        current = current.Parent
    end
    return path
end

local function fastsliderbylabel(prefix, fallbacksliderfunc, fallbacklabelfunc, wantnum)
    local label = findsliderlabel(prefix)
    
    print("[DEBUG] Searching for slider: " .. tostring(prefix))
    if label then
        print("[DEBUG] Found label at: " .. getFullPath(label))
        print("[DEBUG] Label POS: " .. tostring(label.AbsolutePosition) .. " SIZE: " .. tostring(label.AbsoluteSize))
        switchtab4obj(label)
    else
        print("[DEBUG] Label NOT found for: " .. tostring(prefix))
        pcall(function()
            if fallbacklabelfunc then label = fallbacklabelfunc() end
        end)
    end
    
    local slider = getslidertrackfromlabel(label, fallbacksliderfunc)
    if slider then
        print("[DEBUG] Found slider track at: " .. getFullPath(slider))
        print("[DEBUG] Track POS: " .. tostring(slider.AbsolutePosition) .. " SIZE: " .. tostring(slider.AbsoluteSize))
    else
        print("[DEBUG] Slider track NOT found for: " .. tostring(prefix))
    end
    
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
            for _, ch in pairs(guis.ScreenGui.Frame.Frame:GetChildren()) do
                if ch:IsA("ScrollingFrame") and ch.Visible then
                    scrolling = ch
                    break
                end
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

    local function getvimy(guiObject, base_y)
        local screenGui = guiObject:FindFirstAncestorOfClass("ScreenGui")
        if screenGui and not screenGui.IgnoreGuiInset then
            local inset = game:GetService("GuiService"):GetGuiInset()
            return base_y + inset.Y
        end
        return base_y
    end

    local vim_y = getvimy(slider, y)

    local vu = game:GetService("VirtualUser")

    local function firesig(obj, sigName, itype, state, px, py)
        local getconn = getconnections or get_signal_cons
        if not getconn or not obj then return end
        pcall(function()
            local fakeInput = {
                UserInputType = itype,
                UserInputState = state,
                Position = Vector3.new(px, py, 0),
                KeyCode = Enum.KeyCode.Unknown,
                Delta = Vector3.new(0, 0, 0)
            }
            local sig = obj[sigName]
            for _, conn in pairs(getconn(sig)) do
                pcall(function() conn:Fire(fakeInput) end)
                if type(conn.Function) == "function" then
                    pcall(function() conn.Function(fakeInput) end)
                end
            end
        end)
    end

    local function begininput(px)
        pcall(function() vman:SendTouchEvent(touchId, 0, px, y) end)
        pcall(function() vman:SendMouseMoveEvent(px, y, game) end)
        pcall(function() vman:SendMouseButtonEvent(px, y, 0, true, game, 1) end)
        pcall(function() vu:Button1Down(Vector2.new(px, y)) end)
        
        firesig(slider, "InputBegan", Enum.UserInputType.MouseButton1, Enum.UserInputState.Begin, px, y)
        firesig(slider, "InputBegan", Enum.UserInputType.Touch, Enum.UserInputState.Begin, px, y)
        if slider.Parent then
            firesig(slider.Parent, "InputBegan", Enum.UserInputType.MouseButton1, Enum.UserInputState.Begin, px, y)
            firesig(slider.Parent, "InputBegan", Enum.UserInputType.Touch, Enum.UserInputState.Begin, px, y)
        end
    end

    local function updateinput(px)
        pcall(function() vman:SendTouchEvent(touchId, 1, px, y) end)
        pcall(function() vman:SendMouseMoveEvent(px, y, game) end)
        pcall(function() vu:MoveMouse(Vector2.new(px, y)) end)
        
        firesig(slider, "InputChanged", Enum.UserInputType.MouseButton1, Enum.UserInputState.Change, px, y)
        firesig(slider, "InputChanged", Enum.UserInputType.Touch, Enum.UserInputState.Change, px, y)
        if slider.Parent then
            firesig(slider.Parent, "InputChanged", Enum.UserInputType.MouseButton1, Enum.UserInputState.Change, px, y)
            firesig(slider.Parent, "InputChanged", Enum.UserInputType.Touch, Enum.UserInputState.Change, px, y)
        end
    end

    local function endinput(px)
        pcall(function() vman:SendTouchEvent(touchId, 2, px, y) end)
        pcall(function() vman:SendMouseMoveEvent(px, y, game) end)
        pcall(function() vman:SendMouseButtonEvent(px, y, 0, false, game, 1) end)
        pcall(function() vu:Button1Up(Vector2.new(px, y)) end)
        
        pcall(function() vman:SendMouseMoveEvent(0, 0, game) end)
        pcall(function() vu:MoveMouse(Vector2.new(0, 0)) end)
        
        firesig(slider, "InputEnded", Enum.UserInputType.MouseButton1, Enum.UserInputState.End, px, y)
        firesig(slider, "InputEnded", Enum.UserInputType.Touch, Enum.UserInputState.End, px, y)
        if slider.Parent then
            firesig(slider.Parent, "InputEnded", Enum.UserInputType.MouseButton1, Enum.UserInputState.End, px, y)
            firesig(slider.Parent, "InputEnded", Enum.UserInputType.Touch, Enum.UserInputState.End, px, y)
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

    local step = math.max(1, math.floor(slider.AbsoluteSize.X / 60)) -- roughly 1.5% steps
    local attempts = 0
    local lastDir = 0

    while attempts < 150 do
        local currentValue = readslidernumber(label)
        if currentValue == wantnum or tostring(label.Text) == wanttxt then
            break
        end

        local direction = 1
        if currentValue ~= nil then
            direction = currentValue > wantnum and -1 or 1
        end

        if lastDir ~= 0 and direction ~= lastDir then
            step = math.max(1, math.floor(step / 2)) -- slow down if overshot
        end
        lastDir = direction

        local nextX = math.clamp(x + (step * direction), left, right)

        if nextX == x then
            if step <= 1 then break end
            step = 1
        end

        x = nextX
        pcall(function() updateinput(x) end)
        task.wait(0.04) -- Extremely fast checking

        attempts = attempts + 1
    end

    pcall(function() endinput(x) end)
    task.wait(0.08)
end

opentab("Auto", 5)

local blkrange = getcfgnum("Auto Block Range", 19)
local cntrrange = getcfgnum("Auto Counter Range", 4)
local dlyval = getcfgnum("Click Delay", 16)

fastsliderbylabel("Auto Block Range", nil, nil, blkrange)
fastsliderbylabel("Auto Counter Range", nil, nil, cntrrange)
fastsliderbylabel("Click Delay", nil, nil, dlyval)

if enablecustomconfig and parsedcfg then
    for cfgk, cfgv in pairs(parsedcfg) do
        local normk = normalizetext(cfgk)
        if type(cfgv) == "number" and not alreadyhandled[normk] then
            fastsliderbylabel(tostring(cfgk), nil, nil, cfgv)
            alreadyhandled[normk] = true
        end
    end
end
