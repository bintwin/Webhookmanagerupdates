-- Exact text config loader
-- Premium and free use the same search logic
-- No numbered GUI paths are used

local env = _G
pcall(function()
    if type(getgenv) == "function" then
        local value = getgenv()
        if type(value) == "table" then
            env = value
        end
    elseif type(getgenv) == "table" then
        env = getgenv
    end
end)

if game.PlaceId ~= 9391468976 and game.GameId ~= 9391468976 then
    return
end

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
if not player then
    return
end

local playerGui = player:WaitForChild("PlayerGui", 10)
if not playerGui then
    return
end

local enabled = env.enablecustomconfig
if enabled == nil then
    enabled = true
end
if enabled ~= true then
    return
end

local rawConfig = env.Config or env.config or env.customconfig
local config = nil

if type(rawConfig) == "string" and rawConfig ~= "" then
    pcall(function()
        local decoded = HttpService:JSONDecode(rawConfig)
        if type(decoded) == "table" then
            config = decoded.CONFIG or decoded
        end
    end)
elseif type(rawConfig) == "table" then
    config = rawConfig.CONFIG or rawConfig
end

if type(config) ~= "table" then
    return
end

local startupWait = env.startup_wait
if startupWait == true then
    startupWait = 4
elseif type(startupWait) ~= "number" then
    startupWait = tonumber(startupWait) or 0
end
startupWait = math.clamp(startupWait, 0, 30)

local showNotification = env.show_notification
if showNotification == nil then
    showNotification = true
end
showNotification = showNotification == true
    or showNotification == 1
    or string.lower(tostring(showNotification)) == "true"

if startupWait > 0 then
    task.wait(startupWait)
end

local touchMode = UserInputService.TouchEnabled

local function normalize(value)
    local text = string.lower(tostring(value or ""))
    text = string.gsub(text, "[%c]", " ")
    text = string.gsub(text, "%s+", " ")
    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    return text
end

local function escapePattern(value)
    return string.gsub(value, "([^%w])", "%%%1")
end

local function isVisible(object)
    if not object or not object:IsA("GuiObject") or not object.Visible then
        return false
    end

    if object.AbsoluteSize.X <= 0 or object.AbsoluteSize.Y <= 0 then
        return false
    end

    local current = object.Parent
    while current and current ~= game do
        if current:IsA("GuiObject") and not current.Visible then
            return false
        end
        current = current.Parent
    end

    return true
end

local function objectText(object)
    if not object then
        return ""
    end

    if object:IsA("TextButton") or object:IsA("TextLabel") or object:IsA("TextBox") then
        return tostring(object.Text or "")
    end

    return ""
end

local function buttonHasExactText(button, wanted)
    if not button or not button:IsA("GuiButton") then
        return false
    end

    local target = normalize(wanted)

    if button:IsA("TextButton") and normalize(button.Text) == target then
        return true
    end

    for _, object in ipairs(button:GetDescendants()) do
        if (object:IsA("TextLabel") or object:IsA("TextButton"))
            and normalize(object.Text) == target then
            return true
        end
    end

    return false
end

local function buttonHasSettingPrefix(button, wanted)
    if not button or not button:IsA("GuiButton") then
        return false
    end

    local target = normalize(wanted)
    local prefix = "^" .. escapePattern(target) .. "%s*:"

    if button:IsA("TextButton") and string.match(normalize(button.Text), prefix) then
        return true
    end

    for _, object in ipairs(button:GetDescendants()) do
        if (object:IsA("TextLabel") or object:IsA("TextButton"))
            and string.match(normalize(object.Text), prefix) then
            return true
        end
    end

    return false
end

local function nearestGuiButton(object, maxDepth)
    local current = object
    local depth = 0

    while current and current ~= game and depth <= (maxDepth or 3) do
        if current:IsA("GuiButton") then
            return current
        end
        current = current.Parent
        depth = depth + 1
    end

    return nil
end

local function findExactTextObjects(wanted, visibleOnly)
    local target = normalize(wanted)
    local results = {}

    for _, object in ipairs(playerGui:GetDescendants()) do
        if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
            if normalize(object.Text) == target and (not visibleOnly or isVisible(object)) then
                table.insert(results, object)
            end
        end
    end

    table.sort(results, function(a, b)
        local aScore = 0
        local bScore = 0

        if isVisible(a) then aScore = aScore + 100 end
        if isVisible(b) then bScore = bScore + 100 end
        if a:IsA("TextButton") then aScore = aScore + 20 end
        if b:IsA("TextButton") then bScore = bScore + 20 end

        return aScore > bScore
    end)

    return results
