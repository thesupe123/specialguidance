local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ==========================================
-- Variables
-- ==========================================
local isTargeting = false
local targetPlayer = nil
local launch = false
local debounce = false

local missile = nil
local target = nil

local speed = 1800
local navConstant = 5.2
local accelFactor = 0.78
local pingMultiplier = 1.45
local smoothingAlpha = 0.26

local targetLastVel = Vector3.new()
local targetAccelSmoothed = Vector3.new()

-- Predicted Position Part
local predictedPart = Instance.new("Part")
predictedPart.Anchored = true
predictedPart.Name = "PredictedPosition"
predictedPart.Size = Vector3.new(16, 16, 16)
predictedPart.Transparency = 0.6
predictedPart.Color = Color3.fromRGB(255, 255, 0)
predictedPart.CanCollide = false
predictedPart.CanTouch = false
predictedPart.Parent = workspace

local handles = Instance.new("Handles")
handles.Adornee = predictedPart
handles.Style = Enum.HandlesStyle.Resize
handles.Color3 = Color3.new(1, 1, 0)
handles.Parent = workspace

-- ==========================================
-- UI
-- ==========================================
local playerGui = game.CoreGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MissileLockSystem"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Main Control Frame
local controlFrame = Instance.new("Frame")
controlFrame.Size = UDim2.new(0, 220, 0, 190)
controlFrame.Position = UDim2.new(0, 20, 0, 50)
controlFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
controlFrame.BorderSizePixel = 0
controlFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 12)
uiCorner.Parent = controlFrame

local uiStroke = Instance.new("UIStroke")
uiStroke.Thickness = 1.5
uiStroke.Color = Color3.fromRGB(80, 80, 90)
uiStroke.Parent = controlFrame

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundTransparency = 1
title.Text = "MISSILE LOCK SYSTEM"
title.TextColor3 = Color3.fromRGB(255, 50, 50)
title.Font = Enum.Font.GothamBlack
title.TextSize = 16
title.Parent = controlFrame

-- Toggle Button
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0.9, 0, 0, 45)
toggleButton.Position = UDim2.new(0.05, 0, 0, 45)
toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.Text = "TARGETING: OFF"
toggleButton.TextSize = 16
toggleButton.Parent = controlFrame

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggleButton

-- Launch Button
local launchButton = Instance.new("TextButton")
launchButton.Size = UDim2.new(0.9, 0, 0, 45)
launchButton.Position = UDim2.new(0.05, 0, 0, 100)
launchButton.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
launchButton.TextColor3 = Color3.fromRGB(255, 255, 255)
launchButton.Font = Enum.Font.GothamBold
launchButton.Text = "LAUNCH MISSILE"
launchButton.TextSize = 17
launchButton.Parent = controlFrame

local launchCorner = Instance.new("UICorner")
launchCorner.CornerRadius = UDim.new(0, 8)
launchCorner.Parent = launchButton

-- Destroy Button
local destroyButton = Instance.new("TextButton")
destroyButton.Size = UDim2.new(0.9, 0, 0, 35)
destroyButton.Position = UDim2.new(0.05, 0, 0, 155)
destroyButton.BackgroundColor3 = Color3.fromRGB(170, 20, 20)
destroyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
destroyButton.Font = Enum.Font.GothamBold
destroyButton.Text = "DESTROY SYSTEM"
destroyButton.TextSize = 14
destroyButton.Parent = controlFrame

local destroyCorner = Instance.new("UICorner")
destroyCorner.CornerRadius = UDim.new(0, 8)
destroyCorner.Parent = destroyButton

-- Target Label
local targetLabel = Instance.new("TextLabel")
targetLabel.Size = UDim2.new(0, 340, 0, 55)
targetLabel.Position = UDim2.new(0.5, -170, 0, 15)
targetLabel.BackgroundTransparency = 0.25
targetLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
targetLabel.TextColor3 = Color3.fromRGB(255, 85, 85)
targetLabel.Font = Enum.Font.GothamBlack
targetLabel.Text = "NO TARGET LOCKED"
targetLabel.TextSize = 20
targetLabel.Parent = screenGui

