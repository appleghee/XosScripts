local Config = getgenv().DefusalConfig
if not Config then error("[DefusalSuite] config.lua must be loaded first!") end
if getgenv().DefusalModules["esp"] then warn("[DefusalSuite] ESP already loaded"); return end

local Players = Config.Services.Players
local RunService = Config.Services.RunService
local CoreGui = Config.Services.CoreGui
local Lighting = Config.Services.Lighting
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local espConnection = nil
local billboardESPs = {}

local function WorldToScreen(worldPos)
    local point, onScreen = Camera:WorldToScreenPoint(worldPos)
    return Vector2.new(point.X, point.Y), onScreen
end

local function GetHealthColor(percent)
    if percent > 60 then return Color3.fromRGB(60, 255, 60)
    elseif percent > 30 then return Color3.fromRGB(255, 255, 60)
    else return Color3.fromRGB(255, 60, 60) end
end

local function GetTeamColor(player)
    if player.Team then
        return player.Team.TeamColor.Color
    end
    return Color3.fromRGB(255, 255, 255)
end

local SkeletonPoints = {
    "Head", "UpperTorso", "LowerTorso",
    "LeftUpperArm", "LeftLowerArm", "LeftHand",
    "RightUpperArm", "RightLowerArm", "RightHand",
    "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
    "RightUpperLeg", "RightLowerLeg", "RightFoot",
}

local SkeletonConnections = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
}

