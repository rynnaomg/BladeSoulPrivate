-- modules/Arrows.lua
-- Arrow module for Forsaken Hub
-- Version: 3.0 (Fixed direction math)

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

-- Create a single arrow
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
        
        -- Arrow image
        local img = Instance.new("ImageLabel")
        img.Name = "ArrowImage"
        img.Size = UDim2.new(1, 0, 1, 0)
        img.BackgroundTransparency = 1
        img.Image = "rbxassetid://6031090990"
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

-- FIXED: Calculate correct angle to target [citation:1][citation:5]
local function getAngleToTarget(camera, targetPos, cameraPos)
    -- Convert target position to camera space
    local relativePos = camera.CFrame:PointToObjectSpace(targetPos)
    
    -- Calculate angle using atan2 with correct X and Z axes
    -- This gives us the horizontal angle (left/right) [citation:5]
    local angle = math.atan2(relativePos.X, -relativePos.Z)
    
    -- Convert to degrees
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
    playerTeam = getPlayerTeam(localPlayer)
    if not playerTeam then return end
    
    -- Determine targets
    local targetTeam = playerTeam == "Killers" and "Survivors" or "Killers"
    
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
    
    -- Clean up old arrows
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
            -- Get or create arrow
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
                
                -- Always visible
                arrow.Visible = true
                
                -- FIXED: Get correct angle using the new function
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
                
                -- Rotate arrow image to point outward from center [citation:2]
                local img = arrow:FindFirstChild("ArrowImage")
                if img then
                    -- Arrow should point away from center toward the target
                    img.Rotation = angle + 90  -- +90 because arrow image points up by default [citation:4]
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
        
    else
        -- Clean up
        for _, conn in ipairs(arrowConnections) do
            pcall(function() conn:Disconnect() end)
        end
        table.clear(arrowConnections)
        
        for _, arrow in pairs(arrows) do
            pcall(function() arrow:Destroy() end)
        end
        table.clear(arrows)
        
        if arrowGui then
            pcall(function() arrowGui:Destroy() end)
            arrowGui = nil
        end
    end
end

return Arrows
