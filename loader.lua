local Config = getgenv().DefusalConfig
if not Config then error("[DefusalSuite] config.lua must be loaded first!") end

local Players = Config.Services.Players
local HttpService = Config.Services.HttpService
local CoreGui = Config.Services.CoreGui
local UserInputService = Config.Services.UserInputService
local LocalPlayer = Players.LocalPlayer

local GitHubRepo = "raw.githubusercontent.com/username/defusal-suite/main"
local LoaderFrame = nil
local ScriptList = {
    {name = "GUI Framework", file = "gui.lua", required = true, loaded = false, desc = "UI components"},
    {name = "ESP Module", file = "esp.lua", required = false, loaded = false, desc = "Player, Bomb, Weapon ESP"},
    {name = "Aimbot Module", file = "aimbot.lua", required = false, loaded = false, desc = "Silent Aim, Triggerbot, Aimbot"},
    {name = "Defuse Module", file = "defuse.lua", required = false, loaded = false, desc = "Auto Defuse, Fast Plant"},
    {name = "Utility Module", file = "utility.lua", required = false, loaded = false, desc = "Cash, Kill All, FOV, etc."},
}

local function LoadScript(name, url)
    local success, err = pcall(function()
        local code = game:HttpGet(url, true)
        if not code or code == "" then error("Empty response") end
        local func, compileErr = loadstring(code)
        if not func then error("Compile error: " .. tostring(compileErr)) end
        func()
    end)
    if not success then
        warn("[DefusalSuite] Failed to load " .. name .. ": " .. tostring(err))
        return false
    end
    return true
end

local function CreateDrawingLoader()
    local bx, by = 385, 415
    local cx, cy = (UserInputService:GetMouseLocation().X - bx/2), (UserInputService:GetMouseLocation().Y - by/2)

    local bg = Drawing.new("Square")
    bg.Size = Vector2.new(bx, by)
    bg.Position = Vector2.new(cx, cy)
    bg.Color = Color3.fromRGB(13, 13, 13)
    bg.Filled = true
    bg.Transparency = 0.85
    bg.Visible = true

    local title = Drawing.new("Text")
    title.Text = "DEFUSAL HUB LOADER"
    title.Position = Vector2.new(cx + 10, cy + 10)
    title.Size = 18
    title.Color = Color3.fromRGB(255, 45, 85)
    title.Center = false
    title.Visible = true

    local dragging, dragStart, startPos = false, nil, nil

    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mPos = UserInputService:GetMouseLocation()
            if mPos.X >= cx and mPos.X <= cx + bx and mPos.Y >= cy and mPos.Y <= cy + 30 then
                dragging = true
                dragStart = input.Position
                startPos = {X = cx, Y = cy}
            end
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            cx = startPos.X + delta.X
            cy = startPos.Y + delta.Y
            bg.Position = Vector2.new(cx, cy)
            title.Position = Vector2.new(cx + 10, cy + 10)
            for i, item in ipairs(itemTexts or {}) do
                if item then item.Position = Vector2.new(cx + 15, cy + 45 + (i-1) * 28) end
            end
            if loadBtn then
                loadBtn.Position = Vector2.new(cx + 10, cy + by - 50)
            end
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    local itemTexts = {}
    local selectedIndex = 1

    for i, script in ipairs(ScriptList) do
        local txt = Drawing.new("Text")
        local label = (script.required and "[REQ] " or "[OPT] ") .. script.name
        txt.Text = label
        txt.Position = Vector2.new(cx + 15, cy + 45 + (i-1) * 28)
        txt.Size = 14
        txt.Color = i == selectedIndex and Color3.fromRGB(0, 212, 255) or Color3.fromRGB(200, 200, 200)
        txt.Visible = true
        itemTexts[i] = txt

        local desc = Drawing.new("Text")
        desc.Text = script.desc
        desc.Position = Vector2.new(cx + 25, cy + 60 + (i-1) * 28)
        desc.Size = 10
        desc.Color = Color3.fromRGB(120, 120, 120)
        desc.Visible = true
        itemTexts[i + #ScriptList] = desc
    end

    local loadBtn = Drawing.new("Square")
    loadBtn.Size = Vector2.new(bx - 20, 30)
    loadBtn.Position = Vector2.new(cx + 10, cy + by - 50)
    loadBtn.Color = Color3.fromRGB(255, 45, 85)
    loadBtn.Filled = true
    loadBtn.Visible = true

    local loadText = Drawing.new("Text")
    loadText.Text = "LOAD SELECTED"
    loadText.Position = Vector2.new(cx + bx/2 - 40, cy + by - 45)
    loadText.Size = 14
    loadText.Color = Color3.fromRGB(255, 255, 255)
    loadText.Visible = true

    local statusText = Drawing.new("Text")
    statusText.Text = "Click a module to select it, then press LOAD"
    statusText.Position = Vector2.new(cx + 10, cy + by - 80)
    statusText.Size = 10
    statusText.Color = Color3.fromRGB(150, 150, 150)
    statusText.Visible = true

    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mPos = UserInputService:GetMouseLocation()
            local relX, relY = mPos.X - cx, mPos.Y - cy

            if relX >= loadBtn.Position.X - cx and relX <= loadBtn.Position.X - cx + loadBtn.Size.X and relY >= loadBtn.Position.Y - cy and relY <= loadBtn.Position.Y - cy + loadBtn.Size.Y then
                local selected = ScriptList[selectedIndex]
                if selected then
                    statusText.Text = "Loading " .. selected.file .. "..."
                    local url = "https://" .. GitHubRepo .. "/" .. selected.file
                    local ok = LoadScript(selected.name, url)
                    if ok then
                        selected.loaded = true
                        itemTexts[selectedIndex].Color = Color3.fromRGB(0, 255, 136)
                        statusText.Text = selected.name .. " loaded successfully!"
                    else
                        statusText.Text = "Failed to load " .. selected.name
                    end
                end
                return
            end

            for i = 1, #ScriptList do
                local yStart = 45 + (i-1) * 28
                if relY >= yStart and relY <= yStart + 25 and relX >= 10 and relX <= bx - 10 then
                    selectedIndex = i
                    for j, txt in ipairs(itemTexts) do
                        if j <= #ScriptList then
                            txt.Color = j == i and Color3.fromRGB(0, 212, 255) or Color3.fromRGB(200, 200, 200)
                        end
                    end
                    break
                end
            end
        end
    end)

    LoaderFrame = {Destroy = function()
        bg:Remove()
        title:Remove()
        loadBtn:Remove()
        loadText:Remove()
        statusText:Remove()
        for _, t in ipairs(itemTexts) do t:Remove() end
    end}
