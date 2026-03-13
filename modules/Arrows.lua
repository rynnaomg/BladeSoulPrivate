-- modules/Arrows.lua
-- Arrow module for Forsaken Hub
-- Version: 9.0 (Drawing API + Local file loading)

local Arrows = {}
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/Library.lua"))()
local Config = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/Config.lua"))()

local players = Library.Services.Players
local workspace = game:GetService("Workspace")
local runService = game:GetService("RunService")
local localPlayer = players.LocalPlayer

local enabled = false
local arrowConnections = {}
local arrows = {} -- table: playerName -> { image, text, isKillerTarget }
local playerTeam = nil
local currentTargetTeam = nil
local arrowImageData = nil

-- File paths for Delta
local ARROW_FILE_NAME = "forsaken_arrow.png"
local ARROW_GITHUB_URL = "https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/assets/arrow.png"

-- Проверяем поддержку Drawing API (есть в Delta)
local drawingSupported = Drawing and Drawing.new
if not drawingSupported then
    warn("[Arrows] Drawing API not supported. Arrows will not work.")
end

-- Load or download arrow image (caching)
local function loadArrowImage()
    if arrowImageData then return arrowImageData end
    if not isfile or not writefile then 
        warn("[Arrows] File operations not supported")
        return nil 
    end

    -- If file exists, read it
    if isfile(ARROW_FILE_NAME) then
        print("[Arrows] Loading cached arrow image")
        local success, data = pcall(readfile, ARROW_FILE_NAME)
        if success and data then
            arrowImageData = data
            return arrowImageData
        end
    end

    -- Download from GitHub
    print("[Arrows] Downloading arrow image from GitHub...")
    local success, data = pcall(function()
        return game:HttpGet(ARROW_GITHUB_URL)
    end)

    if success and data and #data > 0 then
        writefile(ARROW_FILE_NAME, data)
        print("[Arrows] Arrow saved to Delta/Workspace")
        arrowImageData = data
        return arrowImageData
    else
        warn("[Arrows] Failed to download arrow")
        return nil
    end
end

-- Safe camera getter
local function getSafeCamera()
    local success, result = pcall(function()
        return workspace.CurrentCamera
    end)
    return success and result
end

-- Safe root part getter
local function getCharacterRootPart(character)
    if not character then return nil end
    local success, result = pcall(function()
        return character:FindFirstChild("HumanoidRootPart")
    end)
    return success and result
end

-- Get player's team
local function getPlayerTeam(player)
    if not player or not player.Character then return nil end
    
    local success, result = pcall(function()
        local playersFolder = workspace:FindFirstChild("Players")
        if not playersFolder then return nil end
        
        -- Check if lobby (no folders)
        if not playersFolder:FindFirstChild("Killers") and not playersFolder:FindFirstChild("Survivors") then
            return "Lobby"
        end
        
        local killers = playersFolder:FindFirstChild("Killers")
        if killers then
            for _, char in ipairs(killers:GetChildren()) do
                if char:IsA("Model") and player.Character == char then
                    return "Killers"
                end
            end
        end
        
        local survivors = playersFolder:FindFirstChild("Survivors")
        if survivors then
            for _, char in ipairs(survivors:GetChildren()) do
                if char:IsA("Model") and player.Character == char then
                    return "Survivors"
                end
            end
        end
        
        return nil
    end)
    
    return success and result
end

-- Calculate angle to target (for rotation)
local function getAngleToTarget(camera, targetPos)
    local relative = camera.CFrame:PointToObjectSpace(targetPos)
    return math.deg(math.atan2(relative.X, -relative.Z))
end

-- Create a new arrow object (Drawing)
local function createArrow(targetPlayer, targetTeam)
    if not drawingSupported then return nil end
    
    local imgData = loadArrowImage()
    local isKiller = (targetTeam == "Killers")
    local color = isKiller and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(80, 255, 80)
    
    -- Create image using Drawing API
    local img = Drawing.new("Image")
    if imgData then
        img.Data = imgData  -- Load from local file bytes
    else
        -- Fallback: colored circle if image failed
        img = Drawing.new("Circle")
        img.Color = color
        img.Filled = true
        img.Radius = 15
        img.NumSides = 30
    end
    img.Size = Vector2.new(30, 30)
    img.Position = Vector2.new(0, 0)
    img.Transparency = 1
    img.Visible = false
    img.ZIndex = 10
    
    -- Distance text
    local text = Drawing.new("Text")
    text.Text = "0m"
    text.Color = Color3.fromRGB(255, 255, 255)
    text.Size = 14
    text.Center = true
    text.Outline = true
    text.OutlineColor = Color3.fromRGB(0, 0, 0)
    text.Font = Drawing.Fonts.UI
    text.Position = Vector2.new(0, 0)
    text.Visible = false
    text.ZIndex = 10
    
    return {
        image = img,
        text = text,
        isKiller = isKiller,
        playerName = targetPlayer.Name
    }
end

-- Destroy arrow (cleanup)
local function destroyArrow(arrowObj)
    if not arrowObj then return end
    pcall(function()
        if arrowObj.image then arrowObj.image:Remove() end
        if arrowObj.text then arrowObj.text:Remove() end
    end)
end

