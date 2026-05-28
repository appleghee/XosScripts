--[[
    gui.lua — Defusal Hub GUI Library for Roblox
    ─────────────────────────────────────────────
    CS:GO / Counter Blox inspired UI library
    for building script hub interfaces.

    Components:
      Window, Tab, Section, Toggle, Button,
      Slider, Dropdown, Label, ColorPicker,
      Keybind, Notification, Watermark

    Author:  UI Designer
    Version: 2.0.0
    License: MIT
--]]

-- ====================================================================
-- SERVICES
-- ====================================================================
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")
local Players            = game:GetService("Players")
local CoreGui            = game:GetService("CoreGui")
local MarketplaceService = game:GetService("MarketplaceService")

-- ====================================================================
-- FONT HELPERS
-- ====================================================================
-- Attempt to load GothamSSm Bold (CS:GO style); fall back to SourceSans.
local FONT_BOLD, FONT_REGULAR

local ok
ok, FONT_BOLD = pcall(Font.new,
    "rbxasset://fonts/families/GothamSSm.json",
    Enum.FontWeight.Bold
)
if not ok then FONT_BOLD = Font.fromEnum(Enum.Font.SourceSansBold) end

ok, FONT_REGULAR = pcall(Font.new,
    "rbxasset://fonts/families/GothamSSm.json",
    Enum.FontWeight.Medium
)
if not ok then FONT_REGULAR = Font.fromEnum(Enum.Font.SourceSans) end

-- ====================================================================
-- THEME
-- ====================================================================
local Theme = {
    -- Core background
    Background          = Color3.fromRGB(13, 13, 13),
    BackgroundTrans     = 0.85,

    -- Surface & borders
    Section             = Color3.fromRGB(20, 20, 20),
    SectionBorder       = Color3.fromRGB(42, 42, 42),
    TitleBar            = Color3.fromRGB(10, 10, 10),
    AccentStripe        = Color3.fromRGB(255, 45, 85),

    -- Accent (dual-tone gradient support)
    Accent              = Color3.fromRGB(255, 45, 85),    -- #FF2D55
    Accent2             = Color3.fromRGB(0, 212, 255),    -- #00D4FF

    -- Text
    Text                = Color3.fromRGB(255, 255, 255),
    TextSecondary       = Color3.fromRGB(136, 136, 136),

    -- Toggle states
    ToggleOn            = Color3.fromRGB(0, 255, 136),    -- #00FF88
    ToggleOff           = Color3.fromRGB(255, 45, 85),    -- #FF2D55

    -- Dropdown
    DropdownBg          = Color3.fromRGB(30, 30, 30),
    DropdownBorder      = Color3.fromRGB(255, 45, 85),

    -- Scrollbar thumb
    ScrollBar           = Color3.fromRGB(255, 45, 85),

    -- Rainbow mode (optional — set to true to enable cycling accent)
    RainbowEnabled      = false,
    _rainbowHue         = 0,
}

-- ====================================================================
-- UTILITY FUNCTIONS
-- ====================================================================

-- Create a rounded rect Frame with stroke border + corner radius.
local function newFrame(name, parent, size, pos, bg, trans, radius)
    local f = Instance.new("Frame")
    f.Name = name
    f.Size = size or UDim2.fromOffset(100, 30)
    f.Position = pos or UDim2.fromOffset(0, 0)
    f.BackgroundColor3 = bg or Theme.Section
    f.BackgroundTransparency = trans or 0
    f.BorderSizePixel = 0
    f.ClipsDescendants = true
    f.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 4)
    corner.Parent = f

    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.SectionBorder
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = f

    return f
end

-- Create a TextLabel with default styling.
local function newLabel(name, parent, text, size, pos, font, txtColor, txtSize)
    local l = Instance.new("TextLabel")
    l.Name = name
    l.Text = text or ""
    l.Size = size or UDim2.fromOffset(100, 20)
    l.Position = pos or UDim2.fromOffset(0, 0)
    l.FontFace = font or FONT_BOLD
    l.TextColor3 = txtColor or Theme.Text
    l.TextSize = txtSize or 13
    l.BackgroundTransparency = 1
    l.BorderSizePixel = 0
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.Parent = parent
    return l
end

-- Create a UICorner helper.
local function addCorner(inst, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 4)
    c.Parent = inst
    return c
end

-- Create a UIStroke helper.
local function addStroke(inst, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.SectionBorder
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = inst
    return s
end

-- Tween a property on an instance.
local function tween(inst, props, time, style)
    local info = TweenInfo.new(time or 0.2, Enum.EasingStyle[style or "Quad"], Enum.EasingDirection.Out)
    local tw = TweenService:Create(inst, info, props)
    tw:Play()
    return tw
end

-- Make a frame draggable via a handle.
local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging = false
    local dragStart, startPos

    local function update(input)
        if not dragging then return end
        local delta = input.Position - dragStart
        local newPos = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
        frame.Position = newPos
    end

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    conn:Disconnect()
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            -- pass through for InputChanged handler below
        end
    end)

    UserInputService.InputChanged:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)
end

-- Resize handle at bottom-right corner.
local function makeResizable(windowFrame, minSize)
    minSize = minSize or Vector2.new(300, 250)

    local handle = Instance.new("Frame")
    handle.Name = "ResizeHandle"
    handle.Size = UDim2.fromOffset(12, 12)
    handle.Position = UDim2.new(1, -12, 1, -12)
    handle.BackgroundColor3 = Theme.Accent
    handle.BackgroundTransparency = 0.6
    handle.BorderSizePixel = 0
    handle.Parent = windowFrame

    addCorner(handle, 2)

    -- small triangle indicator
    local tri = Instance.new("ImageLabel")
    tri.Size = UDim2.fromOffset(8, 8)
    tri.Position = UDim2.fromOffset(2, 2)
    tri.BackgroundTransparency = 1
    tri.Image = "rbxasset://textures/ui/Graphic/WhiteCircle.png"
    tri.ImageColor3 = Theme.Text
    tri.ImageTransparency = 0.5
    tri.Rotation = 45
    tri.Parent = handle

    local resizing = false
    local resizeStart, startSize

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = true
            resizeStart = input.Position
            startSize = windowFrame.AbsoluteSize

            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    resizing = false
                    conn:Disconnect()
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input, gProcessed)
        if gProcessed then return end
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - resizeStart
            local newW = math.max(minSize.X, startSize.X + delta.X)
            local newH = math.max(minSize.Y, startSize.Y + delta.Y)
            windowFrame.Size = UDim2.fromOffset(newW, newH)
        end
    end)
end

