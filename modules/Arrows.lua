-- modules/Arrows.lua
-- Arrow module for Forsaken Hub
-- Version: 4.0 (FORCE SHOW ARROWS - гарантия появления)

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

-- Create arrow GUI (FORCE CREATE)
local function createArrowGUI()
    if arrowGui and arrowGui.Parent then
        return
    end
    
    local success, result = pcall(function()
        local gui = Instance.new("ScreenGui")
        gui.Name = "ForsakenArrows"
        gui.Parent = localPlayer:WaitForChild("PlayerGui")
        gui.ResetOnSpawn = false
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui.IgnoreGuiInset = true
        return gui
    end)
    
    if success and result then
        arrowGui = result
        print("[Arrows] GUI created successfully")
    else
        warn("[Arrows] Failed to create GUI")
    end
end

-- Create a single arrow (FORCE CREATE with test parameters)
local function createArrow(targetPlayer, targetTeam)
    if not arrowGui then 
        print("[Arrows] No GUI to create arrow")
        return nil 
    end
    
    print("[Arrows] Creating arrow for", targetPlayer.Name, "team:", targetTeam)
    
    local success, arrow = pcall(function()
        -- Main arrow container
        local container = Instance.new("Frame")
        container.Name = "Arrow_" .. targetPlayer.Name
        container.Size = UDim2.new(0, 30, 0, 30)
        container.Position = UDim2.new(0.5, -15, 0.5, -15)
        container.BackgroundTransparency = 1
        container.Parent = arrowGui
        container.Visible = true  -- FORCE visible
        
        -- YOUR ARROW IMAGE
        local img = Instance.new("ImageLabel")
        img.Name = "ArrowImage"
        img.Size = UDim2.new(1, 0, 1, 0)
        img.BackgroundTransparency = 1
        img.Image = "rbxassetid://72385423495250"  -- Твой ассет!
        img.ImageColor3 = targetTeam == "Killers" and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(80, 255, 80)
        img.Rotation = 0
        img.Parent = container
        img.Visible = true  -- FORCE visible
        
        -- Distance text
        local distanceText = Instance.new("TextLabel")
        distanceText.Name = "Distance"
        distanceText.Size = UDim2.new(1, 0, 0, 16)
        distanceText.Position = UDim2.new(0, 0, 1, 2)
        distanceText.BackgroundTransparency = 1
        distanceText.Text = "??m"
        distanceText.TextColor3 = Config.Theme.Text
        distanceText.TextSize = 10
        distanceText.Font = Enum.Font.GothamBold
        distanceText.Parent = container
        distanceText.Visible = true  -- FORCE visible
        
        print("[Arrows] Arrow created successfully for", targetPlayer.Name)
        return container
    end)
    
    if not success then
        warn("[Arrows] Failed to create arrow:", success)
        return nil
    end
    
    return arrow
end