end

local function findNumericLabel(name, visibleOnly)
    local target = normalize(name)
    local pattern = "^" .. escapePattern(target) .. "%s*:%s*[-+]?%d+%.?%d*"
    local best = nil
    local bestScore = -math.huge

    for _, object in ipairs(playerGui:GetDescendants()) do
        if object:IsA("TextLabel") and string.match(normalize(object.Text), pattern) then
            if not visibleOnly or isVisible(object) then
                local row = object.Parent
                if row and row:IsA("Frame") then
                    local score = 0
                    if isVisible(object) then score = score + 1000 end
                    if row.AbsoluteSize.X >= 80 then score = score + 100 end
                    if row.AbsoluteSize.Y >= 20 and row.AbsoluteSize.Y <= 160 then score = score + 100 end

                    if score > bestScore then
                        best = object
                        bestScore = score
                    end
                end
            end
        end
    end

    return best
end

local function fireOneConnection(signal)
    if type(getconnections) ~= "function" or not signal then
        return false
    end

    local connections = nil
    pcall(function()
        connections = getconnections(signal)
    end)

    if type(connections) ~= "table" then
        return false
    end

    for _, connection in ipairs(connections) do
        if pcall(function()
            connection:Fire()
        end) then
            return true
        end
    end

    return false
end

local function mouseClick(x, y)
    x = math.floor(x + 0.5)
    y = math.floor(y + 0.5)

    return pcall(function()
        VirtualInputManager:SendMouseMoveEvent(x, y, game)
        task.wait(0.01)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
        task.wait(0.015)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
    end)
end

local function pressGuiButton(button)
    if not button or not button.Parent or not button:IsA("GuiButton") then
        return false
    end

    if fireOneConnection(button.Activated) then
        return true
    end

    if fireOneConnection(button.MouseButton1Click) then
        return true
    end

    if type(firesignal) == "function" then
        local ok = pcall(function()
            firesignal(button.Activated)
        end)
        if ok then
            return true
        end
    end

    if not isVisible(button) then
        return false
    end

    local x = button.AbsolutePosition.X + button.AbsoluteSize.X / 2
    local y = button.AbsolutePosition.Y + button.AbsoluteSize.Y / 2
    return mouseClick(x, y)
end

local function findExactTabButton(tabName)
    local best = nil
    local bestScore = -math.huge

    for _, object in ipairs(playerGui:GetDescendants()) do
        if object:IsA("GuiButton") and buttonHasExactText(object, tabName) then
            local score = 0
            if isVisible(object) then score = score + 1000 end

            local parent = object.Parent
            local depth = 0
            while parent and parent ~= game and depth < 6 do
                if parent:IsA("ScrollingFrame") then
                    score = score + 300
                    break
                end
                parent = parent.Parent
                depth = depth + 1
            end

            score = score - object.AbsolutePosition.X

            if score > bestScore then
                best = object
                bestScore = score
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

    local button = findExactTabButton(tabName)
    if not button then
        return false
    end

    if not pressGuiButton(button) then
        return false
    end

    currentTab = tabName
    task.wait(touchMode and 0.08 or 0.045)
    return true
end

local function tabForSetting(name)
    local text = normalize(name)

    if string.find(text, "emote", 1, true)
        or string.find(text, "soundboard", 1, true)
        or string.find(text, "extra", 1, true) then
        return "Extra"
    end

    if string.find(text, "lock on", 1, true)
        or string.find(text, "target", 1, true) then
        return "Target"
    end

    if string.find(text, "m1", 1, true)
        or string.find(text, "dash assist", 1, true) then
        return "Combat"
    end

    if string.find(text, "auto", 1, true)
        or string.find(text, "anti", 1, true)
        or string.find(text, "range", 1, true)
        or string.find(text, "delay", 1, true)
        or string.find(text, "domain", 1, true)
        or string.find(text, "blackflash", 1, true)
        or string.find(text, "black flash", 1, true)
        or string.find(text, "swap", 1, true)
        or string.find(text, "chain", 1, true) then
        return "Auto"
    end

    return "Main"
end

