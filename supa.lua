-- LocalScript (Place in StarterPlayer > StarterPlayerScripts)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Configuration
local ESP_COLOR = Color3.fromRGB(0, 255, 0) -- Green
local ESP_ENABLED = false
local selectedPlayerName = nil  -- The variable that will hold the clicked player's name

-- Store highlights and billboards
local espObjects = {}

-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ESPController"
screenGui.ResetOnSpawn = false
screenGui.Parent = game.CoreGui

local toggleFrame = Instance.new("Frame")
toggleFrame.Size = UDim2.new(0, 200, 0, 60)
toggleFrame.Position = UDim2.new(0, 20, 0, 20)
toggleFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
toggleFrame.BorderSizePixel = 0
toggleFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = toggleFrame

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(1, -20, 1, -20)
toggleButton.Position = UDim2.new(0, 10, 0, 10)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
toggleButton.Text = "ESP: OFF"
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.TextScaled = true
toggleButton.Font = Enum.Font.GothamBold
toggleButton.Parent = toggleFrame

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 6)
toggleCorner.Parent = toggleButton

-- Function to create ESP for a character
local function createESP(character)
    if espObjects[character] then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    -- Highlight for hollow green box
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESPHighlight"
    highlight.Adornee = character
    highlight.FillTransparency = 1 -- Hollow
    highlight.OutlineColor = ESP_COLOR
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character
    
    -- Name label (BillboardGui)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESPNameLabel"
    billboard.Adornee = character:FindFirstChild("Head") or rootPart
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.Parent = character
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = character.Name
    nameLabel.TextColor3 = ESP_COLOR
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = billboard
    
    espObjects[character] = {Highlight = highlight, Billboard = billboard}
end

-- Remove ESP from character
local function removeESP(character)
    if espObjects[character] then
        espObjects[character].Highlight:Destroy()
        espObjects[character].Billboard:Destroy()
        espObjects[character] = nil
    end
end

-- Update ESP for all players
local function updateESP()
    if not ESP_ENABLED then return end
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            createESP(plr.Character)
        end
    end
end

-- Toggle function
local function toggleESP()
    ESP_ENABLED = not ESP_ENABLED
    
    if ESP_ENABLED then
        toggleButton.Text = "ESP: ON"
        toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        updateESP()
    else
        toggleButton.Text = "ESP: OFF"
        toggleButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
        
        -- Remove all ESP
        for char, _ in pairs(espObjects) do
            removeESP(char)
        end
        espObjects = {}
    end
end

-- Click detection (Raycast to character)
local function onMouseClick()
    if not ESP_ENABLED then return end
    
    local mouse = player:GetMouse()
    local ray = camera:ScreenPointToRay(mouse.X, mouse.Y)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {player.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local result = workspace:Raycast(ray.Origin, ray.Direction * 500, raycastParams)
    
    if result and result.Instance then
        local character = result.Instance:FindFirstAncestorWhichIsA("Model")
        if character and Players:GetPlayerFromCharacter(character) then
            local targetPlayer = Players:GetPlayerFromCharacter(character)
            if targetPlayer then
                selectedPlayerName = targetPlayer.Name
                print("Selected player: " .. selectedPlayerName)
                -- You can fire a RemoteEvent here or use the variable anywhere else in your script
            end
        end
    end
end

-- Connect toggle
toggleButton.MouseButton1Click:Connect(toggleESP)

-- Mouse click for selection
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        onMouseClick()
    end
end)

-- Handle new players / character added
Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function(char)
        if ESP_ENABLED then
            task.wait(0.5) -- Small delay for character to load
            createESP(char)
        end
    end)
end)

-- Initial players
for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= player and plr.Character then
        createESP(plr.Character)
    end
    plr.CharacterAdded:Connect(function(char)
        if ESP_ENABLED then
            task.wait(0.5)
            createESP(char)
        end
    end)
end

-- Periodic update
RunService.Heartbeat:Connect(function()
    if ESP_ENABLED then
        updateESP()
    end
end)

print("ESP Script loaded! Toggle with the GUI button. Click on a green box to select a player.")