local labelCorner = Instance.new("UICorner")
labelCorner.CornerRadius = UDim.new(0, 10)
labelCorner.Parent = targetLabel

local labelStroke = Instance.new("UIStroke")
labelStroke.Thickness = 2.5
labelStroke.Color = Color3.fromRGB(255, 60, 60)
labelStroke.Parent = targetLabel

-- Box Container
local boxContainer = Instance.new("Frame")
boxContainer.Size = UDim2.new(1, 0, 1, 0)
boxContainer.BackgroundTransparency = 1
boxContainer.Parent = screenGui

-- ==========================================
-- Lock Box System
-- ==========================================
local activeBoxes = {}

local function createLockBox(player)
	local boxFrame = Instance.new("Frame")
	boxFrame.Name = player.Name .. "_LockBox"
	boxFrame.Size = UDim2.new(0, 68, 0, 68)
	boxFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	boxFrame.BackgroundTransparency = 1
	boxFrame.Parent = boxContainer

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2.5
	stroke.Color = Color3.fromRGB(0, 255, 100)
	stroke.Parent = boxFrame

	local infoLabel = Instance.new("TextLabel")
	infoLabel.Size = UDim2.new(0, 200, 0, 40)
	infoLabel.Position = UDim2.new(0.5, -100, 0, -45)
	infoLabel.BackgroundTransparency = 1
	infoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	infoLabel.Font = Enum.Font.GothamBold
	infoLabel.TextSize = 13
	infoLabel.TextStrokeTransparency = 0.4
	infoLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	infoLabel.Parent = boxFrame

	activeBoxes[player] = {Box = boxFrame, Info = infoLabel}
	
	boxFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and isTargeting then
			targetPlayer = player
			targetLabel.Text = "LOCKED → " .. string.upper(player.Name)
			targetLabel.TextColor3 = Color3.fromRGB(255, 70, 70)
		end
	end)
end

-- Render loop for boxes
RunService.RenderStepped:Connect(function()
	if not isTargeting then
		for _, data in pairs(activeBoxes) do
			data.Box.Visible = false
		end
		return
	end

	local myRoot = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
	
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local root = player.Character.HumanoidRootPart
			local screenPos, onScreen = camera:WorldToViewportPoint(root.Position + Vector3.new(0, 2.5, 0))
			
			local boxData = activeBoxes[player] or createLockBox(player)
			local box = boxData.Box
			local info = boxData.Info
			
			box.Visible = onScreen
			
			if onScreen then
				box.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y)
				local distance = myRoot and math.floor((myRoot.Position - root.Position).Magnitude) or 0
				info.Text = string.upper(player.Name) .. "\n" .. distance .. " studs"
				
				local stroke = box:FindFirstChildOfClass("UIStroke")
				if player == targetPlayer then
					stroke.Color = Color3.fromRGB(255, 60, 60)
					stroke.Thickness = 4
					box.Size = UDim2.new(0, 82, 0, 82)
				else
					stroke.Color = Color3.fromRGB(0, 255, 100)
					stroke.Thickness = 2.5
					box.Size = UDim2.new(0, 68, 0, 68)
				end
			end
		end
	end
end)

-- ==========================================
-- Buttons
-- ==========================================
toggleButton.MouseButton1Click:Connect(function()
	isTargeting = not isTargeting
	if isTargeting then
		toggleButton.Text = "TARGETING: ON"
		toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 80)
	else
		toggleButton.Text = "TARGETING: OFF"
		toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
		targetPlayer = nil
		targetLabel.Text = "NO TARGET LOCKED"
		targetLabel.TextColor3 = Color3.fromRGB(255, 85, 85)
	end
end)