local function directSiblingToggle(label)
    local row = label and label.Parent
    if not row or not row:IsA("GuiObject") then
        return nil
    end

    local candidates = {}

    for _, child in ipairs(row:GetChildren()) do
        if child:IsA("GuiButton") and child ~= label and isVisible(child) then
            table.insert(candidates, child)
        elseif child:IsA("Frame") then
            for _, nested in ipairs(child:GetChildren()) do
                if nested:IsA("GuiButton") and isVisible(nested) then
                    table.insert(candidates, nested)
                end
            end
        end
    end

    if #candidates ~= 1 then
        return nil
    end

    local button = candidates[1]
    local labelCenterY = label.AbsolutePosition.Y + label.AbsoluteSize.Y / 2
    local buttonCenterY = button.AbsolutePosition.Y + button.AbsoluteSize.Y / 2

    if math.abs(labelCenterY - buttonCenterY) > math.max(18, row.AbsoluteSize.Y * 0.45) then
        return nil
    end

    return button
end

local function findToggleButton(name)
    local matches = findExactTextObjects(name, true)

    for _, textObject in ipairs(matches) do
        if textObject:IsA("GuiButton") and buttonHasExactText(textObject, name) then
            return textObject
        end

        local ancestor = nearestGuiButton(textObject, 3)
        if ancestor and buttonHasExactText(ancestor, name) then
            return ancestor
        end

        local sibling = directSiblingToggle(textObject)
        if sibling then
            return sibling
        end
    end

    return nil
end

local function colorLooksEnabled(color)
    return color.G > 0.48
        and color.G > color.R * 1.1
        and color.G >= color.B * 0.72
end

local function readToggleState(button)
    if not button then
        return nil
    end

    local objects = {button, button.Parent}
    local names = {"Enabled", "On", "Toggled", "State", "Value"}

    for _, object in ipairs(objects) do
        if object then
            for _, name in ipairs(names) do
                local value = nil
                pcall(function()
                    value = object:GetAttribute(name)
                end)

                if type(value) == "boolean" then
                    return value
                end

                local child = object:FindFirstChild(name, true)
                if child and child:IsA("BoolValue") then
                    return child.Value
                end
            end
        end
    end

    if colorLooksEnabled(button.BackgroundColor3) then
        return true
    end

    for _, object in ipairs(button:GetDescendants()) do
        if object:IsA("GuiObject") and colorLooksEnabled(object.BackgroundColor3) then
            return true
        end
    end

    return nil
end

local function enableToggle(name)
    local button = findToggleButton(name)
    if not button then
        return false
    end

    if readToggleState(button) == true then
        return true
    end

    return pressGuiButton(button)
end

local function readSliderNumber(label)
    if not label then
        return nil
    end

    local value = string.match(tostring(label.Text or ""), ":%s*([-+]?%d+%.?%d*)")
    return value and tonumber(value) or nil
end