-- ====================================================================
-- NOTIFICATION SYSTEM
-- ====================================================================
local NotificationService = {}
local notifContainer = nil

-- Lazy-create the notification container at bottom-right.
local function getNotifContainer(screenGui)
    if not notifContainer then
        notifContainer = Instance.new("Frame")
        notifContainer.Name = "NotificationContainer"
        notifContainer.Size = UDim2.fromOffset(300, 0)
        notifContainer.Position = UDim2.new(1, -320, 1, -60)
        notifContainer.BackgroundTransparency = 1
        notifContainer.BorderSizePixel = 0
        notifContainer.ClipsDescendants = false
        notifContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
        notifContainer.Parent = screenGui

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 8)
        layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = notifContainer
    end
    return notifContainer
end

--- Show a notification popup.
--- @param title   string  Bold title text
--- @param desc    string  Description text
--- @param duration number  Seconds before auto-dismiss (default: 5)
function NotificationService:Notify(title, desc, duration)
    duration = duration or 5

    -- Find the ScreenGui from an active window, or use CoreGui
    local sg = CoreGui:FindFirstChild("DefusalHub")
            or (Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerGui"))
    if not sg then return end

    local container = getNotifContainer(sg)

    -- Card
    local card = Instance.new("Frame")
    card.Name = "Notification"
    card.Size = UDim2.fromOffset(280, 0)
    card.Position = UDim2.fromOffset(0, 0)
    card.BackgroundColor3 = Theme.Section
    card.BackgroundTransparency = 0.1
    card.BorderSizePixel = 0
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.Parent = container

    addCorner(card, 6)
    addStroke(card, Theme.Accent, 1)

    -- Accent left bar
    local bar = Instance.new("Frame")
    bar.Name = "AccentBar"
    bar.Size = UDim2.fromOffset(3, 0)
    bar.Position = UDim2.fromOffset(0, 0)
    bar.BackgroundColor3 = Theme.Accent
    bar.BorderSizePixel = 0
    bar.AutomaticSize = Enum.AutomaticSize.Y
    bar.Parent = card

    -- Title
    newLabel("Title", card, title,
        UDim2.fromOffset(250, 22),
        UDim2.fromOffset(12, 8),
        FONT_BOLD, Theme.Text, 14)

    -- Description
    local descLabel = newLabel("Desc", card, desc,
        UDim2.fromOffset(250, 0),
        UDim2.fromOffset(12, 30),
        FONT_REGULAR, Theme.TextSecondary, 12)
    descLabel.TextWrapped = true
    descLabel.AutomaticSize = Enum.AutomaticSize.Y

    -- Adjust card size after layout
    card.Size = UDim2.fromOffset(280, descLabel.AbsoluteSize.Y + 46)

    -- Slide in from right
    card.Position = UDim2.fromOffset(320, 0)
    tween(card, {Position = UDim2.fromOffset(0, 0)}, 0.35, "Quad")

    -- Animate progress bar
    local progress = Instance.new("Frame")
    progress.Name = "Progress"
    progress.Size = UDim2.fromScale(1, 2)
    progress.Position = UDim2.fromScale(0, 1)
    progress.AnchorPoint = Vector2.new(0, 1)
    progress.BackgroundColor3 = Theme.Accent
    progress.BackgroundTransparency = 0.3
    progress.BorderSizePixel = 0
    progress.Parent = card

    -- Dismiss after duration
    task.spawn(function()
        task.wait(duration - 0.4)
        -- Shrink progress
        tween(progress, {Size = UDim2.fromScale(0, 2)}, 0.4, "Quad")
        task.wait(0.4)
        -- Slide out
        tween(card, {
            Position = UDim2.fromOffset(320, 0),
            BackgroundTransparency = 1
        }, 0.3, "Quad").Completed:Wait()
        card:Destroy()
    end)
end

-- ====================================================================
-- WATERMARK SYSTEM
-- ====================================================================
local WatermarkInstance = nil
local watermarkLabel = nil
local fpsValues = {}

--- Show the on-screen watermark (script name + FPS).
--- @param text string  Watermark text (default: "DEFUSAL HUB")
function NotificationService:Watermark(text)
    text = text or "DEFUSAL HUB"

    -- Destroy existing
    if WatermarkInstance then
        WatermarkInstance:Destroy()
        WatermarkInstance = nil
        watermarkLabel = nil
    end

    local sg = CoreGui:FindFirstChild("DefusalHub")
            or (Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerGui"))
    if not sg then return end

    WatermarkInstance = Instance.new("Frame")
    WatermarkInstance.Name = "Watermark"
    WatermarkInstance.Size = UDim2.fromOffset(240, 28)
    WatermarkInstance.Position = UDim2.fromOffset(10, 10)
    WatermarkInstance.BackgroundColor3 = Theme.Background
    WatermarkInstance.BackgroundTransparency = 0.25
    WatermarkInstance.BorderSizePixel = 0
    WatermarkInstance.Parent = sg

    addCorner(WatermarkInstance, 4)
    addStroke(WatermarkInstance, Theme.Accent, 1)

    -- Left accent
    local bar = Instance.new("Frame")
    bar.Name = "Bar"
    bar.Size = UDim2.fromOffset(3, 1)
    bar.BackgroundColor3 = Theme.Accent
    bar.BorderSizePixel = 0
    bar.Parent = WatermarkInstance

    watermarkLabel = newLabel("Text", WatermarkInstance, text .. " | FPS: 0",
        UDim2.fromOffset(220, 28),
        UDim2.fromOffset(12, 0),
        FONT_BOLD, Theme.Text, 12)

    -- FPS counter loop
    local heartbeat
    heartbeat = RunService.Heartbeat:Connect(function(dt)
        if not WatermarkInstance then
            heartbeat:Disconnect()
            return
        end
        -- Rolling average over 30 frames
        table.insert(fpsValues, 1 / dt)
        if #fpsValues > 30 then table.remove(fpsValues, 1) end
        local avg = 0
        for _, v in ipairs(fpsValues) do avg = avg + v end
        avg = math.floor(avg / #fpsValues)
        watermarkLabel.Text = text .. " | FPS: " .. tostring(avg)
    end)

    -- Make watermark draggable
    makeDraggable(WatermarkInstance)
end

-- Merge NotificationService into GUI later
-- ====================================================================
-- COMPONENT CONSTRUCTORS (returned by Window / Tab)
-- ====================================================================

--
-- LABEL
--
local function newLabelComponent(parent, text, opts)
    opts = opts or {}
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -20, 0, opts.Height or 20)
    label.Position = UDim2.fromOffset(10, opts.Y or 0)
    label.Text = text or ""
    label.FontFace = opts.Font or FONT_BOLD
    label.TextColor3 = opts.Color or Theme.Text
    label.TextSize = opts.TextSize or 13
    label.TextXAlignment = Enum.TextXAlignment[opts.XAlign or "Left"]
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Parent = parent

    local obj = {
        Instance = label,
        _type = "Label",
    }
    function obj:SetText(t) label.Text = t end
    function obj:SetColor(c) label.TextColor3 = c end
    function obj:Destroy() label:Destroy() end
    return obj
end

--
-- BUTTON
--
local function newButton(parent, text, callback)
    callback = callback or function() end

    local btn = Instance.new("TextButton")
    btn.Name = "Button"
    btn.Size = UDim2.new(1, -20, 0, 30)
    btn.Position = UDim2.fromOffset(10, 0)
    btn.Text = text or "Button"
    btn.FontFace = FONT_BOLD
    btn.TextColor3 = Theme.Text
    btn.TextSize = 13
    btn.BackgroundColor3 = Theme.Section
    btn.BackgroundTransparency = 0
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = parent

    addCorner(btn, 4)
    addStroke(btn, Theme.SectionBorder)

    -- Hover glow
    btn.MouseEnter:Connect(function()
        tween(btn, {BackgroundColor3 = Theme.SectionBorder}, 0.15)
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, {BackgroundColor3 = Theme.Section}, 0.15)
    end)

    btn.MouseButton1Click:Connect(function()
        btn.TextColor3 = Theme.Accent
        tween(btn, {TextColor3 = Theme.Text}, 0.3)
        task.spawn(callback)
    end)

    local obj = {
        Instance = btn,
        _type = "Button",
    }
    function obj:SetText(t) btn.Text = t end
    function obj:SetCallback(cb) callback = cb end
    function obj:Destroy() btn:Destroy() end
    return obj
end

--
-- TOGGLE
--
local function newToggle(parent, text, default, callback)
    default = default or false
    callback = callback or function() end

    local value = default

    local frame = Instance.new("Frame")
    frame.Name = "Toggle"
    frame.Size = UDim2.new(1, -20, 0, 26)
    frame.Position = UDim2.fromOffset(10, 0)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Parent = parent

    -- Label
    local lbl = newLabel("Label", frame, text,
        UDim2.new(1, -36, 1, 0),
        UDim2.fromOffset(0, 0),
        FONT_REGULAR, Theme.Text, 13)

    -- Toggle box
    local box = Instance.new("Frame")
    box.Name = "Box"
    box.Size = UDim2.fromOffset(22, 22)
    box.Position = UDim2.new(1, -28, 0.5, -11)
    box.BackgroundColor3 = value and Theme.ToggleOn or Theme.ToggleOff
    box.BackgroundTransparency = 0.15
    box.BorderSizePixel = 0
    box.Parent = frame
    addCorner(box, 4)
    addStroke(box, value and Theme.ToggleOn or Theme.ToggleOff)

    -- Inner fill / check indicator
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = value and UDim2.fromOffset(10, 10) or UDim2.fromOffset(0, 0)
    fill.Position = UDim2.fromOffset(6, 6)
    fill.BackgroundColor3 = value and Theme.Text or Theme.TextSecondary
    fill.BackgroundTransparency = 0
    fill.BorderSizePixel = 0
    fill.Parent = box
    addCorner(fill, 5)

    local function updateUI(v)
        value = v
        box.BackgroundColor3 = value and Theme.ToggleOn or Theme.ToggleOff
        addStroke(box, value and Theme.ToggleOn or Theme.ToggleOff)
        tween(fill, {
            Size = value and UDim2.fromOffset(10, 10) or UDim2.fromOffset(0, 0),
            BackgroundColor3 = value and Theme.Text or Theme.TextSecondary
        }, 0.2, "Back")
    end

    -- Click toggles
    local clickDetector = Instance.new("TextButton")
    clickDetector.Name = "ClickDetector"
    clickDetector.Size = UDim2.fromScale(1, 1)
    clickDetector.Position = UDim2.fromOffset(0, 0)
    clickDetector.BackgroundTransparency = 1
    clickDetector.BorderSizePixel = 0
    clickDetector.Text = ""
    clickDetector.Parent = frame

    clickDetector.MouseButton1Click:Connect(function()
        value = not value
        updateUI(value)
        task.spawn(callback, value)
    end)

    local obj = {
        Instance = frame,
        _type = "Toggle",
        _value = value,
    }
    function obj:SetValue(v)
        value = v
        updateUI(v)
    end
    function obj:GetValue()
        return value
    end
    function obj:SetText(t) lbl.Text = t end
    function obj:SetCallback(cb) callback = cb end
    function obj:Destroy() frame:Destroy() end
    return obj
end

--
-- SLIDER
--
local function newSlider(parent, text, min, max, default, callback)
    min = min or 0
    max = max or 100
    default = math.clamp(default or (min + max) / 2, min, max)
    callback = callback or function() end

    local value = default

    local frame = Instance.new("Frame")
    frame.Name = "Slider"
    frame.Size = UDim2.new(1, -20, 0, 44)
    frame.Position = UDim2.fromOffset(10, 0)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Parent = parent

    -- Label
    local lbl = newLabel("Label", frame, text,
        UDim2.new(1, -80, 0, 18),
        UDim2.fromOffset(0, 0),
        FONT_REGULAR, Theme.Text, 13)

    -- Value text
    local valBox = Instance.new("TextBox")
    valBox.Name = "Value"
    valBox.Size = UDim2.fromOffset(60, 20)
    valBox.Position = UDim2.new(1, -60, 0, -1)
    valBox.Text = tostring(math.floor(value))
    valBox.FontFace = FONT_BOLD
    valBox.TextColor3 = Theme.Accent
    valBox.TextSize = 12
    valBox.TextXAlignment = Enum.TextXAlignment.Center
    valBox.BackgroundColor3 = Theme.Background
    valBox.BackgroundTransparency = 0.3
    valBox.BorderSizePixel = 0
    valBox.ClearTextOnFocus = false
    valBox.Parent = frame
    addCorner(valBox, 3)
    addStroke(valBox, Theme.SectionBorder)

    -- Track background
    local track = Instance.new("Frame")
    track.Name = "Track"
    track.Size = UDim2.new(1, -70, 0, 6)
    track.Position = UDim2.fromOffset(0, 26)
    track.BackgroundColor3 = Theme.Background
    track.BackgroundTransparency = 0.4
    track.BorderSizePixel = 0
    track.Parent = frame
    addCorner(track, 3)

    -- Fill bar
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.fromScale(0, 1)
    fill.BackgroundColor3 = Theme.Accent
    fill.BackgroundTransparency = 0
    fill.BorderSizePixel = 0
    fill.Parent = track
    addCorner(fill, 3)

    -- Thumb
    local thumb = Instance.new("Frame")
    thumb.Name = "Thumb"
    thumb.Size = UDim2.fromOffset(12, 12)
    thumb.Position = UDim2.fromOffset(-6, -3)
    thumb.BackgroundColor3 = Theme.Text
    thumb.BorderSizePixel = 0
    thumb.Parent = track
    addCorner(thumb, 6)

    local function updateThumb(v)
        local ratio = (v - min) / (max - min)
        local trackW = track.AbsoluteSize.X
        local thumbX = ratio * trackW
        thumb.Position = UDim2.fromOffset(thumbX - 6, -3)
        fill.Size = UDim2.fromScale(ratio, 1)
        valBox.Text = tostring(math.floor(v))
    end

    local draggingSlider = false

    local function slide(input)
        if not draggingSlider then return end
        local absPos = track.AbsolutePosition
        local localX = input.Position.X - absPos.X
        local ratio = math.clamp(localX / track.AbsoluteSize.X, 0, 1)
        value = math.floor(min + (max - min) * ratio + 0.5)
        updateThumb(value)
        callback(value)
    end

    thumb.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSlider = true
            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    draggingSlider = false
                    conn:Disconnect()
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input, gp)
        if gp then return end
        if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
            slide(input)
        end
    end)

    -- Allow clicking on track to jump
    track.MouseButton1Click:Connect(function(input)
        draggingSlider = true
        slide(input)
        draggingSlider = false
    end)

    -- TextBox input
    valBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local num = tonumber(valBox.Text)
            if num then
                value = math.clamp(math.floor(num), min, max)
            end
            updateThumb(value)
            callback(value)
        end
    end)

    -- Init position
    task.wait()
    updateThumb(value)

    local obj = {
        Instance = frame,
        _type = "Slider",
    }
    function obj:SetValue(v)
        value = math.clamp(v, min, max)
        updateThumb(value)
        callback(value)
    end
    function obj:GetValue()
        return value
    end
    function obj:SetCallback(cb) callback = cb end
    function obj:Destroy() frame:Destroy() end
    return obj
