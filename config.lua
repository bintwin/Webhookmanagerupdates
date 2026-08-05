-- Jujutsu Shenanigans custom-config UI loader.
--
-- This script deliberately drives the existing ScreenGui instead of changing the
-- game's internal values.  UI libraries differ, so every operation is verified
-- from the visible control before it is counted as applied.

local environment = _G
pcall(function()
    if type(getgenv) == "function" then
        local executorEnvironment = getgenv()
        if type(executorEnvironment) == "table" then
            environment = executorEnvironment
        end
    elseif type(getgenv) == "table" then
        environment = getgenv
    end
end)

local SUPPORTED_PLACE_ID = 9391468976
if game.PlaceId ~= SUPPORTED_PLACE_ID then
    return
end

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
if not player then
    return
end

local playerGui = player:WaitForChild("PlayerGui", 15)
if not playerGui then
    return
end

local function toBoolean(value, defaultValue)
    if value == nil then
        return defaultValue
    end
    if value == true or value == 1 then
        return true
    end
    local text = string.lower(tostring(value))
    return text == "true" or text == "yes" or text == "on" or text == "1"
end

if not toBoolean(environment.enablecustomconfig, true) then
    return
end

local function decodeConfig(value)
    if type(value) == "table" then
        return value.CONFIG or value.Config or value
    end

    if type(value) == "string" and value ~= "" then
        local ok, decoded = pcall(function()
            return HttpService:JSONDecode(value)
        end)
        if ok and type(decoded) == "table" then
            return decoded.CONFIG or decoded.Config or decoded
        end
    end

    return nil
end

local config = decodeConfig(
    environment.Config
        or environment.config
        or environment.customconfig
        or environment.CustomConfig
)

if type(config) ~= "table" then
    warn("[ConfigLoader] Config is missing or invalid")
    return
end

local startupWait = environment.startup_wait
if startupWait == true then
    startupWait = 4
else
    startupWait = tonumber(startupWait) or 0
end
startupWait = math.clamp(startupWait, 0, 30)
if startupWait > 0 then
    task.wait(startupWait)
end

local showNotification = toBoolean(environment.show_notification, true)
local touchMode = UserInputService.TouchEnabled
local STEP_WAIT = touchMode and 0.075 or 0.045
local INPUT_WAIT = touchMode and 0.035 or 0.02

local function trim(text)
    text = tostring(text or "")
    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    return text
end

local function normalize(value)
    local text = string.lower(tostring(value or ""))
    text = string.gsub(text, "[_%-]+", " ")
    text = string.gsub(text, "[^%w%s]", " ")
    text = string.gsub(text, "%s+", " ")
    return trim(text)
end

local function escapePattern(value)
    return string.gsub(value, "([^%w])", "%%%1")
end

