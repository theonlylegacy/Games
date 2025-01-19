local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local Backpack = LocalPlayer:FindFirstChild("Backpack")
local Char = LocalPlayer.Character

if Char and Char:FindFirstChildOfClass("Humanoid") then
    Char:FindFirstChildOfClass("Humanoid"):UnequipTools()
end

if Backpack and Char then
    ReplicatedStorage.WeaponEvent:FireServer("Hammer")

    Backpack:WaitForChild("Hammer").Parent = Char

    for _, Player in Players:GetPlayers() do
        if Player == LocalPlayer then
            continue
        end

        local Character = Player.Character
		local Head = Character and Character:FindFirstChild("Head") or nil
    
        if Head then
            task.defer(function() 
                ReplicatedStorage.DraggerService.DraggerGateway:InvokeServer("RequestDelete", Head)
            end)
        end
    end
end
