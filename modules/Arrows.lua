-- modules/Arrows.lua
-- Arrow module for Forsaken Hub
-- Version: 2.0 (Bulletproof error handling)

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
        local img = Instance.new("ImageLabel")
        img.Name = "Arrow_" .. targetPlayer.Name
        img.Size = UDim2.new(0, 40, 0, 40)
        img.Position = UDim2.new(0.5, -20, 0.3, -20)
        img.BackgroundTransparency = 1
        img.Image = "rbxassetid://6031280882"
        img.ImageColor3 = targetTeam == "Killers" and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 255, 100)
        img.Rotation = 0
        img.Visible = false
        img.Parent = arrowGui
        
        local distanceText = Instance.new("TextLabel")
        distanceText.Name = "Distance"
        distanceText.Size = UDim2.new(1, 0, 0, 20)
        distanceText.Position = UDim2.new(0, 0, 1, 0)
        distanceText.BackgroundTransparency = 1
        distanceText.Text = ""
        distanceText.TextColor3 = Config.Theme.Text
        distanceText.TextSize = 12
        distanceText.Font = Enum.Font.GothamBold
        distanceText.Parent = img
        
        return img
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
                    -- Find player name
                    for _, plr in pairs(players:GetPlayers()) do
                        if plr.Character == character and plr ~= localPlayer then
                            table.insert(results, {
                                player = plr,
                                character = character,
                                rootPart = rootPart,
                                humanoid = humanoid
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
    
    -- Get camera position safely
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
                -- Safely get target position
                local targetPos = target.rootPart.Position
                local direction = (targetPos - cameraPos).unit
                
                -- Check if on screen
                local screenPos, onScreen = camera:WorldToViewportPoint(targetPos)
                
                -- Calculate distance
                local distance = (targetPos - cameraPos).magnitude
                local distanceText = math.floor(distance / 3)
                
                -- Update distance text
                local text = arrow:FindFirstChild("Distance")
                if text then
                    text.Text = distanceText .. "m"
                end
                
                -- If on screen, hide arrow
                if onScreen and screenPos.Z > 0 then
                    arrow.Visible = false
                else
                    arrow.Visible = true
                    
                    -- Calculate angle
                    local cameraDirection = camera.CFrame.LookVector
                    local toTarget = (targetPos - cameraPos).unit
                    
                    local cameraAngle = math.atan2(-cameraDirection.X, -cameraDirection.Z)
                    local targetAngle = math.atan2(-toTarget.X, -toTarget.Z)
                    
                    local angle = (targetAngle - cameraAngle) * (180 / math.pi)
                    if angle > 180 then angle = angle - 360 end
                    if angle < -180 then angle = angle + 360 end
                    
                    -- Position arrow
                    local centerX = arrowGui.AbsoluteSize.X / 2
                    local centerY = arrowGui.AbsoluteSize.Y * 0.3
                    
                    local radius = 120
                    local angleRad = math.rad(angle)
                    
                    local x = centerX + math.sin(angleRad) * radius
                    local y = centerY - math.cos(angleRad) * radius
                    
                    x = math.clamp(x, 40, arrowGui.AbsoluteSize.X - 40)
                    y = math.clamp(y, 40, arrowGui.AbsoluteSize.Y - 40)
                    
                    arrow.Position = UDim2.new(0, x - 20, 0, y - 20)
                    arrow.Rotation = angle
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