local function isTextObject(object)
    return object
        and (object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox"))
end

local function objectText(object)
    if isTextObject(object) then
        return tostring(object.Text or "")
    end
    return ""
end

local function isVisible(object)
    if not object or not object.Parent then
        return false
    end

    if object:IsA("GuiObject") then
        if not object.Visible or object.AbsoluteSize.X <= 0 or object.AbsoluteSize.Y <= 0 then
            return false
        end
    end

    local current = object
    while current and current ~= game do
        if current:IsA("GuiObject") and not current.Visible then
            return false
        end
        if current:IsA("LayerCollector") and not current.Enabled then
            return false
        end
        current = current.Parent
    end

    return true
end

local function descendants(root)
    if root and root.Parent then
        return root:GetDescendants()
    end
    return {}
end

local function waitFrames(count)
    for _ = 1, count or 1 do
        RunService.RenderStepped:Wait()
    end
end

local STANDARD_TABS = {
    "Main",
    "Combat",
    "Auto",
    "Teleports",
    "Target",
    "Extra",
    "Configs",
    "AI Assistant",
}
local TAB_LOOKUP = {}
for _, tabName in ipairs(STANDARD_TABS) do
    TAB_LOOKUP[normalize(tabName)] = tabName
end

local function isArray(value)
    if type(value) ~= "table" then
        return false
    end
    if #value > 0 then
        return true
    end
    return next(value) == nil
end

local entries = {}
local function addEntry(name, value, tabHint)
    table.insert(entries, {
        name = tostring(name),
        value = value,
        tabHint = tabHint,
    })
end

for key, value in pairs(config) do
    local knownTab = TAB_LOOKUP[normalize(key)]
    if knownTab and type(value) == "table" and not isArray(value) then
        for nestedName, nestedValue in pairs(value) do
            addEntry(nestedName, nestedValue, knownTab)
        end
    else
        addEntry(key, value, nil)
    end
end

table.sort(entries, function(a, b)
    local aTab = a.tabHint or ""
    local bTab = b.tabHint or ""
    if aTab == bTab then
        return normalize(a.name) < normalize(b.name)
    end
    return aTab < bTab
end)

local function textMatchesName(text, name)
    local normalizedText = normalize(text)
    local normalizedName = normalize(name)
    if normalizedText == normalizedName then
        return true
    end
    return string.match(normalizedText, "^" .. escapePattern(normalizedName) .. "%s+") ~= nil
end

local function countConfigMatches(root)
    local wanted = {}
    for _, entry in ipairs(entries) do
        wanted[normalize(entry.name)] = true
    end

    local matched = {}
    for _, object in ipairs(descendants(root)) do
        if isTextObject(object) then
            local text = normalize(objectText(object))
            for name in pairs(wanted) do
                if text == name or string.match(text, "^" .. escapePattern(name) .. "%s+") then
                    matched[name] = true
                end
            end
        end
    end

    local count = 0
    for _ in pairs(matched) do
        count = count + 1
    end
    return count
end

local function resolveNamedRoot(name)
    if type(name) ~= "string" or name == "" then
        return nil
    end
    return playerGui:FindFirstChild(name, true)
end

local uiRoot = resolveNamedRoot(environment.config_screen_gui or environment.ScreenGui)
if not uiRoot then
    local bestScore = 0
    for _, child in ipairs(playerGui:GetChildren()) do
        if child:IsA("LayerCollector") then
            local score = countConfigMatches(child)
            if score > bestScore then
                uiRoot = child
                bestScore = score
            end
        end
    end
end
uiRoot = uiRoot or playerGui

-- The panel can be closed while the config is loaded.  Its controls still
-- exist, but Roblox reports them as invisible and will not route input to
-- them.  Open only the selected panel for the duration of this run and put it
-- back exactly as it was afterward.
local uiStateToRestore = {}
local function rememberAndSet(object, property, value)
    table.insert(uiStateToRestore, {
        object = object,
        property = property,
        value = object[property],
    })
    object[property] = value
end

if uiRoot:IsA("LayerCollector") and not uiRoot.Enabled then
    rememberAndSet(uiRoot, "Enabled", true)
end

if uiRoot:IsA("LayerCollector") then
    local guiChildren = {}
    for _, child in ipairs(uiRoot:GetChildren()) do
        if child:IsA("GuiObject") then
            table.insert(guiChildren, child)
        end
    end

    for _, child in ipairs(guiChildren) do
        local ownsControls = countConfigMatches(child) > 0
        if not ownsControls and #guiChildren == 1 then
            ownsControls = true
        end
        if ownsControls and not child.Visible then
            rememberAndSet(child, "Visible", true)
        end
    end
    waitFrames(2)
end

local function restoreUiState()
    for index = #uiStateToRestore, 1, -1 do
        local state = uiStateToRestore[index]
        if state.object and state.object.Parent then
            pcall(function()
                state.object[state.property] = state.value
            end)
        end
    end
end

local function allTextObjects(visibleOnly)
    local results = {}
    for _, object in ipairs(descendants(uiRoot)) do
        if isTextObject(object) and (not visibleOnly or isVisible(object)) then
            table.insert(results, object)
        end
    end
    return results
end

local function nearestButton(object, maxDepth)
    local current = object
    for _ = 0, maxDepth or 5 do
        if not current or current == game then
            break
        end
        if current:IsA("GuiButton") then
            return current
        end
        current = current.Parent
    end
    return nil
end

local function findScrollingAncestor(object)
    local current = object and object.Parent
    while current and current ~= game do
        if current:IsA("ScrollingFrame") then
            return current
        end
        current = current.Parent
    end
    return nil
end

local function bringIntoView(object)
    local scrolling = findScrollingAncestor(object)
    if not scrolling then
        return nil, nil
    end

    local original = scrolling.CanvasPosition
    local top = object.AbsolutePosition.Y
    local bottom = top + object.AbsoluteSize.Y
    local windowTop = scrolling.AbsolutePosition.Y
    local windowBottom = windowTop + scrolling.AbsoluteWindowSize.Y

    if top < windowTop + 8 or bottom > windowBottom - 8 then
        local desired = original.Y + top - windowTop - 24
        local maximum = math.max(0, scrolling.AbsoluteCanvasSize.Y - scrolling.AbsoluteWindowSize.Y)
        scrolling.CanvasPosition = Vector2.new(original.X, math.clamp(desired, 0, maximum))
        waitFrames(2)
    end

    return scrolling, original
end

local function restoreScroll(scrolling, original)
    if scrolling and original then
        pcall(function()
            scrolling.CanvasPosition = original
        end)
    end
end

local function fireConnections(signal)
    if type(getconnections) ~= "function" or not signal then
        return 0
    end

    local ok, connections = pcall(getconnections, signal)
    if not ok or type(connections) ~= "table" then
        return 0
    end

    local fired = 0
    for _, connection in ipairs(connections) do
        if pcall(function()
            connection:Fire()
        end) then
            fired = fired + 1
        end
    end
    return fired
end

local function mouseClick(x, y)
    x = math.floor(x + 0.5)
    y = math.floor(y + 0.5)
    return pcall(function()
        VirtualInputManager:SendMouseMoveEvent(x, y, game)
        task.wait(INPUT_WAIT)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
        task.wait(INPUT_WAIT)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
    end)
end

local function clickGui(object)
    if not object or not object.Parent or not object:IsA("GuiObject") then
        return false
    end

    local scrolling, original = bringIntoView(object)
    local clicked = false

    if isVisible(object) then
        local x = object.AbsolutePosition.X + object.AbsoluteSize.X / 2
        local y = object.AbsolutePosition.Y + object.AbsoluteSize.Y / 2
        clicked = mouseClick(x, y)
    end

    if not clicked and object:IsA("GuiButton") then
        clicked = fireConnections(object.Activated) > 0
        if not clicked and object:IsA("TextButton") then
            clicked = fireConnections(object.MouseButton1Click) > 0
        end
        if not clicked and type(firesignal) == "function" then
            clicked = pcall(firesignal, object.Activated)
        end
    end

    task.wait(STEP_WAIT)
    restoreScroll(scrolling, original)
    return clicked
end

local function collectObjectTexts(object)
    local values = {}
    if isTextObject(object) then
        table.insert(values, objectText(object))
    end
    for _, child in ipairs(descendants(object)) do
        if isTextObject(child) then
            table.insert(values, objectText(child))
        end
    end
    return table.concat(values, " ")
end

local function findTabButton(tabName)
    local target = normalize(tabName)
    local best, bestScore = nil, -math.huge

    for _, object in ipairs(descendants(uiRoot)) do
        if object:IsA("GuiButton") and normalize(collectObjectTexts(object)) == target then
            local score = isVisible(object) and 1000 or 0
            local scrolling = findScrollingAncestor(object)
            if scrolling then
                score = score + 100
            end
            if object.AbsoluteSize.Y >= 18 and object.AbsoluteSize.Y <= 80 then
                score = score + 50
            end
            if score > bestScore then
                best, bestScore = object, score
            end
        end
    end

    return best
end

local currentTab = nil
local function openTab(tabName)
    if currentTab == tabName then
        return true
    end

    local button = findTabButton(tabName)
    if not button or not isVisible(button) then
        return false
    end

    if not clickGui(button) then
        return false
    end

    currentTab = tabName
    waitFrames(2)
    return true
end

local function guessedTab(name)
    local text = normalize(name)
    local rules = {
        {"Extra", {"emote", "soundboard", "extra"}},
        {"Target", {"lock on", "target"}},
        {"Combat", {"m1", "dash assist", "combat"}},
        {"Auto", {"auto", "anti", "range", "delay", "domain", "blackflash", "black flash", "swap", "chain"}},
    }

    for _, rule in ipairs(rules) do
        for _, needle in ipairs(rule[2]) do
            if string.find(text, needle, 1, true) then
                return rule[1]
            end
        end
    end
    return "Main"
end

local function tabSearchOrder(tabHint, name)
    local order, seen = {}, {}
    local function add(tabName)
        if tabName and not seen[tabName] then
            seen[tabName] = true
            table.insert(order, tabName)
        end
    end

    add(tabHint)
    add(guessedTab(name))
    add(currentTab)
    for _, tabName in ipairs(STANDARD_TABS) do
        add(tabName)
    end
    return order
end

local function findSettingText(name, numericOnly)
    local best, bestScore = nil, -math.huge
    local target = normalize(name)
    local prefix = "^" .. escapePattern(target) .. "%s+"

    for _, object in ipairs(allTextObjects(true)) do
        local raw = objectText(object)
        local normalized = normalize(raw)
        local exact = normalized == target
        local prefixed = string.match(normalized, prefix) ~= nil
        local hasNumber = string.match(raw, "[-+]?%d*%.?%d+") ~= nil

        if (exact or prefixed) and (not numericOnly or hasNumber) then
            local score = exact and 500 or 300
            if object:IsA("TextLabel") then score = score + 30 end
            if object:IsA("TextButton") then score = score + 20 end
            score = score - math.min(object.AbsolutePosition.X, 500) * 0.01
            if score > bestScore then
                best, bestScore = object, score
            end
        end
    end

    return best
end

local function locateAcrossTabs(name, tabHint, locator)
    local found = locator()
    if found then
        return found, currentTab
    end

    for _, tabName in ipairs(tabSearchOrder(tabHint, name)) do
        if openTab(tabName) then
            found = locator()
            if found then
                return found, tabName
            end
        end
    end

    return nil, nil
end

local function candidateRows(label)
    local rows = {}
    local current = label and label.Parent
    for depth = 1, 6 do
        if not current or current == uiRoot or current == game then
            break
        end
        if current:IsA("GuiObject") then
            table.insert(rows, {object = current, depth = depth})
        end
        current = current.Parent
    end
    return rows
end

local function interactiveObjects(row, excluded)
    local results = {}
    if row:IsA("GuiButton") and row ~= excluded then
        table.insert(results, row)
    end
    for _, object in ipairs(descendants(row)) do
        if object:IsA("GuiButton") and object ~= excluded and isVisible(object) then
            table.insert(results, object)
        end
    end
    return results
end

local BOOLEAN_ATTRIBUTES = {"Enabled", "On", "Toggled", "Toggle", "State", "Value", "Active"}
local function readBooleanMetadata(object)
    local objects = {object, object and object.Parent}
    for _, item in ipairs(objects) do
        if item then
            for _, attributeName in ipairs(BOOLEAN_ATTRIBUTES) do
                local ok, value = pcall(function()
                    return item:GetAttribute(attributeName)
                end)
                if ok and type(value) == "boolean" then
                    return value
                end

                local child = item:FindFirstChild(attributeName, true)
                if child and child:IsA("BoolValue") then
                    return child.Value
                end
            end
        end
    end
    return nil
end

local function enabledColor(color)
    return color.G >= 0.42 and color.G > color.R * 1.14 and color.G > color.B * 0.78
end

local function disabledColor(color)
    local maximum = math.max(color.R, color.G, color.B)
    local minimum = math.min(color.R, color.G, color.B)
    return maximum < 0.38 and maximum - minimum < 0.1
end

local function readToggleState(button)
    local metadata = readBooleanMetadata(button)
    if metadata ~= nil then
        return metadata
    end

    if button.Selected then
        return true
    end

    local text = " " .. normalize(collectObjectTexts(button)) .. " "
    if string.find(text, " off ", 1, true) or string.find(text, " disabled ", 1, true) then
        return false
    end
    if string.find(text, " on ", 1, true) or string.find(text, " enabled ", 1, true) then
        return true
    end

    local enabledCount, disabledCount = 0, 0
    local visualObjects = {button}
    for _, object in ipairs(descendants(button)) do
        if object:IsA("GuiObject") then
            table.insert(visualObjects, object)
        end
    end
    for _, object in ipairs(visualObjects) do
        if object.BackgroundTransparency < 0.75 then
            if enabledColor(object.BackgroundColor3) then enabledCount = enabledCount + 1 end
            if disabledColor(object.BackgroundColor3) then disabledCount = disabledCount + 1 end
        end
    end
    if enabledCount > 0 then
        return true
    end
    if disabledCount > 0 then
        return false
    end
    return nil
end

local function visualSignature(object)
    local parts = {normalize(collectObjectTexts(object))}
    local objects = {object}
    for _, child in ipairs(descendants(object)) do
        if child:IsA("GuiObject") then
            table.insert(objects, child)
        end
    end
    for index, item in ipairs(objects) do
        if index > 12 then break end
        local color = item.BackgroundColor3
        table.insert(parts, string.format(
            "%.2f,%.2f,%.2f,%.2f",
            color.R,
            color.G,
            color.B,
            item.BackgroundTransparency
        ))
    end
    return table.concat(parts, "|")
end

local function findToggleControl(name)
    local label = findSettingText(name, false)
    if not label then
        return nil
    end

    local direct = nearestButton(label, 3)
    if direct then
        return direct
    end

    local labelCenterY = label.AbsolutePosition.Y + label.AbsoluteSize.Y / 2
    local best, bestScore = nil, -math.huge
    for _, rowInfo in ipairs(candidateRows(label)) do
        for _, button in ipairs(interactiveObjects(rowInfo.object, label)) do
            local centerY = button.AbsolutePosition.Y + button.AbsoluteSize.Y / 2
            local difference = math.abs(centerY - labelCenterY)
            if difference <= math.max(24, rowInfo.object.AbsoluteSize.Y * 0.55) then
                local score = 500 - rowInfo.depth * 40 - difference
                if button.AbsolutePosition.X >= label.AbsolutePosition.X then
                    score = score + 80
                end
                if score > bestScore then
                    best, bestScore = button, score
                end
            end
        end
        if best then break end
    end
    return best
end

local function setToggle(name, wanted, tabHint)
    local button = locateAcrossTabs(name, tabHint, function()
        return findToggleControl(name)
    end)
    if not button then
        return false, "toggle not found"
    end

    local state = readToggleState(button)
    if state == wanted then
        return true, "already " .. (wanted and "on" or "off")
    end

    if state ~= nil then
        if not clickGui(button) then
            return false, "toggle click failed"
        end
        local after = readToggleState(button)
        if after == wanted or after == nil then
            return true, "set " .. (wanted and "on" or "off")
        end
        return false, "toggle state did not change"
    end

    -- Unknown themes are calibrated with one click.  If the new state becomes
    -- readable we can choose the requested side; otherwise default-off UIs are
    -- handled without accidentally enabling values configured as false.
    if not wanted then
        return true, "left at default off (state not exposed)"
    end

    local beforeSignature = visualSignature(button)
    if not clickGui(button) then
        return false, "toggle click failed"
    end
    local after = readToggleState(button)
    if after == false then
        clickGui(button)
    end
    local changed = beforeSignature ~= visualSignature(button)
    if after == true or changed then
        return true, "enabled"
    end
    return false, "toggle gave no state feedback"
end

local function readNumberFromText(text)
    text = tostring(text or "")
    local value = string.match(text, ":%s*([-+]?%d*%.?%d+)%s*$")
        or string.match(text, "([-+]?%d*%.?%d+)%s*$")
    return value and tonumber(value) or nil
end

local function readSliderValue(label)
    if not label or not label.Parent then
        return nil
    end
    return readNumberFromText(objectText(label))
end

local NUMBER_ATTRIBUTES = {
    minimum = {"Min", "Minimum", "MinValue", "MinimumValue", "LowerBound"},
    maximum = {"Max", "Maximum", "MaxValue", "MaximumValue", "UpperBound"},
    step = {"Step", "Increment", "Round", "Rounding"},
}

local function readNumberMetadata(objects, names)
    for _, object in ipairs(objects) do
        if object then
            for _, name in ipairs(names) do
                local ok, value = pcall(function()
                    return object:GetAttribute(name)
                end)
                if ok and type(value) == "number" then
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

local function findSliderTrack(name)
    local label = findSettingText(name, true)
    if not label then
        return nil
    end

    -- The TBO UI builds sliders as:
    --   Row (Frame)
    --     TextLabel  -- e.g. "Auto Block Range: 15"
    --     Frame      -- input track (its child Frame is the fill)
    -- Prefer that exact relationship before using the generic fallback below.
    local directRow = label.Parent
    if directRow and directRow:IsA("GuiObject") then
        local directBest, directBestScore = nil, -math.huge
        for _, sibling in ipairs(directRow:GetChildren()) do
            if sibling:IsA("GuiObject") and sibling ~= label then
                local width, height = sibling.AbsoluteSize.X, sibling.AbsoluteSize.Y
                if width >= 45 and height >= 2 and height <= 24 and width >= height * 3 then
                    local connectionBonus = 0
                    if type(getconnections) == "function" then
                        local okBegan, began = pcall(getconnections, sibling.InputBegan)
                        local okChanged, changed = pcall(getconnections, sibling.InputChanged)
                        if okBegan and #began > 0 then connectionBonus = connectionBonus + 1000 end
                        if okChanged and #changed > 0 then connectionBonus = connectionBonus + 500 end
                    end
                    local score = width + connectionBonus
                    if score > directBestScore then
                        directBest, directBestScore = sibling, score
                    end
                end
            end
        end
        if directBest then
            return {label = label, track = directBest, row = directRow}
        end
    end

    local labelCenterY = label.AbsolutePosition.Y + label.AbsoluteSize.Y / 2
    local bestTrack, bestRow, bestScore = nil, nil, -math.huge

    for _, rowInfo in ipairs(candidateRows(label)) do
        local row = rowInfo.object
        local objects = {row}
        for _, object in ipairs(descendants(row)) do
            if object:IsA("GuiObject") then
                table.insert(objects, object)
            end
        end

        for _, object in ipairs(objects) do
            if object ~= label and not object:IsA("TextLabel") and not object:IsA("TextBox") then
                local width, height = object.AbsoluteSize.X, object.AbsoluteSize.Y
                if width >= 45 and height >= 2 and height <= 42 and width >= height * 2.5 then
                    local centerY = object.AbsolutePosition.Y + height / 2
                    local difference = math.abs(centerY - labelCenterY)
                    local score = width - difference * 1.5 - rowInfo.depth * 15
                    local objectName = normalize(object.Name)
                    if string.find(objectName, "slider", 1, true) then score = score + 500 end
                    if string.find(objectName, "track", 1, true) then score = score + 350 end
                    if string.find(objectName, "bar", 1, true) then score = score + 250 end
                    if object.AbsolutePosition.Y >= label.AbsolutePosition.Y then score = score + 80 end
                    if score > bestScore then
                        bestTrack, bestRow, bestScore = object, row, score
                    end
                end
            end
        end

        if bestTrack and bestScore > 500 then
            break
        end
    end

    if not bestTrack then
        return nil
    end
    return {label = label, track = bestTrack, row = bestRow}
end

local function sliderGeometry(control)
    local track = control.track
    local padding = math.max(1, math.min(5, track.AbsoluteSize.Y * 0.25))
    local left = track.AbsolutePosition.X + padding
    local right = track.AbsolutePosition.X + track.AbsoluteSize.X - padding
    local y = track.AbsolutePosition.Y + track.AbsoluteSize.Y / 2

    local knobX = nil
    for _, object in ipairs(descendants(track)) do
        if object:IsA("GuiObject") and isVisible(object) then
            local width, height = object.AbsoluteSize.X, object.AbsoluteSize.Y
            if width >= 4 and width <= 40 and height >= 4 and height <= 40 then
                local center = object.AbsolutePosition.X + width / 2
                if center >= left - 8 and center <= right + 8 then
                    knobX = center
                end
            end
        end
    end
    return left, right, y, knobX
end

local function mouseDrag(startX, y, finishX)
    startX = math.floor(startX + 0.5)
    finishX = math.floor(finishX + 0.5)
    y = math.floor(y + 0.5)
    local held = false

    local ok = pcall(function()
        VirtualInputManager:SendMouseMoveEvent(startX, y, game)
        task.wait(INPUT_WAIT)
        VirtualInputManager:SendMouseButtonEvent(startX, y, 0, true, game, 1)
        held = true
        task.wait(INPUT_WAIT)
        for step = 1, 12 do
            local x = startX + (finishX - startX) * step / 12
            VirtualInputManager:SendMouseMoveEvent(math.floor(x + 0.5), y, game)
            task.wait(0.01)
        end
        VirtualInputManager:SendMouseButtonEvent(finishX, y, 0, false, game, 1)
        held = false
    end)

    if held then
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(finishX, y, 0, false, game, 1)
        end)
    end
    return ok
