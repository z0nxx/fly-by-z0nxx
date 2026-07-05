-- Fly Script in z0nxx Hub Style (Monochrome) with +/- Speed Buttons
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Цветовая палитра (ч/б)
local BG_DARK = Color3.fromRGB(18, 18, 18)
local BG_MEDIUM = Color3.fromRGB(28, 28, 28)
local BG_LIGHT = Color3.fromRGB(42, 42, 42)
local ACCENT = Color3.fromRGB(100, 100, 100)
local TEXT_PRIMARY = Color3.fromRGB(235, 235, 235)
local GREEN_ACT = Color3.fromRGB(50, 120, 50)

-- Состояние флая
local Flying = false
local FlySpeed = 50
local FlyBind = Enum.KeyCode.E
local ChangingBind = false
local BodyVelocity, BodyGyro
local KeysPressed = {}

-- Создание GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "z0nxxFlyGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local main = Instance.new("Frame", screenGui)
main.Size = UDim2.new(0, 280, 0, 210)
main.Position = UDim2.new(0.5, -140, 0.5, -105)
main.BackgroundColor3 = BG_DARK
main.BackgroundTransparency = 0.15
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.ZIndex = 1
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)

local mainStroke = Instance.new("UIStroke", main)
mainStroke.Thickness = 2
mainStroke.Color = ACCENT
mainStroke.Transparency = 0.3

-- Заголовок
local header = Instance.new("Frame", main)
header.Size = UDim2.new(1, 0, 0, 36)
header.BackgroundColor3 = BG_MEDIUM
header.BorderSizePixel = 0
header.ZIndex = 2
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(1, -30, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "z0nxx Hub | Fly System"
title.TextColor3 = TEXT_PRIMARY
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 3

local closeBtn = Instance.new("TextButton", header)
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -32, 0, 3)
closeBtn.BackgroundColor3 = ACCENT
closeBtn.Text = "X"
closeBtn.TextColor3 = TEXT_PRIMARY
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 16
closeBtn.ZIndex = 3
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

-- Кнопка активации Fly
local toggleBtn = Instance.new("TextButton", main)
toggleBtn.Size = UDim2.new(1, -20, 0, 40)
toggleBtn.Position = UDim2.new(0, 10, 0, 48)
toggleBtn.BackgroundColor3 = ACCENT
toggleBtn.Text = "Toggle Fly: OFF"
toggleBtn.TextColor3 = TEXT_PRIMARY
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.TextSize = 16
toggleBtn.ZIndex = 2
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)

-- Кнопка уменьшения скорости [-]
local minusBtn = Instance.new("TextButton", main)
minusBtn.Size = UDim2.new(0, 30, 0, 36)
minusBtn.Position = UDim2.new(0, 10, 0, 96)
minusBtn.BackgroundColor3 = BG_LIGHT
minusBtn.Text = "-"
minusBtn.TextColor3 = TEXT_PRIMARY
minusBtn.Font = Enum.Font.SourceSansBold
minusBtn.TextSize = 18
minusBtn.ZIndex = 2
Instance.new("UICorner", minusBtn).CornerRadius = UDim.new(0, 6)

-- Поле ввода скорости (в центре)
local speedInput = Instance.new("TextBox", main)
speedInput.Size = UDim2.new(0, 65, 0, 36)
speedInput.Position = UDim2.new(0, 45, 0, 96)
speedInput.BackgroundColor3 = BG_LIGHT
speedInput.BorderSizePixel = 0
speedInput.Text = tostring(FlySpeed)
speedInput.TextColor3 = TEXT_PRIMARY
speedInput.Font = Enum.Font.SourceSans
speedInput.TextSize = 16
speedInput.ZIndex = 2

-- Кнопка увеличения скорости [+]
local plusBtn = Instance.new("TextButton", main)
plusBtn.Size = UDim2.new(0, 30, 0, 36)
plusBtn.Position = UDim2.new(0, 115, 0, 96)
plusBtn.BackgroundColor3 = BG_LIGHT
plusBtn.Text = "+"
plusBtn.TextColor3 = TEXT_PRIMARY
plusBtn.Font = Enum.Font.SourceSansBold
plusBtn.TextSize = 18
plusBtn.ZIndex = 2
Instance.new("UICorner", plusBtn).CornerRadius = UDim.new(0, 6)

-- Кнопка изменения бинда
local bindBtn = Instance.new("TextButton", main)
bindBtn.Size = UDim2.new(0, 125, 0, 36)
bindBtn.Position = UDim2.new(0, 145, 0, 96)
bindBtn.BackgroundColor3 = BG_LIGHT
bindBtn.Text = "Bind: E"
bindBtn.TextColor3 = TEXT_PRIMARY
bindBtn.Font = Enum.Font.SourceSans
bindBtn.TextSize = 16
bindBtn.ZIndex = 2
Instance.new("UICorner", bindBtn).CornerRadius = UDim.new(0, 6)

-- Лог статуса
local statusLabel = Instance.new("TextLabel", main)
statusLabel.Size = UDim2.new(1, -20, 0, 20)
statusLabel.Position = UDim2.new(0, 10, 0, 142)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "System Idle (Press Bind or Button)"
statusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextSize = 13
statusLabel.TextXAlignment = Enum.TextXAlignment.Center
statusLabel.ZIndex = 2

-- Подсказка управления
local controlsLabel = Instance.new("TextLabel", main)
controlsLabel.Size = UDim2.new(1, -20, 0, 20)
controlsLabel.Position = UDim2.new(0, 10, 0, 180)
controlsLabel.BackgroundTransparency = 1
controlsLabel.Text = "W,A,S,D = Move | Space = Up | LShift = Down"
controlsLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
controlsLabel.Font = Enum.Font.SourceSansItalic
controlsLabel.TextSize = 12
controlsLabel.TextXAlignment = Enum.TextXAlignment.Center
controlsLabel.ZIndex = 2

