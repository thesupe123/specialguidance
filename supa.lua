local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local mouse = localPlayer:GetMouse()
local camera = workspace.CurrentCamera

-- ==========================================
-- 1. UI CREATION
-- ==========================================
local playerGui = game.CoreGui

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MissileLockSystem"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true -- Fixes 2D bounding boxes shifting downward
screenGui.Parent = playerGui

-- Targeting Button (Shifted down to Y=56 to avoid the Roblox Topbar)
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(0, 180, 0, 40)
toggleButton.Position = UDim2.new(0, 20, 0, 56) 
toggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextScaled = true
toggleButton.Text = "Targeting: OFF"
toggleButton.Parent = screenGui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 6)
toggleCorner.Parent = toggleButton

-- Destroy Button (Below Targeting Button)
local destroyButton = Instance.new("TextButton")
destroyButton.Name = "DestroyButton"
destroyButton.Size = UDim2.new(0, 180, 0, 30)
destroyButton.Position = UDim2.new(0, 20, 0, 106) 
destroyButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
destroyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
destroyButton.Font = Enum.Font.GothamBold
destroyButton.TextScaled = true
destroyButton.Text = "Destroy System"
destroyButton.Parent = screenGui

local destroyCorner = Instance.new("UICorner")
destroyCorner.CornerRadius = UDim.new(0, 6)
destroyCorner.Parent = destroyButton

-- Target Label (Shifted down to Y=56 to avoid the Topbar)
local targetLabel = Instance.new("TextLabel")
targetLabel.Name = "TargetLabel"
targetLabel.Size = UDim2.new(0, 300, 0, 40)
targetLabel.Position = UDim2.new(0.5, -150, 0, 56)
targetLabel.BackgroundTransparency = 1
targetLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
targetLabel.Font = Enum.Font.GothamBlack
targetLabel.TextScaled = true
targetLabel.Text = "NO TARGET LOCKED"
targetLabel.TextStrokeTransparency = 0 
targetLabel.Parent = screenGui

-- Container for the 2D Lock Boxes
local boxContainer = Instance.new("Frame")
boxContainer.Name = "BoxContainer"
boxContainer.Size = UDim2.new(1, 0, 1, 0)
boxContainer.BackgroundTransparency = 1
boxContainer.Parent = screenGui

-- ==========================================
-- 2. STATE & VARIABLES
-- ==========================================
local isTargeting = false
local targetPlayer = nil
local activeBoxes = {} 
local connections = {} 

-- ==========================================
-- 3. CORE LOGIC & MATH
-- ==========================================

-- Function to create a 2D box for a player
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

-- Render loop: Calculates 3D to 2D math every single frame
local renderConnection = RunService.RenderStepped:Connect(function()
	if not isTargeting then 
		for _, box in pairs(activeBoxes) do
			box.Visible = false
		end
		return 
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local rootPart = player.Character.HumanoidRootPart
			
			-- Shift the tracking point slightly up so it frames the upper body
			local targetPosition = rootPart.Position + Vector3.new(0, 1, 0)
			
			-- Convert 3D world position to 2D screen coordinates
			local screenPosition, onScreen = camera:WorldToViewportPoint(targetPosition)
			
			local box = activeBoxes[player] or createLockBox(player)
			
			if onScreen then
				box.Visible = true
				box.Position = UDim2.new(0, screenPosition.X, 0, screenPosition.Y)
				
				local stroke = box:FindFirstChildOfClass("UIStroke")
				if stroke then
					if player == targetPlayer then
						stroke.Color = Color3.fromRGB(255, 0, 0) -- RED for target
						stroke.Thickness = 3
						box.Size = UDim2.new(0, 65, 0, 65) 
					else
						stroke.Color = Color3.fromRGB(0, 255, 0) -- GREEN for others
						stroke.Thickness = 2
						box.Size = UDim2.new(0, 50, 0, 50)
					end
				end
			else
				box.Visible = false 
			end
		else
			if activeBoxes[player] then
				activeBoxes[player].Visible = false
			end
		end
	end
end)
table.insert(connections, renderConnection)

-- Toggle Targeting Button
local toggleConnection = toggleButton.MouseButton1Click:Connect(function()
	isTargeting = not isTargeting
	if isTargeting then
		toggleButton.Text = "Targeting: ON"
		toggleButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
	else
		toggleButton.Text = "Targeting: OFF"
		toggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		targetPlayer = nil
		targetLabel.Text = "NO TARGET LOCKED"
		targetLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
	end
end)
table.insert(connections, toggleConnection)

-- Click-to-Lock Logic (IMPROVED)
local clickConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or not isTargeting then return end
	
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		
		-- FIX: Prevent your own character from blocking your mouse clicks!
		if localPlayer.Character then
			mouse.TargetFilter = localPlayer.Character
		end
		
		local clickedPart = mouse.Target
		
		if clickedPart then
			local current = clickedPart
			local clickedPlayer = nil
			
			while current and current ~= workspace do
				clickedPlayer = Players:GetPlayerFromCharacter(current)
				if clickedPlayer then break end
				current = current.Parent
			end
			
			if clickedPlayer and clickedPlayer ~= localPlayer then
				-- We successfully clicked a new player
				targetPlayer = clickedPlayer
				targetLabel.Text = "LOCKED ON: " .. string.upper(targetPlayer.Name)
				targetLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
			elseif not clickedPlayer then
				-- We clicked a wall, baseplate, or building. Clear the target.
				targetPlayer = nil
				targetLabel.Text = "NO TARGET LOCKED"
				targetLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
			end
		else
			-- We clicked the empty sky. Clear the target.
			targetPlayer = nil
			targetLabel.Text = "NO TARGET LOCKED"
			targetLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
		end
	end
end)
table.insert(connections, clickConnection)

-- Cleanup function when players leave
local leaveConnection = Players.PlayerRemoving:Connect(function(player)
	if activeBoxes[player] then
		activeBoxes[player]:Destroy()
		activeBoxes[player] = nil
	end
	if targetPlayer == player then
		targetPlayer = nil
		targetLabel.Text = "TARGET LOST"
	end
end)
table.insert(connections, leaveConnection)

-- ==========================================
-- 4. DESTROY GUI LOGIC
-- ==========================================
destroyButton.MouseButton1Click:Connect(function()
	for _, connection in ipairs(connections) do
		if connection.Connected then
			connection:Disconnect()
		end
	end
	table.clear(connections)
	
	screenGui:Destroy()
	print("Missile lock system destroyed.")
end)
