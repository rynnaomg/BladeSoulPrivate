-- GameCheck.lua
-- Game validation module

local GameCheck = {}
local Config = loadstring(game:HttpGet("https://raw.githubusercontent.com/rynnaomg/BladeSoulPrivate/main/Config.lua"))()
local Marketplace = game:GetService("MarketplaceService")

function GameCheck:IsCorrectGame()
    -- Primary check by PlaceId
    if game.PlaceId == Config.PlaceID then
        return true
    end
    
    -- Secondary check by game name
    local success, productInfo = pcall(function()
        return Marketplace:GetProductInfo(Config.PlaceID, Enum.InfoType.Asset)
    end)
    
    if success and productInfo then
        if productInfo.Name == Config.GameName then
            return true
        end
    end
    
    return false
end

function GameCheck:GetGameInfo()
    local success, productInfo = pcall(function()
        return Marketplace:GetProductInfo(Config.PlaceID, Enum.InfoType.Asset)
    end)
    
    if success then
        return productInfo
    end
    return nil
end

return GameCheck
