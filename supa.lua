local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
-- Simulate pressing a key


local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local mainheart
-- ==========================================
-- 1. MODERN UI CREATION
-- ==========================================
local playerGui = game.CoreGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MissileLockSystem"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Main Control Frame
local controlFrame = Instance.new("Frame")
controlFrame.Size = UDim2.new(0, 220, 0, 140)
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

-- Destroy Button
local destroyButton = Instance.new("TextButton")
destroyButton.Size = UDim2.new(0.9, 0, 0, 30)
destroyButton.Position = UDim2.new(0.05, 0, 0, 100)
destroyButton.BackgroundColor3 = Color3.fromRGB(170, 20, 20)
destroyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
destroyButton.Font = Enum.Font.GothamBold
destroyButton.Text = "DESTROY SYSTEM"
destroyButton.TextSize = 14
destroyButton.Parent = controlFrame

local destroyCorner = Instance.new("UICorner")
destroyCorner.CornerRadius = UDim.new(0, 8)
destroyCorner.Parent = destroyButton

-- Target Label (Improved Readability)
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
-- 2. LOGIC
-- ==========================================
local isTargeting = false
local targetPlayer = nil
local activeBoxes = {}
local connections = {}

local function createLockBox(player)
	local boxFrame = Instance.new("Frame")
	boxFrame.Name = player.Name .. "_LockBox"
	boxFrame.Size = UDim2.new(0, 68, 0, 68)
	boxFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	boxFrame.BackgroundTransparency = 1
	boxFrame.Parent = boxContainer

	-- Sharp stroke (no corner)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2.5
	stroke.Color = Color3.fromRGB(0, 255, 100)
	stroke.Parent = boxFrame

	-- Info Label (Name + Distance)
	local infoLabel = Instance.new("TextLabel")
	infoLabel.Size = UDim2.new(0, 200, 0, 40)
	infoLabel.Position = UDim2.new(0.5, -100, 0, -45)  -- Above the box
	infoLabel.BackgroundTransparency = 1
	infoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	infoLabel.Font = Enum.Font.GothamBold
	infoLabel.TextSize = 13
	infoLabel.TextStrokeTransparency = 0.4
	infoLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	infoLabel.Parent = boxFrame

	activeBoxes[player] = {Box = boxFrame, Info = infoLabel}

	-- Click on box to lock
	boxFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and isTargeting then
			targetPlayer = player
			targetLabel.Text = "LOCKED → " .. string.upper(player.Name)
			targetLabel.TextColor3 = Color3.fromRGB(255, 70, 70)
		end
	end)

	return activeBoxes[player]
end

-- Render loop
local renderConnection = RunService.RenderStepped:Connect(function()
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

				-- Update info text
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

table.insert(connections, renderConnection)

-- Toggle
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

-- Destroy
destroyButton.MouseButton1Click:Connect(function()
	for _, c in ipairs(connections) do c:Disconnect() end
	screenGui:Destroy()
	mainheart:Disconnect()
	if game.Workspace:FindFirstChild("PredictedPosition") then
		game.Workspace.PredictedPosition:Destroy()	
	end
end)

-- ==================== LAUNCH BUTTON ====================
local launchButton = Instance.new("TextButton")
launchButton.Size = UDim2.new(0.9, 0, 0, 45)
launchButton.Position = UDim2.new(0.05, 0, 0, 145)  -- Below the destroy button
launchButton.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
launchButton.TextColor3 = Color3.fromRGB(255, 255, 255)
launchButton.Font = Enum.Font.GothamBold
launchButton.Text = "LAUNCH MISSILE"
launchButton.TextSize = 17
launchButton.Parent = controlFrame

local launchCorner = Instance.new("UICorner")
launchCorner.CornerRadius = UDim.new(0, 8)
launchCorner.Parent = launchButton

local launch = false
local debounce = false
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
		debounce  = false
	else
		launch = true
		debounce = true
	end
end)
local predictedPart = Instance.new("Part")
predictedPart.Anchored = true
predictedPart.Name = "PredictedPosition"
predictedPart.Size = Vector3.new(1, 1, 1)
predictedPart.Position = Vector3.new(0, 5, 0)
predictedPart.Parent = workspace
local handles = Instance.new("Handles")
handles.Adornee = predictedPart
handles.Style = Enum.HandlesStyle.Resize
handles.Color3 = Color3.new(1, 1, 0) -- Bright yellow
handles.Parent = workspace
handles.Faces = Faces.new(Enum.NormalId.Top)

local targetlastvelocity = Vector3.new(0,0,0)
local missilelastvelocity = Vector3.new(0,0,0)
local localplayer = game:GetService("Players").LocalPlayer
local target = nil
local missile = nil
local speed = 800

local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")

local isDetonating = false -- Debounce to prevent double-firing
local mainheart -- Declare variable upward so it can reference itself to disconnect

mainheart = RunService.RenderStepped:Connect(function(dt)
	-- Target validation
	if targetPlayer and targetPlayer.Character then
		target = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
		
		local aircraft = game.Workspace:FindFirstChild(localplayer.Name.." Aircraft")
		if aircraft and aircraft:FindFirstChild("ExplosiveBlock") then
			missile = aircraft.ExplosiveBlock.Decorate
		end
	end
	
	-- Only run guidance if everything exists and we aren't already exploding
	if launch and target ~= nil and missile ~= nil and not isDetonating then
		-- Modern Roblox property update (Velocity is deprecated)
		local targetvelocity = target.AssemblyLinearVelocity 
		local missilevelocity = missile.AssemblyLinearVelocity 
		
		local targetacceleration = Vector3.new(0,0,0)
		
		local displacement = target.Position - missile.Position
		local dist = displacement.Magnitude
		
		-- Fix: Calculate Closing Velocity so 'timetotarget' is accurate
		-- This figures out if the target is flying away or towards the missile
		local missileDir = displacement.Unit
		local closingSpeed = speed - targetvelocity:Dot(missileDir)
		if closingSpeed <= 0 then closingSpeed = speed end -- Fallback
		
		local timetotarget = dist / closingSpeed
		local ping = localplayer:GetNetworkPing() / 2
		local totaltime = timetotarget + ping
		
		-- Kinematic prediction
		local calculatedtargetpos = target.Position + (targetvelocity * totaltime) + (0.5 * targetacceleration * (totaltime^2))
		
		-- Update your indicator part safely
		if predictedPart then
			predictedPart.Position = calculatedtargetpos
		end
		
		targetlastvelocity = targetvelocity
		missilelastvelocity = missilevelocity

		-- Guidance updates
		local direction = (calculatedtargetpos - missile.Position).Unit
		missile.AssemblyLinearVelocity = direction * speed
		missile.CFrame = CFrame.lookAt(missile.Position, calculatedtargetpos)
		
		-- Detonation Logic (Checks actual distance to target part for consistency)
		if (missile.Position - target.Position).Magnitude < 20 then
			isDetonating = true -- Lock the loop immediately
			mainheart:Disconnect() -- Stop tracking entirely
			
			-- Fire the keypress safely in a separate thread
			task.spawn(function()
				print("DETONATE")
				VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
				task.wait(0.1)
				VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
			end)
		end
	end
end)