local function containsVisibleText(frame)
    for _, object in ipairs(frame:GetDescendants()) do
        if (object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox"))
            and normalize(object.Text) ~= "" then
            return true
        end
    end

    return false
end

local function containsGuiButton(frame)
    if frame:IsA("GuiButton") then
        return true
    end

    for _, object in ipairs(frame:GetDescendants()) do
        if object:IsA("GuiButton") then
            return true
        end
    end

    return false
end

local function findDirectSliderBar(label)
    local row = label and label.Parent
    if not row or not row:IsA("Frame") then
        return nil, nil
    end

    local best = nil
    local bestScore = -math.huge
    local labelCenterY = label.AbsolutePosition.Y + label.AbsoluteSize.Y / 2

    for _, child in ipairs(row:GetChildren()) do
        if child:IsA("Frame") and child ~= label then
            local width = child.AbsoluteSize.X
            local height = child.AbsoluteSize.Y

            if width >= 30
                and height >= 2
                and height <= 50
                and width >= height * 2.2
                and not containsGuiButton(child)
                and not containsVisibleText(child) then

                local centerY = child.AbsolutePosition.Y + height / 2
                local score = width - math.abs(centerY - labelCenterY) * 3

                if child.Name == "Frame" then
                    score = score + 300
                end

                if child.AbsolutePosition.Y >= label.AbsolutePosition.Y then
                    score = score + 120
                end

                if score > bestScore then
                    best = child
                    bestScore = score
                end
            end
        end
    end

    return best, row
end

local sliderRanges = {
    [normalize("Auto Block Range")] = {0, 30},
    [normalize("Auto Counter Range")] = {0, 30},
    [normalize("Click Delay")] = {0, 30}
}

local function readNumericMetadata(objects, names)
    for _, object in ipairs(objects) do
        if object then
            for _, name in ipairs(names) do
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

local function sliderRange(name, label, bar, row)
    local objects = {bar, row, label}

    local minimum = readNumericMetadata(objects, {
        "Min", "Minimum", "MinValue", "MinimumValue", "LowerBound"
    })

    local maximum = readNumericMetadata(objects, {
        "Max", "Maximum", "MaxValue", "MaximumValue", "UpperBound"
    })

    if type(minimum) == "number" and type(maximum) == "number" and maximum > minimum then
        return minimum, maximum
    end

    local fallback = sliderRanges[normalize(name)]
    if fallback then
        return fallback[1], fallback[2]
    end

    return 0, 30
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

    local oldPosition = scrolling.CanvasPosition
    local top = object.AbsolutePosition.Y
    local bottom = top + object.AbsoluteSize.Y
    local windowTop = scrolling.AbsolutePosition.Y
    local windowBottom = windowTop + scrolling.AbsoluteWindowSize.Y

    if top < windowTop + 4 or bottom > windowBottom - 4 then
        local difference = top - windowTop - 20
        local maxY = math.max(0, scrolling.AbsoluteCanvasSize.Y - scrolling.AbsoluteWindowSize.Y)
        local newY = math.clamp(oldPosition.Y + difference, 0, maxY)
        scrolling.CanvasPosition = Vector2.new(oldPosition.X, newY)
        task.wait(touchMode and 0.06 or 0.035)
    end

    return scrolling, oldPosition
end

local function restoreScroll(scrolling, oldPosition)
    if scrolling and oldPosition then
        pcall(function()
            scrolling.CanvasPosition = oldPosition
        end)
    end
end

local function mouseDrag(startX, y, finishX)
    startX = math.floor(startX + 0.5)
    finishX = math.floor(finishX + 0.5)
    y = math.floor(y + 0.5)

    local held = false
    local ok = pcall(function()
        VirtualInputManager:SendMouseMoveEvent(startX, y, game)
        task.wait(0.015)
        VirtualInputManager:SendMouseButtonEvent(startX, y, 0, true, game, 1)
        held = true
        task.wait(0.02)

        for step = 1, 8 do
            local x = startX + (finishX - startX) * (step / 8)
            VirtualInputManager:SendMouseMoveEvent(math.floor(x + 0.5), y, game)
            task.wait(0.012)
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

local function waitForSliderValue(label, previous, timeout)
    local started = os.clock()
    local latest = readSliderNumber(label)

    while os.clock() - started < timeout do
        latest = readSliderNumber(label)
        if latest ~= nil and latest ~= previous then
            return latest
        end
        task.wait(0.015)
    end

    return latest
end

local function setSlider(name, wanted)
    if type(wanted) ~= "number" then
        return false
    end

    local label = findNumericLabel(name, true)
    if not label then
        return false
    end

    local bar, row = findDirectSliderBar(label)
    if not bar or not row then
        return false
    end

    local minimum, maximum = sliderRange(name, label, bar, row)
    wanted = math.clamp(math.floor(wanted + 0.5), minimum, maximum)

    local current = readSliderNumber(label)
    if current == wanted then
        return true
    end

    local scrolling, oldPosition = bringIntoView(row)

    label = findNumericLabel(name, true) or label
    bar, row = findDirectSliderBar(label)
    if not bar or not row then
        restoreScroll(scrolling, oldPosition)
        return false
    end

    local padding = math.max(2, math.min(5, bar.AbsoluteSize.Y / 2))
    local left = bar.AbsolutePosition.X + padding
    local right = bar.AbsolutePosition.X + bar.AbsoluteSize.X - padding
    local y = bar.AbsolutePosition.Y + bar.AbsoluteSize.Y / 2

    if right - left < 20 then
        restoreScroll(scrolling, oldPosition)
        return false
    end

    local function valueToX(value)
        local ratio = (value - minimum) / (maximum - minimum)
        return left + math.clamp(ratio, 0, 1) * (right - left)
    end

    current = current or minimum
    local currentX = valueToX(current)
    local targetX = valueToX(wanted)

    mouseDrag(currentX, y, targetX)
    local newValue = waitForSliderValue(label, current, touchMode and 0.28 or 0.18)

    if newValue == current then
        mouseClick(targetX, y)
        newValue = waitForSliderValue(label, current, touchMode and 0.24 or 0.16)
    end

    if newValue ~= nil and newValue ~= wanted and newValue ~= current then
        local movedPixels = targetX - currentX
        local movedValues = newValue - current

        if math.abs(movedPixels) >= 1 and movedValues ~= 0 then
            local pixelsPerValue = movedPixels / movedValues
            local correctedX = math.clamp(
                targetX + (wanted - newValue) * pixelsPerValue,
                left,
                right
            )

            if math.abs(correctedX - targetX) >= 1 then
                mouseDrag(targetX, y, correctedX)
                waitForSliderValue(label, newValue, touchMode and 0.24 or 0.16)
            end
        end
    end

    restoreScroll(scrolling, oldPosition)
    return readSliderNumber(label) == wanted
end

local function findSettingButton(name)
    local matches = findExactTextObjects(name, true)

    for _, object in ipairs(matches) do
        if object:IsA("GuiButton") and buttonHasExactText(object, name) then
            return object
        end

        local button = nearestGuiButton(object, 3)
        if button and buttonHasExactText(button, name) then
            return button
        end

        local sibling = directSiblingToggle(object)
        if sibling then
            return sibling
        end
    end

    for _, object in ipairs(playerGui:GetDescendants()) do
        if object:IsA("GuiButton")
            and isVisible(object)
            and buttonHasSettingPrefix(object, name) then
            return object
        end
    end

    return nil
end

local function findExactVisibleOption(option, excludedButton)
    local matches = findExactTextObjects(option, true)

    for _, object in ipairs(matches) do
        local button = nil

        if object:IsA("GuiButton") then
            button = object
        else
            button = nearestGuiButton(object, 3)
        end

        if button
            and button ~= excludedButton
            and button:IsA("GuiButton")
            and isVisible(button)
            and buttonHasExactText(button, option) then
            return button
        end
    end

    return nil
end

local function selectOption(name, option)
    option = tostring(option or "")
    if option == "" or normalize(option) == "select" or normalize(option) == "none" then
        return false
    end

    local control = findSettingButton(name)
    if not control then
        return false
    end

    if not pressGuiButton(control) then
        return false
    end

    task.wait(touchMode and 0.07 or 0.04)

    local optionButton = findExactVisibleOption(option, control)
    if not optionButton then
        return false
    end

    return pressGuiButton(optionButton)
end

local function notify(text)
    if not showNotification then
        return
    end

    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Config Loader",
            Text = text,
            Duration = 4
        })
    end)
