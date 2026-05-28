local Config = getgenv().DefusalConfig
if not Config then error("[DefusalSuite] config.lua must be loaded first!") end
if getgenv().DefusalModules["utility"] then warn("[DefusalSuite] Utility already loaded"); return end

local Players = Config.Services.Players
local RunService = Config.Services.RunService
local UserInputService = Config.Services.UserInputService
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local cashConnection = nil
local thirdPersonConn = nil
local fovChangerConn = nil
local antiAimConn = nil

local function FindRemoteByName(name)
    if Config.Remotes[name] then
        if type(Config.Remotes[name]) == "table" then
            for _, r in pairs(Config.Remotes[name]) do
                if type(r) == "userdata" then return r end
            end
        else
            return Config.Remotes[name]
        end
    end
    local rs = Config.Services.ReplicatedStorage
    local found = rs:FindFirstChild(name, true)
    if found and (found:IsA("RemoteEvent") or found:IsA("RemoteFunction")) then
        return found
    end
    return nil
end

local function SafeFireServer(remote, ...)
    if not remote then return false end
    local args = {...}
    local success, err = pcall(function()
        remote:FireServer(unpack(args))
    end)
    if not success then
        warn("[DefusalSuite] Remote call failed: " .. tostring(err))
        return false
    end
    return true
end

local function SetupCashHook(cashValue)
    if cashConnection then cashConnection:Disconnect() end
    cashConnection = cashValue:GetPropertyChangedSignal("Value"):Connect(function()
        if Config.Toggles.Utility_InfiniteCash then
            cashValue.Value = 16000
        end
    end)
    if Config.Toggles.Utility_InfiniteCash then
        cashValue.Value = 16000
    end
end

local function EnableInfiniteCash()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        for _, child in ipairs(leaderstats:GetChildren()) do
            if child:IsA("NumberValue") or child:IsA("IntValue") then
                local name = child.Name:lower()
                if name == "cash" or name == "money" or name == "points" or name == "score" then
                    SetupCashHook(child)
                    return
                end
            end
        end
    end
    LocalPlayer.DescendantAdded:Connect(function(child)
        if Config.Toggles.Utility_InfiniteCash then
            if child:IsA("NumberValue") or child:IsA("IntValue") then
                local name = child.Name:lower()
                if name == "cash" or name == "money" or name == "points" or name == "score" then
                    SetupCashHook(child)
                end
            end
        end
    end)
end

local function KillAll()
    local character = LocalPlayer.Character
    if not character then return end
    local tool = character:FindFirstChildOfClass("Tool")
    if not tool then
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            local firstTool = backpack:FindFirstChildWhichIsA("Tool")
            if firstTool then
                LocalPlayer.Character.Humanoid:EquipTool(firstTool)
                task.wait(0.1)
            end
        end
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not player.Character then continue end

        local rootPart = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Torso") or player.Character:FindFirstChild("Head")
        if not rootPart then continue end

        local hitRemote = FindRemoteByName("Shoot") or FindRemoteByName("Damage")
        if hitRemote then
            SafeFireServer(hitRemote, player, rootPart.Position, rootPart)
        end

        for _, remote in ipairs(tool:GetDescendants()) do
            if remote:IsA("RemoteEvent") then
                SafeFireServer(remote, player, rootPart.Position, rootPart)
            elseif remote:IsA("RemoteFunction") then
                pcall(function() remote:InvokeServer(player, rootPart.Position, rootPart) end)
            end
        end

        local characterDescendants = player.Character:GetDescendants()
        for _, obj in ipairs(characterDescendants) do
            if obj:IsA("ClickDetector") then
                fireclickdetector(obj)
            end
        end
    end
end

local mouse = LocalPlayer:GetMouse()
if mouse then
    mouse.Button1Down:Connect(function()
        if Config.Toggles.Utility_KillAll then
            for _ = 1, 3 do
                KillAll()
                task.wait(0.05)
            end
        end
    end)
end

local function FindThirdPersonValue()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BoolValue") and (obj.Name == "ThirdPerson" or obj.Name == "Third") then
            return obj
        end
    end
    return nil
end

