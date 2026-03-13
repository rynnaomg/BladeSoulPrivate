-- main.lua
-- Main loader for Forsaken Hub
-- Version: 1.1

-- Load required modules
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/Library.lua?nocache=" .. tostring(os.time())))()
local GameCheck = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/GameCheck.lua?nocache=" .. tostring(os.time())))()
local Config = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/Config.lua?nocache=" .. tostring(os.time())))()

-- Check if we're in the correct game
if GameCheck:IsCorrectGame() then
    print("[Forsaken Hub] Game detected. Loading cheat...")
    Library:Notify("Welcome to Forsaken Hub", 3)
    
    -- Load main GUI
    local GUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/GUI.lua"))()
    GUI:Create()
else
    print("[Forsaken Hub] Wrong game.")
    Library:Notify("Wrong game. Execute only in Forsaken Modded", 3)
end
