local player = game:GetService("Players").LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

local flying = false
local baseSpeed = 50
local flyKey = Enum.KeyCode.X
local camera = workspace.CurrentCamera
local userInputService = game:GetService("UserInputService")
local tweenService = game:GetService("TweenService")
local tiltAngle = 15 -- Maximum tilt angle in degrees
local tiltSpeed = 5 -- Speed of tilt interpolation

-- Physical components
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

-- Notification system
local function showNotification(message)
	local playerGui = player:WaitFirstChild("PlayerGui")
	if not playerGui then
		playerGui = Instance.new("PlayerGui")
		playerGui.Name = "PlayerGui"
		playerGui.Parent = player
	end

	for _, v in ipairs(playerGui:GetChildren()) do
		if v.Name == "FlyNotification" then
			v:Destroy()
		end
	end

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

	tweenService:Create(frame, TweenInfo.new(0.3), {BackgroundTransparency = 0.3}):Play()
	tweenService:Create(textLabel, TweenInfo.new(0.3), {TextTransparency = 0}):Play()

	task.delay(2, function()
		tweenService:Create(frame, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
		tweenService:Create(textLabel, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
		task.delay(0.5, function()
			frame:Destroy()
		end)
	end)
end

-- Animation control
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

-- Flight loop
local function flightLoop()
	local lastCFrame = rootPart.CFrame
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
		
		-- Calculate tilt based on direction (reversed)
		local tiltX, tiltZ = 0, 0
		if direction.Magnitude > 0 then
			local localDir = cf:VectorToObjectSpace(direction)
			tiltX = localDir.Z * tiltAngle -- Reverse forward/back tilt
			tiltZ = -localDir.X * tiltAngle -- Reverse left/right tilt
		end
		
		-- Apply smooth tilt using Lerp
		local targetCFrame = cf * CFrame.Angles(math.rad(tiltX), 0, math.rad(tiltZ))
		lastCFrame = lastCFrame:Lerp(targetCFrame, tiltSpeed * task.wait())
		bg.CFrame = lastCFrame
		
		task.wait()
	end
end

-- Toggle flight
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

-- Mobile GUI setup
local function setupMobileGUI()
	if not userInputService.TouchEnabled then return end

	local playerGui = player:WaitFirstChild("PlayerGui")
	if not playerGui then
		playerGui = Instance.new("PlayerGui")
		playerGui.Name = "PlayerGui"
		playerGui.Parent = player
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MobileFlyGui"
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Name = "FlyButtonFrame"
	frame.Size = UDim2.new(0, 80, 0, 80)
	frame.Position = UDim2.new(0.9, -90, 0.8, -90)
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

	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, -10, 0.7, -10)
	button.Position = UDim2.new(0.5, 0, 0.35, 0)
	button.AnchorPoint = Vector2.new(0.5, 0.35)
	button.BackgroundTransparency = 1
	button.Text = "✈️ OFF"
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 20
	button.Font = Enum.Font.GothamBold
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
	creditLabel.Parent = frame

	-- Button animations
	local function animateButton(state)
		local scale = state == "Hover" and 1.05 or state == "Press" and 0.95 or 1
		local transparency = state == "Hover" and 0.2 or 0
		tweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
			TextTransparency = transparency,
			[Enum.UIPadding.PaddingTop] = UDim.new(0, 0)
		}):Play()
		tweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
			Size = UDim2.new(0, 80 * scale, 0, 80 * scale)
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
		if humanoid.Health > 0 then
			toggleFlight()
			button.Text = flying and "✈️ ON" or "✈️ OFF"
		end
	end)
end

-- Input handling
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == flyKey and humanoid.Health > 0 then
		toggleFlight()
	end
end)

-- Character reset handling
player.CharacterAdded:Connect(function(newChar)
	character = newChar
	humanoid = newChar:WaitForChild("Humanoid")
	rootPart = newChar:WaitForChild("HumanoidRootPart")
	createPhysics()
	flying = false
	controlAnimations(true)
end)

-- Initial setup
controlAnimations(true)
setupMobileGUI()
