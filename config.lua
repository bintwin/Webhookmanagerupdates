-- Search based config loader
-- Premium and free use the same text search system
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

local enableCustomConfig = env.enablecustomconfig
if enableCustomConfig == nil then
    enableCustomConfig = true
end

if not enableCustomConfig then
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

if startupWait > 0 then
    task.wait(startupWait)
end

local touchMode = UserInputService.TouchEnabled
local textIndex = {}

local function normalize(value)
    local text = string.lower(tostring(value or ""))
    text = string.gsub(text, "[%c]", " ")
    text = string.gsub(text, "%s+", " ")
    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    return text
end

local function removeOnly(value)
    return string.gsub(normalize(value), "%s+only$", "")
end

local function sameText(a, b)
    local left = removeOnly(a)
    local right = removeOnly(b)
    return left == right
end

local function startsWithSetting(actual, wanted)
    local text = normalize(actual)
    local setting = normalize(wanted)
    return text == setting
        or string.sub(text, 1, #setting + 1) == setting .. ":"
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

local function scanText()
    textIndex = {}

    local descendants = playerGui:GetDescendants()
    for index, object in ipairs(descendants) do
        if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
            local text = tostring(object.Text or "")
            if text ~= "" then
                table.insert(textIndex, {
                    object = object,
                    text = text,
                    visible = isVisible(object)
                })
            end
        end

        if touchMode and index % 300 == 0 then
            task.wait()
        end
    end
end

local function findTextMatches(wanted, prefix, visibleOnly)
    local matches = {}

    for _, entry in ipairs(textIndex) do
        local matched = prefix
            and startsWithSetting(entry.text, wanted)
            or sameText(entry.text, wanted)

        if matched and entry.object and entry.object.Parent then
            if not visibleOnly or isVisible(entry.object) then
                local score = 0

                if isVisible(entry.object) then
                    score = score + 1000
                end
                if entry.object:IsA("TextButton") then
                    score = score + 150
                end
                if sameText(entry.text, wanted) then
                    score = score + 100
                end

                table.insert(matches, {
                    object = entry.object,
                    score = score
                })
            end
        end
    end

    table.sort(matches, function(a, b)
        return a.score > b.score
    end)

    local result = {}
    for _, match in ipairs(matches) do
        table.insert(result, match.object)
    end

    return result
end

local function nearestGuiButton(object, maxDepth)
    local current = object
    local depth = 0

    while current and current ~= game and depth <= (maxDepth or 6) do
        if current:IsA("GuiButton") then
            return current
        end
        current = current.Parent
        depth = depth + 1
    end

    return nil
end

local function buttonText(button)
    if not button then
        return ""
    end

    if button:IsA("TextButton") and tostring(button.Text or "") ~= "" then
        return button.Text
    end

    for _, child in ipairs(button:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") then
            local text = tostring(child.Text or "")
            if text ~= "" then
                return text
            end
        end
    end

    return ""
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
        local ok = pcall(function()
            connection:Fire()
        end)
        if ok then
            return true
        end
    end

    return false
end

local function rawMouseClick(x, y)
    x = math.floor(x + 0.5)
    y = math.floor(y + 0.5)

    return pcall(function()
        VirtualInputManager:SendMouseMoveEvent(x, y, game)
        task.wait(0.008)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
        task.wait(0.012)
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
    return rawMouseClick(x, y)
end

local function findExactTabButton(tabName)
    local best = nil
    local bestScore = -math.huge

    for _, object in ipairs(playerGui:GetDescendants()) do
        if object:IsA("GuiButton") and sameText(buttonText(object), tabName) then
            local score = 0

            if isVisible(object) then
                score = score + 1000
            end

            local centerX = object.AbsolutePosition.X + object.AbsoluteSize.X / 2
            score = score - centerX

            local current = object.Parent
            local depth = 0
            while current and current ~= game and depth < 6 do
                if current:IsA("ScrollingFrame") then
                    score = score + 300
                    break
                end
                current = current.Parent
                depth = depth + 1
            end

            if score > bestScore then
                best = object
                bestScore = score
            end
        end
    end

    return best
end

local function openTab(tabName)
    local button = findExactTabButton(tabName)
    if not button then
        return false
    end

    if not pressGuiButton(button) then
        return false
    end

    task.wait(touchMode and 0.075 or 0.045)
    scanText()
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

local function findSmallRow(label)
    local current = label and label.Parent
    local depth = 0

    while current and current ~= game and depth < 4 do
        if current:IsA("Frame") then
            local width = current.AbsoluteSize.X
            local height = current.AbsoluteSize.Y

            if width >= math.max(80, label.AbsoluteSize.X)
                and height >= math.max(20, label.AbsoluteSize.Y)
                and height <= 130 then
                return current
            end
        end

        current = current.Parent
        depth = depth + 1
    end

    return nil
end

local function findToggleButton(name)
    local matches = findTextMatches(name, false, true)

    for _, label in ipairs(matches) do
        if label:IsA("GuiButton") then
            return label
        end

        local ancestorButton = nearestGuiButton(label, 5)
        if ancestorButton then
            return ancestorButton
        end

        local row = findSmallRow(label)
        if row then
            local labelCenterY = label.AbsolutePosition.Y + label.AbsoluteSize.Y / 2
            local labelRight = label.AbsolutePosition.X + label.AbsoluteSize.X
            local best = nil
            local bestScore = -math.huge

            for _, candidate in ipairs(row:GetDescendants()) do
                if candidate:IsA("GuiButton") and isVisible(candidate) then
                    local centerY = candidate.AbsolutePosition.Y + candidate.AbsoluteSize.Y / 2
                    local verticalDistance = math.abs(centerY - labelCenterY)

                    if verticalDistance <= math.max(16, row.AbsoluteSize.Y * 0.45) then
                        local score = -verticalDistance * 8

                        if candidate.AbsolutePosition.X >= labelRight - 8 then
                            score = score + 350
                        end

                        if label:IsDescendantOf(candidate) then
                            score = score + 900
                        end

                        if candidate.Parent == row then
                            score = score + 100
                        end

                        if candidate.AbsoluteSize.X <= 180 and candidate.AbsoluteSize.Y <= 80 then
                            score = score + 80
                        end

                        if score > bestScore then
                            best = candidate
                            bestScore = score
                        end
                    end
                end
            end

            if best and bestScore >= 0 then
                return best
            end
        end
    end

    return nil
end

local function colorLooksEnabled(color)
    return color.G > 0.45
        and color.G > color.R * 1.12
        and color.G >= color.B * 0.72
end

local function readBooleanMetadata(objects)
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

    return nil
end

local function readToggleState(button)
    if not button then
        return nil
    end

    local metadata = readBooleanMetadata({button, button.Parent})
    if metadata ~= nil then
        return metadata
    end

    if colorLooksEnabled(button.BackgroundColor3) then
        return true
    end

    local bestKnob = nil
    local bestKnobScore = -math.huge

    for _, object in ipairs(button:GetDescendants()) do
        if object:IsA("GuiObject") then
            if colorLooksEnabled(object.BackgroundColor3) then
                return true
            end

            local width = object.AbsoluteSize.X
            local height = object.AbsoluteSize.Y

            if width >= 7 and width <= 60 and height >= 7 and height <= 60 then
                local score = -math.abs(width - height) * 3
                local name = string.lower(object.Name)

                if string.find(name, "knob", 1, true) then
                    score = score + 200
                end
                if string.find(name, "circle", 1, true) then
                    score = score + 120
                end
                if object.BackgroundColor3.R > 0.72
                    and object.BackgroundColor3.G > 0.72
                    and object.BackgroundColor3.B > 0.72 then
                    score = score + 80
                end

                if score > bestKnobScore then
                    bestKnob = object
                    bestKnobScore = score
                end
            end
        end
    end

    if bestKnob and bestKnobScore >= 20 and button.AbsoluteSize.X > 0 then
        local knobCenter = bestKnob.AbsolutePosition.X + bestKnob.AbsoluteSize.X / 2
        local buttonCenter = button.AbsolutePosition.X + button.AbsoluteSize.X / 2
        return knobCenter > buttonCenter
    end

    return nil
end

local function enableToggle(name)
    local button = findToggleButton(name)
    if not button then
        return false
    end

    local state = readToggleState(button)
    if state == true then
        return true
    end

    return pressGuiButton(button)
end

local function readSliderNumber(label)
    if not label then
        return nil
    end

    local text = tostring(label.Text or "")
    local value = string.match(text, ":%s*([-+]?%d+%.?%d*)")
        or string.match(text, "([-+]?%d+%.?%d*)")

    return value and tonumber(value) or nil
end

local function descendantDepth(object, ancestor)
    local current = object
    local depth = 0

    while current and current ~= game do
        if current == ancestor then
            return depth
        end
        current = current.Parent
        depth = depth + 1
    end

    return math.huge
end

local function findSliderSurface(name)
    local matches = findTextMatches(name, true, true)

    for _, label in ipairs(matches) do
        if readSliderNumber(label) ~= nil then
            local surface = nil

            if label.Parent and label.Parent:IsA("Frame") then
                surface = label.Parent
            end

            if surface and surface.AbsoluteSize.X >= 80 and surface.AbsoluteSize.Y >= 12 then
                return label, surface
            end

            local current = label.Parent
            local depth = 0
            while current and current ~= game and depth < 3 do
                if current:IsA("Frame")
                    and current.AbsoluteSize.X >= 80
                    and current.AbsoluteSize.Y >= 12
                    and current.AbsoluteSize.Y <= 150 then
                    return label, current
                end

                current = current.Parent
                depth = depth + 1
            end
        end
    end

    return nil, nil
end

local function horizontalFrames(surface, label)
    local frames = {}
    local labelCenterY = label.AbsolutePosition.Y + label.AbsoluteSize.Y / 2

    for _, object in ipairs(surface:GetDescendants()) do
        if object:IsA("Frame") and descendantDepth(object, surface) <= 2 then
            local width = object.AbsoluteSize.X
            local height = object.AbsoluteSize.Y
            local centerY = object.AbsolutePosition.Y + height / 2

            if width >= 8
                and height >= 2
                and height <= 40
                and width >= height * 2.5
                and centerY >= labelCenterY - 6 then

                table.insert(frames, object)
            end
        end
    end

    table.sort(frames, function(a, b)
        local aScore = a.AbsoluteSize.X - a.AbsoluteSize.Y * 2
        local bScore = b.AbsoluteSize.X - b.AbsoluteSize.Y * 2

        if a.Parent == surface then
            aScore = aScore + 60
        end
        if b.Parent == surface then
            bScore = bScore + 60
        end

        return aScore > bScore
    end)

    return frames
end

local function sliderGeometry(label, surface, currentValue, minimum, maximum)
    local frames = horizontalFrames(surface, label)
    local guide = frames[1]

    local surfaceLeft = surface.AbsolutePosition.X
    local surfaceRight = surfaceLeft + surface.AbsoluteSize.X
    local surfaceWidth = surface.AbsoluteSize.X

    local left = surfaceLeft + 4
    local right = surfaceRight - 4
    local y = surface.AbsolutePosition.Y + surface.AbsoluteSize.Y / 2

    if guide then
        y = guide.AbsolutePosition.Y + guide.AbsoluteSize.Y / 2

        if guide.AbsoluteSize.X >= surfaceWidth * 0.62 then
            left = guide.AbsolutePosition.X + 2
            right = guide.AbsolutePosition.X + guide.AbsoluteSize.X - 2
        else
            local leftPadding = math.max(2, guide.AbsolutePosition.X - surfaceLeft)
            left = surfaceLeft + leftPadding
            right = surfaceRight - leftPadding
        end
    else
        local labelBottom = label.AbsolutePosition.Y + label.AbsoluteSize.Y
        if labelBottom < surface.AbsolutePosition.Y + surface.AbsoluteSize.Y - 4 then
            y = math.max(y, labelBottom + 5)
        end
    end

    if right - left < 30 then
        return nil
    end

    local ratio = 0.5
    if maximum > minimum and type(currentValue) == "number" then
        ratio = math.clamp((currentValue - minimum) / (maximum - minimum), 0, 1)
    end

    local currentX = left + ratio * (right - left)
    local bestFill = nil
    local bestFillScore = -math.huge

    for _, frame in ipairs(frames) do
        local frameLeft = frame.AbsolutePosition.X
        local frameRight = frameLeft + frame.AbsoluteSize.X
        local frameCenterY = frame.AbsolutePosition.Y + frame.AbsoluteSize.Y / 2

        if frameLeft >= left - 10
            and frameLeft <= left + 18
            and frameRight >= left
            and frameRight <= right + 10
            and math.abs(frameCenterY - y) <= 12 then

            local ratioWidth = frame.AbsoluteSize.X / math.max(1, right - left)
            local score = 0

            if ratioWidth < 0.98 then
                score = score + 150
            end
            if colorLooksEnabled(frame.BackgroundColor3) then
                score = score + 180
            end
            if frame.Parent == surface then
                score = score + 60
            end

            score = score - math.abs(frameCenterY - y) * 4

            if score > bestFillScore then
                bestFill = frame
                bestFillScore = score
            end
        end
    end

    if bestFill and bestFillScore >= 80 then
        currentX = math.clamp(
            bestFill.AbsolutePosition.X + bestFill.AbsoluteSize.X,
            left,
            right
        )
        y = bestFill.AbsolutePosition.Y + bestFill.AbsoluteSize.Y / 2
    end

    return {
        left = left,
        right = right,
        y = y,
        currentX = currentX
    }
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

local function sliderRange(name, label, surface)
    local objects = {surface, label, surface.Parent}

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

local function releaseInput(x, y)
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

local function executorMouseDrag(startX, y, finishX)
    if type(mousemoveabs) ~= "function"
        or type(mouse1press) ~= "function"
        or type(mouse1release) ~= "function" then
        return false
    end

    local held = false
    local ok = pcall(function()
        mousemoveabs(math.floor(startX + 0.5), math.floor(y + 0.5))
        task.wait(0.015)
        mouse1press()
        held = true
        task.wait(0.02)

        for step = 1, 6 do
            local x = startX + (finishX - startX) * (step / 6)
            mousemoveabs(math.floor(x + 0.5), math.floor(y + 0.5))
            task.wait(0.012)
        end

        mouse1release()
        held = false
    end)

    if held then
        releaseInput(finishX, y)
    end

    return ok
end

local function virtualMouseDrag(startX, y, finishX)
    local held = false
    local ok = pcall(function()
        VirtualInputManager:SendMouseMoveEvent(
            math.floor(startX + 0.5),
            math.floor(y + 0.5),
            game
        )
        task.wait(0.015)

        VirtualInputManager:SendMouseButtonEvent(
            math.floor(startX + 0.5),
            math.floor(y + 0.5),
            0,
            true,
            game,
            1
        )
        held = true
        task.wait(0.02)

        for step = 1, 6 do
            local x = startX + (finishX - startX) * (step / 6)
            VirtualInputManager:SendMouseMoveEvent(
                math.floor(x + 0.5),
                math.floor(y + 0.5),
                game
            )
            task.wait(0.012)
        end

        VirtualInputManager:SendMouseButtonEvent(
            math.floor(finishX + 0.5),
            math.floor(y + 0.5),
            0,
            false,
            game,
            1
        )
        held = false
    end)

    if held then
        releaseInput(finishX, y)
    end

    return ok
end

local function virtualTouchDrag(startX, y, finishX)
    local held = false
    local ok = pcall(function()
        VirtualInputManager:SendTouchEvent(
            0,
            0,
            math.floor(startX + 0.5),
            math.floor(y + 0.5)
        )
        held = true
        task.wait(0.02)

        for step = 1, 6 do
            local x = startX + (finishX - startX) * (step / 6)
            VirtualInputManager:SendTouchEvent(
                0,
                1,
                math.floor(x + 0.5),
                math.floor(y + 0.5)
            )
            task.wait(0.014)
        end

        VirtualInputManager:SendTouchEvent(
            0,
            2,
            math.floor(finishX + 0.5),
            math.floor(y + 0.5)
        )
        held = false
    end)

    if held then
        releaseInput(finishX, y)
    end

    return ok
end

local function performDrag(startX, y, finishX, useTouch)
    startX = math.floor(startX + 0.5)
    finishX = math.floor(finishX + 0.5)
    y = math.floor(y + 0.5)

    if math.abs(finishX - startX) < 1 then
        return true
    end

    if not useTouch and executorMouseDrag(startX, y, finishX) then
        return true
    end

    if not useTouch and virtualMouseDrag(startX, y, finishX) then
        return true
    end

    if useTouch then
        return virtualTouchDrag(startX, y, finishX)
    end

    return false
end

local function waitForSliderChange(label, oldValue, timeout)
    local started = os.clock()
    local latest = readSliderNumber(label)

    while os.clock() - started < timeout do
        local value = readSliderNumber(label)
        if value ~= nil then
            latest = value
            if oldValue == nil or value ~= oldValue then
                return value
            end
        end
        task.wait(0.015)
    end

    return latest
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
    local viewportTop = scrolling.AbsolutePosition.Y
    local viewportBottom = viewportTop + scrolling.AbsoluteWindowSize.Y

    if top < viewportTop + 8 or bottom > viewportBottom - 8 then
        local newY = math.max(0, oldPosition.Y + top - viewportTop - 18)
        scrolling.CanvasPosition = Vector2.new(oldPosition.X, newY)
        task.wait(touchMode and 0.055 or 0.03)
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

local function setSlider(name, wanted)
    if type(wanted) ~= "number" then
        return false
    end

    local label, surface = findSliderSurface(name)
    if not label or not surface then
        return false
    end

    local minimum, maximum = sliderRange(name, label, surface)
    wanted = math.clamp(math.floor(wanted + 0.5), minimum, maximum)

    local currentValue = readSliderNumber(label)
    if currentValue == wanted then
        return true
    end

    local scrolling, oldPosition = bringIntoView(surface)
    task.wait(touchMode and 0.04 or 0.02)

    local geometry = sliderGeometry(label, surface, currentValue, minimum, maximum)
    if not geometry then
        restoreScroll(scrolling, oldPosition)
        return false
    end

    local function valueToX(value)
        local ratio = (value - minimum) / (maximum - minimum)
        return geometry.left + math.clamp(ratio, 0, 1) * (geometry.right - geometry.left)
    end

    local startX = geometry.currentX
    local targetX = valueToX(wanted)
    local oldValue = currentValue

    performDrag(startX, geometry.y, targetX, false)
    local newValue = waitForSliderChange(label, oldValue, touchMode and 0.24 or 0.16)

    if touchMode and newValue == oldValue then
        performDrag(startX, geometry.y, targetX, true)
        newValue = waitForSliderChange(label, oldValue, 0.24)
    end

    local pixelsPerUnit = nil
    if oldValue ~= nil
        and newValue ~= nil
        and newValue ~= oldValue
        and math.abs(targetX - startX) >= 1 then
        pixelsPerUnit = (targetX - startX) / (newValue - oldValue)
    end

    for _ = 1, 2 do
        if newValue == wanted or newValue == nil then
            break
        end

        local refreshedGeometry = sliderGeometry(label, surface, newValue, minimum, maximum)
        if not refreshedGeometry then
            break
        end

        local liveX = refreshedGeometry.currentX
        local correctionX

        if pixelsPerUnit and math.abs(pixelsPerUnit) < (geometry.right - geometry.left) then
            correctionX = liveX + (wanted - newValue) * pixelsPerUnit
        else
            correctionX = valueToX(wanted)
        end

        correctionX = math.clamp(correctionX, geometry.left, geometry.right)
        if math.abs(correctionX - liveX) < 1 then
            break
        end

        local previousValue = newValue
        performDrag(liveX, refreshedGeometry.y, correctionX, false)
        newValue = waitForSliderChange(
            label,
            previousValue,
            touchMode and 0.2 or 0.14
        )

        if newValue == previousValue then
            break
        end
    end

    releaseInput(targetX, geometry.y)
    restoreScroll(scrolling, oldPosition)
    return readSliderNumber(label) == wanted
end

local function findControlButton(name, prefix)
    local matches = findTextMatches(name, prefix == true, true)

    for _, textObject in ipairs(matches) do
        if textObject:IsA("GuiButton") then
            return textObject, textObject
        end

        local button = nearestGuiButton(textObject, 5)
        if button then
            return button, textObject
        end

        local row = findSmallRow(textObject)
        if row then
            local labelCenterY = textObject.AbsolutePosition.Y + textObject.AbsoluteSize.Y / 2
            local best = nil
            local bestScore = -math.huge

            for _, candidate in ipairs(row:GetDescendants()) do
                if candidate:IsA("GuiButton") and isVisible(candidate) then
                    local centerY = candidate.AbsolutePosition.Y + candidate.AbsoluteSize.Y / 2
                    local distance = math.abs(centerY - labelCenterY)

                    if distance <= math.max(16, row.AbsoluteSize.Y * 0.45) then
                        local score = -distance * 6
                        if candidate.Parent == row then
                            score = score + 80
                        end
                        if textObject:IsDescendantOf(candidate) then
                            score = score + 800
                        end
                        if score > bestScore then
                            best = candidate
                            bestScore = score
                        end
                    end
                end
            end

            if best and bestScore >= 0 then
                return best, textObject
            end
        end
    end

    return nil, matches[1]
end

local function findVisibleOptionButton(option, control)
    local matches = findTextMatches(option, false, true)
    local best = nil
    local bestScore = -math.huge

    for _, textObject in ipairs(matches) do
        local button = textObject:IsA("GuiButton")
            and textObject
            or nearestGuiButton(textObject, 5)

        if button and isVisible(button) then
            local score = 0

            if sameText(buttonText(button), option) then
                score = score + 500
            end

            if control then
                local controlX = control.AbsolutePosition.X + control.AbsoluteSize.X / 2
                local controlY = control.AbsolutePosition.Y + control.AbsoluteSize.Y / 2
                local buttonX = button.AbsolutePosition.X + button.AbsoluteSize.X / 2
                local buttonY = button.AbsolutePosition.Y + button.AbsoluteSize.Y / 2
                score = score - math.abs(buttonX - controlX) * 0.2
                score = score - math.abs(buttonY - controlY) * 0.2
            end

            if score > bestScore then
                best = button
                bestScore = score
            end
        end
    end

    return best
end

local function setKeybind(name, keyName)
    local keyCode = Enum.KeyCode[tostring(keyName or "")]
    if not keyCode then
        return false
    end

    local control = findControlButton(name, true)
    if not control or not pressGuiButton(control) then
        return false
    end

    task.wait(0.03)

    pcall(function()
        VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
        task.wait(0.015)
        VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
    end)

    return true
end

local function selectOption(name, option)
    option = tostring(option or "")
    local lowered = string.lower(option)

    if option == "" or lowered == "select" or lowered == "none" then
        return false
    end

    if string.find(string.lower(name), "keybind", 1, true) then
        return setKeybind(name, option)
    end

    local control = findControlButton(name, true)
    if control then
        pressGuiButton(control)
        task.wait(touchMode and 0.055 or 0.035)
        scanText()
    end

    local optionButton = findVisibleOptionButton(option, control)
    if optionButton then
        return pressGuiButton(optionButton)
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

local readyStarted = os.clock()
repeat
    scanText()
    if #textIndex >= 10 then
        break
    end
    task.wait(0.05)
until os.clock() - readyStarted >= 5

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
        local lowered = string.lower(value)
        if value ~= "" and lowered ~= "select" and lowered ~= "none" then
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
        scanText()

        table.sort(group.booleans, function(a, b) return a.name < b.name end)
        table.sort(group.numbers, function(a, b) return a.name < b.name end)
        table.sort(group.strings, function(a, b) return a.name < b.name end)
        table.sort(group.tables, function(a, b) return a.name < b.name end)

        for _, item in ipairs(group.booleans) do
            if enableToggle(item.name) then
                applied = applied + 1
            else
                skipped = skipped + 1
            end
            task.wait(touchMode and 0.012 or 0.006)
        end

        for _, item in ipairs(group.tables) do
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
                skipped = skipped + 1
            end
        end

        for _, item in ipairs(group.strings) do
            if selectOption(item.name, item.value) then
                applied = applied + 1
            else
                skipped = skipped + 1
            end
            task.wait(touchMode and 0.012 or 0.006)
        end

        for _, item in ipairs(group.numbers) do
            scanText()
            if setSlider(item.name, item.value) then
                applied = applied + 1
            else
                skipped = skipped + 1
            end
            task.wait(touchMode and 0.015 or 0.008)
        end
    end
end

notify("Applied " .. tostring(applied) .. " config settings")
