-- modules/StaffList.lua
-- Staff List module for Forsaken Hub
-- Version: 3.0 (AUTO-DETECT RANKS)

local StaffList = {}
local Config = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/Config.lua"))()
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/Library.lua"))()

local players = Library.Services.Players
local tween = Library.Services.Tween
local screenGui = nil
local staffListFrame = nil
local enabled = false
local updateConnection = nil

-- Debug function
local function debugPrint(...)
    print("[StaffList Debug]", ...)
end

-- We'll auto-detect ranks! This will be filled dynamically
local STAFF_RANKS = {}  -- Empty for now, will be filled

-- Function to learn ranks
local function learnRanks()
    debugPrint("=== LEARNING RANKS ===")
    local foundRanks = {}
    
    -- Check all players
    for _, plr in pairs(players:GetPlayers()) do
        local rankNum = plr:GetRankInGroup(Config.StaffGroup.GroupID)
        if rankNum and rankNum > 0 then
            -- Try to get rank name (if possible)
            local rankName = "Unknown"
            local success, name = pcall(function()
                return plr:GetRoleInGroup(Config.StaffGroup.GroupID)
            end)
            if success and name and name ~= "Guest" then
                rankName = name
            end
            
            debugPrint("Found:", plr.Name, "-> Rank", rankNum, "(" .. rankName .. ")")
            foundRanks[rankNum] = rankName
        end
    end
    
    -- Match with our target ranks from config
    -- We'll try to map them based on common patterns
    local targetRanks = {"Testers", "Moderator", "Developer", "Owner"}
    
    -- Sort found ranks by number (lower numbers first)
    local sorted = {}
    for num, name in pairs(foundRanks) do
        table.insert(sorted, {num = num, name = name})
    end
    table.sort(sorted, function(a, b) return a.num < b.num end)
    
    -- Try to assign them in order
    for i, targetRank in ipairs(targetRanks) do
        if sorted[i] then
            STAFF_RANKS[sorted[i].num] = targetRank
            debugPrint("✅ Mapped rank", sorted[i].num, "->", targetRank)
        else
            debugPrint("⚠️ Could not find rank for", targetRank)
        end
    end
    
    debugPrint("=== LEARNING COMPLETE ===")
end

-- Function to check if player is staff
local function isStaff(targetPlayer)
    if not targetPlayer then return false, nil end
    
    local success, rankNumber = pcall(function()
        return targetPlayer:GetRankInGroup(Config.StaffGroup.GroupID)
    end)
    
    debugPrint("Player", targetPlayer.Name, "Rank number:", rankNumber or "nil")
    
    if success and rankNumber and rankNumber > 0 then
        -- Check if this rank number is in our staff list
        local rankName = STAFF_RANKS[rankNumber]
        if rankName then
            debugPrint("✅ Staff found:", rankName, "(rank", rankNumber, ")")
            return true, rankName
        else
            debugPrint("❌ Rank", rankNumber, "not in staff list (needs mapping)")
        end
    end
    
    return false, nil
end

-- Function to update staff list
local function updateStaffList()
    if not staffListFrame or not enabled then return end
    
    -- Learn ranks if we haven't yet
    if not next(STAFF_RANKS) then
        learnRanks()
    end
    
    -- Clear old entries
    for _, v in pairs(staffListFrame:GetChildren()) do
        if v:IsA("Frame") and v.Name == "StaffEntry" then
            v:Destroy()
        end
    end
    
    local yOffset = 5
    local maxWidth = 180
    local entries = {}
    
    -- Check all players
    for _, plr in pairs(players:GetPlayers()) do
        if plr ~= players.LocalPlayer then
            local isStaffMember, rankName = isStaff(plr)
            if isStaffMember then
                table.insert(entries, {player = plr, rank = rankName})
            end
        end
    end
    
    -- Sort entries by rank priority
    table.sort(entries, function(a, b)
        local rankPriority = {
            ["Owner"] = 1,
            ["Developer"] = 2,
            ["Moderator"] = 3,
            ["Testers"] = 4
        }
        return (rankPriority[a.rank] or 5) < (rankPriority[b.rank] or 5)
    end)
    
    -- Create entries
    for _, entry in ipairs(entries) do
        local plr = entry.player
        local rank = entry.rank
        local entryText = string.format("[%s] %s", rank, plr.Name)
        
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
        
        -- Rank color indicator
        local rankColor = Config.Theme.Cyan
        if rank == "Owner" then
            rankColor = Color3.fromRGB(255, 50, 50)
        elseif rank == "Developer" then
            rankColor = Color3.fromRGB(50, 255, 50)
        elseif rank == "Moderator" then
            rankColor = Color3.fromRGB(255, 255, 50)
        elseif rank == "Testers" then
            rankColor = Color3.fromRGB(50, 150, 255)
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
    
    -- Adjust staff list size
    if #entries > 0 then
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

-- Function to create staff list
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
        -- Learn ranks first
        learnRanks()
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