end

--
-- DROPDOWN
--
local function newDropdown(parent, text, options, default, callback)
    options = options or {"Option 1", "Option 2"}
    default = default or options[1]
    callback = callback or function() end

    local value = default
    local open = false

    local frame = Instance.new("Frame")
    frame.Name = "Dropdown"
    frame.Size = UDim2.new(1, -20, 0, 44)
    frame.Position = UDim2.fromOffset(10, 0)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Parent = parent

    -- Label
    newLabel("Label", frame, text,
        UDim2.new(1, 0, 0, 18),
        UDim2.fromOffset(0, 0),
        FONT_REGULAR, Theme.Text, 13)

    -- Main button
    local btn = Instance.new("TextButton")
    btn.Name = "Selected"
    btn.Size = UDim2.new(1, 0, 0, 22)
    btn.Position = UDim2.fromOffset(0, 20)
    btn.Text = tostring(value)
    btn.FontFace = FONT_REGULAR
    btn.TextColor3 = Theme.Text
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.TextTruncate = Enum.TextTruncate.AtEnd
    btn.BackgroundColor3 = Theme.DropdownBg
    btn.BackgroundTransparency = 0
    btn.BorderSizePixel = 0
    btn.Parent = frame
    addCorner(btn, 3)
    addStroke(btn, Theme.DropdownBorder)

    -- Arrow indicator
    local arrow = newLabel("Arrow", btn, ">",
        UDim2.fromOffset(20, 22),
        UDim2.new(1, -22, 0, 0),
        FONT_BOLD, Theme.Accent, 14)
    arrow.TextXAlignment = Enum.TextXAlignment.Center

    -- Dropdown list (ScrollingFrame)
    local listFrame = Instance.new("ScrollingFrame")
    listFrame.Name = "List"
    listFrame.Size = UDim2.new(1, 0, 0, 120)
    listFrame.Position = UDim2.fromOffset(0, 24)
    listFrame.BackgroundColor3 = Theme.Background
    listFrame.BackgroundTransparency = 0.2
    listFrame.BorderSizePixel = 0
    listFrame.Visible = false
    listFrame.ScrollBarThickness = 4
    listFrame.ScrollBarImageColor3 = Theme.ScrollBar
    listFrame.CanvasSize = UDim2.fromScale(0, 0)
    listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    listFrame.ClipsDescendants = true
    listFrame.Parent = frame
    addCorner(listFrame, 4)
    addStroke(listFrame, Theme.DropdownBorder)

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 2)
    listLayout.Parent = listFrame

    -- Populate
    local optionButtons = {}
    local function rebuild()
        for _, ob in ipairs(optionButtons) do
            ob:Destroy()
        end
        optionButtons = {}

        for _, opt in ipairs(options) do
            local ob = Instance.new("TextButton")
            ob.Name = "Option"
            ob.Size = UDim2.new(1, -4, 0, 24)
            ob.Text = "   " .. tostring(opt)
            ob.FontFace = FONT_REGULAR
            ob.TextColor3 = Theme.TextSecondary
            ob.TextSize = 12
            ob.TextXAlignment = Enum.TextXAlignment.Left
            ob.BackgroundColor3 = Color3.new(0, 0, 0)
            ob.BackgroundTransparency = 0.5
            ob.BorderSizePixel = 0
            ob.Parent = listFrame

            ob.MouseEnter:Connect(function()
                ob.BackgroundColor3 = Theme.DropdownBorder
                ob.BackgroundTransparency = 0.7
            end)
            ob.MouseLeave:Connect(function()
                ob.BackgroundColor3 = Color3.new(0, 0, 0)
                ob.BackgroundTransparency = 0.5
            end)
            ob.MouseButton1Click:Connect(function()
                value = opt
                btn.Text = tostring(value)
                toggleOpen(false)
                task.spawn(callback, value)
            end)

            table.insert(optionButtons, ob)
        end
    end

    local function toggleOpen(state)
        if state ~= nil then
            open = state
        else
            open = not open
        end
        listFrame.Visible = open
        arrow.Text = open and "v" or ">"
    end

    btn.MouseButton1Click:Connect(function()
        toggleOpen()
    end)

    rebuild()

    -- Close dropdown when clicking outside
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if open and input.UserInputType == Enum.UserInputType.MouseButton1 then
            -- Check if the click was outside the dropdown
            task.wait()
            if open and not UserInputService:IsMouseOnFrame(frame) then
                toggleOpen(false)
            end
        end
    end)

    local obj = {
        Instance = frame,
        _type = "Dropdown",
    }
    function obj:SetValue(v)
        value = v
        btn.Text = tostring(value)
    end
    function obj:GetValue()
        return value
    end
    function obj:AddOption(opt)
        table.insert(options, opt)
        rebuild()
    end
    function obj:RemoveOption(opt)
        for i, v in ipairs(options) do
            if v == opt then
                table.remove(options, i)
                break
            end
        end
        rebuild()
    end
    function obj:SetCallback(cb) callback = cb end
    function obj:Destroy() frame:Destroy() end
    return obj
