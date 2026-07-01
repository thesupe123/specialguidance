-- LocalScript (StarterPlayer > StarterPlayerScripts)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local ESP_ENABLED = false
local targetPlayerName = nil

local espObjects = {}  -- character -> data

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ESPController"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Toggle GUI
local toggleFrame = Instance.new("Frame")
toggleFrame.Size = UDim2.new(0, 220, 0, 70)
toggleFrame.Position = UDim2.new(0, 20, 0, 20)
toggleFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
toggleFrame.BorderSizePixel = 0
toggleFrame.Parent = screenGui

Instance.new("UICorner", toggleFrame).CornerRadius = UDim.new(0, 10)

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(1, -20, 1, -20)
toggleButton.Position = UDim2.new(0, 10, 0, 10)
toggleButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
toggleButton.Text = "ESP: OFF"
toggleButton.TextColor3 = Color3.new(1,1,1)
toggleButton.TextScaled = true
toggleButton.Font = Enum.Font.GothamBold
toggleButton.Parent = toggleFrame

Instance.new("UICorner", toggleButton).CornerRadius = UDim.new(0, 8)

local function createESP(character)
    if espObjects[character] then return end
    if not character:FindFirstChild("HumanoidRootPart") then return end

    print("Creating ESP for: " .. character.Name)

    -- 3D Highlight
    local highlight = Instance.new("Highlight")
    highlight.Adornee = character
    highlight.FillTransparency = 1
    highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character

    -- Name Label (fixed size)
    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = character:FindFirstChild("Head") or character.HumanoidRootPart
    billboard.Size = UDim2.new(0, 160, 0, 45)
    billboard.StudsOffset = Vector3.new(0, 3.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = character

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1,0,1,0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = character.Name
    nameLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    nameLabel.TextScaled = false
    nameLabel.TextSize = 18
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.new(0,0,0)
    nameLabel.Parent = billboard

    -- Clickable Missile Lock Square (Green Corners)
    local screenBox = Instance.new("Frame")
    screenBox.Name = "TargetBox"
    screenBox.BackgroundTransparency = 1
    screenBox.Size = UDim2.new(0, 90, 0, 90)
    screenBox.Visible = false
    screenBox.Parent = screenGui

    -- Green corner brackets
    local function createCorner(pos, sizeX, sizeY)
        local corner = Instance.new("Frame")
        corner.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        corner.BorderSizePixel = 0
        corner.Size = UDim2.new(0, sizeX, 0, sizeY)
        corner.Parent = screenBox
        return corner
    end

    local tl = createCorner("TopLeft", 25, 3)
    local tr = createCorner("TopRight", 25, 3)
    local bl = createCorner("BottomLeft", 25, 3)
    local br = createCorner("BottomRight", 25, 3)

    tl.Position = UDim2.new(0, 0, 0, 0)
    tr.Position = UDim2.new(1, -25, 0, 0)
    bl.Position = UDim2.new(0, 0, 1, -3)
    br.Position = UDim2.new(1, -25, 1, -3)

    -- Click detection
    screenBox.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            targetPlayerName = character.Name
            print("Target locked: " .. targetPlayerName)
        end
    end)

    espObjects[character] = {
        Highlight = highlight,
        Billboard = billboard,
        ScreenBox = screenBox
    }
end

local function removeESP(character)
    local data = espObjects[character]
    if data then
        data.Highlight:Destroy()
        data.Billboard:Destroy()
        data.ScreenBox:Destroy()
        espObjects[character] = nil
    end
end

local function updateScreenBoxes()
    for character, data in pairs(espObjects) do
        if character and character.Parent and character:FindFirstChild("HumanoidRootPart") then
            local root = character.HumanoidRootPart
            local screenPos, onScreen = camera:WorldToViewportPoint(root.Position)
            
            if onScreen then
                data.ScreenBox.Visible = true
                data.ScreenBox.Position = UDim2.new(0, screenPos.X - 45, 0, screenPos.Y - 45)
            else
                data.ScreenBox.Visible = false
            end
        else
            removeESP(character)
        end
    end
end

local function refreshAllESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            createESP(plr.Character)
        end
    end
end

local function toggleESP()
    ESP_ENABLED = not ESP_ENABLED
    
    if ESP_ENABLED then
        toggleButton.Text = "ESP: ON"
        toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        refreshAllESP()
        print("ESP Enabled")
    else
        toggleButton.Text = "ESP: OFF"
        toggleButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
        
        for char in pairs(espObjects) do
            removeESP(char)
        end
        print("ESP Disabled")
    end
end

-- Connections
toggleButton.MouseButton1Click:Connect(toggleESP)

-- Player & Character handling
Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function(char)
        if ESP_ENABLED then
            task.wait(0.8)
            createESP(char)
        end
    end)
end)

for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= player then
        if plr.Character then createESP(plr.Character) end
        plr.CharacterAdded:Connect(function(char)
            if ESP_ENABLED then
                task.wait(0.8)
                createESP(char)
            end
        end)
    end
end

-- Main update loop
RunService.RenderStepped:Connect(function()
    if ESP_ENABLED then
        updateScreenBoxes()
    end
end)

print("Missile Lock ESP script loaded!")
print("Toggle with the button. Click the green corner squares to select target.")
