-- GUI.lua
-- Main GUI interface for BladeSoul
-- Version: 4.0 (Flat Modern redesign)

local GUI = {}
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/Library.lua?nocache=" .. tostring(os.time())))()
local Config = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/Config.lua?nocache=" .. tostring(os.time())))()
local StaffList = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/modules/StaffList.lua?nocache=" .. tostring(os.time())))()
local ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/modules/ESP.lua?nocache=" .. tostring(os.time())))()
local Arrows = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/modules/Arrows.lua?nocache=" .. tostring(os.time())))()

local player = Library.Services.Players.LocalPlayer
local tween = Library.Services.Tween

-- Colors
local C = {
    BG         = Color3.fromRGB(18, 18, 20),
    Surface    = Color3.fromRGB(26, 26, 30),
    Surface2   = Color3.fromRGB(32, 32, 38),
    Accent     = Color3.fromRGB(155, 89, 182),
    AccentDark = Color3.fromRGB(120, 60, 150),
    Text       = Color3.fromRGB(240, 240, 240),
    TextMuted  = Color3.fromRGB(140, 140, 150),
    Border     = Color3.fromRGB(45, 45, 52),
    Success    = Color3.fromRGB(80, 200, 120),
    Danger     = Color3.fromRGB(220, 80, 80),
}

local mainWindow = nil
local minimizedButton = nil
local screenGui = nil
local isMinimized = false

local function makeTween(obj, t, props)
    tween:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play()
end

local function addCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function addStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or C.Border
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

-- Tab page frame
local function makeTabPage(parent)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 1, 0)
    f.BackgroundTransparency = 1
    f.Visible = false
    f.Parent = parent
    return f
end

-- Section label
local function makeLabel(parent, text, posY)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 18)
    l.Position = UDim2.new(0, 0, 0, posY)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = C.TextMuted
    l.TextSize = 11
    l.Font = Enum.Font.GothamBold
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

-- Toggle row
local function makeToggle(parent, text, posY, default, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 38)
    row.Position = UDim2.new(0, 0, 0, posY)
    row.BackgroundColor3 = C.Surface2
    row.BorderSizePixel = 0
    row.Parent = parent
    addCorner(row, 8)
    addStroke(row, C.Border, 1)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = C.Text
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    -- Toggle pill
    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0, 36, 0, 18)
    pill.Position = UDim2.new(1, -48, 0.5, -9)
    pill.BackgroundColor3 = default and C.Accent or C.Border
    pill.Parent = row
    addCorner(pill, 9)

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 12, 0, 12)
    dot.Position = default and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
    dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    dot.Parent = pill
    addCorner(dot, 6)

    local toggled = default or false

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = row

    btn.MouseButton1Click:Connect(function()
        toggled = not toggled
        makeTween(pill, 0.2, {BackgroundColor3 = toggled and C.Accent or C.Border})
        makeTween(dot, 0.2, {Position = toggled and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)})
        if callback then callback(toggled) end
    end)

    return row
end

