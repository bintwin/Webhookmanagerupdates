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

-- Startup options
-- getgenv().startup_wait = 4       -- number of seconds to wait
-- getgenv().startup_wait = false   -- disables the wait
-- getgenv().show_notification = true
local startup_wait_value = env.startup_wait
if startup_wait_value == nil then
    startup_wait_value = env.wait_before_load
end
if startup_wait_value == nil then
    startup_wait_value = env.four_second_wait
end

local startup_wait = 0
if startup_wait_value == true then
    startup_wait = 4
elseif type(startup_wait_value) == "number" then
    startup_wait = math.clamp(startup_wait_value, 0, 30)
elseif type(startup_wait_value) == "string" then
    local lowered = string.lower(startup_wait_value)
    if lowered == "true" then
        startup_wait = 4
    else
        startup_wait = math.clamp(tonumber(startup_wait_value) or 0, 0, 30)
    end
end

local notification_value = env.show_notification
if notification_value == nil then
    notification_value = env.notification
end
if notification_value == nil then
    notification_value = true
end

local show_notification = notification_value == true
    or notification_value == 1
    or string.lower(tostring(notification_value)) == "true"

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
            task.wait(0.012)
            vman:SendTouchEvent(0, 2, touchX, touchY)
            worked = true
        end)
    end

    if not worked then
        pcall(function()
            vman:SendMouseMoveEvent(x, y, game)
            vman:SendMouseButtonEvent(x, y, 0, true, game, 1)
            task.wait(0.012)
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

local currenttab = nil
local textsearchcache = {}
local prefixsearchcache = {}
local tabindexes = {}
local tabscanned = {}
local globalindex = nil

-- Always scan tabs silently.
-- Hardcoded paths remain fallbacks when text search cannot find a control.
local silent_tab_scan = true
local exhaustive_tab_scan = false

local directsignalsavailable = type(getconnections) == "function"
    or type(firesignal) == "function"

local function getsearchcachekey(wanted)
    return tostring(currenttab or "__visible") .. "|" .. normalizetext(wanted)
end

local function addtabindexentry(index, textvalue, control, score)
    if not control or not control.Parent then return end

    local normalized = normalizetext(textvalue)
    if normalized == "" then return end

    local function addkey(key)
        local oldentry = index.exact[key]
        if not oldentry or score > oldentry.score then
            index.exact[key] = {
                object = control,
                score = score,
                text = normalized
            }
        end
    end

    addkey(normalized)
    addkey(striponly(normalized))

    table.insert(index.entries, {
        object = control,
        score = score,
        text = normalized
    })
end

local function nearestguibutton(obj)
    local current = obj and obj.Parent
    local depth = 0

    while current and current ~= game and depth < 8 do
        if current:IsA("GuiButton") then
            return current
        end
        current = current.Parent
        depth = depth + 1
    end

    return nil
end

local function buildglobalindex()
    if globalindex then return end

    local index = {
        exact = {},
        entries = {}
    }

    local descendants = guis:GetDescendants()

    for position, obj in ipairs(descendants) do
        if obj:IsA("GuiButton") then
            local visibleBonus = isguivisible(obj) and 180 or 0

            if obj:IsA("TextButton") then
                addtabindexentry(index, obj.Text, obj, 1200 + visibleBonus)
            end

            addtabindexentry(index, obj.Name, obj, 650 + visibleBonus)
        elseif obj:IsA("TextLabel") or obj:IsA("TextBox") then
            local button = nearestguibutton(obj)
            if button then
                local visibleBonus = isguivisible(button) and 180 or 0
                addtabindexentry(index, obj.Text, button, 1050 + visibleBonus)
            end
        end

        if touchmode and position % 160 == 0 then
            task.wait()
        end
    end

    globalindex = index
end

local function findglobalexact(wanted)
    buildglobalindex()
    if not globalindex then return nil end

    local normalized = normalizetext(wanted)
    local entry = globalindex.exact[normalized] or globalindex.exact[striponly(normalized)]

    if entry and entry.object and entry.object.Parent then
        return entry.object
    end

    return nil
end

local function findglobalprefix(wanted)
    buildglobalindex()
    if not globalindex then return nil end

    local best = nil
    local bestscore = -math.huge

    for _, entry in pairs(globalindex.entries) do
        if entry.object and entry.object.Parent and textstartswith(entry.text, wanted) then
            if entry.score > bestscore then
                best = entry.object
                bestscore = entry.score
            end
        end
    end

    return best
end

local function buildtabindex(tabname)
    if not tabname or tabscanned[tabname] then return end

    local index = {
        exact = {},
        entries = {}
    }

    local descendants = guis:GetDescendants()

    for position, obj in ipairs(descendants) do
        if obj:IsA("GuiButton") and isguivisible(obj) then
            if obj:IsA("TextButton") then
                addtabindexentry(index, obj.Text, obj, 1200)
            end

            addtabindexentry(index, obj.Name, obj, 700)
        elseif (obj:IsA("TextLabel") or obj:IsA("TextBox")) and isguivisible(obj) then
            local button = nearestguibutton(obj)
            if button and isguivisible(button) then
                addtabindexentry(index, obj.Text, button, 1050)
            end
        end

        if touchmode and position % 160 == 0 then
            task.wait()
        end
    end

    tabindexes[tabname] = index
    tabscanned[tabname] = true
end

local function findindexedexact(tabname, wanted)
    local index = tabindexes[tabname]
    if not index then return nil end

    local normalized = normalizetext(wanted)
    local entry = index.exact[normalized] or index.exact[striponly(normalized)]
    if entry and entry.object and entry.object.Parent then
        return entry.object
    end

    return nil
end

local function findindexedprefix(tabname, wanted)
    local index = tabindexes[tabname]
    if not index then return nil end

    local best = nil
    local bestscore = -math.huge

    for _, entry in pairs(index.entries) do
        if entry.object and entry.object.Parent and textstartswith(entry.text, wanted) and entry.score > bestscore then
            best = entry.object
            bestscore = entry.score
        end
    end

    return best
end

local function findcontrolbytext(wanted)
    local cachekey = getsearchcachekey(wanted)
    local cached = textsearchcache[cachekey]
    if cached and cached.Parent then return cached end

    if currenttab then
        buildtabindex(currenttab)
        local indexed = findindexedexact(currenttab, wanted)
        if indexed then
            textsearchcache[cachekey] = indexed
            return indexed
        end
    end

    local globalmatch = findglobalexact(wanted)
    if globalmatch then
        textsearchcache[cachekey] = globalmatch
        return globalmatch
    end

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
        textsearchcache[cachekey] = bestButton
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
        textsearchcache[cachekey] = bestRowButton
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
    local cachekey = getsearchcachekey(wanted)
    local cached = prefixsearchcache[cachekey]
    if cached and cached.Parent then return cached end

    if currenttab then
        buildtabindex(currenttab)
        local indexed = findindexedprefix(currenttab, wanted)
        if indexed then
            prefixsearchcache[cachekey] = indexed
            return indexed
        end
    end

    local globalmatch = findglobalprefix(wanted)
    if globalmatch then
        prefixsearchcache[cachekey] = globalmatch
        return globalmatch
    end

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

    if bestButton then
        prefixsearchcache[cachekey] = bestButton
        return bestButton
    end

    for _, label in pairs(labels) do
        local button = getrowbuttonfromlabel(label)
        if button then
            prefixsearchcache[cachekey] = button
            return button
        end
    end

    return nil
end

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
    if currenttab == tname then
        buildtabindex(tname)
        return true
    end

    local worked = false
    local tabbutton = findtabbutton(tname)
    local rootframe = nil
    local oldrootvisible = nil

    -- Hide the menu for the tiny amount of time a required tab is opened.
    -- This prevents visible tab flashing while still allowing signal clicks.
    if silent_tab_scan and directsignalsavailable then
        pcall(function()
            rootframe = guis.ScreenGui.Frame
            if rootframe and rootframe:IsA("GuiObject") then
                oldrootvisible = rootframe.Visible
                rootframe.Visible = false
            end
        end)
    end

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
        globalindex = nil
        textsearchcache = {}
        prefixsearchcache = {}
        task.wait(silent_tab_scan and 0.025 or 0.07)
    end

    if rootframe and oldrootvisible ~= nil then
        pcall(function()
            rootframe.Visible = oldrootvisible
        end)
    end

    if worked then
        buildtabindex(tname)
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

    -- Hidden buttons can be activated silently when signal helpers exist.
    if found and (isguivisible(found) or directsignalsavailable) then
        return found
    end

    local tried = {}
    local hints = preferredtabs or gettabhints(wanted)

    local function trytab(tabname)
        if not tabname or tried[tabname] then return nil end
        tried[tabname] = true

        if currenttab ~= tabname then
            opentab(tabname, tabfallbacks[tabname])
        else
            buildtabindex(tabname)
        end

        return findindexedexact(tabname, wanted)
            or findglobalexact(wanted)
            or findcontrolbytext(wanted)
    end

    -- Only open likely tabs when the control was not already loaded.
    for _, tabname in pairs(hints) do
        found = trytab(tabname)
        if found then return found end
    end

    -- Full visible scanning is optional because it causes the tab flicker.
    if exhaustive_tab_scan or not silent_tab_scan then
        for _, tabname in pairs(alltabs) do
            found = trytab(tabname)
            if found then return found end
        end
    end

    return withfallback(nil, fbackfunc)
end

local function findprefixalltabs(wanted, fbackfunc, preferredtabs)
    local found = findcontrolbyprefix(wanted)

    if found and (isguivisible(found) or directsignalsavailable) then
        return found
    end

    local tried = {}
    local hints = preferredtabs or gettabhints(wanted)

    local function trytab(tabname)
        if not tabname or tried[tabname] then return nil end
        tried[tabname] = true

        if currenttab ~= tabname then
            opentab(tabname, tabfallbacks[tabname])
        else
            buildtabindex(tabname)
        end

        return findindexedprefix(tabname, wanted)
            or findglobalprefix(wanted)
            or findcontrolbyprefix(wanted)
    end

    for _, tabname in pairs(hints) do
        found = trytab(tabname)
        if found then return found end
    end

    if exhaustive_tab_scan or not silent_tab_scan then
        for _, tabname in pairs(alltabs) do
            found = trytab(tabname)
            if found then return found end
        end
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
while not guiready and attempts < 100 do
    pcall(function()
        if guis.ScreenGui.Frame.Frame.ScrollingFrame then
            guiready = true
        end
    end)
    if guiready then break end
    attempts = attempts + 1
    task.wait(0.012)
end

if not guiready then return end

if startup_wait > 0 then
    task.wait(startup_wait)
end

if show_notification then
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Config Loader",
            Text = premium_mode and "Premium paths selected" or "Free paths selected",
            Duration = 4
        })
    end)
