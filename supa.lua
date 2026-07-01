-- LocalScript → StarterPlayerScripts
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local ESP_ENABLED = false
local targetPlayerName = nil  -- ← Your target variable

local espObjects = {}  -- character -> {Highlight, Billboard, ScreenBox}

-- GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ESPController"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Toggle Button
local toggleFrame = Instance.new("Frame")
toggleFrame.Size = UDim2.new(0, 220, 0, 70)
toggleFrame.Position = UDim2.new(0, 20, 0, 20)
toggleFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
toggleFrame.BorderSizePixel = 0
toggleFrame.Parent = screenGui

Instance.new("UICorner", toggleFrame).CornerRadius = UDim.new(0, 10)

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(1, -20, 1, -20)
toggleButton.Position = UDim2.new(0, 10, 0, 10)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
toggleButton.Text = "ESP: OFF"
toggleButton.TextColor3 = Color3.new(1,1,1)
toggleButton.TextScaled = true
toggleButton.Font = Enum.Font.GothamBold
toggleButton.Parent = toggleFrame

Instance.new("UICorner", toggleButton).CornerRadius = UDim.new(0, 8)

-- Create missile-lock style square around player
local function createESP(character)
    if espObjects[character] then return end

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- 3D Highlight (green hollow box)
    local highlight = Instance.new("Highlight")
    highlight.Adornee = character
    highlight.FillTransparency = 1
    highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character

    -- Fixed size name label
    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = character:FindFirstChild("Head") or root
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

    -- Clickable Screen Box (Missile Lock Style)
    local screenBox = Instance.new("Frame")
    screenBox.Name = "TargetBox"
    screenBox.BackgroundTransparency = 1
    screenBox.Size = UDim2.new(0, 80, 0, 80)
    screenBox.Parent = screenGui

    -- Green corner brackets (classic missile lock look)
    local corners = {}
    for _, pos in ipairs({"TopLeft", "TopRight", "BottomLeft", "BottomRight"}) do
        local corner = Instance.new("Frame")
        corner.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        corner.BorderSizePixel = 0
        corner.Size = UDim2.new(0, 12, 0, 2)
        corner.Parent = screenBox

        if pos == "TopLeft" then
            corner.Position = UDim2.new(0, 0, 0, 0)
            corner.Size = UDim2.new(0, 20, 0, 3)
        elseif pos == "TopRight" then
            corner.Position = UDim2.new(1, -20, 0, 0)
            corner.Size = UDim2.new(0, 20, 0, 3)
        elseif pos == "BottomLeft" then
            corner.Position = UDim2.new(0, 0, 1, -3)
            corner.Size = UDim2.new(0, 20, 0, 3)
        elseif pos == "BottomRight" then
            corner.Position = UDim2.new(1, -20, 1, -3)
            corner.Size = UDim2.new(0, 20, 0, 3)
        end
        corners[pos] = corner
    end

    -- Make the whole box clickable
    screenBox.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            targetPlayerName = character.Name
            print("Target locked: " .. targetPlayerName)
        end
    end)

    espObjects[character] = {
        Highlight = highlight,
        Billboard = billboard,
        ScreenBox = screenBox,
        Corners = corners
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
    if not ESP_ENABLED then return end

    for character, data in pairs(espObjects) do
        if character and character.Parent then
            local root = character:FindFirstChild("HumanoidRootPart")
            if root then
                local screenPos, onScreen = camera:WorldToViewportPoint(root.Position)
                
                if onScreen then
                    data.ScreenBox.Visible = true
                    data.ScreenBox.Position = UDim2.new(0, screenPos.X - 40, 0, screenPos.Y - 40)
                else
                    data.ScreenBox.Visible = false
                end
            end
        else
            removeESP(character)
        end
    end
end

local function toggleESP()
    ESP_ENABLED = not ESP_ENABLED
    
    if ESP_ENABLED then
        toggleButton.Text = "ESP: ON"
        toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    else
        toggleButton.Text = "ESP: OFF"
        toggleButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
        
        for char in pairs(espObjects) do
            removeESP(char)
        end
    end
end

-- Connections
toggleButton.MouseButton1Click:Connect(toggleESP)

-- Character handling
local function onCharacterAdded(char)
    if ESP_ENABLED then
        task.wait(0.6)
        createESP(char)
    end
end

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(onCharacterAdded)
end)

for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= player then
        if plr.Character then
            createESP(plr.Character)
        end
        plr.CharacterAdded:Connect(onCharacterAdded)
    end
end

-- Main loop
RunService.RenderStepped:Connect(updateScreenBoxes)

print("Missile Lock ESP loaded! Click the green squares to lock target.")
