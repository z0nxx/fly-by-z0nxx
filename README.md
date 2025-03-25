-- Ultimate Fly Script v6 (Fixed Notifications)
local player = game:GetService("Players").LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

local flying = false
local baseSpeed = 50
local flyKey = Enum.KeyCode.X
local camera = workspace.CurrentCamera
local userInputService = game:GetService("UserInputService")

-- Физические компоненты
local bg, bv = nil, nil

local function createPhysics()
    if bg then bg:Destroy() end
    if bv then bv:Destroy() end
    
    bg = Instance.new("BodyGyro")
    bg.P = 20000
    bg.D = 500
    bg.MaxTorque = Vector3.new(0, 0, 0)
    bg.Parent = rootPart

    bv = Instance.new("BodyVelocity")
    bv.P = 20000
    bv.MaxForce = Vector3.new(0, 0, 0)
    bv.Velocity = Vector3.new(0, 0, 0)
    bv.Parent = rootPart
end

createPhysics()

-- Улучшенная система уведомлений
local function showNotification(message)
    -- Создаем GUI если его нет
    local playerGui = player:FindFirstChildOfClass("PlayerGui")
    if not playerGui then
        playerGui = Instance.new("PlayerGui")
        playerGui.Name = "PlayerGui"
        playerGui.Parent = player
    end

    -- Удаляем старые уведомления
    for _, v in ipairs(playerGui:GetChildren()) do
        if v.Name == "FlyNotification" then
            v:Destroy()
        end
    end

    -- Создаем новое уведомление
    local frame = Instance.new("Frame")
    frame.Name = "FlyNotification"
    frame.Size = UDim2.new(0, 300, 0, 50)
    frame.Position = UDim2.new(0.5, -150, 0.9, 0)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.ZIndex = 10

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -20, 1, -20)
    textLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
    textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "✈️ " .. message
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextSize = 18
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Parent = frame

    frame.Parent = playerGui

    -- Анимация появления
    frame.BackgroundTransparency = 1
    textLabel.TextTransparency = 1

    local tweenService = game:GetService("TweenService")
    tweenService:Create(frame, TweenInfo.new(0.3), {BackgroundTransparency = 0.3}):Play()
    tweenService:Create(textLabel, TweenInfo.new(0.3), {TextTransparency = 0}):Play()

    -- Автоматическое исчезновение через 2 секунды
    task.delay(2, function()
        tweenService:Create(frame, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
        tweenService:Create(textLabel, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
        task.delay(0.5, function()
            frame:Destroy()
        end)
    end)
end

-- Контроль анимаций
local function controlAnimations(enable)
    if not humanoid then return end
    
    for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
        if track.Animation.AnimationId:match("walk") then
            if enable then
                track:Play()
            else
                track:Stop()
            end
        end
    end
end

-- Основной цикл полета
local function flightLoop()
    while flying and humanoid and rootPart and humanoid.Health > 0 do
        local speed = baseSpeed
        if userInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            speed = baseSpeed * 2
            showNotification("Fly ON | Speed: "..speed.." (Turbo)")
        elseif userInputService:IsKeyDown(Enum.KeyCode.Space) then
            speed = baseSpeed / 2
            showNotification("Fly ON | Speed: "..speed.." (Slow)")
        end
        
        local cf = camera.CFrame
        local direction = Vector3.new()
        
        if userInputService:IsKeyDown(Enum.KeyCode.W) then direction += cf.LookVector end
        if userInputService:IsKeyDown(Enum.KeyCode.S) then direction -= cf.LookVector end
        if userInputService:IsKeyDown(Enum.KeyCode.A) then direction -= cf.RightVector end
        if userInputService:IsKeyDown(Enum.KeyCode.D) then direction += cf.RightVector end
        
        if userInputService:IsKeyDown(Enum.KeyCode.E) then direction += Vector3.new(0, 1, 0) end
        if userInputService:IsKeyDown(Enum.KeyCode.Q) then direction -= Vector3.new(0, 1, 0) end
        
        if direction.Magnitude > 0 then
            direction = direction.Unit * speed
        end
        bv.Velocity = direction
        bg.CFrame = cf
        
        task.wait()
    end
end

-- Переключение режима полета
local function toggleFlight()
    flying = not flying
    
    if flying then
        humanoid.PlatformStand = true
        bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        showNotification("Fly ON | Speed: "..baseSpeed)
        controlAnimations(false)
        coroutine.wrap(flightLoop)()
    else
        bg.MaxTorque = Vector3.new(0, 0, 0)
        bv.MaxForce = Vector3.new(0, 0, 0)
        bv.Velocity = Vector3.new(0, 0, 0)
        humanoid.PlatformStand = false
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        showNotification("Fly OFF")
        controlAnimations(true)
    end
end

-- Обработка ввода
userInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == flyKey and humanoid.Health > 0 then
        toggleFlight()
    end
end)

-- Обработка смены персонажа
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    rootPart = newChar:WaitForChild("HumanoidRootPart")
    createPhysics()
    flying = false
    controlAnimations(true)
end)

-- Первоначальная настройка
controlAnimations(true)
