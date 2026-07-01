local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local mouse = localPlayer:GetMouse()
local button = script.Parent -- Assumes this script is inside a TextButton

-- State variables
local isTargeting = false
local targetName = nil
local activeBoxes = {}

-- Function to clear all targeting boxes
local function clearBoxes()
	for _, box in pairs(activeBoxes) do
		if box then 
			box:Destroy() 
		end
	end
	table.clear(activeBoxes)
end

-- Function to draw boxes around all other players
local function drawBoxes()
	clearBoxes()
	for _, otherPlayer in pairs(Players:GetPlayers()) do
		-- Don't put a box around ourselves
		if otherPlayer ~= localPlayer and otherPlayer.Character then
			local box = Instance.new("SelectionBox")
			box.Name = "MissileLockBox"
			box.Color3 = Color3.fromRGB(0, 255, 0) -- Green for "unlocked"
			box.LineThickness = 0.05
			box.Adornee = otherPlayer.Character
			
			-- Parent it to our own PlayerGui or the Character so it renders
			box.Parent = otherPlayer.Character
			
			table.insert(activeBoxes, box)
		end
	end
end

-- 1. Toggle Button Logic
button.MouseButton1Click:Connect(function()
	isTargeting = not isTargeting
	
	if isTargeting then
		button.Text = "Targeting: ON"
		drawBoxes()
	else
		button.Text = "Targeting: OFF"
		clearBoxes()
		targetName = nil
		print("Targeting disabled. Target cleared.")
	end
end)

-- 2. Click-to-Lock Logic
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	-- Ignore clicks if the player is clicking a UI button or typing in chat
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
					for _, box in pairs(activeBoxes) do
						if box.Adornee == character then
							box.Color3 = Color3.fromRGB(255, 0, 0) -- Red for locked
							box.LineThickness = 0.08
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
