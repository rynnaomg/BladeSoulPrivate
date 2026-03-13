-- modules/Arrows.lua
-- Arrow module for Forsaken Hub
-- Version: 11.0 - ABSOLUTELY NO GUI ELEMENTS

local Arrows = {}
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/Library.lua"))()
local Config = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/Config.lua"))()

local players = Library.Services.Players
local workspace = game:GetService("Workspace")
local runService = game:GetService("RunService")
local localPlayer = players.LocalPlayer

local enabled = false
local arrowConnections = {}
local arrows = {}
local playerTeam = nil
local currentTargetTeam = nil
local arrowImageData = nil

local ARROW_FILE_NAME = "forsaken_arrow.png"
local ARROW_GITHUB_URL = "https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/assets/arrow.png"

local drawingSupported = Drawing and Drawing.new
if not drawingSupported then
    warn("[Arrows] Drawing API not supported")
end

local function loadArrowImage()
    if arrowImageData then return arrowImageData end
    if not isfile or not writefile then return nil end
    if isfile(ARROW_FILE_NAME) then
        local s, d = pcall(readfile, ARROW_FILE_NAME)
        if s and d then arrowImageData = d; return arrowImageData end
    end
    local s, d = pcall(function() return game:HttpGet(ARROW_GITHUB_URL) end)
    if s and d and #d > 0 then
        writefile(ARROW_FILE_NAME, d)
        arrowImageData = d
        return arrowImageData
    end
    return nil
end

local function getSafeCamera()
    local s, r = pcall(function() return workspace.CurrentCamera end)
    return s and r
end

local function getCharacterRootPart(character)
    if not character then return nil end
    local s, r = pcall(function() return character:FindFirstChild("HumanoidRootPart") end)
    return s and r
end

local function getPlayerTeam(player)
    if not player or not player.Character then return nil end
    local s, r = pcall(function()
        local pf = workspace:FindFirstChild("Players")
        if not pf then return nil end
        if not pf:FindFirstChild("Killers") and not pf:FindFirstChild("Survivors") then return "Lobby" end
        local kf = pf:FindFirstChild("Killers")
        if kf then for _, ch in ipairs(kf:GetChildren()) do if ch:IsA("Model") and player.Character == ch then return "Killers" end end end
        local sf = pf:FindFirstChild("Survivors")
        if sf then for _, ch in ipairs(sf:GetChildren()) do if ch:IsA("Model") and player.Character == ch then return "Survivors" end end end
        return nil
    end)
    return s and r
end

local function getAngleToTarget(camera, targetPos)
    local rel = camera.CFrame:PointToObjectSpace(targetPos)
    return math.deg(math.atan2(rel.X, -rel.Z))
end

local function createArrow(targetPlayer, targetTeam)
    if not drawingSupported then return nil end
    
    local imgData = loadArrowImage()
    local isKiller = (targetTeam == "Killers")
    local color = isKiller and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(80, 255, 80)
    
    local img
    if imgData then
        local s, result = pcall(function()
            local i = Drawing.new("Image")
            i.Data = imgData
            i.Size = Vector2.new(30, 30)
            return i
        end)
        if s and result then
            img = result
        end
    end
    if not img then
        img = Drawing.new("Circle")
        img.Color = color
        img.Filled = true
        img.Radius = 15
        img.NumSides = 30
    end
    
    img.Position = Vector2.new(0, 0)
    img.Visible = false
    img.ZIndex = 10
    pcall(function() img.Transparency = 1 end)
    
    local txt = Drawing.new("Text")
    txt.Text = "0m"
    txt.Color = Color3.fromRGB(255, 255, 255)
    txt.Size = 14
    txt.Center = true
    txt.Outline = true
    txt.OutlineColor = Color3.fromRGB(0, 0, 0)
    txt.Font = Drawing.Fonts.UI
    txt.Position = Vector2.new(0, 0)
    txt.Visible = false
    txt.ZIndex = 10
    
    return { image = img, text = txt, playerName = targetPlayer.Name }
end

local function destroyArrow(a)
    if not a then return end
    pcall(function() if a.image then a.image:Remove() end end)
    pcall(function() if a.text then a.text:Remove() end end)