end

if chkdo("Lock On") then
    local lockbtn = getbtnany("Lock On", function()
        return getlblparent("Lock On", function() return guis.ScreenGui.Frame.Frame.ScrollingFrame:GetChildren()[14] end, {"Target", "Main", "Combat"})
    end, {"Target", "Main", "Combat"})
    if lockbtn then
        clickybtn(lockbtn)
        task.wait(0.012)
    end
    local b1 = findprefixalltabs("Lock On Keybind", function() return guis.ScreenGui.Frame.Frame.ScrollingFrame:GetChildren()[15] end, {"Target", "Main", "Combat"})
    clickybtn(b1)
    task.wait(0.012)
    local keytohit = Enum.KeyCode.C
    if enablecustomconfig and parsedcfg and parsedcfg["Lock On Keybind"] then
        pcall(function()
            keytohit = Enum.KeyCode[tostring(parsedcfg["Lock On Keybind"])]
        end)
    end
    vman:SendKeyEvent(true, keytohit, false, game)
    task.wait(0.008)
    vman:SendKeyEvent(false, keytohit, false, game)
    task.wait(0.012)
end

if chklockmethod("Character") then
    local charbtn = getbtnany("Character", function()
        for _, ch in pairs(guis.ScreenGui.Frame.Frame.ScrollingFrame:GetChildren()[13].Frame.ScrollingFrame:GetChildren()) do
            if ch:IsA("TextButton") and (ch.Name == "Character" or ch.Text == "Character") then return ch end
        end
        return guis.ScreenGui.Frame.Frame.ScrollingFrame:GetChildren()[13].Frame.ScrollingFrame:GetChildren()[3]
    end)
    clickybtn(charbtn)
    task.wait(0.03)