end

local grouped = {}
local tabOrder = {"Main", "Target", "Combat", "Auto", "Extra", "Configs"}

local function addToGroup(tabName, kind, name, value)
    grouped[tabName] = grouped[tabName] or {
        booleans = {},
        numbers = {},
        strings = {},
        tables = {}
    }

    table.insert(grouped[tabName][kind], {
        name = tostring(name),
        value = value
    })
end

for name, value in pairs(config) do
    local tabName = tabForSetting(name)

    if value == true then
        addToGroup(tabName, "booleans", name, value)
    elseif type(value) == "number" then
        addToGroup(tabName, "numbers", name, value)
    elseif type(value) == "string" then
        local lowered = normalize(value)
        if lowered ~= "" and lowered ~= "select" and lowered ~= "none" then
            addToGroup(tabName, "strings", name, value)
        end
    elseif type(value) == "table" then
        addToGroup(tabName, "tables", name, value)
    end
end

local applied = 0
local skipped = 0

for _, tabName in ipairs(tabOrder) do
    local group = grouped[tabName]

    if group then
        openTab(tabName)

        table.sort(group.numbers, function(a, b) return a.name < b.name end)
        table.sort(group.booleans, function(a, b) return a.name < b.name end)
        table.sort(group.strings, function(a, b) return a.name < b.name end)
        table.sort(group.tables, function(a, b) return a.name < b.name end)

        -- Numbers are the only values treated as sliders.
        for _, item in ipairs(group.numbers) do
            if setSlider(item.name, item.value) then
                applied = applied + 1
            else
                skipped = skipped + 1
            end
            task.wait(touchMode and 0.02 or 0.01)
        end

        -- True booleans are the only values treated as toggles.
        for _, item in ipairs(group.booleans) do
            if enableToggle(item.name) then
                applied = applied + 1
            else
                skipped = skipped + 1
            end
            task.wait(touchMode and 0.015 or 0.008)
        end

        for _, item in ipairs(group.tables) do
            local worked = false

            for _, option in pairs(item.value) do
                if selectOption(item.name, option) then
                    worked = true
                end
                task.wait(touchMode and 0.015 or 0.008)
            end

            if worked then
                applied = applied + 1
            else
                skipped = skipped + 1
            end
        end

        for _, item in ipairs(group.strings) do
            if selectOption(item.name, item.value) then
                applied = applied + 1
            else
                skipped = skipped + 1
            end
            task.wait(touchMode and 0.015 or 0.008)
        end
    end
end

notify("Applied " .. tostring(applied) .. " config settings")