end

local function waitForNumber(label, previous, timeout)
    local started = os.clock()
    local latest = readSliderValue(label)
    while os.clock() - started < timeout do
        latest = readSliderValue(label)
        if latest ~= nil and (previous == nil or latest ~= previous) then
            return latest
        end
        task.wait(0.02)
    end
    return latest
end

local function configuredRange(name)
    local ranges = environment.slider_ranges or environment.SliderRanges
    if type(ranges) == "table" then
        local value = ranges[name] or ranges[normalize(name)]
        if type(value) == "table" then
            local minimum = tonumber(value.min or value.minimum or value[1])
            local maximum = tonumber(value.max or value.maximum or value[2])
            if minimum and maximum and maximum > minimum then
                return minimum, maximum
            end
        end
    end
    return nil, nil
end

local function moveSlider(control, startX, targetX)
    local _, _, y, knobX = sliderGeometry(control)
    startX = knobX or startX
    if not startX then
        startX = targetX
    end
    if mouseDrag(startX, y, targetX) then
        task.wait(STEP_WAIT)
        return true
    end
    return mouseClick(targetX, y)
end

local function nearlyEqual(a, b, step)
    if a == nil or b == nil then return false end
    local tolerance = math.max(0.001, math.abs(step or 0) * 0.25)
    return math.abs(a - b) <= tolerance