end

if not chklockmethod("Camera") then
    local cambtn = getbtnany("Camera", function()
        for _, ch in pairs(guis.ScreenGui.Frame.Frame.ScrollingFrame:GetChildren()[13].Frame.ScrollingFrame:GetChildren()) do
            if ch:IsA("TextButton") and (ch.Name == "Camera" or ch.Text == "Camera") then return ch end
        end
        return nil
    end)
    clickybtn(cambtn)
    task.wait(0.025)
end

if chkdo("Unlock Extra Emote slot") then
    local emotebtn = getlblparent("Unlock Extra Emote Slot", function() return guis.ScreenGui.Frame.Frame:GetChildren()[7]:GetChildren()[25] end, {"Extra"})
    if not emotebtn then
        pcall(function() emotebtn = guis.ScreenGui.Frame.Frame:GetChildren()[7]:GetChildren()[25] end)
    end
    clickybtn(emotebtn)
    task.wait(0.012)
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
    task.wait(0.008)
    local m1m = "UpperCut"
    if enablecustomconfig and parsedcfg and parsedcfg["M1 Method"] then
        m1m = tostring(parsedcfg["M1 Method"])
    end
    clickybtn(getbtnany(m1m, function() return nil end))
    task.wait(0.008)
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
        task.wait(0.012)
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
            task.wait(0.008)
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
            task.wait(0.008)
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
                task.wait(0.008)
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