end

--
-- SECTION (group container)
--
local function newSection(parent, title)
    local frame = newFrame("Section", parent,
        UDim2.new(1, -12, 0, 0),
        UDim2.fromOffset(6, 0),
        Theme.Section, 0, 6)
    frame.AutomaticSize = Enum.AutomaticSize.Y

    -- Top accent line
    local accentLine = Instance.new("Frame")
    accentLine.Name = "AccentLine"
    accentLine.Size = UDim2.fromOffset(40, 2)
    accentLine.Position = UDim2.fromOffset(10, 0)
    accentLine.BackgroundColor3 = Theme.Accent
    accentLine.BorderSizePixel = 0
    accentLine.Parent = frame

    -- Title
    newLabel("Title", frame, title,
        UDim2.new(1, -20, 0, 20),
        UDim2.fromOffset(14, 8),
        FONT_BOLD, Theme.Text, 13)

    -- Separator line under title
    local sep = Instance.new("Frame")
    sep.Name = "Separator"
    sep.Size = UDim2.new(1, -28, 0, 1)
    sep.Position = UDim2.fromOffset(14, 30)
    sep.BackgroundColor3 = Theme.SectionBorder
    sep.BackgroundTransparency = 0.5
    sep.BorderSizePixel = 0
    sep.Parent = frame

    -- Content container
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -28, 0, 0)
    content.Position = UDim2.fromOffset(14, 36)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.AutomaticSize = Enum.AutomaticSize.Y
    content.Parent = frame

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = content

    local padding = Instance.new("UIPadding")
    padding.PaddingBottom = UDim.new(0, 8)
    padding.Parent = content

    local obj = {
        Instance = frame,
        Content = content,
        _type = "Section",
        _children = {},
    }
    function obj:AddToggle(text, default, cb)
        local t = newToggle(content, text, default, cb)
        table.insert(obj._children, t)
        return t
    end
    function obj:AddButton(text, cb)
        local b = newButton(content, text, cb)
        table.insert(obj._children, b)
        return b
    end
    function obj:AddSlider(text, minv, maxv, default, cb)
        local s = newSlider(content, text, minv, maxv, default, cb)
        table.insert(obj._children, s)
        return s
    end
    function obj:AddDropdown(text, opts, default, cb)
        local d = newDropdown(content, text, opts, default, cb)
        table.insert(obj._children, d)
        return d
    end
    function obj:AddLabel(text, opts)
        local l = newLabelComponent(content, text, opts)
        table.insert(obj._children, l)
        return l
    end
    function obj:AddColorPicker(text, default, cb)
        local cp = newColorPicker(content, text, default, cb)
        table.insert(obj._children, cp)
        return cp
    end
    function obj:AddKeybind(text, default, cb)
        local kb = newKeybind(content, text, default, cb)
        table.insert(obj._children, kb)
        return kb
    end
    function obj:Destroy()
        for _, child in ipairs(obj._children) do
            child:Destroy()
        end
        frame:Destroy()
    end
    return obj
