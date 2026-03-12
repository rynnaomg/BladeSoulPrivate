-- GUI.lua
-- Main GUI interface for Forsaken Hub
-- Version: 1.1 (with modules system)

local GUI = {}
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/Library.lua"))()
local Config = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/Config.lua"))()
local StaffList = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/modules/StaffList.lua"))()

local player = Library.Services.Players.LocalPlayer
local tween = Library.Services.Tween
local userInput = Library.Services.UserInput
local players = Library.Services.Players

-- Variables for minimize system
local mainWindow = nil
local minimizedButton = nil
local screenGui = nil
local isMinimized = false

-- Staff List variables
local staffListModule = nil
local staffListEnabled = false

function GUI:Create()
    if not player then return end
    
    -- Main ScreenGui
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ForsakenHub"
    screenGui.Parent = player:WaitForChild("PlayerGui")
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Create Staff List module instance
    staffListModule = StaffList:Create(screenGui)
    
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
    
    -- Button corner
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(1, 0)
    buttonCorner.Parent = minimizedButton
    
    -- Button text
    local buttonText = Instance.new("TextLabel")
    buttonText.Size = UDim2.new(1, 0, 1, 0)
    buttonText.BackgroundTransparency = 1
    buttonText.Text = "FH"
    buttonText.TextColor3 = Config.Theme.Background
    buttonText.TextSize = 18
    buttonText.Font = Enum.Font.GothamBold
    buttonText.Parent = minimizedButton
    
    -- Button click to restore
    minimizedButton.MouseButton1Click:Connect(function()
        isMinimized = false
        minimizedButton.Visible = false
        mainWindow.Visible = true
    end)
    
    -- ===== MAIN WINDOW =====
    mainWindow = Instance.new("Frame")
    mainWindow.Name = "MainWindow"
    mainWindow.Size = UDim2.new(0, 500, 0, 400)
    mainWindow.Position = UDim2.new(0.5, -250, 0.5, -200)
    mainWindow.BackgroundColor3 = Config.Theme.Background
    mainWindow.BorderSizePixel = 0
    mainWindow.Active = true
    mainWindow.Draggable = true
    mainWindow.Parent = screenGui
    
    -- Rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainWindow
    
    -- Cyan border accent
    local borderAccent = Instance.new("Frame")
    borderAccent.Name = "BorderAccent"
    borderAccent.Size = UDim2.new(1, 0, 0, 2)
    borderAccent.Position = UDim2.new(0, 0, 0, 0)
    borderAccent.BackgroundColor3 = Config.Theme.Cyan
    borderAccent.BorderSizePixel = 0
    borderAccent.Parent = mainWindow
    
    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Config.Theme.Darker
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainWindow
    
    -- Title bar corner
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = titleBar
    
    -- Title text
    local titleText = Instance.new("TextLabel")
    titleText.Name = "TitleText"
    titleText.Size = UDim2.new(1, -90, 1, 0)
    titleText.Position = UDim2.new(0, 15, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = Config.GUI.Title .. " v" .. Config.GUI.Version
    titleText.TextColor3 = Config.Theme.Cyan
    titleText.TextSize = 18
    titleText.Font = Enum.Font.GothamBold
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    
    -- Minimize button
    local minimizeButton = Instance.new("TextButton")
    minimizeButton.Name = "MinimizeButton"
    minimizeButton.Size = UDim2.new(0, 30, 0, 30)
    minimizeButton.Position = UDim2.new(1, -70, 0, 5)
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
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 5)
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
    tabContainer.Size = UDim2.new(1, -20, 0, 40)
    tabContainer.Position = UDim2.new(0, 10, 0, 50)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = mainWindow
    
    -- Tab buttons
    local tabs = {"Main", "Combat", "Visuals", "Misc", "Settings"}
    local tabButtons = {}
    
    for i, tabName in ipairs(tabs) do
        local tabButton = Instance.new("TextButton")
        tabButton.Name = tabName .. "Tab"
        tabButton.Size = UDim2.new(0, 90, 0, 35)
        tabButton.Position = UDim2.new(0, (i-1) * 95, 0, 0)
        tabButton.Text = tabName
        tabButton.TextColor3 = Config.Theme.TextSecondary
        tabButton.TextSize = 14
        tabButton.Font = Enum.Font.Gotham
        tabButton.BackgroundTransparency = 1
        tabButton.Parent = tabContainer
        
        local underline = Instance.new("Frame")
        underline.Name = "Underline"
        underline.Size = UDim2.new(1, 0, 0, 2)
        underline.Position = UDim2.new(0, 0, 1, -2)
        underline.BackgroundColor3 = Config.Theme.Cyan
        underline.BackgroundTransparency = 1
        underline.Parent = tabButton
        
        tabButtons[tabName] = {button = tabButton, underline = underline}
    end
    
    -- Content container
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Size = UDim2.new(1, -20, 1, -100)
    contentContainer.Position = UDim2.new(0, 10, 0, 100)
    contentContainer.BackgroundTransparency = 1
    contentContainer.Parent = mainWindow
    
    -- Create tab contents
    local mainContent = Instance.new("Frame")
    mainContent.Name = "MainContent"
    mainContent.Size = UDim2.new(1, 0, 1, 0)
    mainContent.BackgroundTransparency = 1
    mainContent.Parent = contentContainer
    mainContent.Visible = true
    
    local combatContent = Instance.new("Frame")
    combatContent.Name = "CombatContent"
    combatContent.Size = UDim2.new(1, 0, 1, 0)
    combatContent.BackgroundTransparency = 1
    combatContent.Parent = contentContainer
    combatContent.Visible = false
    
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
    
    -- ===== MISC TAB CONTENT =====
    local miscLabel = Instance.new("TextLabel")
    miscLabel.Size = UDim2.new(1, 0, 0, 30)
    miscLabel.Position = UDim2.new(0, 10, 0, 10)
    miscLabel.BackgroundTransparency = 1
    miscLabel.Text = "Miscellaneous Features"
    miscLabel.TextColor3 = Config.Theme.Cyan
    miscLabel.TextSize = 16
    miscLabel.Font = Enum.Font.GothamBold
    miscLabel.TextXAlignment = Enum.TextXAlignment.Left
    miscLabel.Parent = miscContent
    
    -- Staff List Toggle
    Library:CreateToggle("Staff List", UDim2.new(1, -20, 0, 30), UDim2.new(0, 10, 0, 50), miscContent, false, function(state)
        staffListEnabled = state
        StaffList:Toggle(state)
    end)
    
    -- ===== MAIN TAB CONTENT =====
    local welcomeText = Instance.new("TextLabel")
    welcomeText.Name = "WelcomeText"
    welcomeText.Size = UDim2.new(1, 0, 0, 50)
    welcomeText.Position = UDim2.new(0, 10, 0, 20)
    welcomeText.BackgroundTransparency = 1
    welcomeText.Text = "Welcome, " .. player.Name .. "!"
    welcomeText.TextColor3 = Config.Theme.Text
    welcomeText.TextSize = 24
    welcomeText.Font = Enum.Font.GothamBold
    welcomeText.TextXAlignment = Enum.TextXAlignment.Left
    welcomeText.Parent = mainContent
    
    local statusText = Instance.new("TextLabel")
    statusText.Name = "StatusText"
    statusText.Size = UDim2.new(1, 0, 0, 30)
    statusText.Position = UDim2.new(0, 10, 0, 70)
    statusText.BackgroundTransparency = 1
    statusText.Text = "Status: Connected"
    statusText.TextColor3 = Config.Theme.Cyan
    statusText.TextSize = 16
    statusText.Font = Enum.Font.Gotham
    statusText.TextXAlignment = Enum.TextXAlignment.Left
    statusText.Parent = mainContent
    
    -- Test button
    Library:CreateButton("Test Button", UDim2.new(0, 150, 0, 35), UDim2.new(0, 10, 0, 120), Config.Theme.Darker, mainContent, function()
        Library:Notify("Button clicked!", 2)
    end)
    
    -- Tab switching function
    local function switchTab(tabName)
        mainContent.Visible = (tabName == "Main")
        combatContent.Visible = (tabName == "Combat")
        visualsContent.Visible = (tabName == "Visuals")
        miscContent.Visible = (tabName == "Misc")
        settingsContent.Visible = (tabName == "Settings")
        
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
    tabButtons["Main"].button.MouseButton1Click:Connect(function() switchTab("Main") end)
    tabButtons["Combat"].button.MouseButton1Click:Connect(function() switchTab("Combat") end)
    tabButtons["Visuals"].button.MouseButton1Click:Connect(function() switchTab("Visuals") end)
    tabButtons["Misc"].button.MouseButton1Click:Connect(function() switchTab("Misc") end)
    tabButtons["Settings"].button.MouseButton1Click:Connect(function() switchTab("Settings") end)
    
    -- Animation on spawn
    mainWindow.Size = UDim2.new(0, 0, 0, 0)
    mainWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    tween:Create(mainWindow, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 500, 0, 400),
        Position = UDim2.new(0.5, -250, 0.5, -200)
    }):Play()
end

return GUI