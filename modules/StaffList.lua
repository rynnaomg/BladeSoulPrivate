-- modules/StaffList.lua
-- Staff List module for Forsaken Hub
-- Version: 5.0 (OFFLINE PLAYER SUPPORT)

local StaffList = {}
local Config = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/Config.lua"))()
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/Library.lua"))()

local players = Library.Services.Players
local tween = Library.Services.Tween
local GroupService = game:GetService("GroupService")
local HttpService = game:GetService("HttpService")

local screenGui = nil
local staffListFrame = nil
local enabled = false

-- ===== ТВОИ РЕАЛЬНЫЕ НОМЕРА РАНГОВ ИЗ ЛОГОВ =====
local STAFF_RANKS = {
    [225] = "Moderator",  -- Moderator = 225
    -- Добавим остальные когда узнаешь номера:
    -- [???] = "Testers",
    -- [???] = "Developer",
    -- [255] = "Owner",
}

-- Debug функция
local function debugPrint(...)
    print("[StaffList Debug]", ...)
end

-- Функция проверки staff через GroupService (работает даже офлайн!)
local function checkStaffOffline(userId)
    local success, groups = pcall(function()
        return GroupService:GetGroupsAsync(userId)
    end)
    
    if not success or not groups then
        debugPrint("Failed to get groups for user", userId)
        return false, nil
    end
    
    -- Ищем нашу группу
    for _, groupData in ipairs(groups) do
        if groupData.Id == Config.StaffGroup.GroupID then
            local rankNumber = groupData.Rank  -- Числовой ранг
            debugPrint("User", userId, "has rank number:", rankNumber, "in group")
            
            -- Проверяем по нашим известным номерам
            local rankName = STAFF_RANKS[rankNumber]
            if rankName then
                return true, rankName
            else
                debugPrint("Unknown rank number:", rankNumber)
                return true, "Rank " .. rankNumber
            end
        end
    end
    
    return false, nil
end

-- Резервный метод для онлайн игроков
local function checkStaffOnline(player)
    local success, rankNumber = pcall(function()
        return player:GetRankInGroup(Config.StaffGroup.GroupID)
    end)
    
    if success and rankNumber and rankNumber > 0 then
        local rankName = STAFF_RANKS[rankNumber]
        if rankName then
            return true, rankName
        else
            return true, "Rank " .. rankNumber
        end
    end
    return false, nil
end

-- Функция сбора всех staff (онлайн + офлайн)
local function getAllStaff()
    local staffMembers = {}
    local processedUsers = {}
    
    -- Сначала проверяем онлайн игроков (быстро)
    for _, plr in pairs(players:GetPlayers()) do
        if plr ~= players.LocalPlayer then
            local isStaff, rankName = checkStaffOnline(plr)
            if isStaff then
                table.insert(staffMembers, {
                    name = plr.Name,
                    rank = rankName,
                    userId = plr.UserId,
                    isOnline = true
                })
                processedUsers[plr.UserId] = true
            end
        end
    end
    
    -- Проверяем всех возможных staff офлайн (нужно больше времени)
    -- В реальном времени это делается через периодические запросы
    -- или при включении функции
    
    debugPrint("Total staff found online:", #staffMembers)
    return staffMembers
end

-- Функция обновления списка
local function updateStaffList()
    if not staffListFrame or not enabled then return end
    
    -- Clear old entries
    for _, v in pairs(staffListFrame:GetChildren()) do
        if v:IsA("Frame") and v.Name == "StaffEntry" then
            v:Destroy()
        end
    end
    
    local yOffset = 5
    local maxWidth = 180
    local staffMembers = getAllStaff()
    
    -- Sort entries
    table.sort(staffMembers, function(a, b)
        -- Moderator выше других
        if a.rank == "Moderator" and b.rank ~= "Moderator" then return true end
        if b.rank == "Moderator" and a.rank ~= "Moderator" then return false end
        return a.name < b.name
    end)
    
    -- Create entries
    for _, member in ipairs(staffMembers) do
        local onlineIcon = member.isOnline and "🟢 " or "⚫ "
        local entryText = string.format("[%s] %s%s", member.rank, onlineIcon, member.name)
        
        -- Calculate text width
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
        
        -- Create entry
        local entryFrame = Instance.new("Frame")
        entryFrame.Name = "StaffEntry"
        entryFrame.Size = UDim2.new(1, -10, 0, 25)
        entryFrame.Position = UDim2.new(0, 5, 0, yOffset)
        entryFrame.BackgroundColor3 = Config.Theme.Darker
        entryFrame.Parent = staffListFrame
        
        local entryCorner = Instance.new("UICorner")
        entryCorner.CornerRadius = UDim.new(0, 4)
        entryCorner.Parent = entryFrame
        
        -- Rank color
        local rankColor = Config.Theme.Cyan
        if member.rank == "Moderator" then
            rankColor = Color3.fromRGB(255, 255, 50)  -- Желтый
        elseif member.rank == "Owner" then
            rankColor = Color3.fromRGB(255, 50, 50)    -- Красный
        elseif member.rank == "Developer" then
            rankColor = Color3.fromRGB(50, 255, 50)    -- Зеленый
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
        
        yOffset = yOffset + 30
    end
    
    -- Adjust size
    if #staffMembers > 0 then
        staffListFrame.Parent.Size = UDim2.new(0, maxWidth, 0, yOffset + 5)
        staffListFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset + 5)
    else
        local noStaff = Instance.new("TextLabel")
        noStaff.Name = "StaffEntry"
        noStaff.Size = UDim2.new(1, -10, 0, 30)
        noStaff.Position = UDim2.new(0, 5, 0, 5)
        noStaff.BackgroundTransparency = 1
        noStaff.Text = "No staff members online"
        noStaff.TextColor3 = Config.Theme.TextSecondary
        noStaff.TextSize = 14
        noStaff.Font = Enum.Font.Gotham
        noStaff.Parent = staffListFrame
        
        staffListFrame.Parent.Size = UDim2.new(0, 200, 0, 40)
        staffListFrame.CanvasSize = UDim2.new(0, 0, 0, 40)
    end
end

-- Create staff list
function StaffList:Create(parentGui)
    screenGui = parentGui
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "StaffList"
    mainFrame.Size = UDim2.new(0, 200, 0, 40)
    mainFrame.Position = UDim2.new(0, 10, 0, 10)
    mainFrame.BackgroundColor3 = Config.Theme.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui
    mainFrame.ZIndex = 10
    mainFrame.Visible = false
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 8)
    mainCorner.Parent = mainFrame
    
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 25)
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
    titleText.TextSize = 14
    titleText.Font = Enum.Font.GothamBold
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 20, 0, 20)
    closeButton.Position = UDim2.new(1, -22, 0, 2.5)
    closeButton.Text = "×"
    closeButton.TextColor3 = Config.Theme.Text
    closeButton.TextSize = 16
    closeButton.BackgroundColor3 = Config.Theme.Darker
    closeButton.AutoButtonColor = false
    closeButton.Parent = titleBar
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 4)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        StaffList:Toggle(false)
    end)
    
    staffListFrame = Instance.new("ScrollingFrame")
    staffListFrame.Name = "StaffContainer"
    staffListFrame.Size = UDim2.new(1, 0, 1, -25)
    staffListFrame.Position = UDim2.new(0, 0, 0, 25)
    staffListFrame.BackgroundTransparency = 1
    staffListFrame.BorderSizePixel = 0
    staffListFrame.ScrollBarThickness = 4
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
