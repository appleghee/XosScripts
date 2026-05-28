local Config = {
    Services = {
        Players = game:GetService("Players"),
        RunService = game:GetService("RunService"),
        UserInputService = game:GetService("UserInputService"),
        CoreGui = game:GetService("CoreGui"),
        ReplicatedStorage = game:GetService("ReplicatedStorage"),
        Workspace = workspace,
        Lighting = game:GetService("Lighting"),
        TweenService = game:GetService("TweenService"),
        HttpService = game:GetService("HttpService"),
        Teams = game:GetService("Teams"),
        ContextActionService = game:GetService("ContextActionService"),
    },
    LocalPlayer = nil,
    Mouse = nil,
    Character = nil,
    Capabilities = {},
    RegisteredModules = {},
    Toggles = {
        ESP_Players = false, ESP_Bomb = false, ESP_Weapons = false, ESP_TeamCheck = false, ESP_Skeleton = false, ESP_BoxType = "2D",
        Aimbot_Enabled = false, Aimbot_SilentAim = false, Aimbot_Triggerbot = false, Aimbot_TeamCheck = false, Aimbot_RageMode = false, Aimbot_AntiRecoil = false,
        Defuse_AutoDefuse = false, Defuse_FastPlant = false, Defuse_AutoPlant = false, Defuse_AutoTeleport = false,
        Utility_InfiniteCash = false, Utility_KillAll = false, Utility_ThirdPerson = false, Utility_FovChanger = false, Utility_AntiAim = false, Utility_Skinchanger = false, Utility_AutoLoadout = false,
    },
    Sliders = {
        Aimbot_FOV = 90, Aimbot_Smoothness = 0.5, Aimbot_HitChance = 70, Aimbot_TriggerbotDelay = 0,
        ESP_Distance = 1000, FovChanger_Amount = 90, ThirdPerson_Distance = 10,
    },
    Dropdowns = {
        ESP_BoxType = "2D", Aimbot_AimPart = "Head", Aimbot_Method = "Silent", AntiAim_Mode = "Jitter",
    },
    Anti = {
        DisableOnLowHealth = false, HealthThreshold = 20, PanicKey = Enum.KeyCode.F8, RandomizedDelay = true, PanicMode = false, HealthDisabled = false,
    },
    Remotes = {},
    Drawings = {},
    Connections = {},
    Keybinds = {},
    GUIInstance = nil,
}

local Players = Config.Services.Players
local RunService = Config.Services.RunService
local HttpService = Config.Services.HttpService

local function DetectCapabilities()
    Config.Capabilities = {
        HasDrawingAPI = pcall(function() local sq = Drawing.new("Square") sq:Remove() return true end),
        HasMouseMoveRel = type(mousemoverel) == "function",
        HasClamp = type(clamp) == "function",
        HasRawMeta = pcall(function() return getrawmetatable(game) ~= nil end),
        HasNewCClosure = type(newcclosure) == "function",
        HasCheckCaller = type(checkcaller) == "function",
        HasIsLuaFunction = type(isluafunction) == "function",
        HasFireServer = type(fireserver) == "function",
        HasFireClickDetector = type(fireclickdetector) == "function",
    }
end

DetectCapabilities()

Config.LocalPlayer = Players.LocalPlayer
if Config.LocalPlayer then
    Config.Mouse = Config.LocalPlayer:GetMouse()
    Config.Character = Config.LocalPlayer.Character
end

Players:GetPropertyChangedSignal("LocalPlayer"):Connect(function()
    Config.LocalPlayer = Players.LocalPlayer
    if Config.LocalPlayer then
        Config.Mouse = Config.LocalPlayer:GetMouse()
    end
end)

local REMOTE_PATTERNS = {
    Defuse = {"Defuse", "DefuseC4", "C4Defuse", "Defusing", "BombDefuse"},
    Plant = {"PlantC4", "BombPlant", "PlantBomb", "C4Plant", "BombPlace"},
    Bomb = {"Bomb", "C4", "BombRemote", "C4Remote"},
    Turn = {"ControlTurn", "TurnCharacter", "Rotate", "ControlRotation"},
    Movement = {"Move", "Movement", "Input", "PlayerInput"},
    Shoot = {"Shoot", "Fire", "WeaponFire", "Remote", "Bullet", "Hit"},
    Damage = {"Damage", "HitPlayer", "ApplyDamage", "DealDamage"},
    Reload = {"Reload", "Ammo", "WeaponReload"},
    Spawn = {"Spawn", "Respawn", "PlayerSpawned", "OnSpawn"},
    Round = {"RoundStart", "RoundEnd", "GameStart", "NewRound"},
    Cash = {"UpdateCash", "MoneyChanged", "CashUpdate", "Points"},
    Buy = {"BuyWeapon", "PurchaseItem", "BuyItem", "ShopBuy"},
    Skin = {"UpdateSkin", "WeaponSkin", "ApplySkin", "SkinChanger"},
    Loadout = {"Loadout", "SelectLoadout", "EquipWeapon", "WeaponSelect"},
    Interact = {"Interact", "InteractObject", "UseItem", "Pickup"},
}

local function SmartRemoteScan()
    local scanResult = {}
    local rs = Config.Services.ReplicatedStorage
    for _, obj in ipairs(rs:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            scanResult[obj.Name] = obj
        end
    end
    for _, obj in ipairs(Config.Services.Workspace:GetDescendants()) do
        if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) and not scanResult[obj.Name] then
            scanResult[obj.Name] = obj
        end
    end
    for _, obj in ipairs(Config.LocalPlayer:GetDescendants()) do
        if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) and not scanResult[obj.Name] then
            scanResult[obj.Name] = obj
        end
    end
    for name, remote in pairs(scanResult) do
        local lowerName = name:lower()
        for category, patterns in pairs(REMOTE_PATTERNS) do
            for _, pattern in ipairs(patterns) do
                if lowerName:find(pattern:lower()) then
                    Config.Remotes[category] = Config.Remotes[category] or {}
                    Config.Remotes[category][name] = remote
                    break
                end
            end
        end
    end
    return scanResult
end

local success, result = pcall(SmartRemoteScan)
if not success then
    warn("[DefusalSuite] Remote scan failed: " .. tostring(result))
end

task.spawn(function()
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function()
            pcall(SmartRemoteScan)
        end)
    end)
end)

getgenv().DefusalConfig = Config
getgenv().DefusalModules = {}

return Config
