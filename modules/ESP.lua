-- modules/ESP.lua
-- ESP module for Forsaken Hub
-- Version: 2.1 (Fixed local player check)

local ESP = {}
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/Library.lua"))()
local Config = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/Config.lua"))()

local players = Library.Services.Players
local workspace = game:GetService("Workspace")
local localPlayer = players.LocalPlayer

local enabled = false
local espConnections = {}
local espObjects = {}
local currentCharacters = {}

-- Clean up ESP for a specific character
local function cleanupCharacterESP(character)
    if not character then return end
    
    local highlight = character:FindFirstChild("ForsakenESP")
    if highlight then
        pcall(function() highlight:Destroy() end)
    end
end

-- Clean up all ESP
local function cleanupAllESP()
    for obj in pairs(espObjects) do
        if obj and obj.Parent then
            pcall(function() obj:Destroy() end)
        end
    end
    table.clear(espObjects)
    table.clear(currentCharacters)
end

-- Create ESP highlight only
local function createESP(character, team)
    if not character or not character:FindFirstChild("Humanoid") then return end
    
    -- FIXED: Better check for local player
    local isLocalPlayer = false
    if localPlayer and localPlayer.Character == character then
        isLocalPlayer = true
    end
    
    -- Skip local player
    if isLocalPlayer then 
        return 
    end
    
    -- Remove old ESP if exists
    cleanupCharacterESP(character)
    
    -- Create highlight box
    local highlight = Instance.new("Highlight")
    highlight.Name = "ForsakenESP"
    highlight.Parent = character
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    
    -- Team colors
    if team == "Killers" then
        highlight.FillColor = Color3.fromRGB(255, 80, 80)
        highlight.OutlineColor = Color3.fromRGB(200, 40, 40)
    elseif team == "Survivors" then
        highlight.FillColor = Color3.fromRGB(80, 255, 80)
        highlight.OutlineColor = Color3.fromRGB(40, 200, 40)
    end
    
    highlight.FillTransparency = 0.4
    highlight.OutlineTransparency = 0.2
    
    return highlight
end

-- Update ESP for all players
local function updateESP()
    if not enabled then return end
    
    -- Track current characters
    local newCharacters = {}
    
    local playersFolder = workspace:FindFirstChild("Players")
    if not playersFolder then 
        cleanupAllESP()
        return 
    end
    
    -- Process Killers
    local killersFolder = playersFolder:FindFirstChild("Killers")
    if killersFolder then
        for _, character in ipairs(killersFolder:GetChildren()) do
            if character:IsA("Model") and character:FindFirstChild("Humanoid") then
                newCharacters[character] = "Killers"
                
                if not currentCharacters[character] then
                    local esp = createESP(character, "Killers")
                    if esp then
                        espObjects[esp] = true
                        currentCharacters[character] = "Killers"
                    end
                end
            end
        end
    end
    
    -- Process Survivors
    local survivorsFolder = playersFolder:FindFirstChild("Survivors")
    if survivorsFolder then
        for _, character in ipairs(survivorsFolder:GetChildren()) do
            if character:IsA("Model") and character:FindFirstChild("Humanoid") then
                newCharacters[character] = "Survivors"
                
                if not currentCharacters[character] then
                    local esp = createESP(character, "Survivors")
                    if esp then
                        espObjects[esp] = true
                        currentCharacters[character] = "Survivors"
                    end
                end
            end
        end
    end
    
    -- Clean up characters that no longer exist
    for character in pairs(currentCharacters) do
        if not newCharacters[character] then
            cleanupCharacterESP(character)
            currentCharacters[character] = nil
        end
    end
end

-- Toggle ESP
function ESP:Toggle(state)
    enabled = state
    
    if enabled then
        updateESP()
        
        spawn(function()
            while enabled do
                updateESP()
                task.wait(0.5)
            end
        end)
        
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
        
        local conn = workspace.ChildAdded:Connect(function(child)
            if child.Name == "Players" then
                task.wait(0.5)
                updateESP()
            end
        end)
        table.insert(espConnections, conn)
        
    else
        for _, conn in ipairs(espConnections) do
            pcall(function() conn:Disconnect() end)
        end
        table.clear(espConnections)
        cleanupAllESP()
    end
end

return ESP
