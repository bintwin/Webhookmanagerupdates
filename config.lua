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

local enableCustomConfig = env.enablecustomconfig
if enableCustomConfig == nil then
    enableCustomConfig = true
end

local startupWaitValue = env.startup_wait
local startupWait = 0

if startupWaitValue == true then
    startupWait = 4
elseif type(startupWaitValue) == "number" then
    startupWait = math.clamp(startupWaitValue, 0, 30)
elseif type(startupWaitValue) == "string" then
    if string.lower(startupWaitValue) == "true" then
        startupWait = 4
    else
        startupWait = math.clamp(tonumber(startupWaitValue) or 0, 0, 30)
    end
end

local showNotification = env.show_notification
if showNotification == nil then
    showNotification = true
end
showNotification = showNotification == true
    or showNotification == 1
    or string.lower(tostring(showNotification)) == "true"

local parsedConfig = nil
local rawConfig = env.Config or env.config or env.customconfig

if enableCustomConfig and type(rawConfig) == "string" and rawConfig ~= "" then
    pcall(function()
        local decoded = HttpService:JSONDecode(rawConfig)
        if type(decoded) == "table" and type(decoded.CONFIG) == "table" then
            parsedConfig = decoded.CONFIG
        elseif type(decoded) == "table" then
            parsedConfig = decoded
        end
    end)
elseif enableCustomConfig and type(rawConfig) == "table" then
    parsedConfig = rawConfig.CONFIG or rawConfig
end

if not enableCustomConfig or type(parsedConfig) ~= "table" then
    return
end

if startupWait > 0 then
    task.wait(startupWait)
end

local touchMode = UserInputService.TouchEnabled
local textEntries = {}
local textCache = {}
local currentTab = nil

local function normalize(value)
    local text = string.lower(tostring(value or ""))
    text = string.gsub(text, "[%c]", " ")
    text = string.gsub(text, "%s+", " ")
    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    return text
end

local function removeOnly(value)
    local text = normalize(value)
    text = string.gsub(text, "%s+only$", "")
    return text
end

local function keyify(value)
    local text = removeOnly(value)
    return string.gsub(text, "[^%w]", "")
end