local function isvalidslidertrack(track, label)
    if not track or not track:IsA("GuiObject") then return false end

    local width = track.AbsoluteSize.X
    local height = track.AbsoluteSize.Y

    if width < 55 or height < 2 or height > 36 then
        return false
    end

    if label and label:IsA("GuiObject") then
        local labelBottom = label.AbsolutePosition.Y + label.AbsoluteSize.Y
        local trackCenterY = track.AbsolutePosition.Y + (height / 2)
        local distance = trackCenterY - labelBottom

        if distance < -12 or distance > 80 then
            return false
        end
    end

    local lowerName = string.lower(track.Name)
    if string.find(lowerName, "slider", 1, true)
        or string.find(lowerName, "track", 1, true)
        or string.find(lowerName, "bar", 1, true) then
        return true
    end

    local trackLeft = track.AbsolutePosition.X
    local trackRight = trackLeft + width
    local trackCenterY = track.AbsolutePosition.Y + (height / 2)

    for _, child in pairs(track:GetDescendants()) do
        if child:IsA("GuiObject") and child.Visible then
            local childWidth = child.AbsoluteSize.X
            local childHeight = child.AbsoluteSize.Y
            local childCenterX = child.AbsolutePosition.X + (childWidth / 2)
            local childCenterY = child.AbsolutePosition.Y + (childHeight / 2)
            local childName = string.lower(child.Name)

            local inside = childCenterX >= trackLeft - 3
                and childCenterX <= trackRight + 3
                and math.abs(childCenterY - trackCenterY) <= math.max(18, height)

            if inside then
                if string.find(childName, "knob", 1, true)
                    or string.find(childName, "thumb", 1, true)
                    or string.find(childName, "handle", 1, true) then
                    return true
                end

                if not child:IsA("TextLabel")
                    and not child:IsA("TextButton")
                    and childWidth > 1
                    and childWidth < width - 1
                    and childHeight <= math.max(28, height + 10) then
                    return true
                end
            end
        end
    end

    return false
end

