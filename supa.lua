local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

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
end)
