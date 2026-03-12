-- GUI.lua
-- Main GUI interface for Forsaken Hub
-- Version: 2.0 (New modern design)

local GUI = {}
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/Library.lua"))()
local Config = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/Config.lua"))()
local StaffList = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/modules/StaffList.lua"))()
local ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/modules/ESP.lua"))()

local player = Library.Services.Players.LocalPlayer
local tween = Library.Services.Tween

-- Variables for minimize system
local mainWindow = nil
local minimizedButton = nil
local screenGui = nil
local isMinimized = false

-- Function to create a modern section container
local function createModernSection(parent, title, position)
    -- Main container with darker background
    local container = Instance.new("Frame")
    container.Name = title .. "Section"
    container.Size = UDim2.new(0, 230, 0, 80)
    container.Position = position
    container.BackgroundColor3 = Color3.fromRGB(25, 25, 25)  -- Even darker than main
    container.BorderSizePixel = 0
    container.Parent = parent
    
    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 8)
    containerCorner.Parent = container
    
    -- Inner glow (cyan border)
    local innerGlow = Instance.new("Frame")
    innerGlow.Size = UDim2.new(1, -2, 1, -2)
    innerGlow.Position = UDim2.new(0, 1, 0, 1)
    innerGlow.BackgroundTransparency = 1
    innerGlow.BorderSizePixel = 0
    innerGlow.Parent = container
    
    local glowCorner = Instance.new("UICorner")
    glowCorner.CornerRadius = UDim.new(0, 7)
    glowCorner.Parent = innerGlow
    
    -- Title with cyan accent
    local titleFrame = Instance.new("Frame")
    titleFrame.Size = UDim2.new(1, -20, 0, 25)
    titleFrame.Position = UDim2.new(0, 10, 0, 5)
    titleFrame.BackgroundTransparency = 1
    titleFrame.Parent = container
    
    local titleDot = Instance.new("Frame")
    titleDot.Size = UDim2.new(0, 4, 0, 4)
    titleDot.Position = UDim2.new(0, 0, 0.5, -2)
    titleDot.BackgroundColor3 = Config.Theme.Cyan
    titleDot.BorderSizePixel = 0
    titleDot.Parent = titleFrame
    
    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = titleDot
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -15, 1, 0)
    titleLabel.Position = UDim2.new(0, 15, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Config.Theme.Cyan
    titleLabel.TextSize = 14
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleFrame
    
    -- Separator line
    local separator = Instance.new("Frame")
    separator.Size = UDim2.new(1, -20, 0, 1)
    separator.Position = UDim2.new(0, 10, 0, 32)
    separator.BackgroundColor3 = Config.Theme.Cyan
    separator.BackgroundTransparency = 0.7
    separator.BorderSizePixel = 0
    separator.Parent = container
    
    return container
end

-- Create modern toggle
local function createModernToggle(container, text, posY, default, callback)
    local toggleContainer = Instance.new("Frame")
    toggleContainer.Size = UDim2.new(1, -20, 0, 30)
    toggleContainer.Position = UDim2.new(0, 10, 0, posY)
    toggleContainer.BackgroundTransparency = 1
    toggleContainer.Parent = container
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 150, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Config.Theme.Text
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = toggleContainer
    
    -- Modern toggle switch
    local toggleBg = Instance.new("Frame")
    toggleBg.Size = UDim2.new(0, 44, 0, 20)
    toggleBg.Position = UDim2.new(1, -54, 0.5, -10)
    toggleBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    toggleBg.Parent = toggleContainer
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = toggleBg
    
    -- Glow effect
    local toggleGlow = Instance.new("ImageLabel")
    toggleGlow.Size = UDim2.new(1, 10, 1, 10)
    toggleGlow.Position = UDim2.new(0.5, -5, 0.5, -5)
    toggleGlow.BackgroundTransparency = 1
    toggleGlow.Image = "rbxassetid://3570695787"
    toggleGlow.ImageColor3 = Config.Theme.Cyan
    toggleGlow.ImageTransparency = 0.8
    toggleGlow.Parent = toggleBg
    
    local toggleCircle = Instance.new("Frame")
    toggleCircle.Size = UDim2.new(0, 16, 0, 16)
    toggleCircle.Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    toggleCircle.BackgroundColor3 = default and Config.Theme.Cyan or Color3.fromRGB(150, 150, 150)
    toggleCircle.Parent = toggleBg
    
    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = toggleCircle
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Parent = toggleContainer
    
    local toggled = default
    
    button.MouseButton1Click:Connect(function()
        toggled = not toggled
        local goalPos = toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        local goalColor = toggled and Config.Theme.Cyan or Color3.fromRGB(150, 150, 150)
        
        tween:Create(toggleCircle, TweenInfo.new(0.2), {Position = goalPos, BackgroundColor3 = goalColor}):Play()
        callback(toggled)
    end)
end

function GUI:Create()
    if not player then return end
    
    -- Main ScreenGui
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ForsakenHub"
    screenGui.Parent = player:WaitForChild("PlayerGui")
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Create modules
    local staffListModule = StaffList:Create(screenGui)
    -- ESP module will be created when toggled
    
    -- ===== MINIMIZED BUTTON =====
    minimizedButton = Instance.new("ImageButton")
    minimizedButton.Name = "MinimizedButton"
    minimizedButton.Size = UDim2.new(0, 50, 0, 50)
    minimizedButton.Position = UDim2.new(0, 20, 0, 100)
    minimizedButton.BackgroundColor3 = Config.Theme.Cyan
    minimizedButton.Image = "rbxassetid://3570695787"
    minimizedButton.ImageColor3 = Config.Theme.Cyan
    minimizedButton.ScaleType = Enum.ScaleType.Fit
    minimizedButton.BackgroundTransparency = 0.2
    minimizedButton.Visible = false
    minimizedButton.Parent = screenGui
    minimizedButton.Active = true
    minimizedButton.Draggable = true
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(1, 0)
    buttonCorner.Parent = minimizedButton
    
    local buttonText = Instance.new("TextLabel")
    buttonText.Size = UDim2.new(1, 0, 1, 0)
    buttonText.BackgroundTransparency = 1
    buttonText.Text = "FH"
    buttonText.TextColor3 = Config.Theme.Background
    buttonText.TextSize = 18
    buttonText.Font = Enum.Font.GothamBold
    buttonText.Parent = minimizedButton
    
    minimizedButton.MouseButton1Click:Connect(function()
        isMinimized = false
        minimizedButton.Visible = false
        mainWindow.Visible = true
    end)
    
    -- ===== MAIN WINDOW =====
    mainWindow = Instance.new("Frame")
    mainWindow.Name = "MainWindow"
    mainWindow.Size = UDim2.new(0, 550, 0, 450)
    mainWindow.Position = UDim2.new(0.5, -275, 0.5, -225)
    mainWindow.BackgroundColor3 = Config.Theme.Background
    mainWindow.BorderSizePixel = 0
    mainWindow.Active = true
    mainWindow.Draggable = true
    mainWindow.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainWindow
    
    -- Cyan glow effect
    local glow = Instance.new("ImageLabel")
    glow.Size = UDim2.new(1, 20, 1, 20)
    glow.Position = UDim2.new(0.5, -10, 0.5, -10)
    glow.BackgroundTransparency = 1
    glow.Image = "rbxassetid://3570695787"
    glow.ImageColor3 = Config.Theme.Cyan
    glow.ImageTransparency = 0.8
    glow.Parent = mainWindow
    
    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 45)
    titleBar.BackgroundColor3 = Config.Theme.Darker
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainWindow
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar
    
    -- Gradient effect
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Config.Theme.Darker),
        ColorSequenceKeypoint.new(1, Config.Theme.Background)
    })
    gradient.Rotation = 90
    gradient.Parent = titleBar
    
    -- Title with icon
    local titleIcon = Instance.new("Frame")
    titleIcon.Size = UDim2.new(0, 8, 0, 8)
    titleIcon.Position = UDim2.new(0, 15, 0.5, -4)
    titleIcon.BackgroundColor3 = Config.Theme.Cyan
    titleIcon.BorderSizePixel = 0
    titleIcon.Parent = titleBar
    
    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(1, 0)
    iconCorner.Parent = titleIcon
    
    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(1, -100, 1, 0)
    titleText.Position = UDim2.new(0, 30, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = Config.GUI.Title .. " v" .. Config.GUI.Version
    titleText.TextColor3 = Config.Theme.Text
    titleText.TextSize = 20
    titleText.Font = Enum.Font.GothamBold
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    
    -- Minimize button
    local minimizeButton = Instance.new("TextButton")
    minimizeButton.Name = "MinimizeButton"
    minimizeButton.Size = UDim2.new(0, 32, 0, 32)
    minimizeButton.Position = UDim2.new(1, -74, 0.5, -16)
    minimizeButton.Text = "–"
    minimizeButton.TextColor3 = Config.Theme.Text
    minimizeButton.TextSize = 24
    minimizeButton.BackgroundColor3 = Config.Theme.Darker
    minimizeButton.AutoButtonColor = false
    minimizeButton.Parent = titleBar
    
    local minCorner = Instance.new("UICorner")
    minCorner.CornerRadius = UDim.new(0, 6)
    minCorner.Parent = minimizeButton
    
    minimizeButton.MouseEnter:Connect(function()
        tween:Create(minimizeButton, TweenInfo.new(0.2), {BackgroundColor3 = Config.Theme.Cyan}):Play()
    end)
    
    minimizeButton.MouseLeave:Connect(function()
        tween:Create(minimizeButton, TweenInfo.new(0.2), {BackgroundColor3 = Config.Theme.Darker}):Play()
    end)
    
    minimizeButton.MouseButton1Click:Connect(function()
        isMinimized = true
        mainWindow.Visible = false
        minimizedButton.Visible = true
    end)
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 32, 0, 32)
    closeButton.Position = UDim2.new(1, -37, 0.5, -16)
    closeButton.Text = "×"
    closeButton.TextColor3 = Config.Theme.Text
    closeButton.TextSize = 24
    closeButton.BackgroundColor3 = Config.Theme.Darker
    closeButton.AutoButtonColor = false
    closeButton.Parent = titleBar
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeButton
    
    closeButton.MouseEnter:Connect(function()
        tween:Create(closeButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 50, 50)}):Play()
    end)
    
    closeButton.MouseLeave:Connect(function()
        tween:Create(closeButton, TweenInfo.new(0.2), {BackgroundColor3 = Config.Theme.Darker}):Play()
    end)
    
    closeButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
    
    -- Tab container
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Size = UDim2.new(1, -30, 0, 45)
    tabContainer.Position = UDim2.new(0, 15, 0, 55)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = mainWindow
    
    -- Modern tab buttons
    local tabs = {"MAIN", "VISUALS", "MISC", "SETTINGS"}
    local tabButtons = {}
    local tabWidth = 100
    
    for i, tabName in ipairs(tabs) do
        local tabButton = Instance.new("TextButton")
        tabButton.Name = tabName .. "Tab"
        tabButton.Size = UDim2.new(0, tabWidth, 0, 35)
        tabButton.Position = UDim2.new(0, (i-1) * (tabWidth + 5), 0, 5)
        tabButton.Text = tabName
        tabButton.TextColor3 = i == 1 and Config.Theme.Cyan or Config.Theme.TextSecondary
        tabButton.TextSize = 14
        tabButton.Font = Enum.Font.GothamBold
        tabButton.BackgroundTransparency = 1
        tabButton.Parent = tabContainer
        
        local underline = Instance.new("Frame")
        underline.Name = "Underline"
        underline.Size = UDim2.new(0, 60, 0, 2)
        underline.Position = UDim2.new(0.5, -30, 1, -2)
        underline.BackgroundColor3 = Config.Theme.Cyan
        underline.BackgroundTransparency = i == 1 and 0 or 1
        underline.BorderSizePixel = 0
        underline.Parent = tabButton
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 2)
        corner.Parent = underline
        
        tabButtons[tabName] = {button = tabButton, underline = underline}
    end
    
    -- Content container
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Size = UDim2.new(1, -30, 1, -120)
    contentContainer.Position = UDim2.new(0, 15, 0, 105)
    contentContainer.BackgroundTransparency = 1
    contentContainer.Parent = mainWindow
    
    -- Create tab contents
    local mainContent = Instance.new("Frame")
    mainContent.Name = "MainContent"
    mainContent.Size = UDim2.new(1, 0, 1, 0)
    mainContent.BackgroundTransparency = 1
    mainContent.Parent = contentContainer
    mainContent.Visible = true
    
    local visualsContent = Instance.new("Frame")
    visualsContent.Name = "VisualsContent"
    visualsContent.Size = UDim2.new(1, 0, 1, 0)
    visualsContent.BackgroundTransparency = 1
    visualsContent.Parent = contentContainer
    visualsContent.Visible = false
    
    local miscContent = Instance.new("Frame")
    miscContent.Name = "MiscContent"
    miscContent.Size = UDim2.new(1, 0, 1, 0)
    miscContent.BackgroundTransparency = 1
    miscContent.Parent = contentContainer
    miscContent.Visible = false
    
    local settingsContent = Instance.new("Frame")
    settingsContent.Name = "SettingsContent"
    settingsContent.Size = UDim2.new(1, 0, 1, 0)
    settingsContent.BackgroundTransparency = 1
    settingsContent.Parent = contentContainer
    settingsContent.Visible = false
    
    -- ===== MAIN TAB =====
    local mainWelcome = Instance.new("TextLabel")
    mainWelcome.Size = UDim2.new(1, 0, 0, 40)
    mainWelcome.Position = UDim2.new(0, 10, 0, 10)
    mainWelcome.BackgroundTransparency = 1
    mainWelcome.Text = "Welcome back, " .. player.Name
    mainWelcome.TextColor3 = Config.Theme.Text
    mainWelcome.TextSize = 22
    mainWelcome.Font = Enum.Font.GothamBold
    mainWelcome.TextXAlignment = Enum.TextXAlignment.Left
    mainWelcome.Parent = mainContent
    
    local mainStatus = Instance.new("TextLabel")
    mainStatus.Size = UDim2.new(1, 0, 0, 25)
    mainStatus.Position = UDim2.new(0, 10, 0, 50)
    mainStatus.BackgroundTransparency = 1
    mainStatus.Text = "● Status: Connected"
    mainStatus.TextColor3 = Config.Theme.Cyan
    mainStatus.TextSize = 14
    mainStatus.Font = Enum.Font.Gotham
    mainStatus.TextXAlignment = Enum.TextXAlignment.Left
    mainStatus.Parent = mainContent
    
    -- ===== VISUALS TAB (with ESP) =====
    local espSection = createModernSection(visualsContent, "PLAYER ESP", UDim2.new(0, 0, 0, 0))
    
    createModernToggle(espSection, "Enable ESP", 40, false, function(state)
        ESP:Toggle(state)
    end)
    
    -- ===== MISC TAB (with Staff List) =====
    local miscSection = createModernSection(miscContent, "MISC FEATURES", UDim2.new(0, 0, 0, 0))
    
    createModernToggle(miscSection, "Staff List", 40, false, function(state)
        StaffList:Toggle(state)
    end)
    
    -- Tab switching function
    local function switchTab(tabName)
        mainContent.Visible = (tabName == "MAIN")
        visualsContent.Visible = (tabName == "VISUALS")
        miscContent.Visible = (tabName == "MISC")
        settingsContent.Visible = (tabName == "SETTINGS")
        
        for name, data in pairs(tabButtons) do
            if name == tabName then
                data.button.TextColor3 = Config.Theme.Cyan
                tween:Create(data.underline, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
            else
                data.button.TextColor3 = Config.Theme.TextSecondary
                tween:Create(data.underline, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
            end
        end
    end
    
    -- Connect tab buttons
    tabButtons["MAIN"].button.MouseButton1Click:Connect(function() switchTab("MAIN") end)
    tabButtons["VISUALS"].button.MouseButton1Click:Connect(function() switchTab("VISUALS") end)
    tabButtons["MISC"].button.MouseButton1Click:Connect(function() switchTab("MISC") end)
    tabButtons["SETTINGS"].button.MouseButton1Click:Connect(function() switchTab("SETTINGS") end)
    
    -- Animation on spawn
    mainWindow.Size = UDim2.new(0, 0, 0, 0)
    mainWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    tween:Create(mainWindow, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 550, 0, 450),
        Position = UDim2.new(0.5, -275, 0.5, -225)
    }):Play()
end

return GUI