-- Clean all arrows
local function cleanAllArrows()
    for _, arrowObj in pairs(arrows) do
        destroyArrow(arrowObj)
    end
    table.clear(arrows)
end

-- Update arrows (main loop)
local function updateArrows()
    if not enabled then return end
    if not drawingSupported then return end
    if not localPlayer or not localPlayer.Character then return end
    
    local camera = getSafeCamera()
    if not camera then return end
    
    -- Get current team
    local newTeam = getPlayerTeam(localPlayer)
    
    -- If in lobby, hide everything
    if newTeam == "Lobby" or not newTeam then
        for _, arrowObj in pairs(arrows) do
            if arrowObj.image then arrowObj.image.Visible = false end
            if arrowObj.text then arrowObj.text.Visible = false end
        end
        playerTeam = newTeam
        return
    end
    
    -- Team changed? Clean all and reset
    if newTeam ~= playerTeam then
        cleanAllArrows()
        playerTeam = newTeam
        currentTargetTeam = nil
    end
    
    if not playerTeam then return end
    
    -- Determine target team
    local targetTeam = playerTeam == "Killers" and "Survivors" or "Killers"
    
    if targetTeam ~= currentTargetTeam then
        cleanAllArrows()
        currentTargetTeam = targetTeam
    end
    
    -- Find targets
    local targets = {}
    local playersFolder = workspace:FindFirstChild("Players")
    if playersFolder then
        local targetFolder = playersFolder:FindFirstChild(targetTeam)
        if targetFolder then
            for _, char in ipairs(targetFolder:GetChildren()) do
                if char:IsA("Model") then
                    local root = getCharacterRootPart(char)
                    if root then
                        for _, plr in pairs(players:GetPlayers()) do
                            if plr.Character == char and plr ~= localPlayer then
                                table.insert(targets, {
                                    player = plr,
                                    rootPart = root
                                })
                                break
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Remove arrows for players who left
    for name, arrowObj in pairs(arrows) do
        local found = false
        for _, t in ipairs(targets) do
            if t.player.Name == name then
                found = true
                break
            end
        end
        if not found then
            destroyArrow(arrowObj)
            arrows[name] = nil
        end
    end
    
    local camPos = camera.CFrame.Position
    local screenSize = camera.ViewportSize
    
    -- Update/create arrows for current targets
    for _, target in ipairs(targets) do
        local arrowObj = arrows[target.player.Name]
        if not arrowObj then
            arrowObj = createArrow(target.player, targetTeam)
            if arrowObj then
                arrows[target.player.Name] = arrowObj
            end
        end
        
        if arrowObj then
            local targetPos = target.rootPart.Position
            local dist = (targetPos - camPos).Magnitude
            local distM = math.floor(dist / 3)
            
            local angle = getAngleToTarget(camera, targetPos)
            local rad = math.rad(angle)
            local radius = 80
            
            -- Position around center
            local cx = screenSize.X / 2 + math.sin(rad) * radius
            local cy = screenSize.Y / 2 - math.cos(rad) * radius
            
            -- Keep on screen
            cx = math.clamp(cx, 20, screenSize.X - 20)
            cy = math.clamp(cy, 20, screenSize.Y - 20)
            
            -- Update image position
            if arrowObj.image then
                arrowObj.image.Position = Vector2.new(cx - 15, cy - 15)
                arrowObj.image.Visible = true
                
                -- Try to rotate (works in some executors)
                if arrowObj.image.Rotation then
                    arrowObj.image.Rotation = angle
                end
                
                -- Update color if needed
                local correctColor = targetTeam == "Killers" and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(80, 255, 80)
                if arrowObj.image.Color and arrowObj.image.Color ~= correctColor then
                    arrowObj.image.Color = correctColor
                end
            end
            
            -- Update text
            if arrowObj.text then
                arrowObj.text.Text = distM .. "m"
                arrowObj.text.Position = Vector2.new(cx - 15, cy + 18)
                arrowObj.text.Visible = true
            end
        end
    end
end

-- Public: Toggle arrows
function Arrows:Toggle(state)
    enabled = state
    
    if enabled then
        -- Preload image
        task.spawn(loadArrowImage)
        
        -- Reset state
        playerTeam = nil
        currentTargetTeam = nil
        cleanAllArrows()
        
        -- Initial update
        updateArrows()
        
        -- Connect render loop
        local conn = runService.RenderStepped:Connect(function()
            if enabled then updateArrows() end
        end)
        table.insert(arrowConnections, conn)
        
        -- Handle round start/end
        local conn2 = workspace.ChildAdded:Connect(function()
            task.wait(0.5)
            if enabled then updateArrows() end
        end)
        table.insert(arrowConnections, conn2)
        
        local conn3 = workspace.ChildRemoved:Connect(function()
            task.wait(0.5)
            if enabled then
                cleanAllArrows()
                playerTeam = nil
                currentTargetTeam = nil
                updateArrows()
            end
        end)
        table.insert(arrowConnections, conn3)
        
    else
        -- Disable: clean everything
        for _, conn in ipairs(arrowConnections) do
            pcall(function() conn:Disconnect() end)
        end
        table.clear(arrowConnections)
        
        cleanAllArrows()
        playerTeam = nil
        currentTargetTeam = nil
    end
end

return Arrows