end

local function setSlider(name, wanted, tabHint)
    wanted = tonumber(wanted)
    if not wanted then
        return false, "slider value is not numeric"
    end

    local control = locateAcrossTabs(name, tabHint, function()
        return findSliderTrack(name)
    end)
    if not control then
        return false, "slider not found"
    end

    local scrolling, original = bringIntoView(control.row)
    waitFrames(1)
    control = findSliderTrack(name) or control

    local current = readSliderValue(control.label)
    if current == nil then
        restoreScroll(scrolling, original)
        return false, "slider value label is unreadable"
    end

    local objects = {control.track, control.row, control.label}
    local minimum = readNumberMetadata(objects, NUMBER_ATTRIBUTES.minimum)
    local maximum = readNumberMetadata(objects, NUMBER_ATTRIBUTES.maximum)
    local step = readNumberMetadata(objects, NUMBER_ATTRIBUTES.step)
    if not minimum or not maximum or maximum <= minimum then
        minimum, maximum = configuredRange(name)
    end

    local left, right, _, knobX = sliderGeometry(control)
    if right - left < 20 then
        restoreScroll(scrolling, original)
        return false, "slider track is too small"
    end

    -- If the UI exposes no range, briefly sample both endpoints.  This makes
    -- sliders with uncommon limits work without another hard-coded name.
    if not minimum or not maximum then
        moveSlider(control, knobX, left)
        minimum = waitForNumber(control.label, current, 0.35)
        local _, _, _, leftKnob = sliderGeometry(control)
        moveSlider(control, leftKnob or left, right)
        maximum = waitForNumber(control.label, minimum, 0.35)
        if not minimum or not maximum or maximum <= minimum then
            restoreScroll(scrolling, original)
            return false, "could not calibrate slider range"
        end
    end

    wanted = math.clamp(wanted, minimum, maximum)
    if step and step > 0 then
        wanted = minimum + math.floor((wanted - minimum) / step + 0.5) * step
    end

    current = readSliderValue(control.label)
    if nearlyEqual(current, wanted, step) then
        restoreScroll(scrolling, original)
        return true, "already " .. tostring(current)
    end

    local ratio = (wanted - minimum) / (maximum - minimum)
    local targetX = left + math.clamp(ratio, 0, 1) * (right - left)
    local _, _, _, currentKnob = sliderGeometry(control)
    if not currentKnob and current then
        local currentRatio = (current - minimum) / (maximum - minimum)
        currentKnob = left + math.clamp(currentRatio, 0, 1) * (right - left)
    end

    moveSlider(control, currentKnob, targetX)
    local actual = waitForNumber(control.label, current, 0.45)

    -- Pixel rounding can put the first attempt one step away.  Correct using
    -- the observed value-to-pixel error, then verify again.
    if actual and not nearlyEqual(actual, wanted, step) then
        local valueSpan = maximum - minimum
        local correction = (wanted - actual) / valueSpan * (right - left)
        local correctedX = math.clamp(targetX + correction, left, right)
        local _, _, _, newKnob = sliderGeometry(control)
        moveSlider(control, newKnob or targetX, correctedX)
        actual = waitForNumber(control.label, actual, 0.4)
    end

    restoreScroll(scrolling, original)
    if nearlyEqual(actual, wanted, step) then
        return true, "set to " .. tostring(actual)
    end
    return false, "wanted " .. tostring(wanted) .. ", got " .. tostring(actual)
