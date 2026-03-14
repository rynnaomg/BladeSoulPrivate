-- modules/ESP.lua
-- ESP module for BladeSoul
-- Version: 3.6 (clean, no compensation)

local ESP = {}
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/Library.lua?nocache=" .. tostring(os.time())))()
local Config = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/Config.lua?nocache=" .. tostring(os.time())))()

local players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local runService = game:GetService("RunService")
local localPlayer = players.LocalPlayer

local enabled = false
local espConnections = {}
local espData = {}

local KILLER_COLOR = Color3.fromRGB(255, 80, 80)
local SURVIVOR_COLOR = Color3.fromRGB(80, 255, 80)

local ignoredParts = {
    CollisionHitbox = true,
    QueryHitbox = true,
    HumanoidRootPart = true,
    Handle = true,
    Machete = true,
    Chainsaw = true,
    Note = true,
    Knife = true,
}

local function getTeam(character)
    local playersFolder = workspace:FindFirstChild("Players")
    if not playersFolder then return nil end
    local killers = playersFolder:FindFirstChild("Killers")
    if killers then
        for _, ch in ipairs(killers:GetChildren()) do
            if ch == character then return "Killers" end
        end
    end
    local survivors = playersFolder:FindFirstChild("Survivors")
    if survivors then
        for _, ch in ipairs(survivors:GetChildren()) do
            if ch == character then return "Survivors" end
        end
    end
    return nil
end

local function createESPObjects()
    local objects = {}

    for i = 1, 4 do
        local line = Drawing.new("Line")
        line.Thickness = 1.5
        line.Visible = false
        line.ZIndex = 5
        objects["line" .. i] = line
    end

    local nameText = Drawing.new("Text")
    nameText.Size = 13
    nameText.Center = true
    nameText.Outline = true
    nameText.OutlineColor = Color3.fromRGB(0, 0, 0)
    nameText.Font = Drawing.Fonts.UI
    nameText.Visible = false
    nameText.ZIndex = 6
    objects.nameText = nameText

    local hpText = Drawing.new("Text")
    hpText.Size = 12
    hpText.Center = true
    hpText.Outline = true
    hpText.OutlineColor = Color3.fromRGB(0, 0, 0)
    hpText.Font = Drawing.Fonts.UI
    hpText.Visible = false
    hpText.ZIndex = 6
    objects.hpText = hpText

    return objects
end

local function destroyESPObjects(objects)
    if not objects then return end
    for _, obj in pairs(objects) do
        pcall(function() obj:Remove() end)
    end
end

