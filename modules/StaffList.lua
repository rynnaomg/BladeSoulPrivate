-- modules/StaffList.lua
-- Staff List module for Forsaken Hub
-- Version: 5.3 (FIXED GroupService)

local StaffList = {}
local Config = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/Config.lua"))()
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/Library.lua"))()

local players = Library.Services.Players
local tween = Library.Services.Tween

-- ===== ИСПРАВЛЕНО: Правильный способ получить GroupService =====
local GroupService
local success, result = pcall(function()
    return game:GetService("GroupService")
end)
if success then
    GroupService = result
else
    -- Альтернативный вариант
    GroupService = game:GetService("Groups")
end

local screenGui = nil
local staffListFrame = nil
local enabled = false

-- ===== ТВОИ РЕАЛЬНЫЕ НОМЕРА РАНГОВ =====
local STAFF_RANKS = {
    [225] = "Moderator",  -- Твой ранг
    -- Добавим остальные когда узнаем
}

-- Debug функция
local function debugPrint(...)
    print("[StaffList Debug]", ...)
end

-- Функция проверки staff через GroupService
local function checkStaff(userId)
    if not GroupService then
        debugPrint("GroupService not available")
        return false, nil
    end
    
    local success, groups = pcall(function()
        return GroupService:GetGroupsAsync(userId)
    end)
    
    if not success or not groups then
        return false, nil
    end
    
    for _, groupData in ipairs(groups) do
        if groupData.Id == Config.StaffGroup.GroupID then
            local rankNumber = groupData.Rank
            
            -- Проверяем по нашим известным номерам
            local rankName = STAFF_RANKS[rankNumber]
            if rankName then
                debugPrint("✅ Найден staff:", rankName, "(ранг", rankNumber, ")")
                return true, rankName
            else
                debugPrint("⚠️ Неизвестный номер ранга:", rankNumber)
                return true, "Rank " .. rankNumber
            end
        end
    end
    
    return false, nil
end

-- Функция обновления списка
local function updateStaffList()
    if not staffListFrame or not enabled then return end
    
    -- Очистка
    for _, v in pairs(staffListFrame:GetChildren()) do
        if v:IsA("Frame") and v.Name == "StaffEntry" then
            v:Destroy()
        end
    end
    
    local yOffset = 5
    local maxWidth = 220
    local entries = {}
    
    -- Проверяем всех игроков
    for _, plr in pairs(players:GetPlayers()) do
        if plr ~= players.LocalPlayer then
            local isStaff, rankName = checkStaff(plr.UserId)
            if isStaff then
                table.insert(entries, {
                    name = plr.Name,
                    rank = rankName,
                    isOnline = true
                })
            end
        end
    end
    
    -- Сортировка
    table.sort(entries, function(a, b)
        if a.rank == "Moderator" and not b.rank:find("Moderator") then return true end
        if b.rank == "Moderator" and not a.rank:find("Moderator") then return false end
        return a.name < b.name
    end)
    
    -- Создание записей
    for _, entry in ipairs(entries) do
        local entryText = string.format("[%s] 🟢 %s", entry.rank, entry.name)
        
        -- Подсчёт ширины
        local tempLabel = Instance.new("TextLabel")
        tempLabel.Text = entryText
        tempLabel.TextSize = 14
        tempLabel.Font = Enum.Font.Gotham
        tempLabel.TextTransparency = 1
        tempLabel.Parent = staffListFrame
        local textWidth = tempLabel.TextBounds.X + 40
        tempLabel:Destroy()
        
        if textWidth > maxWidth then
            maxWidth = textWidth
        end
        
        -- Создание фрейма
        local entryFrame = Instance.new("Frame")
        entryFrame.Name = "StaffEntry"
        entryFrame.Size = UDim2.new(1, -10, 0, 28)
        entryFrame.Position = UDim2.new(0, 5, 0, yOffset)
        entryFrame.BackgroundColor3 = Config.Theme.Darker
        entryFrame.Parent = staffListFrame
        
        local entryCorner = Instance.new("UICorner")
        entryCorner.CornerRadius = UDim.new(0, 4)
        entryCorner.Parent = entryFrame
        
        -- Цвет по рангу
        local rankColor = Config.Theme.Cyan
        if entry.rank == "Moderator" then
            rankColor = Color3.fromRGB(255, 255, 50)  -- Жёлтый
        elseif entry.rank == "Owner" then
            rankColor = Color3.fromRGB(255, 50, 50)    -- Красный
        elseif entry.rank == "Developer" then
            rankColor = Color3.fromRGB(50, 255, 50)    -- Зелёный
        elseif entry.rank == "Testers" then
            rankColor = Color3.fromRGB(50, 150, 255)   -- Синий
        elseif entry.rank:find("Rank") then
            rankColor = Color3.fromRGB(150, 150, 150)  -- Серый для неизвестных
        end
        
        local colorBar = Instance.new("Frame")
        colorBar.Size = UDim2.new(0, 3, 1, -4)
        colorBar.Position = UDim2.new(0, 2, 0, 2)
        colorBar.BackgroundColor3 = rankColor
        colorBar.BorderSizePixel = 0
        colorBar.Parent = entryFrame
        
        local barCorner = Instance.new("UICorner")
        barCorner.CornerRadius = UDim.new(0, 2)
        barCorner.Parent = colorBar
        
        local entryLabel = Instance.new("TextLabel")
        entryLabel.Size = UDim2.new(1, -15, 1, 0)
        entryLabel.Position = UDim2.new(0, 8, 0, 0)
        entryLabel.BackgroundTransparency = 1
        entryLabel.Text = entryText
        entryLabel.TextColor3 = Config.Theme.Text
        entryLabel.TextSize = 14
        entryLabel.Font = Enum.Font.Gotham
        entryLabel.TextXAlignment = Enum.TextXAlignment.Left
        entryLabel.Parent = entryFrame
        
        yOffset = yOffset + 33
    end
    
    -- Настройка размера
    if #entries > 0 then
        local neededHeight = math.max(200, yOffset + 15)
        staffListFrame.Parent.Size = UDim2.new(0, maxWidth + 20, 0, neededHeight)
        staffListFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset + 15)
    else
        staffListFrame.Parent.Size = UDim2.new(0, 220, 0, 80)
        staffListFrame.CanvasSize = UDim2.new(0, 0, 0, 80)
        
        local noStaff = Instance.new("TextLabel")
        noStaff.Name = "StaffEntry"
        noStaff.Size = UDim2.new(1, -10, 0, 40)
        noStaff.Position = UDim2.new(0, 5, 0, 20)
        noStaff.BackgroundTransparency = 1
        noStaff.Text = "No staff members online"
        noStaff.TextColor3 = Config.Theme.TextSecondary
        noStaff.TextSize = 14
        noStaff.Font = Enum.Font.Gotham
        noStaff.Parent = staffListFrame
    end
