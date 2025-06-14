local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local flying = false
local baseFlightSpeed = 50 -- Base flight speed
local flightSpeed = baseFlightSpeed
local bodyVelocity = nil
local bodyGyro = nil
local tiltMaxAngle = 30 -- Max tilt angle for character flight (degrees)
local targetPart = nil -- Tracks character or vehicle part
local circlePart = nil -- Tracks neon circle effect
local colorConnection = nil -- Tracks color animation

-- Circle effect configuration
local CIRCLE_THICKNESS = 0.2 -- Thickness of the circle (studs)
local CIRCLE_TRANSPARENCY = 0.3 -- Transparency (0 = opaque, 1 = invisible)
local SIZE_MULTIPLIER = 1.5 -- Circle size relative to vehicle
local COLOR_SHIFT_SPEED = 2 -- Speed of color cycling (higher = faster)

local function createCircleEffect(vehicle, seatPart)
	if circlePart then
		circlePart:Destroy()
		circlePart = nil
	end
	if colorConnection then
		colorConnection:Disconnect()
		colorConnection = nil
	end

	local cframe, size = vehicle:GetBoundingBox()
	local maxDimension = math.max(size.X, size.Z) * SIZE_MULTIPLIER
	local height = CIRCLE_THICKNESS

	circlePart = Instance.new("Part")
	circlePart.Name = "VehicleCircleEffect"
	circlePart.Shape = Enum.PartType.Cylinder
	circlePart.Size = Vector3.new(height, maxDimension, maxDimension)
	circlePart.CFrame = CFrame.new(cframe.Position - Vector3.new(0, size.Y / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	circlePart.Anchored = true
	circlePart.CanCollide = false
	circlePart.Transparency = CIRCLE_TRANSPARENCY
	circlePart.Material = Enum.Material.Neon
	circlePart.Parent = workspace

	local startHue = 0
	colorConnection = RunService.Heartbeat:Connect(function(dt)
		if circlePart and circlePart.Parent then
			startHue = (startHue + dt * COLOR_SHIFT_SPEED) % 1
			local color = Color3.fromHSV(startHue, 1, 1)
			circlePart.BrickColor = BrickColor.new(color)
		else
			if colorConnection then
				colorConnection:Disconnect()
				colorConnection = nil
			end
		end
	end)

	local targetPart = vehicle.PrimaryPart or seatPart
	RunService:BindToRenderStep("UpdateCircleEffect", Enum.RenderPriority.Camera.Value, function()
		if circlePart and targetPart and targetPart.Parent then
			local vehicleCFrame, vehicleSize = vehicle:GetBoundingBox()
			circlePart.CFrame = CFrame.new(vehicleCFrame.Position - Vector3.new(0, vehicleSize.Y / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
		else
			if circlePart then
				circlePart:Destroy()
				circlePart = nil
				RunService:UnbindFromRenderStep("UpdateCircleEffect")
				if colorConnection then
					colorConnection:Disconnect()
					colorConnection = nil
				end
			end
		end
	end)
end

local function toggleFlight()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	
	if not (character and humanoid and rootPart and humanoid.Health > 0) then
		return
	end

	flying = not flying
	if bodyVelocity then
		bodyVelocity:Destroy()
		bodyVelocity = nil
	end
	if bodyGyro then
		bodyGyro:Destroy()
		bodyGyro = nil
	end

	if flying then
		targetPart = rootPart
		local isSeated = humanoid.SeatPart ~= nil
		if isSeated then
			local vehicle = humanoid.SeatPart.Parent
			targetPart = vehicle.PrimaryPart or humanoid.SeatPart
		else
			humanoid.PlatformStand = true
		end
		
		bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		bodyVelocity.Velocity = Vector3.new(0, 0, 0)
		bodyVelocity.Parent = targetPart
		
		bodyGyro = Instance.new("BodyGyro")
		bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
		bodyGyro.CFrame = targetPart.CFrame
		bodyGyro.Parent = targetPart
	else
		if humanoid.SeatPart == nil then
			humanoid.PlatformStand = false
		end
		targetPart = nil
	end
end

local function updateFlight()
	if not flying then return end
	
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not (character and humanoid and bodyVelocity and bodyGyro and targetPart) then
		flying = false
		return
	end
	
	local camera = workspace.CurrentCamera
	local moveDirection = Vector3.new()
	
	-- Horizontal movement inputs
	if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then
		moveDirection = moveDirection + camera.CFrame.LookVector
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) then
		moveDirection = moveDirection - camera.CFrame.LookVector
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then
		moveDirection = moveDirection - camera.CFrame.RightVector
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then
		moveDirection = moveDirection + camera.CFrame.RightVector
	end
	
	-- Vertical movement for character flight only
	if not humanoid.SeatPart then
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			moveDirection = moveDirection + Vector3.new(0, 1, 0)
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
			moveDirection = moveDirection - Vector3.new(0, 1, 0)
		end
	end
	
	-- Speed modifiers
	flightSpeed = baseFlightSpeed
	if humanoid.SeatPart then
		-- Vehicle flight: Shift (3x), Space (0.5x)
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
			flightSpeed = baseFlightSpeed * 3
		elseif UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			flightSpeed = baseFlightSpeed * 0.5
		end
	else
		-- Character flight: Shift (2x)
		if not UserInputService.TouchEnabled and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
			flightSpeed = baseFlightSpeed * 2
		end
	end
	
	-- Apply instant movement
	local velocity = Vector3.new(0, 0, 0)
	if moveDirection.Magnitude > 0 then
		velocity = moveDirection.Unit * flightSpeed
	end
	bodyVelocity.Velocity = velocity
	
	-- Orientation
	local lookCFrame
	if velocity.Magnitude > 0 then
		lookCFrame = CFrame.new(Vector3.new(0, 0, 0), velocity * Vector3.new(1, 0, 1))
	else
		lookCFrame = camera.CFrame * CFrame.new(0, 0, -1)
	end
	
	if humanoid.SeatPart then
		-- Sharp orientation for vehicle flight
		bodyGyro.CFrame = lookCFrame
	else
		-- Smooth tilt for character flight
		local velocityLocal = camera.CFrame:VectorToObjectSpace(velocity)
		local pitchAngle = math.clamp(-velocityLocal.Y / flightSpeed * tiltMaxAngle, -tiltMaxAngle, tiltMaxAngle)
		local rollAngle = math.clamp(velocityLocal.X / flightSpeed * tiltMaxAngle, -tiltMaxAngle, tiltMaxAngle)
		local tiltCFrame = CFrame.Angles(math.rad(pitchAngle), 0, math.rad(-rollAngle))
		bodyGyro.CFrame = lookCFrame * tiltCFrame
	end
end

local function setupMobileGUI()
	local playerGui = player:WaitForChild("PlayerGui", 10)
	if not playerGui then
		warn("PlayerGui not found!")
		return
	end

	for _, v in ipairs(playerGui:GetChildren()) do
		if v.Name == "MobileFlyGui" then
			v:Destroy()
		end
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MobileFlyGui"
	screenGui.Enabled = true
	screenGui.IgnoreGuiInset = true
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Name = "FlyButtonFrame"
	frame.Size = UDim2.new(0.15, 0, 0.15, 0)
	frame.Position = UDim2.new(0.85, 0, 0.75, 0)
	frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	frame.BackgroundTransparency = 0
	frame.BorderSizePixel = 0
	frame.ZIndex = 10
	frame.Parent = screenGui

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 80)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 80, 120))
	})
	gradient.Rotation = 45
	gradient.Parent = frame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

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
	button.ZIndex = 11
	button.Parent = frame

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

	local function animateButton(state)
		local scale = state == "Hover" and 1.05 or state == "Press" and 0.95 or 1
		local transparency = state == "Hover" and 0.2 or 0
		TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
			TextTransparency = transparency
		}):Play()
		TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
			Size = UDim2.new(0.15 * scale, 0, 0.15 * scale, 0)
		}):Play()
	end

	button.MouseEnter:Connect(function() animateButton("Hover") end)
	button.MouseLeave:Connect(function() animateButton("Default") end)
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			animateButton("Press")
		end
	end)
	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			animateButton("Hover")
		end
	end)

	local dragging = false
	local dragStart = nil
	local startPos = nil

	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
		end
	end)

	frame.InputChanged:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and dragging then
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
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	return button
end

