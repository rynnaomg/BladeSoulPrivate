-- Config.lua
-- Configuration file for Forsaken Hub

local Config = {}

-- Game settings
Config.GameName = "Forsaken Modded"
Config.PlaceID = 124499025066593

-- GUI settings
Config.GUI = {
    Title = "Forsaken Hub",
    Version = "1.0.0",
    Author = "rynnaomg"
}

-- Theme colors (Cyan/Black)
Config.Theme = {
    Background = Color3.fromRGB(20, 20, 20),
    Darker = Color3.fromRGB(10, 10, 10),
    Cyan = Color3.fromRGB(0, 255, 255),
    CyanDark = Color3.fromRGB(0, 200, 200),
    Text = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(180, 180, 180),
    Border = Color3.fromRGB(40, 40, 40)
}

-- Animation settings
Config.Animations = {
    TweenTime = 0.3,
    EasingStyle = Enum.EasingStyle.Quart,
    EasingDirection = Enum.EasingDirection.Out
}

return Config
