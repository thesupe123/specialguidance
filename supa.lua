local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local mouse = localPlayer:GetMouse()

-- ==========================================
-- 1. RUNTIME UI CREATION
-- ==========================================
local playerGui = game.CoreGui

-- Create the ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MissileLockSystem"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Create the Toggle Button
local button = Instance.new("TextButton")
button.Name = "ToggleButton"
button.Size = UDim2.new(0, 200, 0, 50)
button.Position = UDim2.new(1, -220, 1, -70) -- Places it in the bottom right corner
button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Font = Enum.Font.GothamBold
button.TextScaled = true
button.Text = "Targeting: OFF"
button.Parent = screenGui

-- Add rounded corners to the button for a cleaner look
local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = button

-- ==========================================
-- 2. TARGETING LOGIC
-- ==========================================
local isTargeting = false
local targetName = nil
local activeBoxes = {}

-- Function to clear all targeting boxes
local function clearBoxes()
	for _, box in ipairs(activeBoxes) do
		if box then 
			box:Destroy() 
		end
	end
	table.clear(activeBoxes)
end

-- Function to draw boxes around all other players
local function drawBoxes()
	clearBoxes()
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		-- Don't put a box around ourselves and make sure their character loaded
		if otherPlayer ~= localPlayer and otherPlayer.Character then
			local box = Instance.new("SelectionBox")
			box.Name = "MissileLockBox"
			box.Color3 = Color3.fromRGB(0, 255, 0) -- Green for "unlocked"
			box.LineThickness = 0.05
			box.Adornee = otherPlayer.Character
			
			-- Parent it to our ScreenGui so it renders on our screen
			box.Parent = screenGui
			
			table.insert(activeBoxes, box)
		end
	end
end

-- Toggle Button Click Event
button.MouseButton1Click:Connect(function()
	isTargeting = not isTargeting
	
	if isTargeting then
		button.Text = "Targeting: ON"
		button.BackgroundColor3 = Color3.fromRGB(150, 0, 0) -- Turns red when active
		drawBoxes()
	else
		button.Text = "Targeting: OFF"
		button.BackgroundColor3 = Color3.fromRGB(50, 50, 50) -- Back to grey
		clearBoxes()
		targetName = nil
		print("Targeting disabled. Target cleared.")
	end
end)

-- Click-to-Lock Logic
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	-- Ignore clicks if the player is clicking the UI button or typing in chat
	if gameProcessed or not isTargeting then return end
	
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local clickedPart = mouse.Target
		
		if clickedPart then
			-- Check if the part we clicked belongs to a character model
			local character = clickedPart:FindFirstAncestorOfClass("Model")
			
			if character then
				local clickedPlayer = Players:GetPlayerFromCharacter(character)
				
				-- If it's a valid player and it isn't us, lock on!
				if clickedPlayer and clickedPlayer ~= localPlayer then
					targetName = clickedPlayer.Name
					print("🎯 MISSILE LOCKED ONTO: " .. targetName)
					
					-- Visual update: Turn the locked target red, turn others back to green
					for _, box in ipairs(activeBoxes) do
						if box.Adornee == character then
							box.Color3 = Color3.fromRGB(255, 0, 0) -- Red for locked
							box.LineThickness = 0.1
						else
							box.Color3 = Color3.fromRGB(0, 255, 0) -- Green for others
							box.LineThickness = 0.05
						end
					end
				end
			end
		end
	end
end)

-- Update boxes if a player dies/respawns while targeting is active
for _, player in ipairs(Players:GetPlayers()) do
	player.CharacterAdded:Connect(function()
		if isTargeting then
			task.wait(1) -- Wait for character to fully load
			drawBoxes()
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		if isTargeting then
			task.wait(1)
			drawBoxes()
		end
	end)
end)