end

--
-- COLOR PICKER (grid of presets)
--
local function newColorPicker(parent, text, default, callback)
    default = default or Color3.fromRGB(255, 45, 85)
    callback = callback or function() end

    local value = default
    local open = false

    local PRESET_COLORS = {
        Color3.fromRGB(255, 45, 85),    -- Red accent
        Color3.fromRGB(255, 68, 68),    -- Bright red
        Color3.fromRGB(255, 170, 0),    -- Orange
        Color3.fromRGB(255, 200, 50),   -- Yellow
        Color3.fromRGB(0, 255, 136),    -- Green (toggle on)
        Color3.fromRGB(0, 212, 255),    -- Cyan accent
        Color3.fromRGB(50, 100, 255),   -- Blue
        Color3.fromRGB(136, 50, 255),   -- Purple
        Color3.fromRGB(255, 50, 200),   -- Pink
        Color3.fromRGB(200, 200, 200),  -- White-ish
        Color3.fromRGB(100, 100, 100),  -- Grey
        Color3.fromRGB(255, 255, 255),  -- White
    }

    local frame = Instance.new("Frame")
    frame.Name = "ColorPicker"
    frame.Size = UDim2.new(1, -20, 0, 38)
    frame.Position = UDim2.fromOffset(10, 0)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Parent = parent

    -- Label
    newLabel("Label", frame, text,
        UDim2.new(1, -40, 0, 20),
        UDim2.fromOffset(0, 0),
        FONT_REGULAR, Theme.Text, 13)

    -- Color preview button
    local preview = Instance.new("Frame")
    preview.Name = "Preview"
    preview.Size = UDim2.fromOffset(28, 16)
    preview.Position = UDim2.new(1, -28, 0, 2)
    preview.BackgroundColor3 = value
    preview.BorderSizePixel = 0
    preview.Parent = frame
    addCorner(preview, 3)
    addStroke(preview, Theme.SectionBorder)

    local click = Instance.new("TextButton")
    click.Name = "Click"
    click.Size = UDim2.fromScale(1, 1)
    click.Position = UDim2.fromOffset(0, 0)
    click.BackgroundTransparency = 1
    click.BorderSizePixel = 0
    click.Text = ""
    click.Parent = preview

    -- Popup grid
    local grid = Instance.new("Frame")
    grid.Name = "Grid"
    grid.Size = UDim2.fromOffset(180, 80)
    grid.Position = UDim2.new(1, -180, 0, 20)
    grid.BackgroundColor3 = Theme.Background
    grid.BackgroundTransparency = 0.15
    grid.BorderSizePixel = 0
    grid.Visible = false
    grid.ZIndex = 10
    grid.Parent = frame
    addCorner(grid, 4)
    addStroke(grid, Theme.SectionBorder)

    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.fromOffset(20, 20)
    gridLayout.CellPadding = UDim2.fromOffset(4, 4)
    gridLayout.StartCorner = Enum.StartCorner.TopLeft
    gridLayout.Parent = grid

    for _, color in ipairs(PRESET_COLORS) do
        local swatch = Instance.new("Frame")
        swatch.Size = UDim2.fromScale(1, 1)
        swatch.BackgroundColor3 = color
        swatch.BorderSizePixel = 0
        swatch.Parent = grid
        addCorner(swatch, 3)

        local swatchClick = Instance.new("TextButton")
        swatchClick.Size = UDim2.fromScale(1, 1)
        swatchClick.BackgroundTransparency = 1
        swatchClick.BorderSizePixel = 0
        swatchClick.Text = ""
        swatchClick.Parent = swatch
        swatchClick.ZIndex = 11

        swatchClick.MouseButton1Click:Connect(function()
            value = color
            preview.BackgroundColor3 = value
            grid.Visible = false
            open = false
            task.spawn(callback, value)
        end)
    end

    click.MouseButton1Click:Connect(function()
        open = not open
        grid.Visible = open
    end)

    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if open and input.UserInputType == Enum.UserInputType.MouseButton1 then
            task.wait()
            if open and not UserInputService:IsMouseOnFrame(grid)
                and not UserInputService:IsMouseOnFrame(preview) then
                grid.Visible = false
                open = false
            end
        end
    end)

    local obj = {
        Instance = frame,
        _type = "ColorPicker",
    }
    function obj:SetValue(c)
        value = c
        preview.BackgroundColor3 = value
    end
    function obj:GetValue()
        return value
    end
    function obj:SetCallback(cb) callback = cb end
    function obj:Destroy() frame:Destroy() end
    return obj
