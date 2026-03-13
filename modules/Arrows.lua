-- test_arrow.lua
local player = game:GetService("Players").LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Parent = player:WaitForChild("PlayerGui")

local arrow = Instance.new("ImageLabel")
arrow.Size = UDim2.new(0, 100, 0, 100)
arrow.Position = UDim2.new(0.5, -50, 0.5, -50)
arrow.BackgroundColor3 = Color3.fromRGB(255,255,255)
arrow.Image = "rbxassetid://72385423495250"
arrow.Parent = gui

print("Test arrow created with ID: 72385423495250")