end

local function findSettingButton(name)
    local label = findSettingText(name, false)
    if not label then
        return nil
    end

    local direct = nearestButton(label, 4)
    if direct then
        return direct
    end

    for _, rowInfo in ipairs(candidateRows(label)) do
        local buttons = interactiveObjects(rowInfo.object, label)
        if #buttons == 1 then
            return buttons[1]
        end
    end
    return nil
end

local function findVisibleOption(option, excluded)
    local target = normalize(option)
    local best, bestScore = nil, -math.huge
    for _, object in ipairs(allTextObjects(true)) do
        if normalize(objectText(object)) == target then
            local button = nearestButton(object, 4)
            if button and button ~= excluded and not button:IsDescendantOf(excluded) then
                local score = 1000
                if object:IsA("TextButton") then score = score + 100 end
                if button.AbsolutePosition.Y >= excluded.AbsolutePosition.Y then score = score + 50 end
                if score > bestScore then
                    best, bestScore = button, score
                end
            end
        end
    end
    return best
end

local function findTextBox(name)
    local label = findSettingText(name, false)
    if not label then return nil end
    if label:IsA("TextBox") then return label end

    for _, rowInfo in ipairs(candidateRows(label)) do
        for _, object in ipairs(descendants(rowInfo.object)) do
            if object:IsA("TextBox") and isVisible(object) then
                return object
            end
        end
    end
    return nil
