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

    if tabbutton then
        clickybtn(tabbutton)
        worked = true
    end

    -- A numbered child is only allowed as a fallback when its own visible text
    -- still matches the requested tab. This prevents a changed child order from
    -- opening a random page.
    if not worked then
        local fallbackIndex = idxfallback or tabfallbacks[tname]
        if fallbackIndex then
            pcall(function()
                local fallbackButton = guis.ScreenGui.Frame.ScrollingFrame:GetChildren()[fallbackIndex]
                local matchesRequestedTab = false

                if fallbackButton then
                    if fallbackButton:IsA("TextButton") and sametext(fallbackButton.Text, tname) then
                        matchesRequestedTab = true
                    elseif objecthastext(fallbackButton, tname) then
                        matchesRequestedTab = true
                    end
                end

                if matchesRequestedTab then
                    clickybtn(fallbackButton)
                    worked = true
                end
            end)
        end
    end

    if worked then
        currenttab = tname
        globalindex = nil
        textsearchcache = {}
        prefixsearchcache = {}
        task.wait(0.03)
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
    -- Loaded hidden controls are returned immediately. Their text is already
    -- available in PlayerGui, so scanning does not need to open another tab.
    if found then
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

    -- Loaded hidden controls are returned immediately. Their text is already
    -- available in PlayerGui, so scanning does not need to open another tab.
    if found then
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
    local value = string.match(textvalue, ":%s*([-+]?%d+%.?%d*)")
        or string.match(textvalue, "[-+]?%d+%.?%d*")

    return value and tonumber(value) or nil
end

