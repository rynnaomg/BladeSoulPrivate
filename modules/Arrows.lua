-- modules/Arrows.lua
-- Arrow module for Forsaken Hub
-- Version: 3.1 (Fixed arrow image, proper cleanup, correct colors)

local Arrows = {}
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/Library.lua"))()
local Config = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/Config.lua"))()

local players = Library.Services.Players
local workspace = game:GetService("Workspace")
local runService = game:GetService("RunService")
local localPlayer = players.LocalPlayer

local enabled = false
local arrowConnections = {}
local arrowGui = nil
local arrows = {}
local playerTeam = nil
local currentTargetTeam = nil

-- Safe function to get camera
local function getSafeCamera()
    local success, result = pcall(function()
        return workspace.CurrentCamera
    end)
    return success and result
end

-- Safe function to get character root part
local function getCharacterRootPart(character)
    if not character then return nil end
    
    local success, result = pcall(function()
        return character:FindFirstChild("HumanoidRootPart")
    end)
    return success and result
end

-- Safe function to get character humanoid
local function getCharacterHumanoid(character)
    if not character then return nil end
    
    local success, result = pcall(function()
        return character:FindFirstChild("Humanoid")
    end)
    return success and result
end

-- Create arrow GUI
local function createArrowGUI()
    if arrowGui then return end
    
    local success, result = pcall(function()
        local gui = Instance.new("ScreenGui")
        gui.Name = "ForsakenArrows"
        gui.Parent = localPlayer:WaitForChild("PlayerGui")
        gui.ResetOnSpawn = false
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui.IgnoreGuiInset = true
        return gui
    end)
    
    if success then
        arrowGui = result
    end
end

-- Create a single arrow with REAL arrow image
local function createArrow(targetPlayer, targetTeam)
    if not arrowGui then return nil end
    
    local success, arrow = pcall(function()
        -- Main arrow container
        local container = Instance.new("Frame")
        container.Name = "Arrow_" .. targetPlayer.Name
        container.Size = UDim2.new(0, 30, 0, 30)
        container.Position = UDim2.new(0.5, -15, 0.5, -15)
        container.BackgroundTransparency = 1
        container.Parent = arrowGui
        
        -- REAL ARROW IMAGE (not play button)
        local img = Instance.new("ImageLabel")
        img.Name = "ArrowImage"
        img.Size = UDim2.new(1, 0, 1, 0)
        img.BackgroundTransparency = 1
        img.Image = "rbxassetid://6034810872"  -- This is a REAL arrow
        img.ImageColor3 = targetTeam == "Killers" and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(80, 255, 80)
        img.Rotation = 0
        img.Parent = container
        
        -- Distance text
        local distanceText = Instance.new("TextLabel")
        distanceText.Name = "Distance"
        distanceText.Size = UDim2.new(1, 0, 0, 16)
        distanceText.Position = UDim2.new(0, 0, 1, 2)
        distanceText.BackgroundTransparency = 1
        distanceText.Text = ""
        distanceText.TextColor3 = Config.Theme.Text
        distanceText.TextSize = 10
        distanceText.Font = Enum.Font.GothamBold
        distanceText.Parent = container
        
        return container
    end)
    
    return success and arrow
end

-- Get player's team safely
local function getPlayerTeam(player)
    if not player or not player.Character then return nil end
    
    local success, result = pcall(function()
        local playersFolder = workspace:FindFirstChild("Players")
        if not playersFolder then return nil end
        
        -- Check if we're in lobby (no Killers/Survivors folders)
        if not playersFolder:FindFirstChild("Killers") and not playersFolder:FindFirstChild("Survivors") then
            return "Lobby"
        end
        
        local killersFolder = playersFolder:FindFirstChild("Killers")
        if killersFolder then
            for _, character in ipairs(killersFolder:GetChildren()) do
                if character:IsA("Model") and player.Character == character then
                    return "Killers"
                end
            end
        end
        
        local survivorsFolder = playersFolder:FindFirstChild("Survivors")
        if survivorsFolder then
            for _, character in ipairs(survivorsFolder:GetChildren()) do
                if character:IsA("Model") and player.Character == character then
                    return "Survivors"
                end
            end
        end
        
        return nil
    end)
    
    return success and result
end

-- Clean all arrows
local function cleanAllArrows()
    for _, arrow in pairs(arrows) do
        pcall(function() arrow:Destroy() end)
    end
    table.clear(arrows)
end

-- Calculate correct angle to target
local function getAngleToTarget(camera, targetPos, cameraPos)
    local relativePos = camera.CFrame:PointToObjectSpace(targetPos)
    local angle = math.atan2(relativePos.X, -relativePos.Z)
    return math.deg(angle)
end

