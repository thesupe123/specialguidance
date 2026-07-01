local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ==========================================
-- 1. UI CREATION (Same as before)
-- ==========================================
local playerGui = game.CoreGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MissileLockSystem"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true 
screenGui.Parent = playerGui

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 180, 0, 40)
toggleButton.Position = UDim2.new(0, 20, 0, 56)
toggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.Text = "Targeting: OFF"
toggleButton.Parent = screenGui

local destroyButton = Instance.new("TextButton")
destroyButton.Size = UDim2.new(0, 180, 0, 30)
destroyButton.Position = UDim2.new(0, 20, 0, 106)
destroyButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
destroyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
destroyButton.Text = "Destroy System"
destroyButton.Parent = screenGui

local targetLabel = Instance.new("TextLabel")
targetLabel.Size = UDim2.new(0, 300, 0, 40)
targetLabel.Position = UDim2.new(0.5, -150, 0, 56)
targetLabel.BackgroundTransparency = 1
targetLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
targetLabel.Font = Enum.Font.GothamBlack
targetLabel.Text = "NO TARGET LOCKED"
targetLabel.Parent = screenGui

local boxContainer = Instance.new("Frame")
boxContainer.Size = UDim2.new(1, 0, 1, 0)
boxContainer.BackgroundTransparency = 1
boxContainer.Parent = screenGui

-- ==========================================
-- 2. LOGIC & RAYCASTING
-- ==========================================
local isTargeting = false
local targetPlayer = nil
local activeBoxes = {} 
local connections = {} 

local function createLockBox(player)
	local frame = Instance.new("Frame")
	frame.Name = player.Name .. "_LockBox"
	frame.Size = UDim2.new(0, 50, 0, 50)
	frame.AnchorPoint = Vector2.new(0.5, 0.5) 
	frame.BackgroundTransparency = 1
	frame.Parent = boxContainer
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(0, 255, 0)
	stroke.Parent = frame
	activeBoxes[player] = frame
	return frame
end

-- Render loop for boxes
local renderConnection = RunService.RenderStepped:Connect(function()
	if not isTargeting then 
		for _, box in pairs(activeBoxes) do box.Visible = false end
		return 
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local screenPos, onScreen = camera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position + Vector3.new(0, 1, 0))
			local box = activeBoxes[player] or createLockBox(player)
			box.Visible = onScreen
			if onScreen then
				box.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y)
				local stroke = box:FindFirstChildOfClass("UIStroke")
				if player == targetPlayer then
					stroke.Color = Color3.fromRGB(255, 0, 0)
					stroke.Thickness = 3
					box.Size = UDim2.new(0, 65, 0, 65)
				else
					stroke.Color = Color3.fromRGB(0, 255, 0)
					stroke.Thickness = 2
					box.Size = UDim2.new(0, 50, 0, 50)
				end
			end
		end
	end
end)
table.insert(connections, renderConnection)

-- Toggle Button
toggleButton.MouseButton1Click:Connect(function()
	isTargeting = not isTargeting
	toggleButton.Text = isTargeting and "Targeting: ON" or "Targeting: OFF"
	toggleButton.BackgroundColor3 = isTargeting and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(50, 50, 50)
end)

-- FIXED: Click-to-Lock using Raycasting
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or not isTargeting or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
	
	local mousePos = UserInputService:GetMouseLocation()
	local unitRay = camera:ViewportPointToRay(mousePos.X, mousePos.Y)
	
	-- Setup Raycast to ignore YOUR character
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {localPlayer.Character}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	
	local raycastResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, raycastParams)
	
	if raycastResult and raycastResult.Instance then
		local character = raycastResult.Instance:FindFirstAncestorOfClass("Model")
		local foundPlayer = character and Players:GetPlayerFromCharacter(character)
		
		if foundPlayer and foundPlayer ~= localPlayer then
			targetPlayer = foundPlayer
			targetLabel.Text = "LOCKED ON: " .. string.upper(targetPlayer.Name)
		else
			targetPlayer = nil
			targetLabel.Text = "NO TARGET LOCKED"
		end
	end
end)

-- Destroy System
destroyButton.MouseButton1Click:Connect(function()
	for _, c in ipairs(connections) do c:Disconnect() end
	screenGui:Destroy()
end)