launchButton.MouseButton1Click:Connect(function()
	if not targetPlayer then
		launchButton.Text = "NO TARGET LOCKED!"
		task.wait(1.5)
		launchButton.Text = "LAUNCH MISSILE"
		return
	end
	
	if not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
		launchButton.Text = "TARGET NOT FOUND!"
		task.wait(1.2)
		launchButton.Text = "LAUNCH MISSILE"
		return
	end
	
	if debounce then
		launch = false
		debounce = false
	else
		-- Setup missile folder if needed
		local aircraft = game.Workspace:FindFirstChild(localPlayer.Name .. " Aircraft")
		if aircraft then
			for _, v in pairs(aircraft:GetDescendants()) do
				if v.Name == "ExplosiveBlock" then
					local folder = v.Parent:FindFirstChild(tostring(v.Decorate.BrickColor))
					if not folder then
						folder = Instance.new("Folder")
						folder.Name = tostring(v.Decorate.BrickColor)
						folder.Parent = v.Parent
					end
					v.Parent = folder
				end
			end
		end
		
		launch = true
		debounce = true
	end
end)

destroyButton.MouseButton1Click:Connect(function()
	screenGui:Destroy()
	if predictedPart then predictedPart:Destroy() end
	if handles then handles:Destroy() end
end)

-- ==========================================
-- Main Guidance Loop
-- ==========================================
RunService.Stepped:Connect(function(dt)
	-- Update references
	if targetPlayer and launch then
		target = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
		local aircraft = workspace:FindFirstChild(localPlayer.Name .. " Aircraft")
		if aircraft then
			local folder = aircraft:FindFirstChildOfClass("Folder")
			if folder then
				missile = folder:FindFirstChild("ExplosiveBlock") and folder.ExplosiveBlock:FindFirstChild("Decorate")
			end
		end
	end
	
	if not (launch and target and missile) then return end
	
	-- Smoothed Acceleration
	local targetVel = target.Velocity
	local rawAccel = (targetVel - targetLastVel) / dt
	targetAccelSmoothed = targetAccelSmoothed:Lerp(rawAccel, smoothingAlpha)
	targetLastVel = targetVel
	
	-- Prediction (latency compensation + lead)
	local ping = localPlayer:GetNetworkPing()
	local dist = (target.Position - missile.Position).Magnitude
	local timeToTarget = dist / speed
	local totalTime = timeToTarget + ping * pingMultiplier
	
	local predictedPos = target.Position 
		+ targetVel * totalTime 
		+ 0.5 * targetAccelSmoothed * totalTime^2
	
	predictedPart.Position = predictedPos
	
	-- EPN Guidance
	local relPos = predictedPos - missile.Position
	local los = relPos.Unit
	local distance = relPos.Magnitude
	
	if distance < 40 then
		los = (target.Position - missile.Position).Unit  -- Terminal phase
	end
	
	local losRate = los:Cross(targetVel) / math.max(distance, 10)
	
	local commandAccel = navConstant * losRate:Cross(missile.Velocity)
	              + (targetAccelSmoothed:Cross(los) * accelFactor)
	
	commandAccel += los * 55
	
	-- Apply Force
	local force = missile:FindFirstChild("GuidanceForce") or Instance.new("VectorForce", missile)
	force.RelativeTo = Enum.ActuatorRelativeTo.World
	if not force.Attachment0 then
		force.Attachment0 = Instance.new("Attachment", missile)
	end
	force.Force = commandAccel * missile:GetMass() * 1.8
	
	-- Visual orientation
	missile.CFrame = CFrame.lookAt(missile.Position, predictedPos)
	
	-- Explosion
	if distance < 18 then
		for _, v in pairs(missile.Parent.Parent:GetChildren()) do
			if v.Name == "ExplosiveBlock" then
				v.Events.Explode:Fire(4)
			end
		end
		launch = false
		debounce = false
		task.wait(2)
		if localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") then
			camera.CameraSubject = localPlayer.Character.Humanoid
		end
		if missile.Parent and missile.Parent.Parent then
			missile.Parent.Parent:Destroy()
		end
	end
end)