end

-- Создание интерфейса
function StaffList:Create(parentGui)
    screenGui = parentGui
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "StaffList"
    mainFrame.Size = UDim2.new(0, 240, 0, 250)
    mainFrame.Position = UDim2.new(0, 10, 0, 50)
    mainFrame.BackgroundColor3 = Config.Theme.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui
    mainFrame.ZIndex = 10
    mainFrame.Visible = false
    mainFrame.ClipsDescendants = true
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 8)
    mainCorner.Parent = mainFrame
    
    -- Заголовок
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 35)
    titleBar.BackgroundColor3 = Config.Theme.Darker
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = titleBar
    
    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(1, -30, 1, 0)
    titleText.Position = UDim2.new(0, 10, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "Staff List"
    titleText.TextColor3 = Config.Theme.Cyan
    titleText.TextSize = 18
    titleText.Font = Enum.Font.GothamBold
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 26, 0, 26)
    closeButton.Position = UDim2.new(1, -30, 0, 4.5)
    closeButton.Text = "×"
    closeButton.TextColor3 = Config.Theme.Text
    closeButton.TextSize = 20
    closeButton.BackgroundColor3 = Config.Theme.Darker
    closeButton.AutoButtonColor = false
    closeButton.Parent = titleBar
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 4)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        StaffList:Toggle(false)
    end)
    
    -- Контейнер для записей
    staffListFrame = Instance.new("ScrollingFrame")
    staffListFrame.Name = "StaffContainer"
    staffListFrame.Size = UDim2.new(1, 0, 1, -35)
    staffListFrame.Position = UDim2.new(0, 0, 0, 35)
    staffListFrame.BackgroundTransparency = 1
    staffListFrame.BorderSizePixel = 0
    staffListFrame.ScrollBarThickness = 6
    staffListFrame.ScrollBarImageColor3 = Config.Theme.Cyan
    staffListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    staffListFrame.Parent = mainFrame
    
    return mainFrame
end

function StaffList:Toggle(state)
    enabled = state
    
    if not staffListFrame then return end
    
    local mainFrame = staffListFrame.Parent
    if not mainFrame then return end
    
    mainFrame.Visible = state
    
    if state then
        updateStaffList()
        
        players.PlayerAdded:Connect(function()
            task.wait(1)
            updateStaffList()
        end)
        
        players.PlayerRemoving:Connect(updateStaffList)
        
        spawn(function()
            while enabled do
                task.wait(5)
                updateStaffList()
            end
        end)
    end
end

return StaffList