-- Update arrows
local function updateArrows()
    if not enabled then return end
    if not arrowGui then return end
    if not localPlayer or not localPlayer.Character then return end
    
    -- Get camera safely
    local camera = getSafeCamera()
    if not camera or not camera.CFrame then return end
    
    -- Get local player team
    local newPlayerTeam = getPlayerTeam(localPlayer)
    
    -- Check if we're in lobby
    if newPlayerTeam == "Lobby" or not newPlayerTeam then
        -- In lobby - hide all arrows
        for _, arrow in pairs(arrows) do
            arrow.Visible = false
        end
        playerTeam = newPlayerTeam
        return
    end
    
    -- If team changed, clean all arrows (they will be recreated with new colors)
    if newPlayerTeam ~= playerTeam then
        cleanAllArrows()
        playerTeam = newPlayerTeam
    end
    
    if not playerTeam then return end
    
    -- Determine targets
    local targetTeam = playerTeam == "Killers" and "Survivors" or "Killers"
    
    -- If target team changed, clean arrows
    if targetTeam ~= currentTargetTeam then
        cleanAllArrows()
        currentTargetTeam = targetTeam
    end
    
    -- Get targets safely
    local targets = {}
    local success, folders = pcall(function()
        local playersFolder = workspace:FindFirstChild("Players")
        if not playersFolder then return {} end
        
        local targetFolder = playersFolder:FindFirstChild(targetTeam)
        if not targetFolder then return {} end
        
        local results = {}
        for _, character in ipairs(targetFolder:GetChildren()) do
            if character:IsA("Model") then
                local humanoid = getCharacterHumanoid(character)
                local rootPart = getCharacterRootPart(character)
                
                if humanoid and rootPart then
                    for _, plr in pairs(players:GetPlayers()) do
                        if plr.Character == character and plr ~= localPlayer then
                            table.insert(results, {
                                player = plr,
                                character = character,
                                rootPart = rootPart
                            })
                            break
                        end
                    end
                end
            end
        end
        return results
    end)
    
    if success and folders then
        targets = folders
    end
    
    -- Clean up old arrows (players who left)
    for playerName, arrow in pairs(arrows) do
        local stillTarget = false
        for _, target in ipairs(targets) do
            if target.player.Name == playerName then
                stillTarget = true
                break
            end
        end
        
        if not stillTarget then
            pcall(function() arrow:Destroy() end)
            arrows[playerName] = nil
        end
    end
    
    -- Get camera position
    local cameraPos = camera.CFrame.Position
    
    -- Update arrows
    for _, target in ipairs(targets) do
        if target.rootPart then
            -- Get or create arrow (with correct team color)
            local arrow = arrows[target.player.Name]
            if not arrow then
                arrow = createArrow(target.player, targetTeam)
                if arrow then
                    arrows[target.player.Name] = arrow
                end
            end
            
            if arrow then
                -- Get target position
                local targetPos = target.rootPart.Position
                
                -- Calculate distance
                local distance = (targetPos - cameraPos).magnitude
                local distanceText = math.floor(distance / 3)
                
                -- Update distance text
                local text = arrow:FindFirstChild("Distance")
                if text then
                    text.Text = distanceText .. "m"
                end
                
                -- Always visible when in game
                arrow.Visible = true
                
                -- Get correct angle
                local angle = getAngleToTarget(camera, targetPos, cameraPos)
                
                -- Position arrow in a circle around exact center
                local centerX = arrowGui.AbsoluteSize.X / 2
                local centerY = arrowGui.AbsoluteSize.Y / 2
                
                local radius = 80
                local angleRad = math.rad(angle)
                
                -- Calculate position in circle
                local x = centerX + math.sin(angleRad) * radius
                local y = centerY - math.cos(angleRad) * radius
                
                -- Keep arrow on screen
                x = math.clamp(x, 20, arrowGui.AbsoluteSize.X - 20)
                y = math.clamp(y, 20, arrowGui.AbsoluteSize.Y - 20)
                
                arrow.Position = UDim2.new(0, x - 15, 0, y - 15)
                
                -- Rotate arrow image
                local img = arrow:FindFirstChild("ArrowImage")
                if img then
                    img.Rotation = angle + 90
                    
                    -- Update color in case team changed
                    local newColor = targetTeam == "Killers" and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(80, 255, 80)
                    img.ImageColor3 = newColor
                end
            end
        end
    end
end

-- Toggle arrows
function Arrows:Toggle(state)
    enabled = state
    
    if enabled then
        -- Create GUI
        createArrowGUI()
        
        -- Reset state
        playerTeam = nil
        currentTargetTeam = nil
        cleanAllArrows()
        
        -- Initial update
        updateArrows()
        
        -- Update loop
        local conn = runService.RenderStepped:Connect(function()
            if enabled then
                updateArrows()
            end
        end)
        table.insert(arrowConnections, conn)
        
        -- Listen for changes
        local conn2 = workspace.ChildAdded:Connect(function()
            task.wait(0.5)
            updateArrows()
        end)
        table.insert(arrowConnections, conn2)
        
        -- Also listen for workspace changes (round end/start)
        local conn3 = workspace.ChildRemoved:Connect(function()
            task.wait(0.5)
            -- Clean arrows when round ends
            cleanAllArrows()
            playerTeam = nil
            currentTargetTeam = nil
        end)
        table.insert(arrowConnections, conn3)
        
    else
        -- Clean up
        for _, conn in ipairs(arrowConnections) do
            pcall(function() conn:Disconnect() end)
        end
        table.clear(arrowConnections)
        
        cleanAllArrows()
        
        if arrowGui then
            pcall(function() arrowGui:Destroy() end)
            arrowGui = nil
        end
        
        playerTeam = nil
        currentTargetTeam = nil
    end
end

return Arrows
