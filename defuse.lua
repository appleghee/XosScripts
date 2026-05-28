local Config = getgenv().DefusalConfig
if not Config then error("[DefusalSuite] config.lua must be loaded first!") end
if getgenv().DefusalModules["defuse"] then warn("[DefusalSuite] Defuse already loaded"); return end

local Players = Config.Services.Players
local RunService = Config.Services.RunService
local LocalPlayer = Players.LocalPlayer
local autoDefuseConn = nil
local autoPlantConn = nil

local function FindBomb()
    local bomb = workspace:FindFirstChild("C4") or workspace:FindFirstChild("PlantedC4") or workspace:FindFirstChild("Bomb")
    if not bomb then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and (obj.Name == "C4" or obj.Name == "PlantedC4" or obj.Name == "Bomb") then
                bomb = obj
                break
            end
        end
    end
    return bomb
end

local function FindRemoteByName(name)
    if Config.Remotes[name] then return Config.Remotes[name] end
    for _, remote in pairs(Config.Remotes) do
        if type(remote) == "table" and remote[name] then
            return remote[name]
        end
    end
    local rs = Config.Services.ReplicatedStorage
    local found = rs:FindFirstChild(name, true)
    if found and (found:IsA("RemoteEvent") or found:IsA("RemoteFunction")) then
        return found
    end
    if Config.Remotes.Defuse then
        for _, r in pairs(Config.Remotes.Defuse) do
            if type(r) == "userdata" then return r end
        end
    end
    return nil
end

local function FindC4InInventory()
    local character = LocalPlayer.Character
    if not character then return nil end
    for _, child in ipairs(character:GetChildren()) do
        local name = child.Name:lower()
        if child:IsA("Tool") and (name:find("c4") or name:find("bomb") or name:find("explosive")) then
            return child
        end
    end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, child in ipairs(backpack:GetChildren()) do
            local name = child.Name:lower()
            if child:IsA("Tool") and (name:find("c4") or name:find("bomb") or name:find("explosive")) then
                return child
            end
        end
    end
    return nil
end

local function FindDefuseKit()
    local character = LocalPlayer.Character
    if not character then return nil end
    for _, child in ipairs(character:GetChildren()) do
        local name = child.Name:lower()
        if name:find("defuse") or name:find("kit") or name:find("defusal") then
            return child
        end
    end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, child in ipairs(backpack:GetChildren()) do
            local name = child.Name:lower()
            if name:find("defuse") or name:find("kit") or name:find("defusal") then
                return child
            end
        end
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

local function TryDefuse(bomb)
    local defuseTool = FindDefuseKit()
    local defuseRemote = FindRemoteByName("Defuse")

    if defuseTool then
        if defuseRemote then
            SafeFireServer(defuseRemote, bomb)
        else
            SafeFireServer(defuseTool, bomb)
        end
        return true
    end

    if defuseRemote then
        SafeFireServer(defuseRemote, bomb)
        return true
    end

    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        local defuseInBackpack = backpack:FindFirstChild("Defuse") or backpack:FindFirstChildWhichIsA("Tool")
        if defuseInBackpack and defuseInBackpack:IsA("Tool") then
            SafeFireServer(defuseInBackpack, bomb)
            return true
        end
    end

    local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
    if playerScripts then
        local defuseModule = playerScripts:FindFirstChild("Defuse", true)
        if defuseModule and defuseModule:IsA("RemoteEvent") then
            SafeFireServer(defuseModule, bomb)
            return true
        end
    end

    warn("[DefusalSuite] Could not find defuse remote or tool")
    return false
end

local function TeleportToBomb(bomb)
    local character = LocalPlayer.Character
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    rootPart.CFrame = CFrame.new(bomb.Position + Vector3.new(2, 0, 2))
end

local function GetOptimalPlantPosition()
    local character = LocalPlayer.Character
    if not character then return nil end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end
    return CFrame.new(rootPart.Position - Vector3.new(0, 2, 0))
end

local function TryPlant(customCFrame)
    local plantRemote = FindRemoteByName("Plant")
    if not plantRemote then
        warn("[DefusalSuite] No plant remote found")
        return false
    end
    local c4Tool = FindC4InInventory()
    if not c4Tool then
        warn("[DefusalSuite] No C4 in inventory")
        return false
    end
    local plantPos = customCFrame or GetOptimalPlantPosition()
    if plantPos then
        return SafeFireServer(plantRemote, plantPos)
    else
        return SafeFireServer(plantRemote, c4Tool)
    end
end

autoDefuseConn = RunService.Heartbeat:Connect(function()
    if not Config.Toggles.Defuse_AutoDefuse then return end
    local bomb = FindBomb()
    if not bomb then return end

    local character = LocalPlayer.Character
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local isPlanted = bomb:FindFirstChildOfClass("IntValue") or bomb:FindFirstChildOfClass("NumberValue") or bomb:FindFirstChildOfClass("BoolValue")
    if not isPlanted then
        local gameMode = workspace:FindFirstChild("Gamemode") or workspace:FindFirstChild("GameMode")
        if gameMode and gameMode.Value ~= "defusal" then return end
    end

    local dist = (rootPart.Position - bomb.Position).Magnitude
    local teleportMode = Config.Toggles.Defuse_AutoTeleport

    if dist > 25 and teleportMode then
        TeleportToBomb(bomb)
        task.wait(0.5)
    end

    if dist < 15 then
        TryDefuse(bomb)
    end
end)

autoPlantConn = RunService.Heartbeat:Connect(function()
    if not Config.Toggles.Defuse_AutoPlant then return end
    local c4Tool = FindC4InInventory()
    if c4Tool then
        TryPlant()
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.E and Config.Toggles.Defuse_FastPlant then
        local c4Tool = FindC4InInventory()
        if c4Tool then
            TryPlant()
        end
    end
end)

getgenv().DefusalModules["defuse"] = {
    name = "Defuse Module",
    version = "1.0.0",
    loaded = true,
    cleanup = function()
        if autoDefuseConn then autoDefuseConn:Disconnect() end
        if autoPlantConn then autoPlantConn:Disconnect() end
    end
}