-- Get player's team safely
local function getPlayerTeam(player)
    if not player or not player.Character then return nil end
    
    local success, result = pcall(function()
        local playersFolder = workspace:FindFirstChild("Players")
        if not playersFolder then return nil end
        
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

-- Update arrows (simplified for debugging)
local function updateArrows()
    if not enabled then 
        print("[Arrows] Disabled, skipping update")
        return 
    end
    
    if not arrowGui then 
        print("[Arrows] No GUI, creating...")
        createArrowGUI()
        if not arrowGui then return end
    end
    
    if not localPlayer or not localPlayer.Character then 
        print("[Arrows] No local player character")
        return 
    end
    
    -- Get camera
    local camera = getSafeCamera()
    if not camera or not camera.CFrame then 
        print("[Arrows] No camera")
        return 
    end
    
    -- Get local player team
    local newPlayerTeam = getPlayerTeam(localPlayer)
    print("[Arrows] Local team:", newPlayerTeam or "nil")
    
    if newPlayerTeam == "Lobby" or not newPlayerTeam then
        print("[Arrows] In lobby, hiding arrows")
        for _, arrow in pairs(arrows) do
            arrow.Visible = false
        end
        playerTeam = newPlayerTeam
        return
    end
    
    if newPlayerTeam ~= playerTeam then
        print("[Arrows] Team changed from", playerTeam or "nil", "to", newPlayerTeam)
        cleanAllArrows()
        playerTeam = newPlayerTeam
    end
    
    if not playerTeam then return end
    
    local targetTeam = playerTeam == "Killers" and "Survivors" or "Killers"
    print("[Arrows] Target team:", targetTeam)
    
    if targetTeam ~= currentTargetTeam then
        print("[Arrows] Target team changed to", targetTeam)
        cleanAllArrows()
        currentTargetTeam = targetTeam
    end
    
    -- Get targets
    local targets = {}
    local playersFolder = workspace:FindFirstChild("Players")
    if playersFolder then
        local targetFolder = playersFolder:FindFirstChild(targetTeam)
        if targetFolder then
            for _, character in ipairs(targetFolder:GetChildren()) do
                if character:IsA("Model") then
                    local rootPart = getCharacterRootPart(character)
                    if rootPart then
                        for _, plr in pairs(players:GetPlayers()) do
                            if plr.Character == character and plr ~= localPlayer then
                                table.insert(targets, {
                                    player = plr,
                                    character = character,
                                    rootPart = rootPart
                                })
                                print("[Arrows] Found target:", plr.Name)
                                break
                            end
                        end
                    end
                end
            end
        end
    end
    
    print("[Arrows] Total targets found:", #targets)
    
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
            print("[Arrows] Removing arrow for", playerName)
            pcall(function() arrow:Destroy() end)
            arrows[playerName] = nil
        end
    end
    
    -- If no targets, create a TEST arrow to verify GUI works
    if #targets == 0 then
        print("[Arrows] No targets, creating TEST arrow")
        if not arrows["TEST"] then
            local testArrow = createArrow({Name = "TEST"}, "Survivors")
            if testArrow then
                arrows["TEST"] = testArrow
            end
        end
        return
    end
    
    local cameraPos = camera.CFrame.Position
    
    -- Create/update arrows for targets
    for _, target in ipairs(targets) do
        if target.rootPart then
            local arrow = arrows[target.player.Name]
            if not arrow then
                print("[Arrows] Creating arrow for", target.player.Name)
                arrow = createArrow(target.player, targetTeam)
                if arrow then
                    arrows[target.player.Name] = arrow
                end
            end
            
            if arrow then
                local targetPos = target.rootPart.Position
                local distance = (targetPos - cameraPos).magnitude
                local distanceText = math.floor(distance / 3)
                
                local text = arrow:FindFirstChild("Distance")
                if text then
                    text.Text = distanceText .. "m"
                end
                
                arrow.Visible = true
                
                local angle = getAngleToTarget(camera, targetPos, cameraPos)
                
                local centerX = arrowGui.AbsoluteSize.X / 2
                local centerY = arrowGui.AbsoluteSize.Y / 2
                
                local radius = 80
                local angleRad = math.rad(angle)
                
                local x = centerX + math.sin(angleRad) * radius
                local y = centerY - math.cos(angleRad) * radius
                
                x = math.clamp(x, 20, arrowGui.AbsoluteSize.X - 20)
                y = math.clamp(y, 20, arrowGui.AbsoluteSize.Y - 20)
                
                arrow.Position = UDim2.new(0, x - 15, 0, y - 15)
                
                local img = arrow:FindFirstChild("ArrowImage")
                if img then
                    img.Rotation = angle + 90
                end
            end
        end
    end
end

-- Toggle arrows
function Arrows:Toggle(state)
    print("[Arrows] Toggle:", state)
    enabled = state
    
    if enabled then
        createArrowGUI()
        
        playerTeam = nil
        currentTargetTeam = nil
        cleanAllArrows()
        
        -- Force immediate update
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
        
        local conn3 = workspace.ChildRemoved:Connect(function()
            task.wait(0.5)
            cleanAllArrows()
            playerTeam = nil
            currentTargetTeam = nil
            updateArrows()
        end)
        table.insert(arrowConnections, conn3)
        
    else
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