local function EnableThirdPerson()
    if thirdPersonConn then thirdPersonConn:Disconnect() end
    local thirdPersonValue = FindThirdPersonValue()
    if thirdPersonValue then
        thirdPersonValue.Value = true
    end
    local camera = Camera
    camera.CameraType = Enum.CameraType.Custom
    if LocalPlayer.Character then
        camera.CameraSubject = LocalPlayer.Character
    end
    thirdPersonConn = RunService.RenderStepped:Connect(function()
        if not Config.Toggles.Utility_ThirdPerson then return end
        local character = LocalPlayer.Character
        if not character then return end
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            local distance = Config.Sliders.ThirdPerson_Distance
            local camPos = rootPart.Position + (rootPart.CFrame.LookVector * -distance) + Vector3.new(0, 5, 0)
            Camera.CFrame = CFrame.lookAt(camPos, rootPart.Position)
        end
    end)
end

local function EnableFOVChanger()
    if fovChangerConn then fovChangerConn:Disconnect() end
    fovChangerConn = RunService.RenderStepped:Connect(function()
        if not Config.Toggles.Utility_FovChanger then return end
        local targetFOV = Config.Sliders.FovChanger_Amount
        local currentFOV = Camera.FieldOfView
        if math.abs(currentFOV - targetFOV) > 0.5 then
            Camera.FieldOfView = currentFOV + (targetFOV - currentFOV) * 0.1
        end
    end)
end

local function EnableAntiAim()
    if antiAimConn then antiAimConn:Disconnect() end
    local antiAimRemote = FindRemoteByName("Turn")
    if antiAimRemote then
        if Config.Dropdowns.AntiAim_Mode == "Jitter" then
            antiAimConn = RunService.Heartbeat:Connect(function()
                if not Config.Toggles.Utility_AntiAim then return end
                local angle = 180 + math.random(-30, 30)
                SafeFireServer(antiAimRemote, angle, false)
            end)
        elseif Config.Dropdowns.AntiAim_Mode == "Spin" then
            antiAimConn = RunService.Heartbeat:Connect(function()
                if not Config.Toggles.Utility_AntiAim then return end
                local angle = (tick() * 100) % 360
                SafeFireServer(antiAimRemote, angle, false)
            end)
        end
    else
        antiAimConn = RunService.RenderStepped:Connect(function()
            if not Config.Toggles.Utility_AntiAim then return end
            local character = LocalPlayer.Character
            if not character then return end
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                local angle = Config.Dropdowns.AntiAim_Mode == "Spin" and (tick() % 360 * 5) or (180 + math.random(-30, 30))
                rootPart.CFrame = CFrame.new(rootPart.Position) * CFrame.Angles(0, math.rad(angle), 0)
            end
        end)
    end
end

local function EnableSkinchanger()
    local skinRemote = FindRemoteByName("Skin")
    if not skinRemote then
        local rs = Config.Services.ReplicatedStorage
        for _, obj in ipairs(rs:GetDescendants()) do
            if obj:IsA("RemoteEvent") and (
                obj.Name:lower():find("skin") or obj.Name:lower():find("weapon") or obj.Name:lower():find("loadout")
            ) then
                skinRemote = obj
                break
            end
        end
    end
    if skinRemote and LocalPlayer.Character then
        LocalPlayer.Character.ChildAdded:Connect(function(child)
            if child:IsA("Tool") and Config.Toggles.Utility_Skinchanger then
                task.wait(0.1)
                local skinID = Config.Dropdowns.Skin_Selected or 0
                SafeFireServer(skinRemote, child, skinID)
            end
        end)
    end
end

local function EnableAutoLoadout()
    local loadoutRemote = FindRemoteByName("Loadout") or FindRemoteByName("Buy")
    LocalPlayer.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid", 5)
        if not humanoid then return end
        task.wait(1)
        if not Config.Toggles.Utility_AutoLoadout then return end
        if loadoutRemote then
            SafeFireServer(loadoutRemote, Config.Dropdowns.AutoLoadout or 1)
        end
    end)
end

EnableInfiniteCash()
EnableThirdPerson()
EnableFOVChanger()
EnableAntiAim()
EnableSkinchanger()
EnableAutoLoadout()

getgenv().DefusalModules["utility"] = {
    name = "Utility Module",
    version = "1.0.0",
    loaded = true,
    cleanup = function()
        if cashConnection then cashConnection:Disconnect() end
        if thirdPersonConn then thirdPersonConn:Disconnect() end
        if fovChangerConn then fovChangerConn:Disconnect() end
        if antiAimConn then antiAimConn:Disconnect() end
    end
}
