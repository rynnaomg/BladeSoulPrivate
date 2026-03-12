-- modules/StaffList.lua
-- Staff List module for Forsaken Hub
-- Version: 6.0 (Smart size, no flickering)

local StaffList = {}
local Config = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/Config.lua"))()
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/Library.lua"))()

local players = Library.Services.Players
local tween = Library.Services.Tween

-- Safe GroupService initialization
local GroupService
local success, result = pcall(function()
    return game:GetService("GroupService")
end)
if success then
    GroupService = result
else
    GroupService = game:GetService("Groups")
end

local screenGui = nil
local mainFrame = nil
local staffContainer = nil
local enabled = false

-- Cache for staff data to prevent flickering
local staffCache = {}
local lastUpdate = 0

-- ===== YOUR GROUP RANK NUMBERS =====
local STAFF_RANKS = {
    [225] = "Moderator",  -- Your rank
    -- Add others when you find them:
    -- [???] = "Testers",
    -- [???] = "Developer",
    -- [255] = "Owner",
}

-- Debug function (remove in production)
local function debugPrint(...)
    -- print("[StaffList Debug]", ...)  -- Commented out to reduce spam
end

-- Check if player is staff
local function checkStaff(userId)
    if not GroupService then
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
            local rankName = STAFF_RANKS[rankNumber]
            if rankName then
                return true, rankName
            else
                return true, "Rank " .. rankNumber
            end
        end
    end
    
    return false, nil
end

-- Update staff list without flickering
local function updateStaffList()
    if not staffContainer or not enabled or not mainFrame then return end
    
    -- Get current staff
    local newStaff = {}
    for _, plr in pairs(players:GetPlayers()) do
        if plr ~= players.LocalPlayer then
            local isStaff, rankName = checkStaff(plr.UserId)
            if isStaff then
                table.insert(newStaff, {
                    name = plr.Name,
                    rank = rankName,
                    userId = plr.UserId,
                    isOnline = true
                })
            end
        end
    end
    
    -- Sort staff
    table.sort(newStaff, function(a, b)
        if a.rank == "Moderator" and b.rank ~= "Moderator" then return true end
        if b.rank == "Moderator" and a.rank ~= "Moderator" then return false end
        return a.name < b.name
    end)
    
    -- Check if data actually changed (prevent flickering)
    local changed = false
    if #staffCache ~= #newStaff then
        changed = true
    else
        for i = 1, #staffCache do
            if staffCache[i].userId ~= newStaff[i].userId or staffCache[i].rank ~= newStaff[i].rank then
                changed = true
                break
            end
        end
    end
    
    -- Only update if something changed
    if not changed then return end
    
    -- Update cache
    staffCache = newStaff
    
    -- Clear container
    for _, v in pairs(staffContainer:GetChildren()) do
        if v:IsA("Frame") then
            v:Destroy()
        end
    end
    
    -- Calculate size based on staff count
    local staffCount = #newStaff
    local baseHeight = 35  -- Title bar height
    local entryHeight = 28  -- Each entry height
    local spacing = 5       -- Spacing between entries
    
    -- Smart height calculation
    local contentHeight
    if staffCount == 0 then
        contentHeight = 60  -- "No staff" message height
    elseif staffCount <= 4 then
        -- For 1-4 staff, size exactly to fit
        contentHeight = (staffCount * entryHeight) + (spacing * (staffCount + 1)) + 10
    else
        -- For 5+ staff, cap at 4 visible + scroll
        contentHeight = (4 * entryHeight) + (spacing * 5) + 10
    end
    
    -- Update main frame size smoothly
    tween:Create(mainFrame, TweenInfo.new(0.2), {
        Size = UDim2.new(0, 240, 0, baseHeight + contentHeight)
    }):Play()
    
    -- Update canvas size for scrolling
    if staffCount > 4 then
        local totalContentHeight = (staffCount * entryHeight) + (spacing * (staffCount + 1)) + 10
        staffContainer.CanvasSize = UDim2.new(0, 0, 0, totalContentHeight)
    else
        staffContainer.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
    end
    
    -- Create entries
    local yOffset = 5
    
    if staffCount == 0 then
        -- No staff message
        local noStaff = Instance.new("TextLabel")
        noStaff.Size = UDim2.new(1, -10, 0, 40)
        noStaff.Position = UDim2.new(0, 5, 0, 10)
        noStaff.BackgroundTransparency = 1
        noStaff.Text = "No staff members online"
        noStaff.TextColor3 = Config.Theme.TextSecondary
        noStaff.TextSize = 14
        noStaff.Font = Enum.Font.Gotham
        noStaff.Parent = staffContainer
    else
        -- Create staff entries
        for _, staff in ipairs(newStaff) do
            local entryText = string.format("[%s] 🟢 %s", staff.rank, staff.name)
            
            -- Create entry frame
            local entryFrame = Instance.new("Frame")
            entryFrame.Name = "StaffEntry"
            entryFrame.Size = UDim2.new(1, -10, 0, entryHeight - 3)
            entryFrame.Position = UDim2.new(0, 5, 0, yOffset)
            entryFrame.BackgroundColor3 = Config.Theme.Darker
            entryFrame.Parent = staffContainer
            
            local entryCorner = Instance.new("UICorner")
            entryCorner.CornerRadius = UDim.new(0, 4)
            entryCorner.Parent = entryFrame
            
            -- Rank color
            local rankColor = Config.Theme.Cyan
            if staff.rank == "Moderator" then
                rankColor = Color3.fromRGB(255, 255, 50)  -- Yellow
            elseif staff.rank == "Owner" then
                rankColor = Color3.fromRGB(255, 50, 50)    -- Red
            elseif staff.rank == "Developer" then
                rankColor = Color3.fromRGB(50, 255, 50)    -- Green
            elseif staff.rank == "Testers" then
                rankColor = Color3.fromRGB(50, 150, 255)   -- Blue
            elseif staff.rank:find("Rank") then
                rankColor = Color3.fromRGB(150, 150, 150)  -- Gray for unknown
            end
            
            -- Color bar
            local colorBar = Instance.new("Frame")
            colorBar.Size = UDim2.new(0, 3, 1, -4)
            colorBar.Position = UDim2.new(0, 2, 0, 2)
            colorBar.BackgroundColor3 = rankColor
            colorBar.BorderSizePixel = 0
            colorBar.Parent = entryFrame
            
            local barCorner = Instance.new("UICorner")
            barCorner.CornerRadius = UDim.new(0, 2)
            barCorner.Parent = colorBar
            
            -- Staff name label
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
            
            yOffset = yOffset + entryHeight + spacing
        end
    end
