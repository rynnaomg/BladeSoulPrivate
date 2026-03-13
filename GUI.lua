-- GUI.lua
-- Main GUI interface for Forsaken Hub
-- Version: 3.0 (Redesigned sections)

local GUI = {}
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/Library.lua?nocache=" .. tostring(os.time())))()
local Config = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/Config.lua?nocache=" .. tostring(os.time())))()
local StaffList = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/modules/StaffList.lua?nocache=" .. tostring(os.time())))()
local ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/modules/ESP.lua?nocache=" .. tostring(os.time())))()
local Arrows = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/modules/Arrows.lua?nocache=" .. tostring(os.time())))()

local player = Library.Services.Players.LocalPlayer
local tween = Library.Services.Tween

-- Variables for minimize system
local mainWindow = nil
local minimizedButton = nil
local screenGui = nil
local isMinimized = false

-- Function to create a redesigned section
local function createSection(parent, title, position, width, height)
    -- Main container with glass effect
    local container = Instance.new("Frame")
    container.Name = title .. "Section"
    container.Size = UDim2.new(0, width or 240, 0, height or 120)
    container.Position = position
    container.BackgroundColor3 = Color3.fromRGB(18, 18, 22)  -- Dark glass
    container.BorderSizePixel = 0
    container.Parent = parent
    
    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 12)
    containerCorner.Parent = container
    
    -- Inner glow
    local innerGlow = Instance.new("ImageLabel")
    innerGlow.Size = UDim2.new(1, 4, 1, 4)
    innerGlow.Position = UDim2.new(0, -2, 0, -2)
    innerGlow.BackgroundTransparency = 1
    innerGlow.Image = "rbxassetid://3570695787"
    innerGlow.ImageColor3 = Config.Theme.Cyan
    innerGlow.ImageTransparency = 0.85
    innerGlow.Parent = container
    innerGlow.ZIndex = 0
    
    -- Top accent line
    local accentLine = Instance.new("Frame")
    accentLine.Size = UDim2.new(1, -20, 0, 2)
    accentLine.Position = UDim2.new(0, 10, 0, 0)
    accentLine.BackgroundColor3 = Config.Theme.Cyan
    accentLine.BorderSizePixel = 0
    accentLine.Parent = container
    
    local accentCorner = Instance.new("UICorner")
    accentCorner.CornerRadius = UDim.new(0, 2)
    accentCorner.Parent = accentLine
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 30)
    titleLabel.Position = UDim2.new(0, 10, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Config.Theme.Text
    titleLabel.TextSize = 16
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = container
    
    -- Content frame (for toggles/buttons)
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -20, 1, -50)
    content.Position = UDim2.new(0, 10, 0, 45)
    content.BackgroundTransparency = 1
    content.Parent = container
    
    return container, content
end

