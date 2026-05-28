local Config = getgenv().DefusalConfig
if not Config then error("[DefusalSuite] config.lua must be loaded first!") end
if getgenv().DefusalModules["aimbot"] then warn("[DefusalSuite] Aimbot already loaded"); return end

local Players = Config.Services.Players
local RunService = Config.Services.RunService
local UserInputService = Config.Services.UserInputService
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local silentAimHooked = false
local oldIndex = nil

local function WorldToScreen(worldPos)
    local point, onScreen = Camera:WorldToScreenPoint(worldPos)
    return Vector2.new(point.X, point.Y), onScreen
end

local function GetClosestTarget()
    local closestDist = Config.Sliders.Aimbot_FOV
    local bestTarget = nil
    local bestPart = nil
    local mousePos = UserInputService:GetMouseLocation()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    local function checkPlayer(player)
        if player == LocalPlayer then return end
        if not player.Character then return end
        local character = player.Character
        local humanoid = character:FindFirstChildWhichIsA("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return end
        if Config.Toggles.Aimbot_TeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
            return
        end

        local aimPart = character:FindFirstChild(Config.Dropdowns.Aimbot_AimPart)
            or character:FindFirstChild("Head")
            or character:FindFirstChild("HumanoidRootPart")
        if not aimPart then return end

        local screenPos, onScreen = Camera:WorldToScreenPoint(aimPart.Position)
        if not onScreen then return end

        local screenVec = Vector2.new(screenPos.X, screenPos.Y)
        local fovDist = (screenVec - center).Magnitude
        if fovDist < closestDist then
            closestDist = fovDist
            bestTarget = player
            bestPart = aimPart
        end
    end

    if Config.Toggles.Aimbot_RageMode then
        for _, player in ipairs(Players:GetPlayers()) do
            checkPlayer(player)
        end
    else
        local target = getgenv().DefusalAimbotTarget
        if target and target.Character then
            checkPlayer(target)
        end
        if not bestTarget then
            for _, player in ipairs(Players:GetPlayers()) do
                checkPlayer(player)
            end
        end
    end

    return bestTarget, bestPart, closestDist
end

local function EnableSilentAim()
    if Config.Capabilities.HasRawMeta and Config.Capabilities.HasNewCClosure and Config.Capabilities.HasCheckCaller and not silentAimHooked then
        local cameraMT = getrawmetatable(Camera)
        if not cameraMT then cameraMT = getrawmetatable(game) end
        if not cameraMT then
            warn("[DefusalSuite] Cannot hook metatable for Silent Aim")
            Config.Dropdowns.Aimbot_Method = "CFrame"
            return
        end

        oldIndex = cameraMT.__index
        cameraMT.__index = newcclosure(function(self, key)
            if not checkcaller() and Config.Toggles.Aimbot_SilentAim and key == "CFrame" then
                local target, aimPart = GetClosestTarget()
                if target and aimPart then
                    if math.random(1, 100) <= Config.Sliders.Aimbot_HitChance then
                        local aimPos = aimPart.Position + Vector3.new(0, 0.5, 0)
                        return CFrame.lookAt(Camera.CFrame.Position, aimPos)
                    end
                end
            end
            return oldIndex(self, key)
        end)

        silentAimHooked = true
        print("[DefusalSuite] Silent Aim enabled")
    elseif not silentAimHooked then
        warn("[DefusalSuite] Executor does not support Silent Aim, falling back to CFrame mode")
        Config.Dropdowns.Aimbot_Method = "CFrame"
    end
end

local function CreateTriggerbot()
    local mouse = LocalPlayer:GetMouse()
    if not mouse then return nil end
    return RunService.Heartbeat:Connect(function()
        if not Config.Toggles.Aimbot_Triggerbot then return end
        local target = mouse.Target
        if not target then return end
        local character = target.Parent
        while character and character ~= workspace do
            if character:IsA("Model") and Players:GetPlayerFromCharacter(character) then
                local player = Players:GetPlayerFromCharacter(character)
                if player ~= LocalPlayer then
                    local delayMs = Config.Sliders.Aimbot_TriggerbotDelay or 0
                    if delayMs > 0 then task.wait(delayMs / 1000) end
                    mouse1click()
                end
                break
            end
            character = character.Parent
        end
    end)
end

local function CreateCFrameAimbot()
    return RunService.RenderStepped:Connect(function()
        if not Config.Toggles.Aimbot_Enabled then return end
        if Config.Dropdowns.Aimbot_Method ~= "CFrame" then return end
        local target, aimPart = GetClosestTarget()
        if not target or not aimPart then return end
        local smoothness = Config.Sliders.Aimbot_Smoothness
        local targetPos = aimPart.Position + Vector3.new(0, 0.5, 0)
        local targetCF = CFrame.lookAt(Camera.CFrame.Position, targetPos)
        local currentCF = Camera.CFrame
        local lerpAlpha = smoothness * RunService.RenderStepped:GetDeltaTime() * 60
        lerpAlpha = math.clamp(lerpAlpha, 0, 1)
        Camera.CFrame = currentCF:Lerp(targetCF, lerpAlpha)
    end)
end

local function CreateMouseAimbot()
    return RunService.RenderStepped:Connect(function()
        if not Config.Toggles.Aimbot_Enabled then return end
        if Config.Dropdowns.Aimbot_Method ~= "Mouse" then return end
        local target, aimPart = GetClosestTarget()
        if not target or not aimPart then return end
        local screenPos, _ = Camera:WorldToScreenPoint(aimPart.Position)
        local mousePos = UserInputService:GetMouseLocation()
        local deltaX = screenPos.X - mousePos.X
        local deltaY = screenPos.Y - mousePos.Y
        local smoothness = Config.Sliders.Aimbot_Smoothness
        if type(mousemoverel) == "function" then
            mousemoverel(deltaX * smoothness, deltaY * smoothness)
        end
    end)
end

local function EnableAntiRecoil()
    return RunService.RenderStepped:Connect(function()
        if not Config.Toggles.Aimbot_AntiRecoil then return end
        local character = LocalPlayer.Character
        if not character then return end
        local currentTool = character:FindFirstChildOfClass("Tool") or character:FindFirstChildWhichIsA("Tool")
        if currentTool then
            local weaponScript = currentTool:FindFirstChild("WeaponScript") or currentTool:FindFirstChild("ModuleScript")
            if weaponScript then
                weaponScript.Disabled = true
                task.wait()
                weaponScript.Disabled = false
            end
        end
    end)
end

local function DrawFOVCircle()
    if not Config.HasDrawingAPI then return end
    Config.Drawings.FOVCircle = Config.Drawings.FOVCircle or Drawing.new("Circle")
    local circle = Config.Drawings.FOVCircle
    RunService.RenderStepped:Connect(function()
        if Config.Toggles.Aimbot_Enabled or Config.Toggles.Aimbot_SilentAim then
            local mousePos = UserInputService:GetMouseLocation()
            circle.Visible = true
            circle.Position = mousePos
            circle.Radius = Config.Sliders.Aimbot_FOV
            circle.Color = Color3.fromRGB(255, 255, 255)
            circle.Thickness = 1
            circle.Transparency = 0.5
            circle.NumSides = 64
            circle.Filled = false
        else
            circle.Visible = false
        end
    end)
end

local triggerbotConn = CreateTriggerbot()
local cframeAimbotConn = CreateCFrameAimbot()
local mouseAimbotConn = CreateMouseAimbot()
local antiRecoilConn = EnableAntiRecoil()

EnableSilentAim()
DrawFOVCircle()

LocalPlayer.CharacterAdded:Connect(function()
    Camera = workspace.CurrentCamera
end)
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = workspace.CurrentCamera
end)

getgenv().DefusalModules["aimbot"] = {
    name = "Aimbot Module",
    version = "1.0.0",
    loaded = true,
    cleanup = function()
        if not silentAimHooked and oldIndex then
            local cameraMT = getrawmetatable(Camera) or getrawmetatable(game)
            if cameraMT then
                cameraMT.__index = oldIndex
            end
        end
        silentAimHooked = false
        if triggerbotConn then triggerbotConn:Disconnect() end
        if cframeAimbotConn then cframeAimbotConn:Disconnect() end
        if mouseAimbotConn then mouseAimbotConn:Disconnect() end
        if antiRecoilConn then antiRecoilConn:Disconnect() end
        if Config.Drawings.FOVCircle then Config.Drawings.FOVCircle:Remove() end
    end
}