local function findsliderknobx(track)
    if not track or not track:IsA("GuiObject") then return nil end

    local width = track.AbsoluteSize.X
    local height = track.AbsoluteSize.Y
    local trackLeft = track.AbsolutePosition.X
    local trackRight = trackLeft + width
    local trackCenterY = track.AbsolutePosition.Y + (height / 2)
    local bestX = nil
    local bestScore = -math.huge
    local fillX = nil
    local fillScore = -math.huge

    for _, child in pairs(track:GetDescendants()) do
        if child:IsA("GuiObject") and child.Visible then
            local childWidth = child.AbsoluteSize.X
            local childHeight = child.AbsoluteSize.Y
            local childLeft = child.AbsolutePosition.X
            local childCenterX = childLeft + (childWidth / 2)
            local childCenterY = child.AbsolutePosition.Y + (childHeight / 2)
            local childName = string.lower(child.Name)

            local inside = childCenterX >= trackLeft - 4
                and childCenterX <= trackRight + 4
                and math.abs(childCenterY - trackCenterY) <= math.max(20, height)

            if inside and not child:IsA("TextLabel") and not child:IsA("TextButton") then
                local knobScore = 0

                if string.find(childName, "knob", 1, true) then knobScore = knobScore + 180 end
                if string.find(childName, "thumb", 1, true) then knobScore = knobScore + 170 end
                if string.find(childName, "handle", 1, true) then knobScore = knobScore + 150 end
                if string.find(childName, "circle", 1, true) then knobScore = knobScore + 80 end
                if child:IsA("ImageButton") or child:IsA("ImageLabel") then knobScore = knobScore + 25 end

                if childWidth >= 3 and childWidth <= 34 and childHeight >= 3 and childHeight <= 34 then
                    knobScore = knobScore + 60
                    knobScore = knobScore - math.abs(childWidth - childHeight)
                else
                    knobScore = knobScore - 80
                end

                if knobScore > bestScore then
                    bestScore = knobScore
                    bestX = childCenterX
                end

                if childLeft <= trackLeft + 8
                    and childWidth > 2
                    and childWidth < width - 2
                    and childHeight <= math.max(26, height + 8) then
                    local score = childWidth
                    if string.find(childName, "fill", 1, true) then score = score + 100 end
                    if string.find(childName, "progress", 1, true) then score = score + 80 end

                    if score > fillScore then
                        fillScore = score
                        fillX = childLeft + childWidth
                    end
                end
            end
        end
    end

    if bestX and bestScore >= 30 then
        return math.clamp(bestX, trackLeft + 2, trackRight - 2)
    end

    if fillX then
        return math.clamp(fillX, trackLeft + 2, trackRight - 2)
    end

    return nil
end

local fastslider

