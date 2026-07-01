-- LocalScript (put in StarterPlayer > StarterPlayerScripts)
-- Missile Lock / Target Selector Script

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local TARGET = nil  -- This is the selected target (Player object)

-- Settings
local BOX_COLOR = Color3.fromRGB(255, 50, 50)
local BOX_THICKNESS = 3
local BOX_SIZE_OFFSET = Vector2.new(80, 120)  -- Base size around character
local UPDATE_RATE = 1 / 30  -- How often to update box positions

-- GUI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MissileLockGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = game.CoreGui

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 180, 0, 50)
toggleButton.Position = UDim2.new(0, 20, 0, 20)
toggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Text = "Missile Lock: OFF"
toggleButton.TextScaled = true
toggleButton.Font = Enum.Font.GothamBold
toggleButton.Parent = screenGui

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0, 250, 0, 30)
statusLabel.Position = UDim2.new(0, 20, 0, 80)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
statusLabel.Text = "No Target"
statusLabel.TextScaled = true
statusLabel.Font = Enum.Font.Gotham
statusLabel.Parent = screenGui

-- Store active lock boxes
local activeBoxes = {}  -- [player] = {billboard, frame, cornerFrames...}

local enabled = false

-- Create lock box for a character
local function createLockBox(character)
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local root = character.HumanoidRootPart
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    -- BillboardGui
    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = root
    billboard.Size = UDim2.new(0, 300, 0, 400)  -- Large enough area
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.Parent = character
    
    -- Main transparent frame for click detection
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundTransparency = 1
    mainFrame.Parent = billboard
    
    -- Corner brackets (classic missile lock look)
    local corners = {}
    local cornerPositions = {
        {0, 0}, {1, 0}, {0, 1}, {1, 1}  -- top-left, top-right, bottom-left, bottom-right
    }
    
    for _, pos in ipairs(cornerPositions) do
        local corner = Instance.new("Frame")
        corner.BackgroundColor3 = BOX_COLOR
        corner.BorderSizePixel = 0
        corner.Size = UDim2.new(0, 40, 0, BOX_THICKNESS)
        corner.Position = UDim2.new(pos[1], pos[1] == 1 and -40 or 0, pos[2], pos[2] == 1 and -BOX_THICKNESS or 0)
        corner.Parent = mainFrame
        table.insert(corners, corner)
        
        -- Vertical part
        local vert = Instance.new("Frame")
        vert.BackgroundColor3 = BOX_COLOR
        vert.BorderSizePixel = 0
        vert.Size = UDim2.new(0, BOX_THICKNESS, 0, 40)
        vert.Position = UDim2.new(pos[1], pos[1] == 1 and -BOX_THICKNESS or 0, pos[2], pos[2] == 1 and -40 or 0)
        vert.Parent = mainFrame
        table.insert(corners, vert)
    end
    
    activeBoxes[character] = {
        billboard = billboard,
        mainFrame = mainFrame,
        corners = corners,
        player = Players:GetPlayerFromCharacter(character)
    }
end

-- Remove box
local function removeLockBox(character)
    if activeBoxes[character] then
        activeBoxes[character].billboard:Destroy()
        activeBoxes[character] = nil
    end
end

-- Update all boxes
local function updateBoxes()
    for character, data in pairs(activeBoxes) do
        if not character.Parent then
            removeLockBox(character)
        end
    end
end

-- Toggle function
local function toggleLock()
    enabled = not enabled
    
    if enabled then
        toggleButton.Text = "Missile Lock: ON"
        toggleButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        
        -- Create boxes for existing characters
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character then
                createLockBox(plr.Character)
            end
        end
        
        -- Listen for new characters
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player then
                plr.CharacterAdded:Connect(function(char)
                    if enabled then
                        createLockBox(char)
                    end
                end)
            end
        end
    else
        toggleButton.Text = "Missile Lock: OFF"
        toggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        
        -- Remove all boxes
        for char, _ in pairs(activeBoxes) do
            removeLockBox(char)
        end
        activeBoxes = {}
    end
end

toggleButton.MouseButton1Click:Connect(toggleLock)

-- Click detection
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not enabled or gameProcessed then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    
    local mousePos = UserInputService:GetMouseLocation()
    
    for character, data in pairs(activeBoxes) do
        if data.mainFrame and data.mainFrame.AbsolutePosition and data.mainFrame.AbsoluteSize then
            local absPos = data.mainFrame.AbsolutePosition
            local absSize = data.mainFrame.AbsoluteSize
            
            if mousePos.X >= absPos.X and mousePos.X <= absPos.X + absSize.X and
               mousePos.Y >= absPos.Y and mousePos.Y <= absPos.Y + absSize.Y then
                
                -- Clicked inside this box!
                TARGET = data.player
                statusLabel.Text = "TARGET: " .. (TARGET and TARGET.Name or "None")
                print("Target locked: " .. (TARGET and TARGET.Name or "None"))
                
                -- Optional: Visual feedback
                for _, corner in ipairs(data.corners or {}) do
                    corner.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
                end
                wait(0.2)
                if data.corners then
                    for _, corner in ipairs(data.corners) do
                        if corner then corner.BackgroundColor3 = BOX_COLOR end
                    end
                end
                return
            end
        end
    end
end)

-- Character cleanup
Players.PlayerRemoving:Connect(function(plr)
    for char, data in pairs(activeBoxes) do
        if data.player == plr then
            removeLockBox(char)
        end
    end
end)

-- Main update loop
RunService.RenderStepped:Connect(function()
    if enabled then
        updateBoxes()
    end
end)

print("Missile Lock script loaded! Click the button to toggle.")