-- Create redesigned toggle
local function createToggle(parent, text, posY, default, callback)
    local toggleContainer = Instance.new("Frame")
    toggleContainer.Size = UDim2.new(1, 0, 0, 35)
    toggleContainer.Position = UDim2.new(0, 0, 0, posY)
    toggleContainer.BackgroundTransparency = 1
    toggleContainer.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 150, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Config.Theme.TextSecondary
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = toggleContainer
    
    -- Modern toggle switch
    local toggleBg = Instance.new("Frame")
    toggleBg.Size = UDim2.new(0, 46, 0, 22)
    toggleBg.Position = UDim2.new(1, -56, 0.5, -11)
    toggleBg.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    toggleBg.Parent = toggleContainer
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = toggleBg
    
    local toggleCircle = Instance.new("Frame")
    toggleCircle.Size = UDim2.new(0, 18, 0, 18)
    toggleCircle.Position = default and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
    toggleCircle.BackgroundColor3 = default and Config.Theme.Cyan or Color3.fromRGB(120, 120, 130)
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
        local goalPos = toggled and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        local goalColor = toggled and Config.Theme.Cyan or Color3.fromRGB(120, 120, 130)
        
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
    
    -- ===== MINIMIZED BUTTON =====
    minimizedButton = Instance.new("ImageButton")
    minimizedButton.Name = "MinimizedButton"
    minimizedButton.Size = UDim2.new(0, 54, 0, 54)
    minimizedButton.Position = UDim2.new(0, 20, 0, 100)
    minimizedButton.BackgroundColor3 = Config.Theme.Cyan
    minimizedButton.Image = "rbxassetid://3570695787"
    minimizedButton.ImageColor3 = Config.Theme.Cyan
    minimizedButton.ScaleType = Enum.ScaleType.Fit
    minimizedButton.BackgroundTransparency = 0.15
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
    buttonText.TextSize = 20
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
    mainWindow.Size = UDim2.new(0, 600, 0, 500)
    mainWindow.Position = UDim2.new(0.5, -300, 0.5, -250)
    mainWindow.BackgroundColor3 = Color3.fromRGB(12, 12, 15)  -- Darker background
    mainWindow.BorderSizePixel = 0
    mainWindow.Active = true
    mainWindow.Draggable = true
    mainWindow.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = mainWindow
    
    -- Glow effect
    local glow = Instance.new("ImageLabel")
    glow.Size = UDim2.new(1, 30, 1, 30)
    glow.Position = UDim2.new(0.5, -15, 0.5, -15)
    glow.BackgroundTransparency = 1
    glow.Image = "rbxassetid://3570695787"
    glow.ImageColor3 = Config.Theme.Cyan
    glow.ImageTransparency = 0.9
    glow.Parent = mainWindow
    
    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 50)
    titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainWindow
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 16)
    titleCorner.Parent = titleBar
    
    -- Gradient
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 30)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 20))
    })
    gradient.Rotation = 90
    gradient.Parent = titleBar
    
    -- Title
    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(1, -100, 1, 0)
    titleText.Position = UDim2.new(0, 20, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "FORSAKEN HUB  •  v" .. Config.GUI.Version
    titleText.TextColor3 = Config.Theme.Text
    titleText.TextSize = 18
    titleText.Font = Enum.Font.GothamBold
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    
    -- Minimize button
    local minimizeButton = Instance.new("TextButton")
    minimizeButton.Name = "MinimizeButton"
    minimizeButton.Size = UDim2.new(0, 34, 0, 34)
    minimizeButton.Position = UDim2.new(1, -78, 0.5, -17)
    minimizeButton.Text = "–"
    minimizeButton.TextColor3 = Config.Theme.Text
    minimizeButton.TextSize = 24
    minimizeButton.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    minimizeButton.AutoButtonColor = false
    minimizeButton.Parent = titleBar
    
    local minCorner = Instance.new("UICorner")
    minCorner.CornerRadius = UDim.new(0, 8)
    minCorner.Parent = minimizeButton
    
    minimizeButton.MouseEnter:Connect(function()
        tween:Create(minimizeButton, TweenInfo.new(0.2), {BackgroundColor3 = Config.Theme.Cyan}):Play()
    end)
    
    minimizeButton.MouseLeave:Connect(function()
        tween:Create(minimizeButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 35)}):Play()
    end)
    
    minimizeButton.MouseButton1Click:Connect(function()
        isMinimized = true
        mainWindow.Visible = false
        minimizedButton.Visible = true
    end)
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 34, 0, 34)
    closeButton.Position = UDim2.new(1, -39, 0.5, -17)
    closeButton.Text = "×"
    closeButton.TextColor3 = Config.Theme.Text
    closeButton.TextSize = 24
    closeButton.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    closeButton.AutoButtonColor = false
    closeButton.Parent = titleBar
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton
    
    closeButton.MouseEnter:Connect(function()
        tween:Create(closeButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 70, 70)}):Play()
    end)
    
    closeButton.MouseLeave:Connect(function()
        tween:Create(closeButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 35)}):Play()
    end)
    
    closeButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
    
    -- Tab container
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Size = UDim2.new(1, -40, 0, 50)
    tabContainer.Position = UDim2.new(0, 20, 0, 60)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = mainWindow
    
    -- Modern tabs
    local tabs = {"MAIN", "VISUALS", "MISC", "SETTINGS"}
    local tabButtons = {}
    local tabWidth = 110
    
    for i, tabName in ipairs(tabs) do
        local tabButton = Instance.new("TextButton")
        tabButton.Name = tabName .. "Tab"
        tabButton.Size = UDim2.new(0, tabWidth, 0, 40)
        tabButton.Position = UDim2.new(0, (i-1) * (tabWidth + 5), 0, 5)
        tabButton.Text = tabName
        tabButton.TextColor3 = i == 1 and Config.Theme.Cyan or Config.Theme.TextSecondary
        tabButton.TextSize = 15
        tabButton.Font = Enum.Font.GothamBold
        tabButton.BackgroundTransparency = 1
        tabButton.Parent = tabContainer
        
        local underline = Instance.new("Frame")
        underline.Name = "Underline"
        underline.Size = UDim2.new(0, 60, 0, 3)
        underline.Position = UDim2.new(0.5, -30, 1, -5)
        underline.BackgroundColor3 = Config.Theme.Cyan
        underline.BackgroundTransparency = i == 1 and 0.2 or 1
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
    contentContainer.Size = UDim2.new(1, -40, 1, -130)
    contentContainer.Position = UDim2.new(0, 20, 0, 115)
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
    mainWelcome.Text = "Welcome, " .. player.Name
    mainWelcome.TextColor3 = Config.Theme.Text
    mainWelcome.TextSize = 24
    mainWelcome.Font = Enum.Font.GothamBold
    mainWelcome.TextXAlignment = Enum.TextXAlignment.Left
    mainWelcome.Parent = mainContent
    
    local mainStatus = Instance.new("TextLabel")
    mainStatus.Size = UDim2.new(1, 0, 0, 25)
    mainStatus.Position = UDim2.new(0, 10, 0, 55)
    mainStatus.BackgroundTransparency = 1
    mainStatus.Text = "● System Online"
    mainStatus.TextColor3 = Config.Theme.Cyan
    mainStatus.TextSize = 14
    mainStatus.Font = Enum.Font.Gotham
    mainStatus.TextXAlignment = Enum.TextXAlignment.Left
    mainStatus.Parent = mainContent
    
    -- ===== VISUALS TAB =====
    local espSection, espContent = createSection(visualsContent, "PLAYER ESP", UDim2.new(0, 0, 0, 0), 240, 100)
    local arrowsSection, arrowsContent = createSection(visualsContent, "DIRECTION ARROWS", UDim2.new(0, 260, 0, 0), 240, 120)
    
    createToggle(espContent, "Enable ESP", 0, false, function(state)
        ESP:Toggle(state)
    end)
    
    createToggle(arrowsContent, "Show Arrows", 0, false, function(state)
        Arrows:Toggle(state)
    end)
    
    -- Info text for arrows
    local arrowsInfo = Instance.new("TextLabel")
    arrowsInfo.Size = UDim2.new(1, 0, 0, 40)
    arrowsInfo.Position = UDim2.new(0, 0, 0, 45)
    arrowsInfo.BackgroundTransparency = 1
    arrowsInfo.Text = "Shows direction to opposite team\n• Killers → Survivors\n• Survivors → Killers"
    arrowsInfo.TextColor3 = Config.Theme.TextSecondary
    arrowsInfo.TextSize = 12
    arrowsInfo.Font = Enum.Font.Gotham
    arrowsInfo.TextXAlignment = Enum.TextXAlignment.Left
    arrowsInfo.TextYAlignment = Enum.TextYAlignment.Top
    arrowsInfo.Parent = arrowsContent
    
    -- ===== MISC TAB =====
    local miscSection, miscContentSection = createSection(miscContent, "MISC FEATURES", UDim2.new(0, 0, 0, 0), 240, 100)
    
    createToggle(miscContentSection, "Staff List", 0, false, function(state)
        StaffList:Toggle(state)
    end)
    
    -- Tab switching
    local function switchTab(tabName)
        mainContent.Visible = (tabName == "MAIN")
        visualsContent.Visible = (tabName == "VISUALS")
        miscContent.Visible = (tabName == "MISC")
        settingsContent.Visible = (tabName == "SETTINGS")
        
        for name, data in pairs(tabButtons) do
            if name == tabName then
                data.button.TextColor3 = Config.Theme.Cyan
                tween:Create(data.underline, TweenInfo.new(0.2), {BackgroundTransparency = 0.2}):Play()
            else
                data.button.TextColor3 = Config.Theme.TextSecondary
                tween:Create(data.underline, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
            end
        end
    end
    
    -- Connect tabs
    tabButtons["MAIN"].button.MouseButton1Click:Connect(function() switchTab("MAIN") end)
    tabButtons["VISUALS"].button.MouseButton1Click:Connect(function() switchTab("VISUALS") end)
    tabButtons["MISC"].button.MouseButton1Click:Connect(function() switchTab("MISC") end)
    tabButtons["SETTINGS"].button.MouseButton1Click:Connect(function() switchTab("SETTINGS") end)
    
    -- Animation
    mainWindow.Size = UDim2.new(0, 0, 0, 0)
    mainWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    tween:Create(mainWindow, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 600, 0, 500),
        Position = UDim2.new(0.5, -300, 0.5, -250)
    }):Play()
end

return GUI