local function updateESPForPlayer(plr, objects)
    local character = plr.Character
    if not character then
        for _, obj in pairs(objects) do pcall(function() obj.Visible = false end) end
        return
    end

    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then
        for _, obj in pairs(objects) do pcall(function() obj.Visible = false end) end
        return
    end

    local team = getTeam(character)
    if not team then
        for _, obj in pairs(objects) do pcall(function() obj.Visible = false end) end
        return
    end

    local color = team == "Killers" and KILLER_COLOR or SURVIVOR_COLOR
    local camera = workspace.CurrentCamera

    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    local anyOnScreen = false

    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and not ignoredParts[part.Name] then
            local size = part.Size
            local corners = {
                Vector3.new( size.X/2,  size.Y/2,  size.Z/2),
                Vector3.new(-size.X/2,  size.Y/2,  size.Z/2),
                Vector3.new( size.X/2, -size.Y/2,  size.Z/2),
                Vector3.new(-size.X/2, -size.Y/2,  size.Z/2),
                Vector3.new( size.X/2,  size.Y/2, -size.Z/2),
                Vector3.new(-size.X/2,  size.Y/2, -size.Z/2),
                Vector3.new( size.X/2, -size.Y/2, -size.Z/2),
                Vector3.new(-size.X/2, -size.Y/2, -size.Z/2),
            }
            for _, corner in ipairs(corners) do
                local worldPos = part.CFrame:PointToWorldSpace(corner)
                -- WorldToScreenPoint учитывает топбар и shift lock правильно
                local screenPos, onScreen = camera:WorldToScreenPoint(worldPos)
                if onScreen and screenPos.Z > 0 then
                    anyOnScreen = true
                    if screenPos.X < minX then minX = screenPos.X end
                    if screenPos.Y < minY then minY = screenPos.Y end
                    if screenPos.X > maxX then maxX = screenPos.X end
                    if screenPos.Y > maxY then maxY = screenPos.Y end
                end
            end
        end
    end

    if not anyOnScreen then
        for _, obj in pairs(objects) do pcall(function() obj.Visible = false end) end
        return
    end

    local pad = 3
    minX = minX - pad
    minY = minY - pad
    maxX = maxX + pad
    maxY = maxY + pad

    objects.line1.From = Vector2.new(minX, minY)
    objects.line1.To   = Vector2.new(maxX, minY)
    objects.line1.Color = color
    objects.line1.Visible = true

    objects.line2.From = Vector2.new(minX, maxY)
    objects.line2.To   = Vector2.new(maxX, maxY)
    objects.line2.Color = color
    objects.line2.Visible = true

    objects.line3.From = Vector2.new(minX, minY)
    objects.line3.To   = Vector2.new(minX, maxY)
    objects.line3.Color = color
    objects.line3.Visible = true

    objects.line4.From = Vector2.new(maxX, minY)
    objects.line4.To   = Vector2.new(maxX, maxY)
    objects.line4.Color = color
    objects.line4.Visible = true

    local centerX = (minX + maxX) / 2

    objects.nameText.Text     = plr.Name
    objects.nameText.Position = Vector2.new(centerX, minY - 18)
    objects.nameText.Color    = color
    objects.nameText.Visible  = true

    local hp    = math.floor(humanoid.Health)
    local maxHp = math.floor(humanoid.MaxHealth)
    objects.hpText.Text     = hp .. "/" .. maxHp .. " HP"
    objects.hpText.Position = Vector2.new(centerX, minY - 32)
    objects.hpText.Color    = Color3.fromRGB(255, 255, 255)
    objects.hpText.Visible  = true
end

local function getTargetPlayers()
    local result = {}
    local playersFolder = workspace:FindFirstChild("Players")
    if not playersFolder then return result end

    for _, folder in ipairs(playersFolder:GetChildren()) do
        if folder:IsA("Folder") and (folder.Name == "Killers" or folder.Name == "Survivors") then
            for _, character in ipairs(folder:GetChildren()) do
                if character:IsA("Model") then
                    for _, plr in ipairs(players:GetPlayers()) do
                        if plr ~= localPlayer and plr.Character == character then
                            table.insert(result, plr)
                        end
                    end
                end
            end
        end
    end
    return result
end

local function cleanupAll()
    for name, objects in pairs(espData) do
        destroyESPObjects(objects)
    end
    espData = {}
end

function ESP:Toggle(state)
    enabled = state

    if enabled then
        local renderConn = runService.RenderStepped:Connect(function()
            if not enabled then return end

            local targets = getTargetPlayers()
            local activeNames = {}

            for _, plr in ipairs(targets) do
                activeNames[plr.Name] = true
                if not espData[plr.Name] then
                    espData[plr.Name] = createESPObjects()
                end
                pcall(function()
                    updateESPForPlayer(plr, espData[plr.Name])
                end)
            end

            for name, objects in pairs(espData) do
                if not activeNames[name] then
                    destroyESPObjects(objects)
                    espData[name] = nil
                end
            end
        end)
        table.insert(espConnections, renderConn)

    else
        for _, conn in ipairs(espConnections) do
            pcall(function() conn:Disconnect() end)
        end
        table.clear(espConnections)
        cleanupAll()
    end
end

return ESP