end

local function setTextInput(name, value, tabHint)
    local textBox = locateAcrossTabs(name, tabHint, function()
        return findTextBox(name)
    end)
    if not textBox then
        return false, "text box not found"
    end

    value = tostring(value)
    if textBox.Text == value then
        return true, "already set"
    end

    local ok = pcall(function()
        textBox:CaptureFocus()
        textBox.Text = value
        waitFrames(1)
        textBox:ReleaseFocus(true)
    end)
    if ok and textBox.Text == value then
        return true, "text entered"
    end
    return false, "text entry failed"
end

local function selectOption(name, option, tabHint)
    option = trim(option)
    if option == "" or normalize(option) == "select" or normalize(option) == "none" then
        return true, "empty option ignored"
    end

    local control = locateAcrossTabs(name, tabHint, function()
        return findSettingButton(name)
    end)
    if not control then
        return setTextInput(name, option, tabHint)
    end

    local controlText = normalize(collectObjectTexts(control))
    if string.find(controlText, normalize(option), 1, true) then
        return true, "already selected"
    end

    if not clickGui(control) then
        return false, "dropdown did not open"
    end

    local optionButton = findVisibleOption(option, control)
    if not optionButton then
        return false, "option not found: " .. option
    end
    if not clickGui(optionButton) then
        return false, "option click failed: " .. option
    end
    return true, "selected " .. option
