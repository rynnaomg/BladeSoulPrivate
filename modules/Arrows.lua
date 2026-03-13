-- modules/Arrows.lua
-- Arrow module for Forsaken Hub
-- Version: 11.0 - ABSOLUTELY NO GUI ELEMENTS

local Arrows = {}
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/Library.lua"))()
local Config = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/Config.lua"))()

local players = Library.Services.Players
local workspace = game:GetService("Workspace")
local runService = game:GetService("RunService")
local localPlayer = players.LocalPlayer

local enabled = false
local arrowConnections = {}
local arrows = {}
local playerTeam = nil
local currentTargetTeam = nil
local arrowImageData = nil

local ARROW_FILE_NAME = "forsaken_arrow.png"
local ARROW_GITHUB_URL = "https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/assets/arrow.png"

local drawingSupported = Drawing and Drawing.new
if not drawingSupported then
    warn("[Arrows] Drawing API not supported")
end

local function loadArrowImage()
    if arrowImageData then return arrowImageData end
    if not isfile or not writefile then return nil end
    if isfile(ARROW_FILE_NAME) then
        local s, d = pcall(readfile, ARROW_FILE_NAME)
        if s and d then arrowImageData = d; return arrowImageData end
    end
    local s, d = pcall(function() return game:HttpGet(ARROW_GITHUB_URL) end)
    if s and d and #d > 0 then
        writefile(ARROW_FILE_NAME, d)
        arrowImageData = d
        return arrowImageData
    end
    return nil
end

local function getSafeCamera()
    local s, r = pcall(function() return workspace.CurrentCamera end)
    return s and r
end

local function getCharacterRootPart(character)
    if not character then return nil end
    local s, r = pcall(function() return character:FindFirstChild("HumanoidRootPart") end)
    return s and r
end

local function getPlayerTeam(player)
    if not player or not player.Character then return nil end
    local s, r = pcall(function()
        local pf = workspace:FindFirstChild("Players")
        if not pf then return nil end
        if not pf:FindFirstChild("Killers") and not pf:FindFirstChild("Survivors") then return "Lobby" end
        local kf = pf:FindFirstChild("Killers")
        if kf then for _, ch in ipairs(kf:GetChildren()) do if ch:IsA("Model") and player.Character == ch then return "Killers" end end end
        local sf = pf:FindFirstChild("Survivors")
        if sf then for _, ch in ipairs(sf:GetChildren()) do if ch:IsA("Model") and player.Character == ch then return "Survivors" end end end
        return nil
    end)
    return s and r
end

local function getAngleToTarget(camera, targetPos)
    local rel = camera.CFrame:PointToObjectSpace(targetPos)
    return math.deg(math.atan2(rel.X, -rel.Z))
end

local function createArrow(targetPlayer, targetTeam)
    if not drawingSupported then return nil end
    
    local imgData = loadArrowImage()
    local isKiller = (targetTeam == "Killers")
    local color = isKiller and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(80, 255, 80)
    
    local img
    if imgData then
        local s, result = pcall(function()
            local i = Drawing.new("Image")
            i.Data = imgData
            i.Size = Vector2.new(30, 30)
            return i
        end)
        if s and result then
            img = result
        end
    end
    if not img then
        img = Drawing.new("Circle")
        img.Color = color
        img.Filled = true
        img.Radius = 15
        img.NumSides = 30
    end
    
    img.Position = Vector2.new(0, 0)
    img.Visible = false
    img.ZIndex = 10
    pcall(function() img.Transparency = 1 end)
    
    local txt = Drawing.new("Text")
    txt.Text = "0m"
    txt.Color = Color3.fromRGB(255, 255, 255)
    txt.Size = 14
    txt.Center = true
    txt.Outline = true
    txt.OutlineColor = Color3.fromRGB(0, 0, 0)
    txt.Font = Drawing.Fonts.UI
    txt.Position = Vector2.new(0, 0)
    txt.Visible = false
    txt.ZIndex = 10
    
    return { image = img, text = txt, playerName = targetPlayer.Name }
end

local function destroyArrow(a)
    if not a then return end
