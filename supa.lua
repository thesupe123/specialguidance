-- LocalScript (StarterPlayer > StarterPlayerScripts)
-- Improved Missile Lock - Fixed Screen Size + Name Tags

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local TARGET = nil

-- Settings
local BOX_COLOR = Color3.fromRGB(255, 50, 50)
local BOX_THICKNESS = 4
local BOX_WIDTH = 90      -- Fixed screen pixels
local BOX_HEIGHT = 130
local NAME_OFFSET = 20    -- Pixels above the box

local enabled = false
local activeBoxes = {}    -- [character] = {frame, nameLabel, player}

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

-- Create box elements
local function createLockBox(character)
    local plr = Players:GetPlayerFromCharacter(character)
    if not plr or plr == player then return end
    
    -- Main Box Frame (fixed screen size)
    local box = Instance.new("Frame")
    box.Size = UDim2.new(0, BOX_WIDTH, 0, BOX_HEIGHT)
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Visible = false
    box.Parent = screenGui
    
    -- Corner brackets
    local corners = {}
    local positions = {
        {0, 0, 40, BOX_THICKNESS},      -- Top Left Horizontal
        {0, 0, BOX_THICKNESS, 40},      -- Top Left Vertical
        {1, 0, -40, BOX_THICKNESS},     -- Top Right Horizontal
        {1, 0, -BOX_THICKNESS, 40},     -- Top Right Vertical
        {0, 1, 40, -BOX_THICKNESS},     -- Bottom Left Horizontal
        {0, 1, BOX_THICKNESS, -40},     -- Bottom Left Vertical
        {1, 1, -40, -BOX_THICKNESS},    -- Bottom Right Horizontal
        {1, 1, -BOX_THICKNESS, -40},    -- Bottom Right Vertical
    }
    
    for _, p in ipairs(positions) do
        local corner = Instance.new("Frame")
        corner.BackgroundColor3 = BOX_COLOR
        corner.BorderSizePixel = 0
        corner.Size = UDim2.new(0, math.abs(p[3]), 0, math.abs(p[4]))
        corner.Position = UDim2.new(p[1], p[2] == 1 and -math.abs(p[3]) or 0, p[2], p[4] < 0 and -math.abs(p[4]) or 0)
        corner.Parent = box
        table.insert(corners, corner)
    end
    
    -- Player Name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0, 200, 0, 30)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
    nameLabel.Text = plr.Name
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = screenGui
    
    activeBoxes[character] = {
        box = box,
        nameLabel = nameLabel,
        corners = corners,
        player = plr
    }
end

local function removeLockBox(character)
    local data = activeBoxes[character]
    if data then
        if data.box then data.box:Destroy() end
        if data.nameLabel then data.nameLabel:Destroy() end
        activeBoxes[character] = nil
    end
end

-- World to Screen Position
local function worldToScreen(pos)
    local screenPos, onScreen = camera:WorldToViewportPoint(pos)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen and screenPos.Z > 0
end

-- Update all boxes
local function updateBoxes()
    for character, data in pairs(activeBoxes) do
        if not character or not character.Parent or not character:FindFirstChild("HumanoidRootPart") then
            removeLockBox(character)
            continue
        end
        
        local root = character.HumanoidRootPart
        local centerPos = root.Position + Vector3.new(0, 2, 0)  -- slightly above center
        
        local screenPos, visible = worldToScreen(centerPos)
        
        if visible then
            -- Center the box on the character
            local box = data.box
            box.Position = UDim2.new(0, screenPos.X - BOX_WIDTH/2, 0, screenPos.Y - BOX_HEIGHT/2)
            box.Visible = true
            
            -- Name above box
            data.nameLabel.Position = UDim2.new(0, screenPos.X - 100, 0, screenPos.Y - BOX_HEIGHT/2 - NAME_OFFSET)
            data.nameLabel.Visible = true
        else
            data.box.Visible = false
            data.nameLabel.Visible = false
        end
    end
end

-- Toggle
local function toggleLock()
    enabled = not enabled
    
    if enabled then
        toggleButton.Text = "Missile Lock: ON"
        toggleButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character then
                createLockBox(plr.Character)
            end
        end
    else
        toggleButton.Text = "Missile Lock: OFF"
        toggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        
        for char, _ in pairs(activeBoxes) do
            removeLockBox(char)
        end
        activeBoxes = {}
    end
end

toggleButton.MouseButton1Click:Connect(toggleLock)

-- Click Detection
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not enabled or gameProcessed or input.UserInputType ~= Enum.UserInputType.MouseButton1 then 
        return 
    end
    
    local mousePos = UserInputService:GetMouseLocation()
    
    for character, data in pairs(activeBoxes) do
        if data.box and data.box.Visible then
            local absPos = data.box.AbsolutePosition
            local absSize = data.box.AbsoluteSize
            
            if mousePos.X >= absPos.X and mousePos.X <= absPos.X + absSize.X and
               mousePos.Y >= absPos.Y and mousePos.Y <= absPos.Y + absSize.Y then
                
                TARGET = data.player
                statusLabel.Text = "TARGET: " .. TARGET.Name
                
                -- Flash effect
                for _, c in ipairs(data.corners) do
                    c.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
                end
                task.delay(0.15, function()
                    if data.corners then
                        for _, c in ipairs(data.corners) do
                            if c then c.BackgroundColor3 = BOX_COLOR end
                        end
                    end
                end)
                return
            end
        end
    end
end)

-- Player / Character handling
Players.PlayerAdded:Connect(function(plr)
    if plr == player then return end
    plr.CharacterAdded:Connect(function(char)
        if enabled then
            task.wait(0.5)
            createLockBox(char)
        end
    end)
end)

for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= player then
        plr.CharacterAdded:Connect(function(char)
            if enabled then createLockBox(char) end
        end)
        if plr.Character then
            createLockBox(plr.Character)
        end
    end
end

-- Main Loop
RunService.RenderStepped:Connect(function()
    if enabled then
        updateBoxes()
    end
end)

print("Fixed-size Missile Lock script loaded!")
