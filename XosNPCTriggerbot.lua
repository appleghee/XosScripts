--// 🏹 NPC TriggerBot GUI (Free Version)

--// 🏛️ Thư viện
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

--// 🔧 Biến cài đặt
local TriggerBotEnabled = false
local HeadHitboxExpand = 1 -- Hệ số mở rộng Hitbox đầu (1x đến 3x để đơn giản)

--// 🎛️ GUI đơn giản
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TriggerBotGui"
ScreenGui.Parent = game.CoreGui
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 200, 0, 150)
MainFrame.Position = UDim2.new(0.5, -100, 0.5, -75)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Title.Text = "NPC TriggerBot (Free)"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16
Title.Parent = MainFrame

local TriggerBotButton = Instance.new("TextButton")
TriggerBotButton.Size = UDim2.new(0.9, 0, 0, 30)
TriggerBotButton.Position = UDim2.new(0.05, 0, 0.2, 0)
TriggerBotButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
TriggerBotButton.Text = "TriggerBot: OFF"
TriggerBotButton.TextColor3 = Color3.fromRGB(255, 255, 255)
TriggerBotButton.Font = Enum.Font.SourceSans
TriggerBotButton.TextSize = 14
TriggerBotButton.Parent = MainFrame

local HeadHitboxSlider = Instance.new("Frame")
HeadHitboxSlider.Size = UDim2.new(0.9, 0, 0, 20)
HeadHitboxSlider.Position = UDim2.new(0.05, 0, 0.5, 0)
HeadHitboxSlider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
HeadHitboxSlider.Parent = MainFrame

local SliderBar = Instance.new("Frame")
SliderBar.Size = UDim2.new(1, -20, 0.5, 0)
SliderBar.Position = UDim2.new(0, 0, 0.25, 0)
SliderBar.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
SliderBar.Parent = HeadHitboxSlider

local SliderButton = Instance.new("TextButton")
SliderButton.Size = UDim2.new(0, 10, 1, 0)
SliderButton.Position = UDim2.new(0, 0, 0, 0)
SliderButton.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
SliderButton.Text = ""
SliderButton.Parent = SliderBar

local HeadHitboxLabel = Instance.new("TextLabel")
HeadHitboxLabel.Size = UDim2.new(1, 0, 0.5, 0)
HeadHitboxLabel.Position = UDim2.new(0, 0, -0.5, 0)
HeadHitboxLabel.BackgroundTransparency = 1
HeadHitboxLabel.Text = "HeadHitbox: 1x"
HeadHitboxLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
HeadHitboxLabel.Font = Enum.Font.SourceSans
HeadHitboxLabel.TextSize = 14
HeadHitboxLabel.Parent = HeadHitboxSlider

--// 🔥 Chức năng TriggerBot
local function ToggleTriggerBot()
    TriggerBotEnabled = not TriggerBotEnabled
    TriggerBotButton.Text = "TriggerBot: " .. (TriggerBotEnabled and "ON" or "OFF")
    TriggerBotButton.BackgroundColor3 = TriggerBotEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(70, 70, 70)
end

local function UpdateSlider(input)
    local position = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
    SliderButton.Position = UDim2.new(position, 0, 0, 0)
    HeadHitboxExpand = math.floor((position * 2) + 1) -- Giới hạn từ 1x đến 3x cho phiên bản free
    HeadHitboxLabel.Text = "HeadHitbox: " .. tostring(HeadHitboxExpand) .. "x"
end

--// 🤖 TriggerBot Logic (đơn giản hóa)
RunService.RenderStepped:Connect(function()
    if TriggerBotEnabled then
        local Target = Mouse.Target
        if Target and Target.Parent:FindFirstChild("Humanoid") then
            local NPC = Target.Parent

            -- Bỏ qua người chơi thật
            if Players:GetPlayerFromCharacter(NPC) then
                return
            end

            -- Kiểm tra NPC còn sống (HP > 0)
            local Humanoid = NPC:FindFirstChild("Humanoid")
            if Humanoid and Humanoid.Health > 0 then
                local Head = NPC:FindFirstChild("Head")
                if Head then
                    -- Mở rộng HeadHitbox
                    Head.Size = Vector3.new(2, 2, 2) * HeadHitboxExpand
                    
                    -- Nhắm vào đầu NPC (giữ góc nhìn tự nhiên, không can thiệp camera)
                    -- Bắn tự động (giả lập click chuột)
                    mouse1press()
                    wait(0.1) -- Tốc độ bắn đơn giản
                    mouse1release()
                    
                    -- Reset HeadHitbox về bình thường sau khi bắn
                    Head.Size = Vector3.new(2, 2, 2)
                end
            end
        end
    end
end)

--// 🎮 Hotkey bật/tắt TriggerBot (phím C)
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.C then
        ToggleTriggerBot()
    end
end)

--// 🖱️ Thanh kéo Hitbox
SliderButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local moveConnection, releaseConnection
        moveConnection = UserInputService.InputChanged:Connect(function(moveInput)
            if moveInput.UserInputType == Enum.UserInputType.MouseMovement then
                UpdateSlider(moveInput)
            end
        end)
        releaseConnection = UserInputService.InputEnded:Connect(function(releaseInput)
            if releaseInput.UserInputType == Enum.UserInputType.MouseButton1 then
                moveConnection:Disconnect()
                releaseConnection:Disconnect()
            end
        end)
    end
end)

TriggerBotButton.MouseButton1Click:Connect(ToggleTriggerBot)

-- Tác Giả: Appleghee