if Config.HasDrawingAPI then
    local function EnsureESPDrawings(count)
        Config.Drawings.ESP = Config.Drawings.ESP or {}
        for i = #Config.Drawings.ESP + 1, count do
            Config.Drawings.ESP[i] = {
                BoxOutline = Drawing.new("Square"),
                BoxFill = Drawing.new("Square"),
                HealthBar = Drawing.new("Square"),
                HealthBarBg = Drawing.new("Square"),
                NameLabel = Drawing.new("Text"),
                DistLabel = Drawing.new("Text"),
                Skeleton = {},
                CornerLines = {},
            }
            for _ = 1, 8 do
                local line = Drawing.new("Line")
                table.insert(Config.Drawings.ESP[i].CornerLines, line)
            end
        end
    end

    local function DrawBox2D(idx, topLeft, size, color, healthPercent)
        local d = Config.Drawings.ESP[idx]
        if not d then return end
        d.BoxOutline.Visible = true
        d.BoxOutline.Size = size
        d.BoxOutline.Position = topLeft
        d.BoxOutline.Color = color
        d.BoxOutline.Thickness = 2
        d.BoxOutline.Filled = false
        d.HealthBarBg.Visible = true
        d.HealthBarBg.Size = Vector2.new(4, size.Y)
        d.HealthBarBg.Position = Vector2.new(topLeft.X - 6, topLeft.Y)
        d.HealthBarBg.Color = Color3.fromRGB(30, 30, 30)
        d.HealthBarBg.Filled = true
        d.HealthBar.Visible = true
        d.HealthBar.Size = Vector2.new(4, size.Y * (healthPercent / 100))
        d.HealthBar.Position = Vector2.new(topLeft.X - 6, topLeft.Y + size.Y * (1 - healthPercent / 100))
        d.HealthBar.Color = GetHealthColor(healthPercent)
        d.HealthBar.Filled = true
    end

    local function DrawCornerBox(idx, topLeft, size, color)
        local d = Config.Drawings.ESP[idx]
        if not d then return end
        local cornerLen = math.min(size.X, size.Y) * 0.2
        local corners = {
            {Vector2.new(topLeft.X, topLeft.Y), Vector2.new(topLeft.X + cornerLen, topLeft.Y)},
            {Vector2.new(topLeft.X, topLeft.Y), Vector2.new(topLeft.X, topLeft.Y + cornerLen)},
            {Vector2.new(topLeft.X + size.X, topLeft.Y), Vector2.new(topLeft.X + size.X - cornerLen, topLeft.Y)},
            {Vector2.new(topLeft.X + size.X, topLeft.Y), Vector2.new(topLeft.X + size.X, topLeft.Y + cornerLen)},
            {Vector2.new(topLeft.X, topLeft.Y + size.Y), Vector2.new(topLeft.X + cornerLen, topLeft.Y + size.Y)},
            {Vector2.new(topLeft.X, topLeft.Y + size.Y), Vector2.new(topLeft.X, topLeft.Y + size.Y - cornerLen)},
            {Vector2.new(topLeft.X + size.X, topLeft.Y + size.Y), Vector2.new(topLeft.X + size.X - cornerLen, topLeft.Y + size.Y)},
            {Vector2.new(topLeft.X + size.X, topLeft.Y + size.Y), Vector2.new(topLeft.X + size.X, topLeft.Y + size.Y - cornerLen)},
        }
        for i, corner in ipairs(corners) do
            if d.CornerLines[i] then
                d.CornerLines[i].Visible = true
                d.CornerLines[i].From = corner[1]
                d.CornerLines[i].To = corner[2]
                d.CornerLines[i].Color = color
                d.CornerLines[i].Thickness = 1.5
            end
        end
    end

    local function DrawSkeleton(idx, character, color)
        local d = Config.Drawings.ESP[idx]
        if not d then return end
        local parts = {}
        for _, name in ipairs(SkeletonPoints) do
            local part = character:FindFirstChild(name)
            if part then
                local pos, onScreen = WorldToScreen(part.Position)
                parts[name] = {pos = pos, onScreen = onScreen}
            end
        end
        for i, conn in ipairs(SkeletonConnections) do
            local from = parts[conn[1]]
            local to = parts[conn[2]]
            if from and to and from.onScreen and to.onScreen then
                if not d.Skeleton[i] then
                    d.Skeleton[i] = Drawing.new("Line")
                end
                d.Skeleton[i].Visible = true
                d.Skeleton[i].From = from.pos
                d.Skeleton[i].To = to.pos
                d.Skeleton[i].Color = color
                d.Skeleton[i].Thickness = 1
            elseif d.Skeleton[i] then
                d.Skeleton[i].Visible = false
            end
        end
    end

    espConnection = RunService.RenderStepped:Connect(function()
        if not Config.Toggles.ESP_Players then
            if Config.Drawings.ESP then
                for _, d in ipairs(Config.Drawings.ESP) do
                    if type(d) == "table" then
                        if d.BoxOutline then d.BoxOutline.Visible = false end
                        if d.BoxFill then d.BoxFill.Visible = false end
                        if d.HealthBar then d.HealthBar.Visible = false end
                        if d.HealthBarBg then d.HealthBarBg.Visible = false end
                        if d.NameLabel then d.NameLabel.Visible = false end
                        if d.DistLabel then d.DistLabel.Visible = false end
                        for _, line in ipairs(d.CornerLines or {}) do
                            if line then line.Visible = false end
                        end
                        for _, line in ipairs(d.Skeleton or {}) do
                            if line then line.Visible = false end
                        end
                    end
                end
            end
            return
        end

        local maxDist = Config.Sliders.ESP_Distance
        local drawIdx = 1
        local targetPlayers = {}

        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then
                if Config.Toggles.ESP_ShowSelf then
                    table.insert(targetPlayers, player)
                end
            else
                table.insert(targetPlayers, player)
            end
        end

        for _, player in ipairs(targetPlayers) do
            if not player.Character then continue end
            local character = player.Character
            local humanoid = character:FindFirstChildWhichIsA("Humanoid")
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if not humanoid or not rootPart then continue end
            if humanoid.Health <= 0 then continue end

            if Config.Toggles.ESP_TeamCheck and player ~= LocalPlayer and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
                continue
            end

            local dist = (rootPart.Position - Camera.CFrame.Position).Magnitude
            if dist > maxDist then continue end

            local head = character:FindFirstChild("Head")
            local torso = character:FindFirstChild("UpperTorso") or rootPart
            if not head then continue end

            local headPos, headOnScreen = WorldToScreen(head.Position + Vector3.new(0, 0.5, 0))
            local rootPos, rootOnScreen = WorldToScreen(rootPart.Position - Vector3.new(0, 1, 0))
            if not (headOnScreen or rootOnScreen) then continue end

            local boxHeight = math.abs(headPos.Y - rootPos.Y)
            local boxWidth = boxHeight * 0.6
            local centerX = (headPos.X + rootPos.X) / 2
            local topLeft = Vector2.new(centerX - boxWidth/2, headPos.Y)

            EnsureESPDrawings(drawIdx + 5)
            local d = Config.Drawings.ESP[drawIdx]
            if not d then continue end

            local espColor = Color3.fromRGB(255, 80, 80)
            if player == LocalPlayer then
                espColor = Color3.fromRGB(80, 255, 80)
            elseif Config.Toggles.ESP_TeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
                espColor = Color3.fromRGB(80, 255, 80)
            end

            local healthPercent = (humanoid.Health / humanoid.MaxHealth) * 100

            local boxType = Config.Dropdowns.ESP_BoxType
            if boxType == "Corner" then
                DrawCornerBox(drawIdx, topLeft, Vector2.new(boxWidth, boxHeight), espColor)
            else
                DrawBox2D(drawIdx, topLeft, Vector2.new(boxWidth, boxHeight), espColor, healthPercent)
            end

            d.NameLabel.Visible = true
            d.NameLabel.Text = player.Name
            d.NameLabel.Position = Vector2.new(topLeft.X, topLeft.Y - 16)
            d.NameLabel.Color = espColor
            d.NameLabel.Size = 13
            d.NameLabel.Center = true
            d.NameLabel.Outline = true

            d.DistLabel.Visible = true
            d.DistLabel.Text = math.floor(dist) .. "m"
            d.DistLabel.Position = Vector2.new(topLeft.X, topLeft.Y + boxHeight + 2)
            d.DistLabel.Color = Color3.fromRGB(200, 200, 200)
            d.DistLabel.Size = 11
            d.DistLabel.Center = true

            if Config.Toggles.ESP_Skeleton then
                DrawSkeleton(drawIdx, character, espColor)
            end

            drawIdx = drawIdx + 1
        end

        for i = drawIdx, #(Config.Drawings.ESP or {}) do
            local d = Config.Drawings.ESP[i]
            if type(d) == "table" then
                if d.BoxOutline then d.BoxOutline.Visible = false end
                if d.HealthBar then d.HealthBar.Visible = false end
                if d.HealthBarBg then d.HealthBarBg.Visible = false end
                if d.NameLabel then d.NameLabel.Visible = false end
                if d.DistLabel then d.DistLabel.Visible = false end
                for _, line in ipairs(d.CornerLines or {}) do
                    if line then line.Visible = false end
                end
                for _, line in ipairs(d.Skeleton or {}) do
                    if line then line.Visible = false end
                end
            end
        end

        if Config.Toggles.ESP_Bomb then
            local bomb = nil
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") and (obj.Name == "C4" or obj.Name == "PlantedC4" or obj.Name == "Bomb") then
                    bomb = obj
                    break
                end
            end
            if bomb then
                local screenPos, onScreen = WorldToScreen(bomb.Position)
                if onScreen then
                    local bombDist = (bomb.Position - Camera.CFrame.Position).Magnitude
                    Config.Drawings.ESP_Bomb = Config.Drawings.ESP_Bomb or {}
                    local bd = Config.Drawings.ESP_Bomb
                    bd.Label = bd.Label or Drawing.new("Text")
                    bd.Outline = bd.Outline or Drawing.new("Square")
                    bd.Label.Visible = true
                    bd.Label.Text = "[BOMB] " .. math.floor(bombDist) .. "m"
                    bd.Label.Position = Vector2.new(screenPos.X, screenPos.Y - 20)
                    bd.Label.Color = Color3.fromRGB(255, 50, 50)
                    bd.Label.Size = 16
                    bd.Label.Center = true
                    bd.Label.Outline = true
                    bd.Outline.Visible = true
                    bd.Outline.Size = Vector2.new(120, 20)
                    bd.Outline.Position = Vector2.new(screenPos.X - 60, screenPos.Y - 30)
                    bd.Outline.Color = Color3.fromRGB(255, 0, 0)
                    bd.Outline.Filled = false
                    bd.Outline.Thickness = 2
                end
            end
        end

        if Config.Toggles.ESP_Weapons then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Tool") and obj.Parent == workspace then
                    local handle = obj:FindFirstChild("Handle") or obj:FindFirstChildWhichIsA("BasePart")
                    if handle then
                        local screenPos, onScreen = WorldToScreen(handle.Position)
                        if onScreen then
                            Config.Drawings.ESP_WeaponLabels = Config.Drawings.ESP_WeaponLabels or {}
                            local wl = Config.Drawings.ESP_WeaponLabels
                            wl.Label = wl.Label or Drawing.new("Text")
                            wl.Label.Visible = true
                            wl.Label.Text = obj.Name
                            wl.Label.Position = Vector2.new(screenPos.X, screenPos.Y)
                            wl.Label.Color = Color3.fromRGB(255, 200, 50)
                            wl.Label.Size = 12
                            wl.Label.Center = true
                        end
                    end
                end
            end
        end
    end)