end

-- Create staff list GUI
function StaffList:Create(parentGui)
    screenGui = parentGui
    
    -- Main frame
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "StaffList"
    mainFrame.Size = UDim2.new(0, 240, 0, 35)  -- Start with just title bar
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
    
    -- Title bar
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
    
    -- Close button
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
    
    -- Container for staff entries (ScrollingFrame)
    staffContainer = Instance.new("ScrollingFrame")
    staffContainer.Name = "StaffContainer"
    staffContainer.Size = UDim2.new(1, 0, 1, -35)
    staffContainer.Position = UDim2.new(0, 0, 0, 35)
    staffContainer.BackgroundTransparency = 1
    staffContainer.BorderSizePixel = 0
    staffContainer.ScrollBarThickness = 6
    staffContainer.ScrollBarImageColor3 = Config.Theme.Cyan
    staffContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    staffContainer.Parent = mainFrame
    staffContainer.AutomaticCanvasSize = Enum.AutomaticSize.None
    
    return mainFrame
end

-- Toggle staff list visibility
function StaffList:Toggle(state)
    enabled = state
    
    if not mainFrame or not staffContainer then return end
    
    mainFrame.Visible = state
    
    if state then
        -- Clear cache to force update
        staffCache = {}
        
        -- Initial update
        updateStaffList()
        
        -- Connect events
        players.PlayerAdded:Connect(function()
            task.wait(0.5)
            updateStaffList()
        end)
        
        players.PlayerRemoving:Connect(function()
            updateStaffList()
        end)
        
        -- Periodic updates (less frequent to reduce flicker)
        spawn(function()
            while enabled do
                task.wait(3)  -- Update every 3 seconds instead of 5
                updateStaffList()
            end
        end)
    end
end

return StaffList
