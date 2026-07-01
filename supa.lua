-- LocalScript (StarterPlayer > StarterPlayerScripts)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local TARGET = nil

-- Settings
local BOX_COLOR = Color3.fromRGB(255, 50, 50)
local BOX_THICKNESS = 4
local BOX_WIDTH = 80
local BOX_HEIGHT = 110
local NAME_OFFSET = 25

local enabled = false
local activeBoxes = {}

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

local function createLockBox(character)
    local plr = Players:GetPlayerFromCharacter(character)
    if not plr or plr == player then return end
    
    local box = Instance.new("Frame")
    box.Size = UDim2.new(0, BOX_WIDTH, 0, BOX_HEIGHT)
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Visible = false
    box.Parent = screenGui
    
    -- Corner brackets (outward facing)
    local corners = {}
    local length = 35
    
    -- Top Left
    local tlH = Instance.new("Frame"); tlH.BackgroundColor3 = BOX_COLOR; tlH.BorderSizePixel = 0
    tlH.Size = UDim2.new(0, length, 0, BOX_THICKNESS); tlH.Position = UDim2.new(0, 0, 0, 0); tlH.Parent = box
    local tlV = Instance.new("Frame"); tlV.BackgroundColor3 = BOX_COLOR; tlV.BorderSizePixel = 0
    tlV.Size = UDim2.new(0, BOX_THICKNESS, 0, length); tlV.Position = UDim2.new(0, 0, 0, 0); tlV.Parent = box
    
    -- Top Right
    local trH = Instance.new("Frame"); trH.BackgroundColor3 = BOX_COLOR; trH.BorderSizePixel = 0
    trH.Size = UDim2.new(0, length, 0, BOX_THICKNESS); trH.Position = UDim2.new(1, -length, 0, 0); trH.Parent = box
    local trV = Instance.new("Frame"); trV.BackgroundColor3 = BOX_COLOR; trV.BorderSizePixel = 0
    trV.Size = UDim2.new(0, BOX_THICKNESS, 0, length); trV.Position = UDim2.new(1, -BOX_THICKNESS, 0, 0); trV.Parent = box
    
    -- Bottom Left
    local blH = Instance.new("Frame"); blH.BackgroundColor3 = BOX_COLOR; blH.BorderSizePixel = 0
    blH.Size = UDim2.new(0, length, 0, BOX_THICKNESS); blH.Position = UDim2.new(0, 0, 1, -BOX_THICKNESS); blH.Parent = box
    local blV = Instance.new("Frame"); blV.BackgroundColor3 = BOX_COLOR; blV.BorderSizePixel = 0
    blV.Size = UDim2.new(0, BOX_THICKNESS, 0, length); blV.Position = UDim2.new(0, 0, 1, -length); blV.Parent = box
    
    -- Bottom Right
    local brH = Instance.new("Frame"); brH.BackgroundColor3 = BOX_COLOR; brH.BorderSizePixel = 0
    brH.Size = UDim2.new(0, length, 0, BOX_THICKNESS); brH.Position = UDim2.new(1, -length, 1, -BOX_THICKNESS); brH.Parent = box
    local brV = Instance.new("Frame"); brV.BackgroundColor3 = BOX_COLOR; brV.BorderSizePixel = 0
    brV.Size = UDim2.new(0, BOX_THICKNESS, 0, length); brV.Position = UDim2.new(1, -BOX_THICKNESS, 1, -length); brV.Parent = box
    
    table.insert(corners, tlH); table.insert(corners, tlV)
    table.insert(corners, trH); table.insert(corners, trV)
    table.insert(corners, blH); table.insert(corners, blV)
    table.insert(corners, brH); table.insert(corners, brV)
    
    -- Player Name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0, 180, 0, 28)
    nameLabel.BackgroundTransparency = 0.6
    nameLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
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

local function worldToScreen(pos)
    local vec, onScreen = camera:WorldToViewportPoint(pos)
    return Vector2.new(vec.X, vec.Y), onScreen and vec.Z > 0
end

local function updateBoxes()
    for character, data in pairs(activeBoxes) do
        if not character or not character.Parent or not character:FindFirstChild("HumanoidRootPart") then
            removeLockBox(character)
            continue
        end
        
        local root = character.HumanoidRootPart
        local centerPos = root.Position + Vector3.new(0, 2.5, 0)
        
        local screenPos, visible = worldToScreen(centerPos)
        
        if visible then
            data.box.Position = UDim2.new(0, screenPos.X - BOX_WIDTH/2, 0, screenPos.Y - BOX_HEIGHT/2)
            data.box.Visible = true
            
            data.nameLabel.Position = UDim2.new(0, screenPos.X - 90, 0, screenPos.Y - BOX_HEIGHT/2 - NAME_OFFSET)
            data.nameLabel.Visible = true
        else
            data.box.Visible = false
            data.nameLabel.Visible = false
        end
    end
end

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
        
        for char in pairs(activeBoxes) do
            removeLockBox(char)
        end
        activeBoxes = {}
    end
end

toggleButton.MouseButton1Click:Connect(toggleLock)

-- Click detection (no green highlight)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not enabled or gameProcessed or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    
    local mousePos = UserInputService:GetMouseLocation()
    
    for character, data in pairs(activeBoxes) do
        if data.box and data.box.Visible then
            local pos = data.box.AbsolutePosition
            local size = data.box.AbsoluteSize
            
            if mousePos.X >= pos.X and mousePos.X <= pos.X + size.X and
               mousePos.Y >= pos.Y and mousePos.Y <= pos.Y + size.Y then
                
                TARGET = data.player
                statusLabel.Text = "TARGET: " .. TARGET.Name
                return
            end
        end
    end
end)

-- Player handling
Players.PlayerAdded:Connect(function(plr)
    if plr == player then return end
    plr.CharacterAdded:Connect(function(char)
        if enabled then task.wait(0.6); createLockBox(char) end
    end)
end)

for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= player then
        if plr.Character then createLockBox(plr.Character) end
        plr.CharacterAdded:Connect(function(char)
            if enabled then task.wait(0.6); createLockBox(char) end
        end)
    end
end

RunService.RenderStepped:Connect(function()
    if enabled then
        updateBoxes()
    end
end)

print("Missile Lock script updated - no green highlight")
