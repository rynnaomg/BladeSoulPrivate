-- modules/ESP.lua
-- ESP module for Forsaken Hub
-- Version: 1.1 (Fixed nil error)

local ESP = {}
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/Library.lua"))()
local Config = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/Config.lua"))()

local players = Library.Services.Players
local runService = game:GetService("RunService")  -- Fixed: Get service directly
local workspace = game:GetService("Workspace")

local enabled = false
local espConnections = {}
local espObjects = {}
local updateLoop = nil

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
    billboard.ResetOnSpawn = false  -- Prevent cleanup
    
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
            pcall(function() obj:Destroy() end)
        end
    end
    table.clear(espObjects)
    
    -- Check if workspace and Players folder exist
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
        
        -- Use a loop instead of Heartbeat to avoid nil issues
        spawn(function()
            while enabled do
                updateESP()
                task.wait(1)  -- Update every second instead of every frame
            end
        end)
        
        -- Listen for character additions (with error handling)
        local playersFolder = workspace:FindFirstChild("Players")
        if playersFolder then
            local killersFolder = playersFolder:FindFirstChild("Killers")
            if killersFolder then
                local conn = killersFolder.ChildAdded:Connect(function()
                    task.wait(0.1)
                    updateESP()
                end)
                table.insert(espConnections, conn)
            end
            
            local survivorsFolder = playersFolder:FindFirstChild("Survivors")
            if survivorsFolder then
                local conn = survivorsFolder.ChildAdded:Connect(function()
                    task.wait(0.1)
                    updateESP()
                end)
                table.insert(espConnections, conn)
            end
        end
        
        -- Also listen for when Players folder changes (new round)
        local conn = workspace.ChildAdded:Connect(function(child)
            if child.Name == "Players" then
                task.wait(0.5)
                updateESP()
            end
        end)
        table.insert(espConnections, conn)
        
    else
        -- Clean up connections
        for _, conn in ipairs(espConnections) do
            pcall(function() conn:Disconnect() end)
        end
        table.clear(espConnections)
        
        -- Clean up ESP objects
        for obj in pairs(espObjects) do
            if obj and obj.Parent then
                pcall(function() obj:Destroy() end)
            end
        end
        table.clear(espObjects)
    end
end

return ESP