local function findsliderlabel(prefix, fallbackfunc)
    local wanted = normalizetext(prefix)
    local best = nil
    local bestScore = -math.huge

    -- Search every loaded page, including hidden page children. Do not open or
    -- switch tabs just to locate a slider label.
    for _, obj in pairs(guis:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            local textvalue = normalizetext(obj.Text)
            local matches = textvalue == wanted
                or string.sub(textvalue, 1, #wanted + 1) == wanted .. ":"
                or string.sub(textvalue, 1, #wanted + 1) == wanted .. " "

            if matches and readslidernumber(obj) ~= nil then
                local score = 0

                if textvalue == wanted then score = score + 80 end
                if string.sub(textvalue, 1, #wanted + 1) == wanted .. ":" then
                    score = score + 160
                end
                if obj:IsA("TextLabel") then score = score + 30 end
                if obj.Parent and obj.Parent:IsA("Frame") then score = score + 30 end
                if isguivisible(obj) then score = score + 15 end

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

    -- Old exact path is fallback only.
    local fallback = nil
    pcall(function()
        if fallbackfunc then
            fallback = fallbackfunc()
        end
    end)

    if fallback
        and (fallback:IsA("TextLabel") or fallback:IsA("TextButton"))
        and readslidernumber(fallback) ~= nil then
        return fallback
    end

    return nil
end

local function getsafeobject(fallbackfunc)
    local object = nil

    pcall(function()
        if fallbackfunc then
            object = fallbackfunc()
        end
    end)

    if object and object:IsA("GuiObject") and object.Parent then
        return object
    end

    return nil
end

local function getcommonancestor(first, second)
    if not first or not second then return nil end

    local seen = {}
    local current = first

    while current and current ~= game do
        seen[current] = true
        current = current.Parent
    end

    current = second
    while current and current ~= game do
        if seen[current] then
            return current
        end
        current = current.Parent
    end

    return nil
end

local function hasnametoken(object, token)
    return string.find(string.lower(tostring(object.Name)), token, 1, true) ~= nil
end

local function istrackshape(object)
    if not object or not object:IsA("GuiObject") then return false end
    if object:IsA("TextLabel") or object:IsA("TextBox") or object:IsA("ScrollingFrame") then
        return false
    end

    local width = object.AbsoluteSize.X
    local height = object.AbsoluteSize.Y

    return width >= 35
        and height >= 2
        and height <= 30
        and width >= height * 3
end

local function findslidertrack(root, label)
    if not root or not label then return nil end

    local labelBottom = label.AbsolutePosition.Y + label.AbsoluteSize.Y
    local maxBelow = math.max(70, label.AbsoluteSize.Y * 5)
    local best = nil
    local bestScore = -math.huge
    local checked = {}

    local scopes = {
        root,
        root.Parent,
        label.Parent,
        label.Parent and label.Parent.Parent,
        getcommonancestor(root, label)
    }

    local function hasvisibletext(object)
        if object:IsA("TextButton") and normalizetext(object.Text) ~= "" then
            return true
        end

        for _, child in pairs(object:GetDescendants()) do
            if (child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox"))
                and normalizetext(child.Text) ~= "" then
                return true
            end
        end

        return false
    end

    local function check(object)
        if checked[object] or not object:IsA("GuiObject") then return end
        checked[object] = true

        if object:IsA("TextLabel") or object:IsA("TextBox") or object:IsA("ScrollingFrame") then
            return
        end

        local width = object.AbsoluteSize.X
        local height = object.AbsoluteSize.Y
        if width < 45 or height < 2 or height > 24 or width < height * 4 then
            return
        end

        local centerY = object.AbsolutePosition.Y + height / 2
        local belowDistance = centerY - labelBottom

        -- A slider track must be on the same row and below its value label.
        -- This blocks the toggle or button above the slider from being selected.
        if belowDistance < -3 or belowDistance > maxBelow then
            return
        end

        local score = width * 0.9 - belowDistance * 3

        if object == root then score = score + 110 end
        if root:IsDescendantOf(object) then score = score + 170 end
        if object:IsDescendantOf(root) then score = score + 130 end
        if object.Parent == root.Parent then score = score + 45 end

        if hasnametoken(object, "slider") then score = score + 220 end
        if hasnametoken(object, "track") then score = score + 190 end
        if hasnametoken(object, "bar") then score = score + 90 end
        if hasnametoken(object, "fill") or hasnametoken(object, "progress") then
            score = score - 170
        end

        if height <= 12 then score = score + 70 end
        if hasvisibletext(object) then score = score - 500 end

        if score > bestScore then
            best = object
            bestScore = score
        end
    end

    for _, scope in pairs(scopes) do
        if scope and scope ~= game then
            if scope:IsA("GuiObject") then
                check(scope)
            end

            for _, object in pairs(scope:GetDescendants()) do
                check(object)
            end
        end
    end

    return best
end

local function findsliderknob(track, root)
    if not track then return nil end

    local trackLeft = track.AbsolutePosition.X
    local trackRight = trackLeft + track.AbsoluteSize.X
    local trackCenterY = track.AbsolutePosition.Y + (track.AbsoluteSize.Y / 2)
    local scope = root or track
    local best = nil
    local bestScore = -math.huge

    local objects = {}
    for _, object in pairs(track:GetDescendants()) do
        table.insert(objects, object)
    end
    if scope ~= track then
        for _, object in pairs(scope:GetDescendants()) do
            table.insert(objects, object)
        end
    end

    local checked = {}
    for _, object in pairs(objects) do
        if not checked[object] and object:IsA("GuiObject") then
            checked[object] = true

            local width = object.AbsoluteSize.X
            local height = object.AbsoluteSize.Y
            local centerX = object.AbsolutePosition.X + (width / 2)
            local centerY = object.AbsolutePosition.Y + (height / 2)

            if width >= 5 and width <= 34
                and height >= 5 and height <= 34
                and centerX >= trackLeft - 8
                and centerX <= trackRight + 8
                and math.abs(centerY - trackCenterY) <= 18 then

                local score = 0
                if hasnametoken(object, "knob") then score = score + 180 end
                if hasnametoken(object, "thumb") then score = score + 180 end
                if hasnametoken(object, "handle") then score = score + 120 end
                if hasnametoken(object, "circle") then score = score + 80 end
                if object:IsA("ImageButton") then score = score + 40 end
                if object:IsA("ImageLabel") then score = score + 20 end
                score = score - math.abs(width - height) * 2
                score = score - math.abs(centerY - trackCenterY) * 3

                if score > bestScore then
                    best = object
                    bestScore = score
                end
            end
        end
    end

    if bestScore < -20 then
        return nil
    end

    return best
end

local function readnumericmetadata(objects, names)
    for _, object in pairs(objects) do
        if object then
            for _, name in pairs(names) do
                local value = nil

                pcall(function()
                    value = object:GetAttribute(name)
                end)

                if type(value) == "number" then
                    return value
                end

                local child = object:FindFirstChild(name, true)
                if child and (child:IsA("NumberValue") or child:IsA("IntValue")) then
                    return child.Value
                end
            end
        end
    end

    return nil
end

local function getsliderrange(prefix, root, track)
    local objects = {track, root}
    local current = root and root.Parent
    local depth = 0

    while current and current ~= game and depth < 4 do
        table.insert(objects, current)
        current = current.Parent
        depth = depth + 1
    end

    local minimum = readnumericmetadata(objects, {
        "Min", "Minimum", "MinValue", "MinimumValue", "LowerBound"
    })
    local maximum = readnumericmetadata(objects, {
        "Max", "Maximum", "MaxValue", "MaximumValue", "UpperBound"
    })

    if type(minimum) == "number" and type(maximum) == "number" and maximum > minimum then
        return minimum, maximum
    end

    local fallbacks = {
        ["Auto Block Range"] = {0, 20},
        ["Auto Counter Range"] = {0, 20},
        ["Click Delay"] = {0, 20}
    }

    local fallback = fallbacks[prefix]
    if fallback then
        return fallback[1], fallback[2]
    end

    return 0, 20
end

local function findscrollingancestor(object)
    local current = object and object.Parent

    while current and current ~= game do
        if current:IsA("ScrollingFrame") then
            return current
        end
        current = current.Parent
    end

    return nil
end

local function isinsideviewport(object, scrolling)
    if not object or not scrolling then return true end

    local objectTop = object.AbsolutePosition.Y
    local objectBottom = objectTop + object.AbsoluteSize.Y
    local windowTop = scrolling.AbsolutePosition.Y
    local windowBottom = windowTop + scrolling.AbsoluteWindowSize.Y

    return objectBottom >= windowTop + 3 and objectTop <= windowBottom - 3
end

local function bringintoviewtemporarily(object)
    local scrolling = findscrollingancestor(object)
    if not scrolling or isinsideviewport(object, scrolling) then
        return nil, nil
    end

    local oldPosition = scrolling.CanvasPosition

    pcall(function()
        local targetY = object.AbsolutePosition.Y
            - scrolling.AbsolutePosition.Y
            + scrolling.CanvasPosition.Y
            - (scrolling.AbsoluteWindowSize.Y / 2)

        local maxY = math.max(
            0,
            scrolling.AbsoluteCanvasSize.Y - scrolling.AbsoluteWindowSize.Y
        )

        scrolling.CanvasPosition = Vector2.new(
            oldPosition.X,
            math.clamp(targetY, 0, maxY)
        )
    end)

    task.wait(touchmode and 0.055 or 0.03)
    return scrolling, oldPosition
end

local function restorescroll(scrolling, oldPosition)
    if not scrolling or not oldPosition then return end

    pcall(function()
        scrolling.CanvasPosition = oldPosition
    end)
end

local function waitforvaluechange(label, oldValue, timeout)
    local deadline = os.clock() + timeout
    local newest = oldValue

    while os.clock() < deadline do
        task.wait(touchmode and 0.018 or 0.01)
        local value = readslidernumber(label)

        if value ~= nil then
            newest = value
            if oldValue == nil or value ~= oldValue then
                task.wait(touchmode and 0.025 or 0.015)
                return readslidernumber(label) or value
            end
        end
    end

    return newest
end

local function releasemouse(x, y)
    pcall(function()
        if type(mouse1release) == "function" then
            mouse1release()
        end
    end)

    pcall(function()
        vman:SendMouseButtonEvent(x, y, 0, false, game, 1)
    end)
end

local function dragslideronce(guiObject, startX, startY, finishX, finishY)
    if not guiObject then return false end

    startX = math.floor(startX + 0.5)
    startY = math.floor(startY + 0.5)
    finishX = math.floor(finishX + 0.5)
    finishY = math.floor(finishY + 0.5)

    if touchmode then
        local touchStartX, touchStartY = gettouchcoords(guiObject, startX, startY)
        local touchFinishX, touchFinishY = gettouchcoords(guiObject, finishX, finishY)
        local begun = false

        local ok = pcall(function()
            vman:SendTouchEvent(0, 0, touchStartX, touchStartY)
            begun = true
            task.wait(0.025)
            vman:SendTouchEvent(0, 1, touchFinishX, touchFinishY)
            task.wait(0.025)
            vman:SendTouchEvent(0, 2, touchFinishX, touchFinishY)
            begun = false
        end)

        if begun then
            pcall(function()
                vman:SendTouchEvent(0, 2, touchFinishX, touchFinishY)
            end)
        end

        return ok
    end

    if type(mousemoveabs) == "function"
        and type(mouse1press) == "function"
        and type(mouse1release) == "function" then

        local pressed = false
        local ok = pcall(function()
            mousemoveabs(startX, startY)
            task.wait(0.015)
            mouse1press()
            pressed = true
            task.wait(0.02)
            mousemoveabs(finishX, finishY)
            task.wait(0.025)
            mouse1release()
            pressed = false
        end)

        if pressed then
            pcall(mouse1release)
        end

        return ok
    end

    local pressed = false
    local ok = pcall(function()
        vman:SendMouseMoveEvent(startX, startY, game)
        vman:SendMouseButtonEvent(startX, startY, 0, true, game, 1)
        pressed = true
        task.wait(0.02)
        vman:SendMouseMoveEvent(finishX, finishY, game)
        task.wait(0.025)
        vman:SendMouseButtonEvent(finishX, finishY, 0, false, game, 1)
        pressed = false
    end)

    if pressed then
        releasemouse(finishX, finishY)
    end

    return ok
end


-- Auto Block Range uses the row that owns the matching TextLabel.
-- row.TextLabel is the value text and row.Frame is the slider bar.
local function setautoblockrange(rootfunc, labelfunc, wanted)
    if type(wanted) ~= "number" then return false end
    wanted = math.floor(wanted + 0.5)

    local LABEL_PREFIX = "auto block range:"

    local function labelmatches(label)
        if not label or not label:IsA("TextLabel") then return false end
        local textvalue = normalizetext(label.Text)
        return string.sub(textvalue, 1, #LABEL_PREFIX) == LABEL_PREFIX
    end

    local function validrow(label)
        if not labelmatches(label) then return nil, nil end

        local row = label.Parent
        if not row or not row:IsA("Frame") then return nil, nil end
        if row:FindFirstChild("TextLabel") ~= label then return nil, nil end

        local bar = row:FindFirstChild("Frame")
        if not bar or not bar:IsA("Frame") or bar.Parent ~= row then
            return nil, nil
        end

        if bar.AbsoluteSize.X < 35 or bar.AbsoluteSize.Y < 2 then
            return nil, nil
        end

        return row, bar
    end

    local function findrow()
        local root = guis
        pcall(function()
            root = guis.ScreenGui.Frame.Frame
        end)

        local visibleMatch = nil
        local hiddenMatch = nil

        for _, object in ipairs(root:GetDescendants()) do
            if object:IsA("TextLabel") and labelmatches(object) then
                local row, bar = validrow(object)
                if row and bar then
                    if isguivisible(object) and isguivisible(bar) then
                        visibleMatch = {object, row, bar}
                        break
                    elseif not hiddenMatch then
                        hiddenMatch = {object, row, bar}
                    end
                end
            end
        end

        local found = visibleMatch or hiddenMatch
        if found then
            return found[1], found[2], found[3]
        end

        local fallbackLabel = nil
        local fallbackBar = nil

        pcall(function()
            if labelfunc then fallbackLabel = labelfunc() end
        end)
        pcall(function()
            if rootfunc then fallbackBar = rootfunc() end
        end)

        local row, exactBar = validrow(fallbackLabel)
        if row and exactBar then
            if fallbackBar == exactBar then
                return fallbackLabel, row, exactBar
            end
            return fallbackLabel, row, exactBar
        end

        return nil, nil, nil
    end

    local function findfillend(bar)
        local barLeft = bar.AbsolutePosition.X
        local barRight = barLeft + bar.AbsoluteSize.X
        local barTop = bar.AbsolutePosition.Y
        local barBottom = barTop + bar.AbsoluteSize.Y
        local best = nil
        local bestScore = -math.huge

        local function check(object, depthBonus)
            if not object:IsA("GuiObject") then return end
            if object == bar then return end
            if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then return end

            local left = object.AbsolutePosition.X
            local right = left + object.AbsoluteSize.X
            local top = object.AbsolutePosition.Y
            local bottom = top + object.AbsoluteSize.Y
            local height = object.AbsoluteSize.Y
            local width = object.AbsoluteSize.X

            if width < 1 or height < 1 then return end
            if left < barLeft - 3 or right > barRight + 3 then return end
            if top < barTop - 4 or bottom > barBottom + 4 then return end

            local score = depthBonus
            if object.Parent == bar then score = score + 200 end
            if object:IsA("Frame") then score = score + 80 end
            if math.abs(left - barLeft) <= 5 then score = score + 160 end
            score = score + math.min(width, bar.AbsoluteSize.X)
            score = score - math.abs(height - bar.AbsoluteSize.Y) * 3

            if score > bestScore then
                best = object
                bestScore = score
            end
        end

        for _, child in ipairs(bar:GetChildren()) do
            check(child, 100)
        end
        for _, object in ipairs(bar:GetDescendants()) do
            check(object, 0)
        end

        if best then
            return math.clamp(best.AbsolutePosition.X + best.AbsoluteSize.X, barLeft, barRight)
        end

        local knob = findsliderknob(bar, bar.Parent)
        if knob then
            return math.clamp(knob.AbsolutePosition.X + knob.AbsoluteSize.X / 2, barLeft, barRight)
        end

        return nil
    end

    local label, row, bar = findrow()

    if not label or not row or not bar or not isguivisible(label) or not isguivisible(bar) then
        opentab("Auto", 5)
        task.wait(touchmode and 0.08 or 0.04)
        label, row, bar = findrow()
    end

    if not label or not row or not bar then return false end
    if not isguivisible(label) or not isguivisible(bar) then return false end

    local currentValue = readslidernumber(label)
    if currentValue == wanted then return true end
    if currentValue == nil then return false end

    local scrolling, oldCanvasPosition = bringintoviewtemporarily(bar)
    task.wait(touchmode and 0.05 or 0.025)

    local left = bar.AbsolutePosition.X + 2
    local right = bar.AbsolutePosition.X + bar.AbsoluteSize.X - 2
    local y = bar.AbsolutePosition.Y + bar.AbsoluteSize.Y / 2

    if right - left < 20 then
        restorescroll(scrolling, oldCanvasPosition)
        return false
    end

    local function releaseinput(x, yPosition)
        local releaseX = math.floor(x + 0.5)
        local releaseY = math.floor(yPosition + 0.5)

        pcall(function()
            local touchX, touchY = gettouchcoords(bar, releaseX, releaseY)
            vman:SendTouchEvent(0, 2, touchX, touchY)
        end)

        pcall(function()
            vman:SendMouseButtonEvent(releaseX, releaseY, 0, false, game, 1)
        end)

        if type(mouse1release) == "function" then
            pcall(mouse1release)
        end
    end

    local function dragto(startX, finishX, previousValue)
        startX = math.clamp(startX, left, right)
        finishX = math.clamp(finishX, left, right)

        local sx = math.floor(startX + 0.5)
        local fx = math.floor(finishX + 0.5)
        local py = math.floor(y + 0.5)
        local held = false

        local ok = pcall(function()
            if touchmode then
                local touchSX, touchSY = gettouchcoords(bar, sx, py)
                local touchFX, touchFY = gettouchcoords(bar, fx, py)

                vman:SendTouchEvent(0, 0, touchSX, touchSY)
                held = true
                task.wait(0.035)
                vman:SendTouchEvent(0, 1, touchFX, touchFY)
                task.wait(0.045)
                vman:SendTouchEvent(0, 2, touchFX, touchFY)
                held = false
            elseif type(mousemoveabs) == "function"
                and type(mouse1press) == "function"
                and type(mouse1release) == "function" then

                mousemoveabs(sx, py)
                task.wait(0.015)
                mouse1press()
                held = true
                task.wait(0.025)
                mousemoveabs(fx, py)
                task.wait(0.04)
                mouse1release()
                held = false
            else
                vman:SendMouseMoveEvent(sx, py, game)
                vman:SendMouseButtonEvent(sx, py, 0, true, game, 1)
                held = true
                task.wait(0.025)
                vman:SendMouseMoveEvent(fx, py, game)
                task.wait(0.04)
                vman:SendMouseButtonEvent(fx, py, 0, false, game, 1)
                held = false
            end
        end)

        if held then releaseinput(fx, py) end
        if not ok then return nil end

        return waitforvaluechange(label, previousValue, touchmode and 0.22 or 0.14)
            or readslidernumber(label)
    end

    local startX = findfillend(bar)
    if not startX then
        restorescroll(scrolling, oldCanvasPosition)
        return false
    end

    local originalValue = currentValue
    local originalX = startX
    local edgeX = wanted > currentValue and right or left
    local edgeValue = dragto(startX, edgeX, currentValue)

    if edgeValue == wanted then
        releaseinput(edgeX, y)
        restorescroll(scrolling, oldCanvasPosition)
        return true
    end

    if edgeValue == nil or edgeValue == originalValue then
        releaseinput(edgeX, y)
        restorescroll(scrolling, oldCanvasPosition)
        return false
    end

    local pixelsPerValue = (edgeX - originalX) / (edgeValue - originalValue)
    if pixelsPerValue ~= pixelsPerValue or math.abs(pixelsPerValue) < 0.05 then
        releaseinput(edgeX, y)
        restorescroll(scrolling, oldCanvasPosition)
        return false
    end

    local targetX = math.clamp(originalX + (wanted - originalValue) * pixelsPerValue, left, right)
    local liveStartX = findfillend(bar) or edgeX
    local reachedValue = dragto(liveStartX, targetX, edgeValue)

    if reachedValue and reachedValue ~= wanted then
        local correctionX = math.clamp(targetX + (wanted - reachedValue) * pixelsPerValue, left, right)
        local correctionStart = findfillend(bar) or targetX

        if math.abs(correctionX - correctionStart) >= 1 then
            reachedValue = dragto(correctionStart, correctionX, reachedValue)
            targetX = correctionX
        end
    end

    releaseinput(targetX, y)
    restorescroll(scrolling, oldCanvasPosition)

    return readslidernumber(label) == wanted
end

local function setsliderdirect(prefix, rootfunc, labelfunc, wanted)
    if type(wanted) ~= "number" then return end

    local suppliedRoot = getsafeobject(rootfunc)
    local label = findsliderlabel(prefix, labelfunc)

    if not suppliedRoot or not label then
        return
    end

    -- The supplied path identifies the correct slider row.
    -- Only search inside that row for the real horizontal track.
    local track = findslidertrack(suppliedRoot, label)
    if not track then
        return
    end

    local scrolling, oldCanvasPosition = bringintoviewtemporarily(track)

    local ok = pcall(function()
        local currentValue = readslidernumber(label)
        if currentValue == wanted then
            return
        end

        local left = track.AbsolutePosition.X + 3
        local right = track.AbsolutePosition.X + track.AbsoluteSize.X - 3
        local y = track.AbsolutePosition.Y + track.AbsoluteSize.Y / 2

        if right - left < 20 then
            return
        end

        local lowX = left
        local highX = right
        local currentX = nil
        local knob = findsliderknob(track, track.Parent)

        if knob then
            currentX = knob.AbsolutePosition.X + knob.AbsoluteSize.X / 2
        end

        currentX = math.clamp(currentX or ((left + right) / 2), left, right)

        local bestValue = currentValue
        local bestX = currentX
        local bestDistance = currentValue ~= nil and math.abs(currentValue - wanted) or math.huge
        local increasingRight = nil
        local unchangedCount = 0

        -- Coordinate binary search does not need guessed minimum or maximum values.
        -- It reads the real number after every controlled move.
        for attempt = 1, 7 do
            if currentValue == wanted or highX - lowX < 0.75 then
                break
            end

            local targetX = (lowX + highX) / 2

            if math.abs(targetX - currentX) < 2 then
                local nudge = math.max(3, (right - left) * 0.08)
                if currentValue == nil or wanted > currentValue then
                    targetX = math.min(right, targetX + nudge)
                else
                    targetX = math.max(left, targetX - nudge)
                end
            end

            local previousX = currentX
            local previousValue = currentValue
            local liveKnob = findsliderknob(track, track.Parent)
            local startX = liveKnob
                and (liveKnob.AbsolutePosition.X + liveKnob.AbsoluteSize.X / 2)
                or currentX

            if not dragslideronce(track, startX, y, targetX, y) then
                break
            end

            local newValue = waitforvaluechange(
                label,
                previousValue,
                touchmode and 0.14 or 0.09
            )

            if newValue == nil then
                break
            end

            currentX = targetX
            currentValue = newValue

            local distance = math.abs(newValue - wanted)
            if distance < bestDistance then
                bestDistance = distance
                bestValue = newValue
                bestX = targetX
            end

            if newValue == wanted then
                break
            end

            if previousValue ~= nil and newValue ~= previousValue and math.abs(targetX - previousX) >= 1 then
                increasingRight = ((targetX - previousX) * (newValue - previousValue)) > 0
                unchangedCount = 0
            else
                unchangedCount = unchangedCount + 1
            end

            local movesRightToIncrease = increasingRight ~= false

            if newValue < wanted then
                if movesRightToIncrease then
                    lowX = math.max(lowX, targetX + 0.5)
                else
                    highX = math.min(highX, targetX - 0.5)
                end
            else
                if movesRightToIncrease then
                    highX = math.min(highX, targetX - 0.5)
                else
                    lowX = math.max(lowX, targetX + 0.5)
                end
            end

            -- Stop instead of fighting one rounded value forever.
            if unchangedCount >= 2 then
                break
            end
        end

        -- Put it back on the closest confirmed coordinate only when the last
        -- move was worse. This is one final move at most.
        if bestX and currentValue ~= wanted and bestValue ~= currentValue
            and math.abs(bestX - currentX) >= 1 then
            local liveKnob = findsliderknob(track, track.Parent)
            local startX = liveKnob
                and (liveKnob.AbsolutePosition.X + liveKnob.AbsoluteSize.X / 2)
                or currentX

            dragslideronce(track, startX, y, bestX, y)
            task.wait(touchmode and 0.035 or 0.02)
        end
    end)

    restorescroll(scrolling, oldCanvasPosition)

    if not ok then
        releasemouse(0, 0)
    end
end

local blkrange = getcfgnum("Auto Block Range", 19)
local cntrrange = getcfgnum("Auto Counter Range", 4)
local dlyval = getcfgnum("Click Delay", 16)

-- The three sliders live on the Auto page in both free and premium modes.
opentab("Auto", 5)
task.wait(touchmode and 0.08 or 0.04)

if premium_mode then
    setautoblockrange(
        function() return guis.ScreenGui.Frame.Frame:GetChildren()[4].Frame.Frame end,
        function() return guis.ScreenGui.Frame.Frame:GetChildren()[4].Frame.TextLabel end,
        blkrange
    )

    setsliderdirect(
        "Auto Counter Range",
        function() return guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[10].Frame end,
        function() return guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[10].TextLabel end,
        cntrrange
    )

    setsliderdirect(
        "Click Delay",
        function() return guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[19].Frame end,
        function() return guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[19].TextLabel end,
        dlyval
    )
else
    setautoblockrange(
        function() return guis.ScreenGui.Frame.Frame:GetChildren()[4].Frame.Frame end,
        function() return guis.ScreenGui.Frame.Frame:GetChildren()[4].Frame.TextLabel end,
        blkrange
    )

    setsliderdirect(
        "Auto Counter Range",
        function() return guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[10].Frame end,
        function() return guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[10].TextLabel end,
        cntrrange
    )

    setsliderdirect(
        "Click Delay",
        function() return guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[15].Frame end,
        function() return guis.ScreenGui.Frame.Frame:GetChildren()[4]:GetChildren()[15].TextLabel end,
        dlyval
    )
end