function GUI:Create()
    if not player then return end

    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BladeSoulGUI"
    screenGui.Parent = player:WaitForChild("PlayerGui")
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- ===== MINIMIZED BUTTON =====
    minimizedButton = Instance.new("TextButton")
    minimizedButton.Size = UDim2.new(0, 40, 0, 40)
    minimizedButton.Position = UDim2.new(0, 20, 0, 20)
    minimizedButton.BackgroundColor3 = C.Accent
    minimizedButton.Text = "BS"
    minimizedButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    minimizedButton.TextSize = 13
    minimizedButton.Font = Enum.Font.GothamBold
    minimizedButton.Visible = false
    minimizedButton.Active = true
    minimizedButton.Draggable = true
    minimizedButton.Parent = screenGui
    addCorner(minimizedButton, 10)

    minimizedButton.MouseButton1Click:Connect(function()
        isMinimized = false
        minimizedButton.Visible = false
        mainWindow.Visible = true
    end)

    -- ===== MAIN WINDOW =====
    mainWindow = Instance.new("Frame")
    mainWindow.Name = "BladeSoulWindow"
    mainWindow.Size = UDim2.new(0, 540, 0, 420)
    mainWindow.Position = UDim2.new(0.5, -270, 0.5, -210)
    mainWindow.BackgroundColor3 = C.BG
    mainWindow.BorderSizePixel = 0
    mainWindow.Active = true
    mainWindow.Draggable = true
    mainWindow.Parent = screenGui
    addCorner(mainWindow, 12)
    addStroke(mainWindow, C.Border, 1)

    -- ===== TITLE BAR =====
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 48)
    titleBar.BackgroundColor3 = C.Surface
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainWindow
    addCorner(titleBar, 12)

    -- Bottom fill to hide bottom corners of titlebar
    local titleFill = Instance.new("Frame")
    titleFill.Size = UDim2.new(1, 0, 0, 12)
    titleFill.Position = UDim2.new(0, 0, 1, -12)
    titleFill.BackgroundColor3 = C.Surface
    titleFill.BorderSizePixel = 0
    titleFill.Parent = titleBar

    -- Accent dot
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 8, 0, 8)
    dot.Position = UDim2.new(0, 16, 0.5, -4)
    dot.BackgroundColor3 = C.Accent
    dot.Parent = titleBar
    addCorner(dot, 4)

    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(0, 200, 1, 0)
    titleText.Position = UDim2.new(0, 30, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "BladeSoul"
    titleText.TextColor3 = C.Text
    titleText.TextSize = 15
    titleText.Font = Enum.Font.GothamBold
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar

    local versionLabel = Instance.new("TextLabel")
    versionLabel.Size = UDim2.new(0, 60, 1, 0)
    versionLabel.Position = UDim2.new(0, 110, 0, 0)
    versionLabel.BackgroundTransparency = 1
    versionLabel.Text = "v" .. Config.GUI.Version
    versionLabel.TextColor3 = C.TextMuted
    versionLabel.TextSize = 11
    versionLabel.Font = Enum.Font.Gotham
    versionLabel.TextXAlignment = Enum.TextXAlignment.Left
    versionLabel.Parent = titleBar

    -- Minimize button
    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 28, 0, 28)
    minBtn.Position = UDim2.new(1, -66, 0.5, -14)
    minBtn.BackgroundColor3 = C.Surface2
    minBtn.Text = "–"
    minBtn.TextColor3 = C.TextMuted
    minBtn.TextSize = 16
    minBtn.Font = Enum.Font.GothamBold
    minBtn.AutoButtonColor = false
    minBtn.Parent = titleBar
    addCorner(minBtn, 6)

    minBtn.MouseEnter:Connect(function() makeTween(minBtn, 0.15, {BackgroundColor3 = C.Border}) end)
    minBtn.MouseLeave:Connect(function() makeTween(minBtn, 0.15, {BackgroundColor3 = C.Surface2}) end)
    minBtn.MouseButton1Click:Connect(function()
        isMinimized = true
        mainWindow.Visible = false
        minimizedButton.Visible = true
    end)

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -34, 0.5, -14)
    closeBtn.BackgroundColor3 = C.Surface2
    closeBtn.Text = "×"
    closeBtn.TextColor3 = C.TextMuted
    closeBtn.TextSize = 18
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.AutoButtonColor = false
    closeBtn.Parent = titleBar
    addCorner(closeBtn, 6)

    closeBtn.MouseEnter:Connect(function() makeTween(closeBtn, 0.15, {BackgroundColor3 = C.Danger}) end)
    closeBtn.MouseLeave:Connect(function() makeTween(closeBtn, 0.15, {BackgroundColor3 = C.Surface2}) end)
    closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)

    -- ===== SIDEBAR TABS =====
    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0, 120, 1, -48)
    sidebar.Position = UDim2.new(0, 0, 0, 48)
    sidebar.BackgroundColor3 = C.Surface
    sidebar.BorderSizePixel = 0
    sidebar.Parent = mainWindow

    local sidebarFill = Instance.new("Frame")
    sidebarFill.Size = UDim2.new(0, 12, 1, 0)
    sidebarFill.Position = UDim2.new(1, -12, 0, 0)
    sidebarFill.BackgroundColor3 = C.Surface
    sidebarFill.BorderSizePixel = 0
    sidebarFill.Parent = sidebar

    -- Bottom corners fix for sidebar
    local sidebarCorner = Instance.new("UICorner")
    sidebarCorner.CornerRadius = UDim.new(0, 12)
    sidebarCorner.Parent = sidebar

    -- Player info at bottom of sidebar
    local playerInfo = Instance.new("TextLabel")
    playerInfo.Size = UDim2.new(1, -16, 0, 30)
    playerInfo.Position = UDim2.new(0, 8, 1, -38)
    playerInfo.BackgroundTransparency = 1
    playerInfo.Text = player.Name
    playerInfo.TextColor3 = C.TextMuted
    playerInfo.TextSize = 11
    playerInfo.Font = Enum.Font.Gotham
    playerInfo.TextXAlignment = Enum.TextXAlignment.Left
    playerInfo.TextTruncate = Enum.TextTruncate.AtEnd
    playerInfo.Parent = sidebar

    -- ===== CONTENT AREA =====
    local contentArea = Instance.new("Frame")
    contentArea.Size = UDim2.new(1, -128, 1, -56)
    contentArea.Position = UDim2.new(0, 128, 0, 56)
    contentArea.BackgroundTransparency = 1
    contentArea.Parent = mainWindow

    -- ===== TABS =====
    local tabDefs = {
        {name = "MAIN",     icon = "⌂"},
        {name = "VISUALS",  icon = "◈"},
        {name = "MISC",     icon = "⚙"},
    }

    local pages = {}
    local tabBtns = {}
    local currentTab = nil

    for i, def in ipairs(tabDefs) do
        -- Tab button
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -16, 0, 34)
        btn.Position = UDim2.new(0, 8, 0, 12 + (i-1) * 40)
        btn.BackgroundColor3 = C.Surface
        btn.BackgroundTransparency = 1
        btn.Text = def.icon .. "  " .. def.name
        btn.TextColor3 = C.TextMuted
        btn.TextSize = 12
        btn.Font = Enum.Font.GothamBold
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.AutoButtonColor = false
        btn.Parent = sidebar
        addCorner(btn, 7)

        -- Left accent bar
        local accent = Instance.new("Frame")
        accent.Size = UDim2.new(0, 3, 0, 16)
        accent.Position = UDim2.new(0, 0, 0.5, -8)
        accent.BackgroundColor3 = C.Accent
        accent.Visible = false
        accent.Parent = btn
        addCorner(accent, 2)

        tabBtns[def.name] = {btn = btn, accent = accent}

        -- Page
        local page = makeTabPage(contentArea)
        pages[def.name] = page

        btn.MouseButton1Click:Connect(function()
            if currentTab == def.name then return end
            -- Deactivate old
            if currentTab then
                local old = tabBtns[currentTab]
                makeTween(old.btn, 0.15, {BackgroundTransparency = 1, TextColor3 = C.TextMuted})
                old.accent.Visible = false
                pages[currentTab].Visible = false
            end
            -- Activate new
            currentTab = def.name
            makeTween(btn, 0.15, {BackgroundTransparency = 0, TextColor3 = C.Text})
            accent.Visible = true
            page.Visible = true
        end)
    end

    -- ===== MAIN PAGE =====
    local mainPage = pages["MAIN"]

    local welcomeLabel = Instance.new("TextLabel")
    welcomeLabel.Size = UDim2.new(1, -16, 0, 28)
    welcomeLabel.Position = UDim2.new(0, 8, 0, 8)
    welcomeLabel.BackgroundTransparency = 1
    welcomeLabel.Text = "Welcome, " .. player.Name
    welcomeLabel.TextColor3 = C.Text
    welcomeLabel.TextSize = 18
    welcomeLabel.Font = Enum.Font.GothamBold
    welcomeLabel.TextXAlignment = Enum.TextXAlignment.Left
    welcomeLabel.Parent = mainPage

    local statusRow = Instance.new("Frame")
    statusRow.Size = UDim2.new(1, -16, 0, 32)
    statusRow.Position = UDim2.new(0, 8, 0, 44)
    statusRow.BackgroundColor3 = C.Surface2
    statusRow.Parent = mainPage
    addCorner(statusRow, 8)

    local statusDot = Instance.new("Frame")
    statusDot.Size = UDim2.new(0, 7, 0, 7)
    statusDot.Position = UDim2.new(0, 12, 0.5, -3)
    statusDot.BackgroundColor3 = C.Success
    statusDot.Parent = statusRow
    addCorner(statusDot, 4)

    local statusText = Instance.new("TextLabel")
    statusText.Size = UDim2.new(1, -30, 1, 0)
    statusText.Position = UDim2.new(0, 26, 0, 0)
    statusText.BackgroundTransparency = 1
    statusText.Text = "System online"
    statusText.TextColor3 = C.TextMuted
    statusText.TextSize = 12
    statusText.Font = Enum.Font.Gotham
    statusText.TextXAlignment = Enum.TextXAlignment.Left
    statusText.Parent = statusRow

    -- ===== VISUALS PAGE =====
    local visualsPage = pages["VISUALS"]

    makeLabel(visualsPage, "PLAYER VISIBILITY", 8)
    makeToggle(visualsPage, "Player ESP", 28, false, function(state)
        ESP:Toggle(state)
    end)
    makeToggle(visualsPage, "Direction Arrows", 74, false, function(state)
        Arrows:Toggle(state)
    end)

    -- ===== MISC PAGE =====
    local miscPage = pages["MISC"]

    makeLabel(miscPage, "UTILITIES", 8)
    makeToggle(miscPage, "Staff List", 28, false, function(state)
        StaffList:Toggle(state)
    end)

    -- Activate first tab
    do
        local first = tabDefs[1]
        currentTab = first.name
        local tb = tabBtns[first.name]
        tb.btn.BackgroundTransparency = 0
        tb.btn.TextColor3 = C.Text
        tb.accent.Visible = true
        pages[first.name].Visible = true
    end

    -- Open animation
    mainWindow.Size = UDim2.new(0, 0, 0, 0)
    mainWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
    makeTween(mainWindow, 0.4, {
        Size = UDim2.new(0, 540, 0, 420),
        Position = UDim2.new(0.5, -270, 0.5, -210)
    })
end

return GUI
