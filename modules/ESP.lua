-- modules/ESP.lua
-- ESP module for Forsaken Hub
-- Version: 1.0

local ESP = {}
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/Library.lua"))()
local Config = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/Config.lua"))()

local players = Library.Services.Players
local runService = Library.Services.RunService
local workspace = game:GetService("Workspace")

local enabled = false
local espConnections = {}
local espObjects = {}

-- Create ESP highlight for a character
local function createESP(character, playerName, team)
    if not character or not character:FindFirstChild("Humanoid") then return end
    
    -- Main highlight box
    local highlight = Instance.new("Highlight")
    highlight.Name = "ForsakenESP"
    highlight.Parent = character
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    
    -- Team colors
    if team == "Killers" then
        highlight.FillColor = Color3.fromRGB(255, 50, 50)  -- Red for killers
        highlight.OutlineColor = Color3.fromRGB(200, 0, 0)
    elseif team == "Survivors" then
        highlight.FillColor = Color3.fromRGB(50, 255, 50)  -- Green for survivors
        highlight.OutlineColor = Color3.fromRGB(0, 200, 0)
    else
        highlight.FillColor = Config.Theme.Cyan
        highlight.OutlineColor = Config.Theme.CyanDark
    end
    
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    
    -- Name tag (BillboardGui)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ForsakenESPName"
    billboard.Parent = character
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    
    local nameFrame = Instance.new("Frame")
    nameFrame.Size = UDim2.new(1, 0, 1, 0)
    nameFrame.BackgroundColor3 = Config.Theme.Background
    nameFrame.BackgroundTransparency = 0.3
    nameFrame.Parent = billboard
    
    local nameCorner = Instance.new("UICorner")
    nameCorner.CornerRadius = UDim.new(0, 4)
    nameCorner.Parent = nameFrame
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 20)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = playerName
    nameLabel.TextColor3 = Config.Theme.Text
    nameLabel.TextSize = 14
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = nameFrame
    
    local teamLabel = Instance.new("TextLabel")
    teamLabel.Size = UDim2.new(1, 0, 0, 16)
    teamLabel.Position = UDim2.new(0, 0, 0, 20)
    teamLabel.BackgroundTransparency = 1
    teamLabel.Text = "[" .. team .. "]"
    teamLabel.TextColor3 = team == "Killers" and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 255, 100)
    teamLabel.TextSize = 12
    teamLabel.Font = Enum.Font.Gotham
    teamLabel.Parent = nameFrame
    
    return highlight
end

-- Update ESP for all players
local function updateESP()
    if not enabled then return end
    
    -- Clear old ESP
    for obj in pairs(espObjects) do
        if obj and obj.Parent then
            obj:Destroy()
        end
    end
    table.clear(espObjects)
    
    -- Check Players folder in Workspace
    local playersFolder = workspace:FindFirstChild("Players")
    if not playersFolder then return end
    
    -- Check Killers
    local killersFolder = playersFolder:FindFirstChild("Killers")
    if killersFolder then
        for _, character in ipairs(killersFolder:GetChildren()) do
            if character:IsA("Model") and character:FindFirstChild("Humanoid") then
                -- Find player name
                local playerName = "Unknown"
                for _, plr in pairs(players:GetPlayers()) do
                    if plr.Character == character then
                        playerName = plr.Name
                        break
                    end
                end
                
                local esp = createESP(character, playerName, "Killers")
                if esp then
                    espObjects[esp] = true
                end
            end
        end
    end
    
    -- Check Survivors
    local survivorsFolder = playersFolder:FindFirstChild("Survivors")
    if survivorsFolder then
        for _, character in ipairs(survivorsFolder:GetChildren()) do
            if character:IsA("Model") and character:FindFirstChild("Humanoid") then
                local playerName = "Unknown"
                for _, plr in pairs(players:GetPlayers()) do
                    if plr.Character == character then
                        playerName = plr.Name
                        break
                    end
                end
                
                local esp = createESP(character, playerName, "Survivors")
                if esp then
                    espObjects[esp] = true
                end
            end
        end
    end
end

-- Toggle ESP
function ESP:Toggle(state)
    enabled = state
    
    if enabled then
        -- Initial update
        updateESP()
        
        -- Connect to game events
        local conn = runService.Heartbeat:Connect(function()
            if enabled then
                updateESP()
            end
        end)
        table.insert(espConnections, conn)
        
        -- Listen for character additions
        local playersFolder = workspace:FindFirstChild("Players")
        if playersFolder then
            local killersFolder = playersFolder:FindFirstChild("Killers")
            if killersFolder then
                local conn2 = killersFolder.ChildAdded:Connect(function()
                    task.wait(0.1)
                    updateESP()
                end)
                table.insert(espConnections, conn2)
            end
            
            local survivorsFolder = playersFolder:FindFirstChild("Survivors")
            if survivorsFolder then
                local conn3 = survivorsFolder.ChildAdded:Connect(function()
                    task.wait(0.1)
                    updateESP()
                end)
                table.insert(espConnections, conn3)
            end
        end
        
    else
        -- Clean up
        for _, conn in ipairs(espConnections) do
            conn:Disconnect()
        end
        table.clear(espConnections)
        
        for obj in pairs(espObjects) do
            if obj and obj.Parent then
                obj:Destroy()
            end
        end
        table.clear(espObjects)
    end
end

return ESP
