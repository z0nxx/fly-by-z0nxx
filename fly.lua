local function setupMobileGUI()
    if not userInputService.TouchEnabled then return end

    -- Wait for PlayerGui to ensure it's ready
    local playerGui = player:WaitForChild("PlayerGui", 5)
    if not playerGui then
        playerGui = Instance.new("PlayerGui")
        playerGui.Name = "PlayerGui"
        playerGui.Parent = player
    end

    -- Remove any existing MobileFlyGui to prevent duplicates
    for _, v in ipairs(playerGui:GetChildren()) do
        if v.Name == "MobileFlyGui" then
            v:Destroy()
        end
    end

    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MobileFlyGui"
    screenGui.Enabled = true -- Explicitly enable the ScreenGui
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui

    -- Create Frame
    local frame = Instance.new("Frame")
    frame.Name = "FlyButtonFrame"
    frame.Size = UDim2.new(0.15, 0, 0.15, 0) -- Use scale for mobile compatibility
    frame.Position = UDim2.new(0.85, 0, 0.75, 0) -- Adjusted for better mobile placement
    frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    frame.BackgroundTransparency = 0
    frame.BorderSizePixel = 0
    frame.ZIndex = 10
    frame.Parent = screenGui

    -- Add gradient
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 80)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 80, 120))
    })
    gradient.Rotation = 45
    gradient.Parent = frame

    -- Add rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame

    -- Add shadow
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(30, 30, 30)
    stroke.Transparency = 0.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = frame

    -- Create Button
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -10, 0.7, -10)
    button.Position = UDim2.new(0.5, 0, 0.35, 0)
    button.AnchorPoint = Vector2.new(0.5, 0.35)
    button.BackgroundTransparency = 1
    button.Text = "✈️ OFF"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 20
    button.Font = Enum.Font.GothamBold
    button.ZIndex = 11 -- Higher ZIndex to ensure visibility
    button.Parent = frame

    -- Credit text
    local creditLabel = Instance.new("TextLabel")
    creditLabel.Size = UDim2.new(1, 0, 0.2, 0)
    creditLabel.Position = UDim2.new(0.5, 0, 0.85, 0)
    creditLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    creditLabel.BackgroundTransparency = 1
    creditLabel.Text = "Fly by z0nxx"
    creditLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    creditLabel.TextSize = 12
    creditLabel.Font = Enum.Font.Gotham
    creditLabel.ZIndex = 11
    creditLabel.Parent = frame

    -- Button animations
    local function animateButton(state)
        local scale = state == "Hover" and 1.05 or state == "Press" and 0.95 or 1
        local transparency = state == "Hover" and 0.2 or 0
        tweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            TextTransparency = transparency
        }):Play()
        tweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            Size = UDim2.new(0.15 * scale, 0, 0.15 * scale, 0)
        }):Play()
    end

    button.MouseEnter:Connect(function() animateButton("Hover") end)
    button.MouseLeave:Connect(function() animateButton("Default") end)
    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            animateButton("Press")
        end
    end)
    button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            animateButton("Hover")
        end
    end)

    -- Draggable functionality
    local dragging = false
    local dragStart = nil
    local startPos = nil

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch and dragging then
            local delta = input.Position - dragStart
            local newPos = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
            frame.Position = newPos
        end
    end)

    frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- Toggle flight on button click
    button.Activated:Connect(function()
        if humanoid and humanoid.Health > 0 then
            toggleFlight()
            button.Text = flying and "✈️ ON" or "✈️ OFF"
        end
    end)
end
