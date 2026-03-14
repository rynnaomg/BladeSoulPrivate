-- modules/ESP.lua
-- ESP module for BladeSoul
-- Version: 2.4 (Full cleanup)

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
    for _, obj in ipairs(character:GetDescendants()) do
        if obj.Name == "ForsakenESP" then
            pcall(function() obj:Destroy() end)
        end
    end
    local highlight = character:FindFirstChild("ForsakenESP")
    if highlight then pcall(function() highlight:Destroy() end) end
end

local function cleanupAllESP()
    -- Чистим все известные объекты
    for obj in pairs(espObjects) do
        if obj and obj.Parent then
            pcall(function() obj:Destroy() end)
        end
    end
    table.clear(espObjects)
    table.clear(currentCharacters)
    
    -- Дополнительно чистим весь workspace от остатков
    for _, plr in pairs(players:GetPlayers()) do
        if plr.Character then
            cleanupCharacterESP(plr.Character)
        end
    end
    
    -- Чистим в папках команд если они ещё есть
    local playersFolder = workspace:FindFirstChild("Players")
    if playersFolder then
        for _, folder in ipairs(playersFolder:GetChildren()) do
            for _, character in ipairs(folder:GetChildren()) do
                if character:IsA("Model") then
                    cleanupCharacterESP(character)
                end
            end
        end
    end
end

local function isLocalPlayer(character)
    return localPlayer and localPlayer.Character == character
end

local function createESP(character, team)
    if not character or not character:FindFirstChild("Humanoid") then return end
    if isLocalPlayer(character) then return end
    
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
            if character:IsA("Model") and character:FindFirstChild("Humanoid") and not isLocalPlayer(character) then
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
    
    local survivorsFolder = playersFolder:FindFirstChild("Survivors")
    if survivorsFolder then
        for _, character in ipairs(survivorsFolder:GetChildren()) do
            if character:IsA("Model") and character:FindFirstChild("Humanoid") and not isLocalPlayer(character) then
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
    
    -- Чистим персонажей которых больше нет в папках команд
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
        
        -- Каждый кадр принудительно ставим Transparency=0 и чистим локального игрока
        local renderConn = runService.RenderStepped:Connect(function()
            if not enabled then return end
            
            -- Убираем ESP с локального игрока если вдруг появился
            if localPlayer and localPlayer.Character then
                cleanupCharacterESP(localPlayer.Character)
            end
            
            -- Принудительно делаем всех видимыми (антиневидимость)
            local playersFolder = workspace:FindFirstChild("Players")
            if not playersFolder then return end
            for _, folder in ipairs(playersFolder:GetChildren()) do
                if folder:IsA("Folder") then
                    for _, character in ipairs(folder:GetChildren()) do
                        if character:IsA("Model") and not isLocalPlayer(character) then
                            for _, part in ipairs(character:GetDescendants()) do
                                if part:IsA("BasePart") and part.Transparency == 1 then
                                    pcall(function() part.Transparency = 0 end)
                                end
                            end
                        end
                    end
                end
            end
        end)
        table.insert(espConnections, renderConn)
        
        -- Периодическое обновление
        spawn(function()
            while enabled do
                updateESP()
                task.wait(0.5)
            end
        end)
        
        -- Слушаем добавление персонажей
        local playersFolder = workspace:FindFirstChild("Players")
        if playersFolder then
            local killersFolder = playersFolder:FindFirstChild("Killers")
            if killersFolder then
                local conn = killersFolder.ChildAdded:Connect(function()
                    task.wait(0.1); updateESP()
                end)
                table.insert(espConnections, conn)
            end
            local survivorsFolder = playersFolder:FindFirstChild("Survivors")
            if survivorsFolder then
                local conn = survivorsFolder.ChildAdded:Connect(function()
                    task.wait(0.1); updateESP()
                end)
                table.insert(espConnections, conn)
            end
        end
        
        -- Чистим когда персонаж удаляется из папки команды
        local connRemoved = workspace.DescendantRemoving:Connect(function(obj)
            if obj:IsA("Model") and obj:FindFirstChild("Humanoid") then
                cleanupCharacterESP(obj)
                currentCharacters[obj] = nil
            end
        end)
        table.insert(espConnections, connRemoved)
        
        local conn = workspace.ChildAdded:Connect(function(child)
            if child.Name == "Players" then
                task.wait(0.5); updateESP()
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