else
    local function CreateBillboardESP(player)
        local character = player.Character
        if not character then return end
        local adornee = character:FindFirstChild("LowerTorso") or character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
        if not adornee then return end

        if billboardESPs[player] then
            pcall(function() billboardESPs[player]:Destroy() end)
        end

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "DefusalESP_" .. player.Name
        billboard.Adornee = adornee
        billboard.Size = UDim2.new(0, 200, 0, 70)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Enabled = Config.Toggles.ESP_Players
        billboard.ClipsDescendants = false
        billboard.Parent = CoreGui

        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(1, 0, 1, 0)
        bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        bg.BackgroundTransparency = 0.4
        bg.BorderSizePixel = 0
        bg.Parent = billboard

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Text = player.Name
        nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.Font = Enum.Font.GothamSSm
        nameLabel.TextSize = 14
        nameLabel.Parent = billboard

        local healthBarBg = Instance.new("Frame")
        healthBarBg.Size = UDim2.new(0.8, 0, 0, 4)
        healthBarBg.Position = UDim2.new(0.1, 0, 0.5, 0)
        healthBarBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        healthBarBg.BorderSizePixel = 0
        healthBarBg.Parent = billboard

        local healthBar = Instance.new("Frame")
        healthBar.Size = UDim2.new(1, 0, 1, 0)
        healthBar.BackgroundColor3 = Color3.fromRGB(60, 255, 60)
        healthBar.BorderSizePixel = 0
        healthBar.Parent = healthBarBg

        local distLabel = Instance.new("TextLabel")
        distLabel.Text = ""
        distLabel.Size = UDim2.new(1, 0, 0.3, 0)
        distLabel.Position = UDim2.new(0, 0, 0.6, 0)
        distLabel.BackgroundTransparency = 1
        distLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        distLabel.Font = Enum.Font.GothamSSm
        distLabel.TextSize = 10
        distLabel.Parent = billboard

        local humanoid = character:FindFirstChildWhichIsA("Humanoid")
        local healthConn
        if humanoid then
            healthConn = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
                local healthPercent = humanoid.Health / humanoid.MaxHealth * 100
                healthBar.Size = UDim2.new(healthPercent / 100, 0, 1, 0)
                healthBar.BackgroundColor3 = GetHealthColor(healthPercent)
            end)
        end

        local updateConn = RunService.RenderStepped:Connect(function()
            if not billboard or not billboard.Parent then
                if updateConn then updateConn:Disconnect() end
                return
            end
            billboard.Enabled = Config.Toggles.ESP_Players
            local dist = 0
            if character and character:FindFirstChild("HumanoidRootPart") then
                dist = (character.HumanoidRootPart.Position - Camera.CFrame.Position).Magnitude
            end
            distLabel.Text = math.floor(dist) .. "m"
        end)

        billboardESPs[player] = billboard
        return billboard
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if player.Character then
                CreateBillboardESP(player)
            end
            player.CharacterAdded:Connect(function()
                CreateBillboardESP(player)
            end)
        end
    end

    Players.PlayerAdded:Connect(function(player)
        if player ~= LocalPlayer then
            player.CharacterAdded:Connect(function()
                CreateBillboardESP(player)
            end)
        end
    end)

    Players.PlayerRemoving:Connect(function(player)
        if billboardESPs[player] then
            pcall(function() billboardESPs[player]:Destroy() end)
            billboardESPs[player] = nil
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(function()
    Camera = workspace.CurrentCamera
end)
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = workspace.CurrentCamera
end)

getgenv().DefusalModules["esp"] = {
    name = "ESP Module",
    version = "1.0.0",
    loaded = true,
    cleanup = function()
        if espConnection then espConnection:Disconnect() end
        for player, billboard in pairs(billboardESPs) do
            pcall(function() billboard:Destroy() end)
        end
        billboardESPs = {}
        if Config.Drawings.ESP then
            for _, d in ipairs(Config.Drawings.ESP) do
                if type(d) == "table" then
                    for _, sub in pairs(d) do
                        if typeof(sub) == "Drawing" then
                            pcall(function() sub:Remove() end)
                        end
                    end
                end
            end
        end
        Config.Drawings.ESP = nil
    end
}