local function fastsliderbylabel(prefix, fallbacksliderfunc, fallbacklabelfunc, wantnum)
    if currenttab ~= "Auto" then
        opentab("Auto", 5)
    end

    local label = findsliderlabel(prefix)

    -- These sliders live on Auto. Do not scan every other tab when one is missing.
    if not label and currenttab ~= "Auto" then
        opentab("Auto", 5)
        label = findsliderlabel(prefix)
    end

    if not label then
        pcall(function()
            if fallbacklabelfunc then
                label = fallbacklabelfunc()
            end
        end)
    end

    local slider = getslidertrackfromlabel(label, nil)

    -- Text search stays first. The exact path is only used when the found object
    -- does not look like a real horizontal slider track.
    if not isvalidslidertrack(slider, label) then
        slider = nil
        pcall(function()
            if fallbacksliderfunc then
                slider = fallbacksliderfunc()
            end
        end)
    end

    if not isvalidslidertrack(slider, label) then
        return
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

    if not slider
        or not label
        or not slider:IsA("GuiObject")
        or not isvalidslidertrack(slider, label)
        or type(wantnum) ~= "number" then
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

    if scrolling then
        pcall(function()
            local targetY = slider.AbsolutePosition.Y
                - scrolling.AbsolutePosition.Y
                + scrolling.CanvasPosition.Y
                - (scrolling.AbsoluteWindowSize.Y / 2)

            local maxY = math.max(
                0,
                scrolling.AbsoluteCanvasSize.Y - scrolling.AbsoluteWindowSize.Y
            )

            scrolling.CanvasPosition = Vector2.new(
                scrolling.CanvasPosition.X,
                math.clamp(targetY, 0, maxY)
            )
        end)

        task.wait(touchmode and 0.07 or 0.035)
    end

    local currentValue = readslidernumber(label)
    if currentValue == nil or currentValue == wantnum or tostring(label.Text) == wanttxt then
        return
    end

    local left = math.floor(slider.AbsolutePosition.X + 3)
    local right = math.floor(slider.AbsolutePosition.X + slider.AbsoluteSize.X - 3)
    local y = math.floor(slider.AbsolutePosition.Y + (slider.AbsoluteSize.Y / 2))

    if right <= left then return end

    local function readwithtimeout(oldValue, timeout)
        local finishAt = os.clock() + timeout
        local value = readslidernumber(label)

        while os.clock() < finishAt do
            if value ~= nil and value ~= oldValue then
                return value
            end
            task.wait(touchmode and 0.025 or 0.012)
            value = readslidernumber(label)
        end

        return value
    end

    local touchId = 1

    local function controlleddrag(startX, endX)
        startX = math.clamp(math.floor(startX + 0.5), left, right)
        endX = math.clamp(math.floor(endX + 0.5), left, right)

        if math.abs(endX - startX) < 1 then
            return true
        end

        if touchmode then
            local startTouchX, startTouchY = gettouchcoords(slider, startX, y)
            local endTouchX, endTouchY = gettouchcoords(slider, endX, y)

            local pressed = pcall(function()
                vman:SendTouchEvent(touchId, 0, startTouchX, startTouchY)
            end)

            if not pressed then return false end

            task.wait(0.035)

            pcall(function()
                vman:SendTouchEvent(touchId, 1, endTouchX, endTouchY)
            end)

            task.wait(0.035)

            pcall(function()
                vman:SendTouchEvent(touchId, 2, endTouchX, endTouchY)
            end)

            task.wait(0.045)
            return true
        end

        local pressed = pcall(function()
            vman:SendMouseMoveEvent(startX, y, game)
            vman:SendMouseButtonEvent(startX, y, 0, true, game, 1)
        end)

        if not pressed then return false end

        task.wait(0.018)

        pcall(function()
            vman:SendMouseMoveEvent(endX, y, game)
        end)

        task.wait(0.018)

        pcall(function()
            vman:SendMouseButtonEvent(endX, y, 0, false, game, 1)
        end)

        task.wait(0.025)
        return true
    end

    local startX = findsliderknobx(slider)
    if not startX then
        -- Do not sweep the full bar when the knob cannot be found.
        -- One small probe is much safer on mobile executors.
        startX = math.floor((left + right) / 2)
    end

    local direction = wantnum > currentValue and 1 or -1
    local trackWidth = right - left
    local probeDistance = math.clamp(math.floor(trackWidth * 0.10), 7, 20)
    local probeX = math.clamp(startX + (direction * probeDistance), left, right)

    if probeX == startX then return end

    if not controlleddrag(startX, probeX) then return end

    local probeValue = readwithtimeout(currentValue, touchmode and 0.18 or 0.10)
    if probeValue == nil or probeValue == currentValue then
        return
    end

    if probeValue == wantnum or tostring(label.Text) == wanttxt then
        return
    end

    local valueDelta = probeValue - currentValue
    local pixelDelta = probeX - startX

    if valueDelta == 0 then return end

    local pixelsPerValue = pixelDelta / valueDelta
    if pixelsPerValue ~= pixelsPerValue
        or math.abs(pixelsPerValue) < 0.15
        or math.abs(pixelsPerValue) > trackWidth then
        return
    end

    local targetX = probeX + ((wantnum - probeValue) * pixelsPerValue)
    targetX = math.clamp(targetX, left, right)

    local secondStartX = findsliderknobx(slider) or probeX
    if math.abs(targetX - secondStartX) >= 1 then
        controlleddrag(secondStartX, targetX)
    end

    local finalValue = readwithtimeout(probeValue, touchmode and 0.20 or 0.11)
    if finalValue == nil or finalValue == wantnum or tostring(label.Text) == wanttxt then
        return
    end

    -- Desktop gets one tiny correction. Mobile stops here to avoid repeated
    -- touch events that can make Delta unstable or leave the slider grabbed.
    if touchmode then
        return
    end

    local secondValueDelta = finalValue - probeValue
    local secondPixelDelta = targetX - probeX

    if secondValueDelta == 0 then return end

    local correctedPixelsPerValue = secondPixelDelta / secondValueDelta
    if correctedPixelsPerValue ~= correctedPixelsPerValue
        or math.abs(correctedPixelsPerValue) < 0.15
        or math.abs(correctedPixelsPerValue) > trackWidth then
        return
    end

    local correctionX = targetX + ((wantnum - finalValue) * correctedPixelsPerValue)
    correctionX = math.clamp(correctionX, left, right)

    local correctionStartX = findsliderknobx(slider) or targetX
    if math.abs(correctionX - correctionStartX) >= 1 then
        controlleddrag(correctionStartX, correctionX)
    end
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
