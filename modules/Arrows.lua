-- modules/Arrows.lua
-- Arrow module for Forsaken Hub
-- Version: 5.1 (Delta Executor compatible)

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
local arrowImagePath = nil

-- Check if file operations are supported (Delta Executor)
local fileSupported = pcall(function() 
    return writefile and readfile and isfile and delfile
end)

if fileSupported then
    print("[Arrows] File operations supported")
else
    warn("[Arrows] File operations not supported, using fallback")
end

-- Function to download and cache the arrow image
local function ensureArrowImage()
    if not fileSupported then
        return "rbxassetid://6031090990" -- Fallback to working Roblox arrow
    end
    
    local fileName = "arrow_cache.png"
    local githubUrl = "https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/assets/arrow.png"
    
    -- Check if file already exists
    if isfile(fileName) then
        print("[Arrows] Using cached arrow image")
        return "rbxasset://" .. fileName
    end
    
    -- Download from GitHub
    print("[Arrows] Downloading arrow image from GitHub...")
    local success, imageData = pcall(function()
        return game:HttpGet(githubUrl)
    end)
    
    if success and imageData and #imageData > 0 then
        -- Save to Delta Workspace folder
        writefile(fileName, imageData)
        print("[Arrows] Arrow image saved to:", fileName)
        return "rbxasset://" .. fileName
    else
        warn("[Arrows] Failed to download arrow image, using fallback")
        return "rbxassetid://6031090990" -- Fallback to working Roblox arrow
    end
end

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

-- Create a single arrow
local function createArrow(targetPlayer, targetTeam)
    if not arrowGui then 
        return nil 
    end
    
    -- Get arrow image (will download if needed)
    local arrowImage = ensureArrowImage()
    if not arrowImagePath then
        arrowImagePath = arrowImage
    end
    
    local success, arrow = pcall(function()
        -- Main arrow container
        local container = Instance.new("Frame")
        container.Name = "Arrow_" .. targetPlayer.Name
        container.Size = UDim2.new(0, 30, 0, 30)
        container.Position = UDim2.new(0.5, -15, 0.5, -15)
        container.BackgroundTransparency = 1
        container.Parent = arrowGui
        container.Visible = true
        
        -- Arrow image
        local img = Instance.new("ImageLabel")
        img.Name = "ArrowImage"
        img.Size = UDim2.new(1, 0, 1, 0)
        img.BackgroundTransparency = 1
        img.Image = arrowImage
        img.ImageColor3 = targetTeam == "Killers" and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(80, 255, 80)
        img.Rotation = 0
        img.Parent = container
        img.Visible = true
        
        -- Distance text
        local distanceText = Instance.new("TextLabel")
        distanceText.Name = "Distance"
        distanceText.Size = UDim2.new(1, 0, 0, 16)
        distanceText.Position = UDim2.new(0, 0, 1, 2)
        distanceText.BackgroundTransparency = 1
        distanceText.Text = "0m"
        distanceText.TextColor3 = Config.Theme.Text
        distanceText.TextSize = 10
        distanceText.Font = Enum.Font.GothamBold
        distanceText.Parent = container
        distanceText.Visible = true
        
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
    if not arrowGui then 
        createArrowGUI()
        if not arrowGui then return end
    end
    
    if not localPlayer or not localPlayer.Character then return end
    
    local camera = getSafeCamera()
    if not camera or not camera.CFrame then return end
    
    local newPlayerTeam = getPlayerTeam(localPlayer)
    
    if newPlayerTeam == "Lobby" or not newPlayerTeam then
        for _, arrow in pairs(arrows) do
            arrow.Visible = false
        end
        playerTeam = newPlayerTeam
        return
    end
    
    if newPlayerTeam ~= playerTeam then
        cleanAllArrows()
        playerTeam = newPlayerTeam
    end
    
    if not playerTeam then return end
    
    local targetTeam = playerTeam == "Killers" and "Survivors" or "Killers"
    
    if targetTeam ~= currentTargetTeam then
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
                                break
                            end
                        end
                    end
                end
            end
        end
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
    
    local cameraPos = camera.CFrame.Position
    
    -- Create/update arrows for targets
    for _, target in ipairs(targets) do
        if target.rootPart then
            local arrow = arrows[target.player.Name]
            if not arrow then
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
    enabled = state
    
    if enabled then
        createArrowGUI()
        
        playerTeam = nil
        currentTargetTeam = nil
        cleanAllArrows()
        
        -- Preload arrow image
        ensureArrowImage()
        
        updateArrows()
        
        local conn = runService.RenderStepped:Connect(function()
            if enabled then
                updateArrows()
            end
        end)
        table.insert(arrowConnections, conn)
        
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
