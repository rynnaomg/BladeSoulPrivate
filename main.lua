-- main.lua
-- Main loader for Forsaken Hub
-- Version: 1.0

-- Load required modules
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/Library.lua"))()
local GameCheck = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/GameCheck.lua"))()
local Config = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/Config.lua"))()

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