-- Перетаскивание (Drag)
local dragging, dragStart, startPos
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
    end
end)
header.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- ЗАКРЫТИЕ GUI
closeBtn.MouseButton1Click:Connect(function()
    if Flying then
        Flying = false
        if BodyVelocity then BodyVelocity:Destroy() end
        if BodyGyro then BodyGyro:Destroy() end
        local char = LocalPlayer.Character
        if char and char:FindFirstChildOfClass("Humanoid") then
            char:FindFirstChildOfClass("Humanoid").PlatformStand = false
        end
    end
    screenGui:Destroy()
end)

-- ДВИЖОК ПОЛЕТА (FLY)
local function StartFly()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then 
        statusLabel.Text = "Character missing!"
        return 
    end
    local hrp = char.HumanoidRootPart
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    
    if humanoid then humanoid.PlatformStand = true end
    
    BodyGyro = Instance.new("BodyGyro")
    BodyGyro.P = 9e4
    BodyGyro.maxTorque = Vector3.new(9e9, 9e9, 9e9)
    BodyGyro.cframe = hrp.CFrame
    BodyGyro.Parent = hrp
    
    BodyVelocity = Instance.new("BodyVelocity")
    BodyVelocity.velocity = Vector3.new(0, 0.1, 0)
    BodyVelocity.maxForce = Vector3.new(9e9, 9e9, 9e9)
    BodyVelocity.Parent = hrp
    
    Flying = true
    toggleBtn.Text = "Toggle Fly: ON"
    toggleBtn.BackgroundColor3 = GREEN_ACT
    statusLabel.Text = "Flying at speed: " .. FlySpeed
    
    task.spawn(function()
        local camera = workspace.CurrentCamera
        while Flying and char and hrp and BodyVelocity and BodyGyro do
            local direction = Vector3.new(0, 0, 0)
            
            if KeysPressed[Enum.KeyCode.W] then direction = direction + camera.CFrame.LookVector end
            if KeysPressed[Enum.KeyCode.S] then direction = direction - camera.CFrame.LookVector end
            if KeysPressed[Enum.KeyCode.A] then direction = direction - camera.CFrame.RightVector end
            if KeysPressed[Enum.KeyCode.D] then direction = direction + camera.CFrame.RightVector end
            if KeysPressed[Enum.KeyCode.Space] then direction = direction + Vector3.new(0, 1, 0) end
            if KeysPressed[Enum.KeyCode.LeftShift] then direction = direction - Vector3.new(0, 1, 0) end
            
            if direction.Magnitude > 0 then
                BodyVelocity.velocity = direction.Unit * FlySpeed
            else
                BodyVelocity.velocity = Vector3.new(0, 0, 0)
            end
            
            BodyGyro.cframe = camera.CFrame
            RunService.RenderStepped:Wait()
        end
    end)
end

local function StopFly()
    Flying = false
    toggleBtn.Text = "Toggle Fly: OFF"
    toggleBtn.BackgroundColor3 = ACCENT
    statusLabel.Text = "Fly Disabled"
    
    if BodyVelocity then BodyVelocity:Destroy() end
    if BodyGyro then BodyGyro:Destroy() end
    
    local char = LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.PlatformStand = false end
    end
end

-- Обработка интеракций
toggleBtn.MouseButton1Click:Connect(function()
    if Flying then StopFly() else StartFly() end
end)

-- Обновление скорости (Ручной ввод)
local function updateSpeed(newSpeed)
    if newSpeed and newSpeed > 0 then
        FlySpeed = newSpeed
        speedInput.Text = tostring(FlySpeed)
        statusLabel.Text = "Speed set to " .. FlySpeed
        if Flying then statusLabel.Text = "Flying at speed: " .. FlySpeed end
    else
        speedInput.Text = tostring(FlySpeed)
    end
end

speedInput.FocusLost:Connect(function()
    updateSpeed(tonumber(speedInput.Text))
end)

-- Логика кнопок [+] и [-] (Шаг изменения: 5 единиц)
plusBtn.MouseButton1Click:Connect(function()
    updateSpeed(FlySpeed + 5)
end)

minusBtn.MouseButton1Click:Connect(function()
    if FlySpeed > 5 then
        updateSpeed(FlySpeed - 5)
    else
        updateSpeed(1) -- Минимальная скорость, чтоб не уйти в минус
    end
end)

-- Бинд клавиши
bindBtn.MouseButton1Click:Connect(function()
    ChangingBind = true
    bindBtn.Text = "Press any key..."
    statusLabel.Text = "Waiting for input..."
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if ChangingBind and input.UserInputType == Enum.UserInputType.Keyboard then
        FlyBind = input.KeyCode
        bindBtn.Text = "Bind: " .. input.KeyCode.Name
        statusLabel.Text = "New bind assigned: " .. input.KeyCode.Name
        ChangingBind = false
        return
    end
    
    if gameProcessed then return end
    
    if input.KeyCode == FlyBind then
        if Flying then StopFly() else StartFly() end
    elseif Flying and input.UserInputType == Enum.UserInputType.Keyboard then
        KeysPressed[input.KeyCode] = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        KeysPressed[input.KeyCode] = nil
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    StopFly()
end)

-- Анимация появления
main.Position = UDim2.new(0.5, -140, 1.5, 0)
local openTween = TweenService:Create(main, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {Position = UDim2.new(0.5, -140, 0.5, -105)})
openTween:Play()