local function onSeated(active, seatPart)
	if active and seatPart then
		local vehicle = seatPart.Parent
		if vehicle:IsA("Model") then
			createCircleEffect(vehicle, seatPart)
		end
	else
		if circlePart then
			circlePart:Destroy()
			circlePart = nil
			RunService:UnbindFromRenderStep("UpdateCircleEffect")
			if colorConnection then
				colorConnection:Disconnect()
				colorConnection = nil
			end
		end
	end
end

local mobileButton = nil
if UserInputService.TouchEnabled then
	mobileButton = setupMobileGUI()
	if mobileButton then
		mobileButton.Activated:Connect(function()
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				toggleFlight()
				mobileButton.Text = flying and "✈️ ON" or "✈️ OFF"
			end
		end)
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.X and not UserInputService.TouchEnabled then
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			toggleFlight()
		end
	end
end)

RunService.RenderStepped:Connect(updateFlight)

player.CharacterAdded:Connect(function(character)
	flying = false
	if bodyVelocity then
		bodyVelocity:Destroy()
		bodyVelocity = nil
	end
	if bodyGyro then
		bodyGyro:Destroy()
		bodyGyro = nil
	end
	if circlePart then
		circlePart:Destroy()
		circlePart = nil
		RunService:UnbindFromRenderStep("UpdateCircleEffect")
		if colorConnection then
			colorConnection:Disconnect()
			colorConnection = nil
		end
	end
	targetPart = nil

	local humanoid = character:WaitForChild("Humanoid", 10)
	if humanoid then
		humanoid.Seated:Connect(onSeated)
	end

	if UserInputService.TouchEnabled then
		mobileButton = setupMobileGUI()
		if mobileButton then
			mobileButton.Activated:Connect(function()
				local char = player.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then
					toggleFlight()
					mobileButton.Text = flying and "✈️ ON" or "✈️ OFF"
				end
			end)
		end
	end
end)

if player.Character then
	local humanoid = player.Character:WaitForChild("Humanoid", 10)
	if humanoid then
		humanoid.Seated:Connect(onSeated)
	end
end