end

--
-- KEYBIND
--
local function newKeybind(parent, text, default, callback)
    default = default or Enum.KeyCode.F1
    callback = callback or function() end

    local value = default
    local listening = false

    local frame = Instance.new("Frame")
    frame.Name = "Keybind"
    frame.Size = UDim2.new(1, -20, 0, 26)
    frame.Position = UDim2.fromOffset(10, 0)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Parent = parent

    -- Label
    newLabel("Label", frame, text,
        UDim2.new(1, -80, 1, 0),
        UDim2.fromOffset(0, 0),
        FONT_REGULAR, Theme.Text, 13)

    -- Key button
    local keyBtn = Instance.new("TextButton")
    keyBtn.Name = "Key"
    keyBtn.Size = UDim2.fromOffset(70, 22)
    keyBtn.Position = UDim2.new(1, -70, 0.5, -11)
    keyBtn.Text = default.Name or "F1"
    keyBtn.FontFace = FONT_BOLD
    keyBtn.TextColor3 = Theme.Accent
    keyBtn.TextSize = 12
    keyBtn.BackgroundColor3 = Theme.DropdownBg
    keyBtn.BorderSizePixel = 0
    keyBtn.AutoButtonColor = false
    keyBtn.Parent = frame
    addCorner(keyBtn, 3)
    addStroke(keyBtn, Theme.DropdownBorder)

    keyBtn.MouseButton1Click:Connect(function()
        listening = true
        keyBtn.Text = "..."
        keyBtn.TextColor3 = Theme.ToggleOn
    end)

    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                listening = false
                value = input.KeyCode
                keyBtn.Text = value.Name
                keyBtn.TextColor3 = Theme.Accent
                task.spawn(callback, value)
            end
        end
    end)

    local obj = {
        Instance = frame,
        _type = "Keybind",
    }
    function obj:SetValue(kc)
        value = kc
        keyBtn.Text = value.Name
    end
    function obj:GetValue()
        return value
    end
    function obj:SetCallback(cb) callback = cb end
    function obj:Destroy() frame:Destroy() end
    return obj
end

-- ====================================================================
-- WINDOW + TAB SYSTEM
-- ====================================================================

