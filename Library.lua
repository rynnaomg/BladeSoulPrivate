-- Library.lua
-- Core library with utilities and services

local Library = {}
local Config = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/Config.lua"))()

-- Roblox services
Library.Services = {
    Players = game:GetService("Players"),
    UserInput = game:GetService("UserInputService"),
    Tween = game:GetService("TweenService"),
    Run = game:GetService("RunService"),
    Marketplace = game:GetService("MarketplaceService")
}

-- Store theme from config
Library.Theme = Config.Theme

-- Create notification system
function Library:Notify(message, duration)
    duration = duration or 3
    
    local player = Library.Services.Players.LocalPlayer
    if not player then return end
    
    local gui = Instance.new("ScreenGui")
    local container = Instance.new("Frame")
    local accent = Instance.new("Frame")
    local textLabel = Instance.new("TextLabel")
    local glow = Instance.new("ImageLabel")
    
    -- Setup GUI
    gui.Name = "ForsakenNotification"
    gui.Parent = player:WaitForChild("PlayerGui")
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Main container
    container.Name = "Container"
    container.Size = UDim2.new(0, 350, 0, 60)
    container.Position = UDim2.new(0.5, -175, 0, -70)
    container.BackgroundColor3 = self.Theme.Background
    container.BorderSizePixel = 0
    container.ClipsDescendants = true
    container.Parent = gui
    
    -- Cyan accent line
    accent.Name = "Accent"
    accent.Size = UDim2.new(1, 0, 0, 3)
    accent.BackgroundColor3 = self.Theme.Cyan
    accent.BorderSizePixel = 0
    accent.Parent = container
    
    -- Glow effect
    glow.Name = "Glow"
    glow.Size = UDim2.new(1, 30, 1, 30)
    glow.Position = UDim2.new(0.5, -15, 0.5, -15)
    glow.BackgroundTransparency = 1
    glow.Image = "rbxassetid://3570695787"
    glow.ImageColor3 = self.Theme.Cyan
    glow.ImageTransparency = 0.7
    glow.Parent = container
    
    -- Text
    textLabel.Name = "Text"
    textLabel.Size = UDim2.new(1, -20, 1, 0)
    textLabel.Position = UDim2.new(0, 10, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = message
    textLabel.TextColor3 = self.Theme.Text
    textLabel.TextSize = 16
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Parent = container
    
    -- Animation
    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    local goal = {Position = UDim2.new(0.5, -175, 0, 30)}
    local tweenIn = self.Services.Tween:Create(container, tweenInfo, goal)
    tweenIn:Play()
    
    -- Auto destroy
    task.wait(duration)
    
    local tweenInfoOut = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    local goalOut = {Position = UDim2.new(0.5, -175, 0, -70)}
    local tweenOut = self.Services.Tween:Create(container, tweenInfoOut, goalOut)
    tweenOut:Play()
    
    tweenOut.Completed:Connect(function()
        gui:Destroy()
    end)
end

-- Create rounded frame
function Library:CreateRoundedFrame(size, position, color, parent)
    local frame = Instance.new("Frame")
    frame.Size = size
    frame.Position = position
    frame.BackgroundColor3 = color or self.Theme.Background
    frame.BorderSizePixel = 0
    frame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame
    
    return frame
end

-- Create button
function Library:CreateButton(text, size, position, color, parent, callback)
    local button = Instance.new("TextButton")
    button.Size = size
    button.Position = position
    button.Text = text
    button.TextColor3 = self.Theme.Text
    button.TextSize = 14
    button.Font = Enum.Font.Gotham
    button.BackgroundColor3 = color or self.Theme.Darker
    button.AutoButtonColor = false
    button.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = button
    
    -- Hover effect
    button.MouseEnter:Connect(function()
        self.Services.Tween:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = self.Theme.Cyan}):Play()
    end)
    
    button.MouseLeave:Connect(function()
        self.Services.Tween:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = color or self.Theme.Darker}):Play()
    end)
    
    button.MouseButton1Click:Connect(callback)
    
    return button
end

-- Create toggle switch
function Library:CreateToggle(text, size, position, parent, default, callback)
    local container = Instance.new("Frame")
    container.Size = size
    container.Position = position
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 150, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = self.Theme.Text
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local toggleBg = Instance.new("Frame")
    toggleBg.Size = UDim2.new(0, 50, 0, 24)
    toggleBg.Position = UDim2.new(1, -60, 0.5, -12)
    toggleBg.BackgroundColor3 = self.Theme.Darker
    toggleBg.Parent = container
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = toggleBg
    
    local toggleCircle = Instance.new("Frame")
    toggleCircle.Size = UDim2.new(0, 20, 0, 20)
    toggleCircle.Position = default and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
    toggleCircle.BackgroundColor3 = default and self.Theme.Cyan or self.Theme.TextSecondary
    toggleCircle.Parent = toggleBg
    
    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = toggleCircle
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Parent = container
    
    local toggled = default
    
    button.MouseButton1Click:Connect(function()
        toggled = not toggled
        local goalPos = toggled and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
        local goalColor = toggled and self.Theme.Cyan or self.Theme.TextSecondary
        
        self.Services.Tween:Create(toggleCircle, TweenInfo.new(0.2), {Position = goalPos, BackgroundColor3 = goalColor}):Play()
        callback(toggled)
    end)
    
    return container
end

return Library