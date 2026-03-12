-- modules/Arrows.lua
-- Arrow module for Forsaken Hub
-- Version: 1.0 (Radar arrows around center screen)

local Arrows = {}
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/Library.lua"))()
local Config = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/Config.lua"))()

local players = Library.Services.Players
local workspace = game:GetService("Workspace")
local camera = workspace.CurrentCamera
local userInput = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local localPlayer = players.LocalPlayer

local enabled = false
local arrowConnections = {}
local arrowGui = nil
local arrows = {}
local playerTeam = nil

-- Create arrow GUI
local function createArrowGUI()
    if arrowGui then return end
    
    arrowGui = Instance.new("ScreenGui")
    arrowGui.Name = "ForsakenArrows"
    arrowGui.Parent = localPlayer:WaitForChild("PlayerGui")
    arrowGui.ResetOnSpawn = false
    arrowGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    arrowGui.IgnoreGuiInset = true
end

-- Create a single arrow
local function createArrow(targetPlayer, targetTeam)
    if not arrowGui then return end
    
    local arrow = Instance.new("ImageLabel")
    arrow.Name = "Arrow_" .. targetPlayer.Name
    arrow.Size = UDim2.new(0, 40, 0, 40)
    arrow.Position = UDim2.new(0.5, -20, 0.3, -20)  -- 30% from top (slightly above center)
    arrow.BackgroundTransparency = 1
    arrow.Image = "rbxassetid://6031280882"  -- Arrow image
    arrow.ImageColor3 = targetTeam == "Killers" and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 255, 100)
    arrow.Rotation = 0
    arrow.Visible = false
    arrow.Parent = arrowGui
    
    -- Distance text
    local distanceText = Instance.new("TextLabel")
    distanceText.Name = "Distance"
    distanceText.Size = UDim2.new(1, 0, 0, 20)
    distanceText.Position = UDim2.new(0, 0, 1, 0)
    distanceText.BackgroundTransparency = 1
    distanceText.Text = ""
    distanceText.TextColor3 = Config.Theme.Text
    distanceText.TextSize = 12
    distanceText.Font = Enum.Font.GothamBold
    distanceText.Parent = arrow
    
    return arrow
end

-- Get player's team
local function getPlayerTeam(player)
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
end

-- Update arrows
local function updateArrows()
    if not enabled or not arrowGui or not localPlayer.Character then return end
    
    -- Get local player team
    playerTeam = getPlayerTeam(localPlayer)
    if not playerTeam then return end
    
    -- Determine targets (opposite team)
    local targetTeam = playerTeam == "Killers" and "Survivors" or "Killers"
    
    -- Get all targets
    local targets = {}
    local playersFolder = workspace:FindFirstChild("Players")
    if not playersFolder then return end
    
    local targetFolder = playersFolder:FindFirstChild(targetTeam)
    if not targetFolder then return end
    
    for _, character in ipairs(targetFolder:GetChildren()) do
        if character:IsA("Model") and character:FindFirstChild("Humanoid") and character:FindFirstChild("HumanoidRootPart") then
            -- Find player name
            for _, plr in pairs(players:GetPlayers()) do
                if plr.Character == character and plr ~= localPlayer then
                    table.insert(targets, {
                        player = plr,
                        character = character,
                        rootPart = character.HumanoidRootPart
                    })
                    break
                end
            end
        end
    end
    
    -- Remove arrows for players who are no longer targets
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
    
    -- Create/update arrows for current targets
    local cameraPos = camera.CameraSubject and camera.CameraSubject.Position or camera.CFrame.Position
    
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
                -- Calculate direction
                local targetPos = target.rootPart.Position
                local direction = (targetPos - cameraPos).unit
                local screenPos, onScreen = camera:WorldToViewportPoint(targetPos)
                
                -- Calculate distance
                local distance = (targetPos - cameraPos).magnitude
                local distanceText = math.floor(distance / 3)  -- Approximate studs to meters
                
                -- Update distance text
                local text = arrow:FindFirstChild("Distance")
                if text then
                    text.Text = distanceText .. "m"
                end
                
                -- If on screen, hide arrow (player is visible)
                if onScreen and screenPos.Z > 0 then
                    arrow.Visible = false
                else
                    -- Show arrow and rotate to point to target
                    arrow.Visible = true
                    
                    -- Calculate angle
                    local angle = math.atan2(direction.Y, math.sqrt(direction.X^2 + direction.Z^2))
                    angle = math.deg(angle)
                    
                    -- Arrow rotates around center (200px radius)
                    local centerX = arrowGui.AbsoluteSize.X / 2
                    local centerY = arrowGui.AbsoluteSize.Y * 0.3  -- 30% from top
                    
                    -- Position arrow in a circle around center
                    local radius = 150
                    local angleRad = math.rad(angle)
                    
                    local x = centerX + math.sin(angleRad) * radius
                    local y = centerY - math.cos(angleRad) * radius
                    
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
        
        -- Update loop (every frame for smooth rotation)
        local conn = runService.RenderStepped:Connect(function()
            if enabled then
                updateArrows()
            end
        end)
        table.insert(arrowConnections, conn)
        
        -- Listen for team changes
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
        
        -- Remove all arrows
        for _, arrow in pairs(arrows) do
            pcall(function() arrow:Destroy() end)
        end
        table.clear(arrows)
        
        -- Remove GUI
        if arrowGui then
            pcall(function() arrowGui:Destroy() end)
            arrowGui = nil
        end
    end
end

return Arrows