end

local function CreateInstanceLoader()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DefusalLoader"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = CoreGui

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 385, 0, 415)
    main.Position = UDim2.new(0.5, -192, 0.5, -207)
    main.BackgroundColor3 = Color3.fromRGB(13, 13, 13)
    main.BackgroundTransparency = 0.15
    main.BorderSizePixel = 0
    main.Active = true
    main.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = main

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(42, 42, 42)
    stroke.Thickness = 1
    stroke.Parent = main

    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 30)
    titleBar.BackgroundColor3 = Color3.fromRGB(255, 45, 85)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = main

    local titleBarCorner = Instance.new("UICorner")
    titleBarCorner.CornerRadius = UDim.new(0, 4)
    titleBarCorner.Parent = titleBar

    local titleText = Instance.new("TextLabel")
    titleText.Text = "DEFUSAL HUB LOADER"
    titleText.Size = UDim2.new(1, -10, 1, 0)
    titleText.Position = UDim2.new(0, 10, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.Font = Enum.Font.GothamSSm
    titleText.TextSize = 16
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar

    local dragging, dragStart, startPos

    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
        end
    end)
    titleBar.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -20, 1, -90)
    scrollFrame.Position = UDim2.new(0, 10, 0, 40)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 45, 85)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #ScriptList * 70)
    scrollFrame.Parent = main

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.Parent = scrollFrame

    local scriptButtons = {}

    for i, script in ipairs(ScriptList) do
        local item = Instance.new("Frame")
        item.Size = UDim2.new(1, -10, 0, 60)
        item.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
        item.BorderSizePixel = 0
        item.Parent = scrollFrame

        local itemCorner = Instance.new("UICorner")
        itemCorner.CornerRadius = UDim.new(0, 3)
        itemCorner.Parent = item

        local itemStroke = Instance.new("UIStroke")
        itemStroke.Color = Color3.fromRGB(42, 42, 42)
        itemStroke.Thickness = 1
        itemStroke.Parent = item

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Text = (script.required and "[REQ] " or "[OPT] ") .. script.name
        nameLabel.Size = UDim2.new(1, -10, 0, 25)
        nameLabel.Position = UDim2.new(0, 10, 0, 5)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        nameLabel.Font = Enum.Font.GothamSSm
        nameLabel.TextSize = 14
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = item

        local descLabel = Instance.new("TextLabel")
        descLabel.Text = script.desc
        descLabel.Size = UDim2.new(1, -10, 0, 20)
        descLabel.Position = UDim2.new(0, 15, 0, 30)
        descLabel.BackgroundTransparency = 1
        descLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
        descLabel.Font = Enum.Font.GothamSSm
        descLabel.TextSize = 11
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.Parent = item

        local statusIcon = Instance.new("Frame")
        statusIcon.Size = UDim2.new(0, 8, 0, 8)
        statusIcon.Position = UDim2.new(1, -18, 0.5, -4)
        statusIcon.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        statusIcon.BorderSizePixel = 0
        statusIcon.Parent = item

        local iconCorner = Instance.new("UICorner")
        iconCorner.CornerRadius = UDim.new(1, 0)
        iconCorner.Parent = statusIcon

        local itemButton = Instance.new("TextButton")
        itemButton.Size = UDim2.new(1, 0, 1, 0)
        itemButton.BackgroundTransparency = 1
        itemButton.Text = ""
        itemButton.Parent = item

        scriptButtons[i] = {item = item, status = statusIcon, button = itemButton}
    end

    local loadBtn = Instance.new("TextButton")
    loadBtn.Size = UDim2.new(1, -20, 0, 35)
    loadBtn.Position = UDim2.new(0, 10, 1, -45)
    loadBtn.BackgroundColor3 = Color3.fromRGB(255, 45, 85)
    loadBtn.Text = "LOAD SELECTED"
    loadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    loadBtn.Font = Enum.Font.GothamSSm
    loadBtn.TextSize = 14
    loadBtn.Parent = main

    local loadCorner = Instance.new("UICorner")
    loadCorner.CornerRadius = UDim.new(0, 3)
    loadCorner.Parent = loadBtn

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Text = "Click a module to select it, then press LOAD"
    statusLabel.Size = UDim2.new(1, -20, 0, 20)
    statusLabel.Position = UDim2.new(0, 10, 1, -70)
    statusLabel.BackgroundTransparency = 1
    statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    statusLabel.Font = Enum.Font.GothamSSm
    statusLabel.TextSize = 11
    statusLabel.Parent = main

    local selectedIdx = 1
    scriptButtons[1].item.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    scriptButtons[1].item.UIStroke.Color = Color3.fromRGB(0, 212, 255)

    for i, btnData in ipairs(scriptButtons) do
        btnData.button.MouseButton1Click:Connect(function()
            for j, bd in ipairs(scriptButtons) do
                bd.item.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
                bd.item.UIStroke.Color = Color3.fromRGB(42, 42, 42)
            end
            selectedIdx = i
            btnData.item.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            btnData.item.UIStroke.Color = Color3.fromRGB(0, 212, 255)
        end)
    end

    loadBtn.MouseButton1Click:Connect(function()
        local selected = ScriptList[selectedIdx]
        if selected and not selected.loaded then
            statusLabel.Text = "Loading " .. selected.file .. "..."
            statusLabel.TextColor3 = Color3.fromRGB(0, 212, 255)
            local url = "https://" .. GitHubRepo .. "/" .. selected.file
            local ok = LoadScript(selected.name, url)
            if ok then
                selected.loaded = true
                scriptButtons[selectedIdx].status.BackgroundColor3 = Color3.fromRGB(0, 255, 136)
                statusLabel.Text = selected.name .. " loaded successfully!"
                statusLabel.TextColor3 = Color3.fromRGB(0, 255, 136)
            else
                statusLabel.Text = "Failed to load " .. selected.name
                statusLabel.TextColor3 = Color3.fromRGB(255, 45, 85)
            end
        elseif selected and selected.loaded then
            statusLabel.Text = selected.name .. " already loaded"
            statusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
        end
    end)

    LoaderFrame = {Destroy = function()
        screenGui:Destroy()
    end}
end

if Config.Capabilities.HasDrawingAPI then
    CreateDrawingLoader()
else
    CreateInstanceLoader()
end

getgenv().DefusalModules["loader"] = {
    name = "Loader Hub",
    version = "1.0.0",
    loaded = true,
    cleanup = function()
        if LoaderFrame then LoaderFrame:Destroy() end
    end
}