end

local function clickAction(name, tabHint)
    local button = locateAcrossTabs(name, tabHint, function()
        return findSettingButton(name)
    end)
    if not button then
        return false, "button not found"
    end
    if clickGui(button) then
        return true, "clicked"
    end
    return false, "button click failed"
end

local report = {
    applied = 0,
    skipped = 0,
    settings = {},
    screenGui = uiRoot:GetFullName(),
}

local function record(entry, ok, detail)
    if ok then
        report.applied = report.applied + 1
    else
        report.skipped = report.skipped + 1
    end
    table.insert(report.settings, {
        name = entry.name,
        value = entry.value,
        success = ok,
        detail = detail,
        tab = currentTab,
    })
    print(string.format(
        "[ConfigLoader] %s %s: %s",
        ok and "OK" or "FAIL",
        entry.name,
        tostring(detail)
    ))
end

for _, entry in ipairs(entries) do
    local valueType = type(entry.value)
    local ok, detail

    if valueType == "boolean" then
        ok, detail = setToggle(entry.name, entry.value, entry.tabHint)
    elseif valueType == "number" then
        ok, detail = setSlider(entry.name, entry.value, entry.tabHint)
    elseif valueType == "string" then
        ok, detail = selectOption(entry.name, entry.value, entry.tabHint)
    elseif valueType == "table" and isArray(entry.value) then
        ok = true
        local selected = 0
        for _, option in ipairs(entry.value) do
            local optionOk, optionDetail = selectOption(entry.name, option, entry.tabHint)
            if optionOk then
                selected = selected + 1
            else
                ok = false
                detail = optionDetail
                break
            end
        end
        detail = detail or ("selected " .. tostring(selected) .. " option(s)")
    elseif valueType == "table" and entry.value.click == true then
        ok, detail = clickAction(entry.name, entry.tabHint)
    else
        ok, detail = false, "unsupported config value type: " .. valueType
    end

    record(entry, ok, detail)
    task.wait(INPUT_WAIT)
end

environment.__CustomConfigReport = report

restoreUiState()

if showNotification then
    pcall(function()
        local text = string.format("Applied %d setting(s)", report.applied)
        if report.skipped > 0 then
            text = text .. string.format("; %d failed (see console)", report.skipped)
        end
        StarterGui:SetCore("SendNotification", {
            Title = "Config Loader",
            Text = text,
            Duration = 5,
        })
    end)
end