local function startsWithLabel(actual, wanted)
    local actualText = normalize(actual)
    local wantedText = normalize(wanted)

    if actualText == wantedText then
        return true
    end

    return string.sub(actualText, 1, #wantedText + 1) == wantedText .. ":"
        or string.sub(actualText, 1, #wantedText + 1) == wantedText .. " "
end

local function isGuiVisible(object)
    if not object or not object:IsA("GuiObject") or not object.Visible then
        return false
    end

    local current = object.Parent
    while current and current ~= game do
        if current:IsA("GuiObject") and not current.Visible then
            return false
        end
        current = current.Parent
    end

    return object.AbsoluteSize.X > 0 and object.AbsoluteSize.Y > 0
end

local function refreshTextIndex()
    textEntries = {}
    textCache = {}

    local descendants = playerGui:GetDescendants()
    for index, object in ipairs(descendants) do
        if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
            local text = tostring(object.Text or "")
            if text ~= "" then
                table.insert(textEntries, {
                    object = object,
                    text = text,
                    normalized = normalize(text),
                    key = keyify(text)
                })
            end
        end

        if touchMode and index % 250 == 0 then
            task.wait()
        end
    end
end

local function findTextObjects(wanted, prefix)
    local cacheKey = tostring(prefix == true) .. "|" .. keyify(wanted)
    local cached = textCache[cacheKey]
    if cached then
        return cached
    end

    local wantedKey = keyify(wanted)
    local matches = {}

    for _, entry in ipairs(textEntries) do
        local matched = false

        if prefix then
            matched = startsWithLabel(entry.text, wanted)
        else
            matched = entry.key == wantedKey
        end

        if matched and entry.object and entry.object.Parent then
            local score = 0
            if isGuiVisible(entry.object) then
                score = score + 500
            end
            if entry.object:IsA("TextButton") then
                score = score + 100
            end
            if normalize(entry.text) == normalize(wanted) then
                score = score + 150
            end

            table.insert(matches, {
                object = entry.object,
                score = score
            })
        end
    end

    table.sort(matches, function(a, b)
        return a.score > b.score
    end)

    local objects = {}
    for _, match in ipairs(matches) do
        table.insert(objects, match.object)
    end

    textCache[cacheKey] = objects
    return objects
end

local function nearestButton(object)
    local current = object
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

local function directFrameRow(label)
    if not label or not label.Parent then
        return nil
    end

    if label.Parent:IsA("Frame") then
        return label.Parent
    end

    local current = label.Parent
    local depth = 0

    while current and current ~= game and depth < 4 do
        if current:IsA("Frame") then
            local width = current.AbsoluteSize.X
            local height = current.AbsoluteSize.Y
            if width >= label.AbsoluteSize.X and height >= label.AbsoluteSize.Y and height <= 140 then
                return current
            end
        end
        current = current.Parent
        depth = depth + 1
    end

    return nil
end

local function getTextFromButton(button)
    if not button then
        return ""
    end

    if button:IsA("TextButton") and button.Text ~= "" then
        return button.Text
    end

    local label = button:FindFirstChildWhichIsA("TextLabel", true)
    if label then
        return label.Text
    end

    return ""
end

local function hasExactButtonText(button, wanted)
    return keyify(getTextFromButton(button)) == keyify(wanted)
end

local function fireFirstConnection(signal)
    if type(getconnections) ~= "function" or not signal then
        return false
    end

    local connections = nil
    pcall(function()
        connections = getconnections(signal)
    end)

    if type(connections) ~= "table" or #connections == 0 then
        return false
    end

    for _, connection in ipairs(connections) do
        local fired = pcall(function()
            connection:Fire()
        end)
        if fired then
            return true
        end
    end

    return false
end

local function mouseClickAt(x, y)
    x = math.floor(x + 0.5)
    y = math.floor(y + 0.5)

    local ok = pcall(function()
        VirtualInputManager:SendMouseMoveEvent(x, y, game)
        task.wait(0.008)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
        task.wait(0.012)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
    end)

    return ok
end

local function touchClickAt(x, y)
    x = math.floor(x + 0.5)
    y = math.floor(y + 0.5)

    local ok = pcall(function()
        VirtualInputManager:SendTouchEvent(0, 0, x, y)
        task.wait(0.012)
        VirtualInputManager:SendTouchEvent(0, 2, x, y)
    end)

    return ok
end

local function pressButton(button)
    if not button or not button.Parent then
        return false
    end

    if button:IsA("GuiButton") then
        if fireFirstConnection(button.Activated) then
            return true
        end
        if fireFirstConnection(button.MouseButton1Click) then
            return true
        end
        if fireFirstConnection(button.MouseButton1Down) then
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
    end

    if not button:IsA("GuiObject") or not isGuiVisible(button) then
        return false
    end

    local x = button.AbsolutePosition.X + button.AbsoluteSize.X / 2
    local y = button.AbsolutePosition.Y + button.AbsoluteSize.Y / 2

    if mouseClickAt(x, y) then
        return true
    end

    if touchMode then
        return touchClickAt(x, y)
    end

    return false
end

local function findTabButton(tabName)
    local wantedKey = keyify(tabName)
    local best = nil
    local bestScore = -math.huge

    for _, object in ipairs(playerGui:GetDescendants()) do
        if object:IsA("GuiButton") and hasExactButtonText(object, tabName) then
            local score = 0

            if isGuiVisible(object) then
                score = score + 500
            end

            local centerX = object.AbsolutePosition.X + object.AbsoluteSize.X / 2
            score = score - centerX

            local ancestor = object.Parent
            local depth = 0
            while ancestor and ancestor ~= game and depth < 6 do
                if ancestor:IsA("ScrollingFrame") then
                    score = score + 250
                    break
                end
                ancestor = ancestor.Parent
                depth = depth + 1
            end

            if keyify(getTextFromButton(object)) == wantedKey then
                score = score + 300
            end

            if score > bestScore then
                best = object
                bestScore = score
            end
        end
    end

    if best then
        return best
    end

    for _, textObject in ipairs(findTextObjects(tabName, false)) do
        local button = nearestButton(textObject)
        if button then
            return button
        end
    end

    return nil
end

local function openTab(tabName)
    if currentTab == tabName then
        return true
    end

    local button = findTabButton(tabName)
    if not button then
        return false
    end

    local worked = pressButton(button)
    if worked then
        currentTab = tabName
        task.wait(touchMode and 0.06 or 0.035)
        refreshTextIndex()
    end

    return worked
end

local function tabHintFor(name)
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
        or string.find(text, "black flash", 1, true) then
        return "Auto"
    end

    return "Main"
end

local function findRowButton(label, wanted)
    if not label then
        return nil
    end

    local direct = nearestButton(label)
    if direct then
        return direct
    end

    local row = directFrameRow(label)
    if not row then
        return nil
    end

    local labelCenterY = label.AbsolutePosition.Y + label.AbsoluteSize.Y / 2
    local labelRight = label.AbsolutePosition.X + label.AbsoluteSize.X
    local best = nil
    local bestScore = -math.huge

    for _, candidate in ipairs(row:GetDescendants()) do
        if candidate:IsA("GuiButton") then
            local centerY = candidate.AbsolutePosition.Y + candidate.AbsoluteSize.Y / 2
            local score = -math.abs(centerY - labelCenterY) * 5

            if candidate.AbsolutePosition.X >= labelRight - 5 then
                score = score + 180
            end

            if candidate.Parent == row then
                score = score + 80
            end

            if hasExactButtonText(candidate, wanted) then
                score = score + 300
            end

            if candidate.AbsoluteSize.X >= candidate.AbsoluteSize.Y then
                score = score + 30
            end

            if score > bestScore then
                best = candidate
                bestScore = score
            end
        end
    end

    return best
end

local function findControl(name, prefix)
    local matches = findTextObjects(name, prefix == true)

    for _, label in ipairs(matches) do
        local button = findRowButton(label, name)
        if button then
            return button, label
        end
    end

    local hint = tabHintFor(name)
    if openTab(hint) then
        matches = findTextObjects(name, prefix == true)
        for _, label in ipairs(matches) do
            local button = findRowButton(label, name)
            if button then
                return button, label
            end
        end
    end

    return nil, matches[1]
end

local function colorLooksOn(color)
    local r = color.R
    local g = color.G
    local b = color.B
    return g > 0.45 and g > r * 1.15 and g >= b * 0.75
end

local function findToggleKnob(button)
    if not button then
        return nil
    end

    local best = nil
    local bestScore = -math.huge

    for _, object in ipairs(button:GetDescendants()) do
        if object:IsA("GuiObject") then
            local width = object.AbsoluteSize.X
            local height = object.AbsoluteSize.Y

            if width >= 8 and width <= 60 and height >= 8 and height <= 60 then
                local score = 0
                score = score - math.abs(width - height) * 3

                local name = string.lower(object.Name)
                if string.find(name, "knob", 1, true) then
                    score = score + 200
                end
                if string.find(name, "circle", 1, true) then
                    score = score + 100
                end

                local color = object.BackgroundColor3
                if color.R > 0.7 and color.G > 0.7 and color.B > 0.7 then
                    score = score + 80
                end

                if score > bestScore then
                    best = object
                    bestScore = score
                end
            end
        end
    end

    if bestScore < 20 then
        return nil
    end

    return best
end

local function readToggleState(button)
    if not button then
        return nil
    end

    local knob = findToggleKnob(button)
    if knob and button.AbsoluteSize.X > 0 then
        local knobCenter = knob.AbsolutePosition.X + knob.AbsoluteSize.X / 2
        local buttonCenter = button.AbsolutePosition.X + button.AbsoluteSize.X / 2
        return knobCenter > buttonCenter
    end

    if colorLooksOn(button.BackgroundColor3) then
        return true
    end

    for _, object in ipairs(button:GetDescendants()) do
        if object:IsA("Frame") or object:IsA("ImageLabel") or object:IsA("ImageButton") then
            if colorLooksOn(object.BackgroundColor3) then
                return true
            end
        end
    end

    return nil
end

local function enableToggle(name)
    local button = findControl(name, false)
    if not button then
        return false
    end

    local state = readToggleState(button)
    if state == true then
        return true
    end

    if pressButton(button) then
        return true
    end

    if openTab(tabHintFor(name)) then
        local retryButton = findControl(name, false)
        if retryButton then
            local retryState = readToggleState(retryButton)
            if retryState == true then
                return true
            end
            return pressButton(retryButton)
        end
    end

    return false
end

local function readSliderNumber(label)
    if not label then
        return nil
    end

    local value = string.match(tostring(label.Text or ""), ":%s*([-+]?%d+%.?%d*)")
        or string.match(tostring(label.Text or ""), "[-+]?%d+%.?%d*")

    return value and tonumber(value) or nil
end

local function findSliderRowAndBar(name)
    local labels = findTextObjects(name, true)

    for _, label in ipairs(labels) do
        local row = directFrameRow(label)
        if row then
            local bestBar = nil
            local bestScore = -math.huge
            local labelCenterY = label.AbsolutePosition.Y + label.AbsoluteSize.Y / 2

            -- The slider bar must be a direct Frame sibling of the TextLabel.
            for _, child in ipairs(row:GetChildren()) do
                if child:IsA("Frame") and child ~= label then
                    local width = child.AbsoluteSize.X
                    local height = child.AbsoluteSize.Y
                    local centerY = child.AbsolutePosition.Y + height / 2

                    if width >= 40 and height >= 2 and height <= 45 and width >= height * 2.5 then
                        local score = width - height * 2

                        if centerY >= labelCenterY then
                            score = score + 180
                        end

                        if child.Name == "Frame" then
                            score = score + 40
                        end

                        if score > bestScore then
                            bestBar = child
                            bestScore = score
                        end
                    end
                end
            end

            if bestBar then
                return label, row, bestBar
            end
        end
    end

    return nil, nil, nil
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
    local objectTop = object.AbsolutePosition.Y
    local objectBottom = objectTop + object.AbsoluteSize.Y
    local viewportTop = scrolling.AbsolutePosition.Y
    local viewportBottom = viewportTop + scrolling.AbsoluteWindowSize.Y

    if objectTop < viewportTop + 8 or objectBottom > viewportBottom - 8 then
        local offset = objectTop - viewportTop - 20
        local newY = math.max(0, oldPosition.Y + offset)
        scrolling.CanvasPosition = Vector2.new(oldPosition.X, newY)
        task.wait(touchMode and 0.05 or 0.025)
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

local function releaseAllInput(x, y)
    x = math.floor((x or 0) + 0.5)
    y = math.floor((y or 0) + 0.5)

    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
    end)

    pcall(function()
        VirtualInputManager:SendTouchEvent(0, 2, x, y)
    end)

    if type(mouse1release) == "function" then
        pcall(mouse1release)
    end
end

local function mouseDrag(startX, y, finishX)
    startX = math.floor(startX + 0.5)
    finishX = math.floor(finishX + 0.5)
    y = math.floor(y + 0.5)

    local held = false
    local ok = pcall(function()
        VirtualInputManager:SendMouseMoveEvent(startX, y, game)
        task.wait(0.01)
        VirtualInputManager:SendMouseButtonEvent(startX, y, 0, true, game, 1)
        held = true
        task.wait(0.015)

        for step = 1, 4 do
            local x = startX + (finishX - startX) * (step / 4)
            VirtualInputManager:SendMouseMoveEvent(math.floor(x + 0.5), y, game)
            task.wait(0.012)
        end

        VirtualInputManager:SendMouseButtonEvent(finishX, y, 0, false, game, 1)
        held = false
    end)

    if held then
        releaseAllInput(finishX, y)
    end

    return ok
end

local function touchDrag(startX, y, finishX)
    startX = math.floor(startX + 0.5)
    finishX = math.floor(finishX + 0.5)
    y = math.floor(y + 0.5)

    local held = false
    local ok = pcall(function()
        VirtualInputManager:SendTouchEvent(0, 0, startX, y)
        held = true
        task.wait(0.02)

        for step = 1, 4 do
            local x = startX + (finishX - startX) * (step / 4)
            VirtualInputManager:SendTouchEvent(0, 1, math.floor(x + 0.5), y)
            task.wait(0.015)
        end

        VirtualInputManager:SendTouchEvent(0, 2, finishX, y)
        held = false
    end)

    if held then
        releaseAllInput(finishX, y)
    end

    return ok
end

local sliderRanges = {
    [keyify("Auto Block Range")] = {0, 30},
    [keyify("Auto Counter Range")] = {0, 30},
    [keyify("Click Delay")] = {0, 30}
}

local function readNumberMetadata(objects, names)
    for _, object in ipairs(objects) do
        if object then
            for _, name in ipairs(names) do
                local attribute = nil
                pcall(function()
                    attribute = object:GetAttribute(name)
                end)

                if type(attribute) == "number" then
                    return attribute
                end

                local valueObject = object:FindFirstChild(name, true)
                if valueObject and (valueObject:IsA("NumberValue") or valueObject:IsA("IntValue")) then
                    return valueObject.Value
                end
            end
        end
    end

    return nil
end

local function getSliderRange(name, row, bar)
    local objects = {bar, row}

    local minimum = readNumberMetadata(objects, {
        "Min", "Minimum", "MinValue", "MinimumValue", "LowerBound"
    })

    local maximum = readNumberMetadata(objects, {
        "Max", "Maximum", "MaxValue", "MaximumValue", "UpperBound"
    })

    if type(minimum) == "number" and type(maximum) == "number" and maximum > minimum then
        return minimum, maximum
    end

    local fallback = sliderRanges[keyify(name)]
    if fallback then
        return fallback[1], fallback[2]
    end

    return 0, 30
end

local function waitForSliderValue(label, oldValue, timeout)
    local started = os.clock()
    local last = readSliderNumber(label)

    while os.clock() - started < timeout do
        local current = readSliderNumber(label)
        if current ~= nil then
            last = current
            if oldValue == nil or current ~= oldValue then
                return current
            end
        end
        task.wait(0.015)
    end

    return last
end

local function setSlider(name, wanted)
    if type(wanted) ~= "number" then
        return false
    end

    openTab(tabHintFor(name))

    local label, row, bar = findSliderRowAndBar(name)
    if not label or not row or not bar then
        refreshTextIndex()
        label, row, bar = findSliderRowAndBar(name)
    end

    if not label or not row or not bar then
        return false
    end

    local minimum, maximum = getSliderRange(name, row, bar)
    wanted = math.clamp(wanted, minimum, maximum)

    local currentValue = readSliderNumber(label)
    if currentValue == wanted then
        return true
    end

    local scrolling, oldCanvasPosition = bringIntoView(row)

    local left = bar.AbsolutePosition.X + 3
    local right = bar.AbsolutePosition.X + bar.AbsoluteSize.X - 3
    local y = bar.AbsolutePosition.Y + bar.AbsoluteSize.Y / 2

    if right - left < 20 then
        restoreScroll(scrolling, oldCanvasPosition)
        return false
    end

    local function valueToX(value)
        local ratio = (value - minimum) / (maximum - minimum)
        return left + math.clamp(ratio, 0, 1) * (right - left)
    end

    local startX = valueToX(currentValue or ((minimum + maximum) / 2))
    local targetX = valueToX(wanted)

    -- First try a normal mouse drag because the same UI code is used on desktop
    -- and most mobile executors translate these events more reliably than touch.
    mouseDrag(startX, y, targetX)
    local newValue = waitForSliderValue(label, currentValue, touchMode and 0.18 or 0.12)

    -- A direct click helps sliders which update from the clicked track position.
    if newValue ~= wanted then
        mouseClickAt(targetX, y)
        newValue = waitForSliderValue(label, newValue, touchMode and 0.16 or 0.1)
    end

    -- Touch is only a fallback on mobile so Delta is not flooded with touch events.
    if touchMode and newValue ~= wanted then
        local liveStartX = valueToX(newValue or currentValue or ((minimum + maximum) / 2))
        touchDrag(liveStartX, y, targetX)
        newValue = waitForSliderValue(label, newValue, 0.2)
    end

    -- At most two feedback corrections. No endless slider loop.
    for _ = 1, 2 do
        if newValue == wanted or newValue == nil then
            break
        end

        local liveX = valueToX(newValue)
        local correctionX = math.clamp(
            liveX + ((wanted - newValue) / (maximum - minimum)) * (right - left),
            left,
            right
        )

        if math.abs(correctionX - liveX) < 1 then
            break
        end

        local previous = newValue
        mouseDrag(liveX, y, correctionX)
        newValue = waitForSliderValue(label, previous, touchMode and 0.16 or 0.1)

        if newValue == previous then
            break
        end
    end

    releaseAllInput(targetX, y)
    restoreScroll(scrolling, oldCanvasPosition)

    return readSliderNumber(label) == wanted
end

local function sendKeybind(name, value)
    local keyName = tostring(value or "")
    if keyName == "" or string.lower(keyName) == "select" then
        return false
    end

    local button = findControl(name, true)
    if not button then
        return false
    end

    if not pressButton(button) then
        return false
    end

    task.wait(0.025)

    local keyCode = Enum.KeyCode[keyName]
    if not keyCode then
        return false
    end

    pcall(function()
        VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
        task.wait(0.015)
        VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
    end)

    return true
end

local function selectOption(configName, optionName)
    local option = tostring(optionName or "")
    local lowered = string.lower(option)

    if option == "" or lowered == "select" or lowered == "none" then
        return false
    end

    if string.find(string.lower(configName), "keybind", 1, true) then
        return sendKeybind(configName, option)
    end

    local control = findControl(configName, true)
    if control then
        pressButton(control)
        task.wait(0.03)
        refreshTextIndex()
    end

    local options = findTextObjects(option, false)
    for _, textObject in ipairs(options) do
        local button = nearestButton(textObject) or findRowButton(textObject, option)
        if button and pressButton(button) then
            return true
        end
    end

    local hint = tabHintFor(configName)
    if openTab(hint) then
        local retryControl = findControl(configName, true)
        if retryControl then
            pressButton(retryControl)
            task.wait(0.03)
            refreshTextIndex()
        end

        options = findTextObjects(option, false)
        for _, textObject in ipairs(options) do
            local button = nearestButton(textObject) or findRowButton(textObject, option)
            if button and pressButton(button) then
                return true
            end
        end
    end

    return false
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

-- Wait until the script UI has created some text controls.
local readyStarted = os.clock()
repeat
    refreshTextIndex()
    if #textEntries > 20 then
        break
    end
    task.wait(0.05)
until os.clock() - readyStarted >= 5

local applied = 0
local missing = 0

-- True booleans are the only toggles enabled.
-- False booleans are intentionally left alone.
local booleanNames = {}
local stringValues = {}
local tableValues = {}
local numberValues = {}

for configName, configValue in pairs(parsedConfig) do
    if configValue == true then
        table.insert(booleanNames, tostring(configName))
    elseif type(configValue) == "number" then
        table.insert(numberValues, {
            name = tostring(configName),
            value = configValue
        })
    elseif type(configValue) == "string" then
        table.insert(stringValues, {
            name = tostring(configName),
            value = configValue
        })
    elseif type(configValue) == "table" then
        table.insert(tableValues, {
            name = tostring(configName),
            value = configValue
        })
    end
end

table.sort(booleanNames)
table.sort(numberValues, function(a, b) return a.name < b.name end)
table.sort(stringValues, function(a, b) return a.name < b.name end)
table.sort(tableValues, function(a, b) return a.name < b.name end)

for _, configName in ipairs(booleanNames) do
    if enableToggle(configName) then
        applied = applied + 1
    else
        missing = missing + 1
    end
    task.wait(touchMode and 0.012 or 0.006)
end

for _, item in ipairs(tableValues) do
    local worked = false
    for _, option in pairs(item.value) do
        if selectOption(item.name, option) then
            worked = true
        end
        task.wait(touchMode and 0.012 or 0.006)
    end

    if worked then
        applied = applied + 1
    else
        missing = missing + 1
    end
end

for _, item in ipairs(stringValues) do
    local lowered = string.lower(item.value)
    if item.value ~= "" and lowered ~= "select" and lowered ~= "none" then
        if selectOption(item.name, item.value) then
            applied = applied + 1
        else
            missing = missing + 1
        end
        task.wait(touchMode and 0.012 or 0.006)
    end
end

-- Numbers are treated as sliders only when a matching "Name: value" label exists.
-- This avoids touching unrelated text boxes such as empty amount fields.
for _, item in ipairs(numberValues) do
    refreshTextIndex()
    local sliderLabel = findTextObjects(item.name, true)[1]

    if sliderLabel and readSliderNumber(sliderLabel) ~= nil then
        if setSlider(item.name, item.value) then
            applied = applied + 1
        else
            missing = missing + 1
        end
    end

    task.wait(touchMode and 0.015 or 0.008)
end

notify("Applied " .. tostring(applied) .. " config settings")