end

local function cleanAllArrows()
    for _, a in pairs(arrows) do destroyArrow(a) end
    table.clear(arrows)
end

local function updateArrows()
    if not enabled or not drawingSupported then return end
    if not localPlayer or not localPlayer.Character then return end
    
    local cam = getSafeCamera()
    if not cam then return end
    
    local newTeam = getPlayerTeam(localPlayer)
    
    if newTeam == "Lobby" or not newTeam then
        for _, a in pairs(arrows) do
            if a.image then a.image.Visible = false end
            if a.text then a.text.Visible = false end
        end
        playerTeam = newTeam
        return
    end
    
    if newTeam ~= playerTeam then
        cleanAllArrows()
        playerTeam = newTeam
        currentTargetTeam = nil
    end
    
    if not playerTeam then return end
    
    local targetTeam = playerTeam == "Killers" and "Survivors" or "Killers"
    if targetTeam ~= currentTargetTeam then
        cleanAllArrows()
        currentTargetTeam = targetTeam
    end
    
    local targets = {}
    local pf = workspace:FindFirstChild("Players")
    if pf then
        local tf = pf:FindFirstChild(targetTeam)
        if tf then
            for _, ch in ipairs(tf:GetChildren()) do
                if ch:IsA("Model") then
                    local root = getCharacterRootPart(ch)
                    if root then
                        for _, plr in pairs(players:GetPlayers()) do
                            if plr.Character == ch and plr ~= localPlayer then
                                table.insert(targets, {player = plr, root = root})
                                break
                            end
                        end
                    end
                end
            end
        end
    end
    
    for name, a in pairs(arrows) do
        local found = false
        for _, t in ipairs(targets) do if t.player.Name == name then found = true break end end
        if not found then destroyArrow(a); arrows[name] = nil end
    end
    
    local camPos = cam.CFrame.Position
    local sz = cam.ViewportSize
    
    for _, t in ipairs(targets) do
        local a = arrows[t.player.Name]
        if not a then
            a = createArrow(t.player, targetTeam)
            if a then arrows[t.player.Name] = a end
        end
        
        if a then
            local tPos = t.root.Position
            local dist = (tPos - camPos).Magnitude
            local distM = math.floor(dist / 3)
            local ang = getAngleToTarget(cam, tPos)
            local rad = math.rad(ang)
            local r = 80
            local cx = sz.X/2 + math.sin(rad) * r
            local cy = sz.Y/2 - math.cos(rad) * r
            cx = math.clamp(cx, 20, sz.X - 20)
            cy = math.clamp(cy, 20, sz.Y - 20)
            
            if a.image then
                if a.image.Type == "Image" then
                    a.image.Position = Vector2.new(cx - 15, cy - 15)
                    if a.image.Rotation then a.image.Rotation = ang end
                else
                    a.image.Position = Vector2.new(cx, cy)
                end
                a.image.Visible = true
            end
            
            if a.text then
                a.text.Text = distM .. "m"
                a.text.Position = Vector2.new(cx - 15, cy + 18)
                a.text.Visible = true
            end
        end
    end
end

function Arrows:Toggle(state)
    enabled = state
    if enabled then
        task.spawn(loadArrowImage)
        playerTeam = nil; currentTargetTeam = nil; cleanAllArrows()
        updateArrows()
        local c1 = runService.RenderStepped:Connect(function() if enabled then updateArrows() end end)
        local c2 = workspace.ChildAdded:Connect(function() task.wait(0.5); if enabled then updateArrows() end end)
        local c3 = workspace.ChildRemoved:Connect(function() task.wait(0.5); if enabled then cleanAllArrows(); playerTeam = nil; currentTargetTeam = nil; updateArrows() end end)
        table.insert(arrowConnections, c1); table.insert(arrowConnections, c2); table.insert(arrowConnections, c3)
    else
        for _, c in ipairs(arrowConnections) do pcall(function() c:Disconnect() end) end
        table.clear(arrowConnections); cleanAllArrows(); playerTeam = nil; currentTargetTeam = nil
    end
end

return Arrows
