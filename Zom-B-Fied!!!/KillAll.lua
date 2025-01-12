local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character
local Tool = Character and Character:FindFirstChildOfClass("Tool") or nil

if Tool and Tool:FindFirstChild("Settings") and Tool.Settings:FindFirstChild("BulletsRemaining") then
    for _, Zombie in workspace.Zombs:GetChildren() do
        local Head = Zombie:FindFirstChild("Head") or nil

        if Head then
            for Number = 1, 10 do
                ReplicatedStorage.Remotes.ToServer.FireDMG:FireServer(Tool, Head)
            end
        end
    end
end
