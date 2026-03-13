-- modules/ESP.lua
-- ESP module for Forsaken Hub
-- Version: 2.3 (Force visibility through invisibility)

local ESP = {}
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/Library.lua?nocache=" .. tostring(os.time())))()
local Config = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/Config.lua?nocache=" .. tostring(os.time())))()

local players = Library.Services.Players
local workspace = game:GetService("Workspace")
local runService = game:GetService("RunService")
local localPlayer = players.LocalPlayer

local enabled = false
local espConnections = {}
local espObjects = {}
local currentCharacters = {}

local function cleanupCharacterESP(character)
    if not character then return end
    local highlight = character:FindFirstChild("ForsakenESP")
    if highlight then
        pcall(function() highlight:Destroy() end)
    end
end

local function cleanupAllESP()
    for obj in pairs(espObjects) do
        if obj and obj.Parent then
            pcall(function() obj:Destroy() end)
        end
    end
    table.clear(espObjects)
    table.clear(currentCharacters)
end

local function forceVisible(character)
    if not character then return end
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                part.LocalTransparencyModifier = 0
            end)
        end
    end
end

local function createESP(character, team)
    if not character or not character:FindFirstChild("Humanoid") then return end
    if localPlayer and localPlayer.Character == character then return end
    
    cleanupCharacterESP(character)
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "ForsakenESP"
    highlight.Parent = character
    highlight.Adornee = character
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    
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

local function updateESP()
    if not enabled then return end
    
    local newCharacters = {}
    
    local playersFolder = workspace:FindFirstChild("Players")
    if not playersFolder then
        cleanupAllESP()
        return
    end
    
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
                forceVisible(character)
            end
        end
    end
    
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
                forceVisible(character)
            end
        end
    end
    
    for character in pairs(currentCharacters) do
        if not newCharacters[character] then
            cleanupCharacterESP(character)
            currentCharacters[character] = nil
        end
    end
end

function ESP:Toggle(state)
    enabled = state
    
    if enabled then
        updateESP()
        
        local renderConn = runService.RenderStepped:Connect(function()
            if enabled then
                local playersFolder = workspace:FindFirstChild("Players")
                if playersFolder then
                    for _, folder in ipairs(playersFolder:GetChildren()) do
                        for _, character in ipairs(folder:GetChildren()) do
                            if character:IsA("Model") and character ~= (localPlayer and localPlayer.Character) then
                                forceVisible(character)
                            end
                        end
                    end
                end
            end
        end)
        table.insert(espConnections, renderConn)
        
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