--- Create a new main window.
--- @param title string  Window title bar text
--- @param size  UDim2   Initial size (default: 385×415)
--- @param opts  table   Options: { parent = Instance, draggable = bool,
---                       resizable = bool, themeOverrides = {} }
--- @return table window object
local function newWindow(title, size, opts)
    opts = opts or {}
    size = size or UDim2.fromOffset(385, 415)

    -- Merge theme overrides
    if opts.themeOverrides then
        for k, v in pairs(opts.themeOverrides) do
            Theme[k] = v
        end
    end

    -- Find the ScreenGui parent
    local parent = opts.parent
    if not parent then
        -- Try CoreGui (persistent), fall back to PlayerGui
        parent = CoreGui:FindFirstChild("DefusalHub")
        if not parent then
            parent = Instance.new("ScreenGui")
            parent.Name = "DefusalHub"
            parent.ResetOnSpawn = false
            parent.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            parent.DisplayOrder = 999

            -- Try CoreGui for persistence
            local success, err = pcall(function()
                parent.Parent = CoreGui
            end)
            if not success then
                -- Fall back to PlayerGui
                local plr = Players.LocalPlayer
                if plr then
                    parent.Parent = plr:FindFirstChild("PlayerGui") or plr.PlayerGui
                    parent.Name = "DefusalHub"
                end
            end
        end
    end

    -- ── MAIN WINDOW FRAME ──
    local main = newFrame("Window", parent, size,
        UDim2.fromOffset(200, 100),
        Theme.Background, Theme.BackgroundTrans, 6)

    -- Outer glow (drop shadow) — duplicate frame behind
    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 10, 1, 10)
    shadow.Position = UDim2.fromOffset(-5, -5)
    shadow.BackgroundColor3 = Color3.new(0, 0, 0)
    shadow.BackgroundTransparency = 0.5
    shadow.BorderSizePixel = 0
    shadow.ZIndex = -1
    shadow.Parent = main
    addCorner(shadow, 8)
    -- blur effect via ImageLabel with gradient could go here but is too heavy

    -- ── TITLE BAR ──
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 32)
    titleBar.Position = UDim2.fromOffset(0, 0)
    titleBar.BackgroundColor3 = Theme.TitleBar
    titleBar.BorderSizePixel = 0
    titleBar.Parent = main
    addCorner(titleBar, 6)
    -- Only round top corners — hide bottom radius via a clipping frame
    -- (Simplified: entire title bar has corner radius, content covers bottom)

    -- Accent stripe at top of title bar
    local accentStripe = Instance.new("Frame")
    accentStripe.Name = "AccentStripe"
    accentStripe.Size = UDim2.new(1, 0, 0, 2)
    accentStripe.BackgroundColor3 = Theme.AccentStripe
    accentStripe.BorderSizePixel = 0
    accentStripe.Parent = titleBar
    addCorner(accentStripe, 2)

    -- Title text
    local titleLabel = newLabel("Title", titleBar, title,
        UDim2.new(1, -70, 1, 0),
        UDim2.fromOffset(12, 0),
        FONT_BOLD, Theme.Text, 14)

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.Size = UDim2.fromOffset(28, 28)
    closeBtn.Position = UDim2.new(1, -30, 0, 2)
    closeBtn.Text = "X"
    closeBtn.FontFace = FONT_BOLD
    closeBtn.TextColor3 = Theme.TextSecondary
    closeBtn.TextSize = 14
    closeBtn.BackgroundTransparency = 1
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = titleBar

    closeBtn.MouseEnter:Connect(function()
        closeBtn.TextColor3 = Theme.Accent
        tween(closeBtn, {BackgroundTransparency = 0.85}, 0.1)
    end)
    closeBtn.MouseLeave:Connect(function()
        closeBtn.TextColor3 = Theme.TextSecondary
        tween(closeBtn, {BackgroundTransparency = 1}, 0.1)
    end)
    closeBtn.MouseButton1Click:Connect(function()
        main.Visible = not main.Visible
    end)

    -- Minimize button
    local minBtn = Instance.new("TextButton")
    minBtn.Name = "Minimize"
    minBtn.Size = UDim2.fromOffset(28, 28)
    minBtn.Position = UDim2.new(1, -62, 0, 2)
    minBtn.Text = "-"
    minBtn.FontFace = FONT_BOLD
    minBtn.TextColor3 = Theme.TextSecondary
    minBtn.TextSize = 16
    minBtn.BackgroundTransparency = 1
    minBtn.BorderSizePixel = 0
    minBtn.Parent = titleBar

    minBtn.MouseEnter:Connect(function()
        minBtn.TextColor3 = Theme.ToggleOn
        tween(minBtn, {BackgroundTransparency = 0.85}, 0.1)
    end)
    minBtn.MouseLeave:Connect(function()
        minBtn.TextColor3 = Theme.TextSecondary
        tween(minBtn, {BackgroundTransparency = 1}, 0.1)
    end)

    -- ── TAB BAR ──
    local tabBar = Instance.new("Frame")
    tabBar.Name = "TabBar"
    tabBar.Size = UDim2.new(1, 0, 0, 28)
    tabBar.Position = UDim2.fromOffset(0, 32)
    tabBar.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
    tabBar.BorderSizePixel = 0
    tabBar.Parent = main

    -- Bottom border line for tab bar
    local tabBorder = Instance.new("Frame")
    tabBorder.Name = "Border"
    tabBorder.Size = UDim2.new(1, 0, 0, 1)
    tabBorder.Position = UDim2.fromOffset(0, 27)
    tabBorder.BackgroundColor3 = Theme.SectionBorder
    tabBorder.BackgroundTransparency = 0.5
    tabBorder.BorderSizePixel = 0
    tabBorder.Parent = tabBar

    -- ── CONTENT AREA ──
    local contentArea = Instance.new("Frame")
    contentArea.Name = "Content"
    contentArea.Size = UDim2.new(1, 0, 1, -62)
    contentArea.Position = UDim2.fromOffset(0, 60)
    contentArea.BackgroundTransparency = 1
    contentArea.BorderSizePixel = 0
    contentArea.Parent = main

    -- ScrollingFrame for content (allows scrollable tabs)
    local contentScrolling = Instance.new("ScrollingFrame")
    contentScrolling.Name = "Scrolling"
    contentScrolling.Size = UDim2.fromScale(1, 1)
    contentScrolling.Position = UDim2.fromOffset(0, 0)
    contentScrolling.BackgroundTransparency = 1
    contentScrolling.BorderSizePixel = 0
    contentScrolling.ScrollBarThickness = 4
    contentScrolling.ScrollBarImageColor3 = Theme.ScrollBar
    contentScrolling.CanvasSize = UDim2.fromScale(0, 0)
    contentScrolling.AutomaticCanvasSize = Enum.AutomaticSize.Y
    contentScrolling.Parent = contentArea

    local contentPadding = Instance.new("UIPadding")
    contentPadding.PaddingTop = UDim.new(0, 6)
    contentPadding.PaddingBottom = UDim.new(0, 8)
    contentPadding.Parent = contentScrolling

    -- ── DRAG / RESIZE ──
    if opts.draggable ~= false then
        makeDraggable(main, titleBar)
    end
    if opts.resizable ~= false then
        makeResizable(main, Vector2.new(300, 250))
    end

    -- ── MINIMIZE LOGIC ──
    local minimized = false
    local contentHeight = size.Y.Offset
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        local targetHeight = minimized and 32 or contentHeight
        tween(main, {Size = UDim2.new(size.X.Scale, size.X.Offset, size.Y.Scale, targetHeight)}, 0.25, "Quad")
        contentArea.Visible = not minimized
        tabBar.Visible = not minimized
    end)

    -- ── RAINBOW ACCENT LOOP ──
    local rainbowConn
    rainbowConn = RunService.RenderStepped:Connect(function()
        if not main.Parent then
            rainbowConn:Disconnect()
            return
        end
        if Theme.RainbowEnabled then
            Theme._rainbowHue = (Theme._rainbowHue + 0.5) % 360
            local rainbow = Color3.fromHSV(Theme._rainbowHue / 360, 1, 1)
            Theme.Accent = rainbow
            Theme.AccentStripe = rainbow
            Theme.ToggleOff = rainbow
            Theme.DropdownBorder = rainbow
            Theme.ScrollBar = rainbow
            -- Update title bar stripe
            accentStripe.BackgroundColor3 = rainbow
        end
    end)

    -- ==================================================================
    -- TAB OBJECT
    -- ==================================================================
    local Tab = {}
    Tab.__index = Tab

    function Tab.new(name)
        local self = setmetatable({}, Tab)
        self.Name = name
        self.Button = nil
        self.Page = nil
        self._children = {}
        self._sectionLayout = nil
        return self
    end

    -- Add a Section to this tab
    function Tab:AddSection(title)
        local section = newSection(self.Page, title)
        table.insert(self._children, section)
        return section
    end

    -- Convenience helpers (auto-wrap in section named "General" if none exists)
    function Tab:_ensureGeneralSection()
        for _, child in ipairs(self._children) do
            if child._type == "Section" then
                return child
            end
        end
        return self:AddSection("General")
    end

    function Tab:AddToggle(text, default, cb)
        return self:_ensureGeneralSection():AddToggle(text, default, cb)
    end
    function Tab:AddButton(text, cb)
        return self:_ensureGeneralSection():AddButton(text, cb)
    end
    function Tab:AddSlider(text, minv, maxv, default, cb)
        return self:_ensureGeneralSection():AddSlider(text, minv, maxv, default, cb)
    end
    function Tab:AddDropdown(text, opts, default, cb)
        return self:_ensureGeneralSection():AddDropdown(text, opts, default, cb)
    end
    function Tab:AddLabel(text, opts)
        return self:_ensureGeneralSection():AddLabel(text, opts)
    end
    function Tab:AddColorPicker(text, default, cb)
        return self:_ensureGeneralSection():AddColorPicker(text, default, cb)
    end
    function Tab:AddKeybind(text, default, cb)
        return self:_ensureGeneralSection():AddKeybind(text, default, cb)
    end

    function Tab:Destroy()
        for _, child in ipairs(self._children) do
            child:Destroy()
        end
        if self.Button then self.Button:Destroy() end
        if self.Page then self.Page:Destroy() end
    end

    -- ==================================================================
    -- WINDOW OBJECT
    -- ==================================================================
    local windowObj = {
        Instance = main,
        ScreenGui = parent,
        Theme = Theme,
        _tabs = {},
        _activeTab = nil,
        _tabButtons = {},
        _tabPages = {},
    }

    --- Add a new tab.
    --- @param name string  Tab display name
    --- @return table tab object
    function windowObj:AddTab(name)
        -- Tab button
        local btn = Instance.new("TextButton")
        btn.Name = name .. "Tab"
        btn.Size = UDim2.fromOffset(0, 26)
        btn.Position = UDim2.fromOffset(0, 1)
        btn.Text = name
        btn.FontFace = FONT_BOLD
        btn.TextColor3 = Theme.TextSecondary
        btn.TextSize = 12
        btn.BackgroundTransparency = 1
        btn.BorderSizePixel = 0
        btn.AutomaticSize = Enum.AutomaticSize.X
        btn.Parent = tabBar

        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 12)
        padding.PaddingRight = UDim.new(0, 12)
        padding.Parent = btn

        -- Underline indicator
        local underline = Instance.new("Frame")
        underline.Name = "Underline"
        underline.Size = UDim2.new(1, 0, 0, 2)
        underline.Position = UDim2.fromOffset(0, 24)
        underline.BackgroundColor3 = Theme.Accent
        underline.BackgroundTransparency = 1
        underline.BorderSizePixel = 0
        underline.Parent = btn

        -- Tab page (container inside ScrollingFrame)
        local page = Instance.new("Frame")
        page.Name = name .. "Page"
        page.Size = UDim2.new(1, -6, 0, 0)
        page.Position = UDim2.fromOffset(3, 0)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.AutomaticSize = Enum.AutomaticSize.Y
        page.Visible = false
        page.Parent = contentScrolling

        local pageLayout = Instance.new("UIListLayout")
        pageLayout.Padding = UDim.new(0, 6)
        pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        pageLayout.Parent = page

        -- Create tab object
        local tab = Tab.new(name)
        tab.Button = btn
        tab.Page = page
        table.insert(self._tabs, tab)
        self._tabButtons[name] = btn
        self._tabPages[name] = page

        -- Switch to this tab on click
        btn.MouseButton1Click:Connect(function()
            self:SelectTab(name)
        end)

        -- If first tab, auto-select
        if #self._tabs == 1 then
            self:SelectTab(name)
        end

        return tab
    end

    --- Select a tab by name.
    function windowObj:SelectTab(name)
        local targetPage = self._tabPages[name]
        if not targetPage then return end

        -- Hide all pages / dim all buttons
        for tabName, btn in pairs(self._tabButtons) do
            local ul = btn:FindFirstChild("Underline")
            if ul then
                tween(ul, {BackgroundTransparency = 1}, 0.15)
            end
            btn.TextColor3 = Theme.TextSecondary
            local pg = self._tabPages[tabName]
            if pg then
                pg.Visible = false
            end
        end

        -- Show target
        targetPage.Visible = true
        local activeBtn = self._tabButtons[name]
        if activeBtn then
            activeBtn.TextColor3 = Theme.Text
            local ul = activeBtn:FindFirstChild("Underline")
            if ul then
                ul.BackgroundTransparency = 0
                tween(ul, {BackgroundTransparency = 0}, 0.2)
            end
        end

        self._activeTab = name

        -- Update canvas size (small delay for layout to settle)
        task.spawn(function()
            task.wait()
            if contentScrolling then
                contentScrolling.CanvasSize = UDim2.fromOffset(0, contentScrolling.CanvasPosition.Y + contentScrolling.AbsoluteWindowSize.Y + 20)
            end
        end)
    end

    --- Toggle window visibility.
    function windowObj:Toggle()
        main.Visible = not main.Visible
    end

    --- Show the window.
    function windowObj:Show()
        main.Visible = true
    end

    --- Hide the window.
    function windowObj:Hide()
        main.Visible = false
    end

    --- Set window title.
    function windowObj:SetTitle(t)
        titleLabel.Text = t
    end

    --- Clean up all objects.
    function windowObj:Destroy()
        for _, tab in ipairs(self._tabs) do
            tab:Destroy()
        end
        if rainbowConn then rainbowConn:Disconnect() end
        main:Destroy()
    end

    return windowObj
end

-- ====================================================================
-- MODULE EXPORT
-- ====================================================================
local GUI = {}

-- Core
GUI.Theme = Theme
GUI.NewWindow = newWindow
GUI.Window = newWindow                           -- alias

-- Components (for advanced use outside of Window/Tab)
GUI.Label = newLabelComponent
GUI.Button = newButton
GUI.Toggle = newToggle
GUI.Slider = newSlider
GUI.Dropdown = newDropdown
GUI.Section = newSection
GUI.ColorPicker = newColorPicker
GUI.Keybind = newKeybind

-- Services
GUI.Notify = NotificationService.Notify
GUI.Watermark = NotificationService.Watermark

-- Utility
GUI.MakeDraggable = makeDraggable
GUI.MakeResizable = makeResizable

-- Theme accessors
function GUI:SetAccent(color)
    Theme.Accent = color
    Theme.AccentStripe = color
    Theme.ToggleOff = color
    Theme.DropdownBorder = color
    Theme.ScrollBar = color
end

function GUI:SetRainbow(enabled)
    Theme.RainbowEnabled = enabled
end

function GUI:SetTransparency(trans)
    Theme.BackgroundTrans = trans
end

return GUI
