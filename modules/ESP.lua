-- modules/ESP.lua
-- ESP module for BladeSoul
-- Version: 3.0 (Drawing Box ESP)

local ESP = {}
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/Library.lua?nocache=" .. tostring(os.time())))()
local Config = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/Config.lua?nocache=" .. tostring(os.time())))()

local players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local runService = game:GetService("RunService")
local localPlayer = players.LocalPlayer

local enabled = false
local espConnections = {}
local espData = {} -- [playerName] = { box lines, text objects }

local KILLER_COLOR = Color3.fromRGB(255, 80, 80)
local SURVIVOR_COLOR = Color3.fromRGB(80, 255, 80)

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

local function worldToScreen(pos)
    local camera = workspace.CurrentCamera
    local screenPos, onScreen = camera:WorldToViewportPoint(pos)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
end

local function createESPObjects()
    local objects = {}

    -- 4 линии бокса
    for i = 1, 4 do
        local line = Drawing.new("Line")
        line.Thickness = 1.5
        line.Visible = false
        line.ZIndex = 5
        objects["line" .. i] = line
    end

    -- Имя игрока
    local nameText = Drawing.new("Text")
    nameText.Size = 13
    nameText.Center = true
    nameText.Outline = true
    nameText.OutlineColor = Color3.fromRGB(0, 0, 0)
    nameText.Font = Drawing.Fonts.UI
    nameText.Visible = false
    nameText.ZIndex = 6
    objects.nameText = nameText

    -- HP текст
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
        for _, obj in pairs(objects) do
            pcall(function() obj.Visible = false end)
        end
        return
    end

    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then
        for _, obj in pairs(objects) do
            pcall(function() obj.Visible = false end)
        end
        return
    end

    local team = getTeam(character)
    if not team then
        for _, obj in pairs(objects) do
            pcall(function() obj.Visible = false end)
        end
        return
    end

    local color = team == "Killers" and KILLER_COLOR or SURVIVOR_COLOR

    -- Получаем позицию корня
    local rootPos = rootPart.Position
    local camera = workspace.CurrentCamera

    -- Высота и ширина бокса (примерные размеры персонажа)
    local height = 5.5
    local width = 2.5

    -- Верхняя и нижняя точки персонажа
    local topPos = rootPos + Vector3.new(0, height / 2, 0)
    local bottomPos = rootPos - Vector3.new(0, height / 2, 0)

    local topScreen, onScreen = worldToScreen(topPos)
    local bottomScreen = worldToScreen(bottomPos)

    if not onScreen then
        for _, obj in pairs(objects) do
            pcall(function() obj.Visible = false end)
        end
        return
    end

    -- Размер бокса на экране
    local boxHeight = math.abs(topScreen.Y - bottomScreen.Y)
    local boxWidth = boxHeight * (width / height)

    local left = topScreen.X - boxWidth / 2
    local right = topScreen.X + boxWidth / 2
    local top = topScreen.Y
    local bottom = bottomScreen.Y

    -- Рисуем 4 линии бокса
    -- Верхняя
    objects.line1.From = Vector2.new(left, top)
    objects.line1.To = Vector2.new(right, top)
    objects.line1.Color = color
    objects.line1.Visible = true

    -- Нижняя
    objects.line2.From = Vector2.new(left, bottom)
    objects.line2.To = Vector2.new(right, bottom)
    objects.line2.Color = color
    objects.line2.Visible = true

    -- Левая
    objects.line3.From = Vector2.new(left, top)
    objects.line3.To = Vector2.new(left, bottom)
    objects.line3.Color = color
    objects.line3.Visible = true

    -- Правая
    objects.line4.From = Vector2.new(right, top)
    objects.line4.To = Vector2.new(right, bottom)
    objects.line4.Color = color
    objects.line4.Visible = true

    -- Имя над боксом
    objects.nameText.Text = plr.Name
    objects.nameText.Position = Vector2.new(topScreen.X, top - 18)
    objects.nameText.Color = color
    objects.nameText.Visible = true

    -- HP под именем
    local hp = math.floor(humanoid.Health)
    local maxHp = math.floor(humanoid.MaxHealth)
    objects.hpText.Text = hp .. "/" .. maxHp .. " HP"
    objects.hpText.Position = Vector2.new(topScreen.X, top - 32)
    objects.hpText.Color = Color3.fromRGB(255, 255, 255)
    objects.hpText.Visible = true
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
        -- RenderStepped — обновляем каждый кадр
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

            -- Чистим ушедших игроков
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
