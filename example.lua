--[[
    example.lua — Usage demo for gui.lua
    ─────────────────────────────────────
    Run this to see the complete UI library in action.
    Paste into a Script or LocalScript in Roblox Studio.
]]

local GUI = require(script.Parent.gui_library)   -- Adjust path as needed
-- If using loadstring:
-- local GUI = loadstring(game:HttpGet("https://pastebin.com/raw/..."))()

-- ====================================================================
-- CREATE THE MAIN WINDOW
-- ====================================================================
local window = GUI:Window("DEFUSAL HUB", UDim2.fromOffset(385, 480), {
    draggable = true,
    resizable = true,
})

-- ====================================================================
-- TAB: MAIN
-- ====================================================================
local mainTab = window:AddTab("Main")

-- Rage section
local rageSection = mainTab:AddSection("RAGE")
rageSection:AddToggle("Kill All", false, function(v)
    print("[RAGE] Kill All:", v)
end)
rageSection:AddToggle("One Shot", true, function(v)
    print("[RAGE] One Shot:", v)
end)
rageSection:AddToggle("Triggerbot", false, function(v)
    print("[RAGE] Triggerbot:", v)
end)
rageSection:AddSlider("Delay (ms)", 0, 500, 100, function(v)
    print("[RAGE] Delay:", v)
end)
rageSection:AddDropdown("Anti-Aim", {"Off", "Backward", "Jitter", "Spin"}, "Off", function(v)
    print("[RAGE] Anti-Aim:", v)
end)

-- Visuals section
local visSection = mainTab:AddSection("VISUALS")
visSection:AddToggle("ESP Boxes", true, function(v)
    print("[VIS] ESP Boxes:", v)
end)
visSection:AddToggle("Player Chams", false, function(v)
    print("[VIS] Player Chams:", v)
end)
visSection:AddToggle("Tracers", false, function(v)
    print("[VIS] Tracers:", v)
end)
visSection:AddColorPicker("ESP Color", GUI.Theme.Accent, function(c)
    print("[VIS] ESP Color:", c)
end)

-- ====================================================================
-- TAB: AIMBOT
-- ====================================================================
local aimTab = window:AddTab("Aimbot")

local aimSection = aimTab:AddSection("AIMBOT SETTINGS")
aimSection:AddToggle("Silent Aim", true, function(v)
    print("[AIM] Silent Aim:", v)
end)
aimSection:AddToggle("Aimbot", true, function(v)
    print("[AIM] Aimbot:", v)
end)
aimSection:AddSlider("Smoothness", 1, 100, 50, function(v)
    print("[AIM] Smoothness:", v)
end)
aimSection:AddSlider("FOV Circle", 0, 360, 90, function(v)
    print("[AIM] FOV:", v)
end)
aimSection:AddDropdown("Priority", {"Head", "Body", "Nearest"}, "Head", function(v)
    print("[AIM] Priority:", v)
end)

-- ====================================================================
-- TAB: DEFUSE
-- ====================================================================
local defuseTab = window:AddTab("Defuse")

local defSection = defuseTab:AddSection("DEFUSE")
defSection:AddToggle("Auto Defuse", true, function(v)
    print("[DEF] Auto Defuse:", v)
end)
defSection:AddDropdown("Type", {"Near", "Priority", "Farthest"}, "Near", function(v)
    print("[DEF] Defuse Type:", v)
end)
defSection:AddToggle("Fast Plant", false, function(v)
    print("[DEF] Fast Plant:", v)
end)
defSection:AddDropdown("Plant Type", {"Normal", "Instant", "Silent"}, "Normal", function(v)
    print("[DEF] Plant Type:", v)
end)
defSection:AddSlider("Plant Time (ms)", 0, 5000, 2000, function(v)
    print("[DEF] Plant Time:", v)
end)
defSection:AddKeybind("Plant Key", Enum.KeyCode.F, function(k)
    print("[DEF] Plant Key changed to:", k.Name)
end)

-- ====================================================================
-- TAB: MISC
-- ====================================================================
local miscTab = window:AddTab("Misc")

local miscSection = miscTab:AddSection("SETTINGS")
miscSection:AddToggle("Auto Strafe", false, function(v)
    print("[MISC] Auto Strafe:", v)
end)
miscSection:AddToggle("Bunny Hop", true, function(v)
    print("[MISC] BHop:", v)
end)
miscSection:AddToggle("No Recoil", false, function(v)
    print("[MISC] No Recoil:", v)
end)
miscSection:AddToggle("No Spread", false, function(v)
    print("[MISC] No Spread:", v)
end)
miscSection:AddLabel("--- Information ---", {
    Color = GUI.Theme.TextSecondary,
    TextSize = 11,
})
miscSection:AddLabel("Script: Defusal Hub v2.0", { Color = GUI.Theme.Accent })
miscSection:AddLabel("Status: Loaded", { Color = GUI.Theme.ToggleOn })

-- Button to toggle rainbow
miscSection:AddButton("Toggle Rainbow Accent", function()
    local enabled = not GUI.Theme.RainbowEnabled
    GUI:SetRainbow(enabled)
    GUI:Notify("Rainbow", enabled and "Rainbow mode ON" or "Rainbow mode OFF", 3)
end)

-- Button to send notification
miscSection:AddButton("Test Notification", function()
    GUI:Notify("Test", "This is a notification popup!", 5)
end)

-- Keybind section
local bindSection = miscTab:AddSection("HOTKEYS")
bindSection:AddKeybind("Toggle UI", Enum.KeyCode.RightControl, function(k)
    window:Toggle()
    print("[HOTKEY] Toggle UI:", k.Name)
end)
bindSection:AddKeybind("Kill All", Enum.KeyCode.Home, function(k)
    print("[HOTKEY] Kill All keybind:", k.Name)
end)
bindSection:AddKeybind("Triggerbot", Enum.KeyCode.End, function(k)
    print("[HOTKEY] Triggerbot keybind:", k.Name)
end)

-- ====================================================================
// STARTUP NOTIFICATIONS & WATERMARK
-- ====================================================================
task.wait(0.5)
GUI:Watermark("DEFUSAL HUB v2.0")
GUI:Notify("Welcome", "Defusal Hub loaded successfully!", 4)
GUI:Notify("Info", "Press RightControl to toggle UI", 6)

-- ====================================================================
-- CONFIGURATION EXAMPLE (theme customization)
-- ====================================================================
-- Uncomment to customize:
-- GUI:SetAccent(Color3.fromRGB(0, 200, 255))   -- Switch to blue accent
-- GUI:SetTransparency(0.9)                       -- More transparent background

print("= DEFUSAL HUB loaded =")
