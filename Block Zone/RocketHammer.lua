-- Basically Kill Aura, teleports to all enemies within 49 studs when you release the hammer.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Tool = require(ReplicatedStorage.Modules.Tool)
local RocketHammer = require(ReplicatedStorage.Systems.Hammers.Variants.RocketHammer)

local LocalPlayer = Players.LocalPlayer

local function Wrap(Function)
    return function(...)
        return Function(...)
    end
end

local function Traverse(Haystack) -- Trying to keep the code looking cleaner in the hook because I don't wanna fill it with shit
    for Index = 1, #Haystack do
        local Point = Haystack[Index]

        LocalPlayer.Character:PivotTo(Point.Coordinates)
        task.wait(0.08)
    end
end

local Old = nil
Old = hookfunction(RocketHammer.stateMachine.step, Wrap(function(...)
    local Array = table.pack(...)

    if Array[3].chargeState ~= "None" and (Array[3].held == false and Tool.CanUse(Array[1]) == true) then
        local Points = {}
        local Haystack = Players:GetPlayers()

        for Index = 1, #Haystack do
            local Player = Haystack[Index]

            if Player == LocalPlayer then
                continue
            end
            
            local Character = Player.Character
            local RootPart = Character and Character:FindFirstChild("HumanoidRootPart") or nil
            local ForceField = Character and Character:FindFirstChildOfClass("ForceField") or nil

            if not (Character and RootPart) or ForceField then
                continue
            end

            local Direction = Character:GetPivot().Position - LocalPlayer.Character:GetPivot().Position
            if Direction.Magnitude >= 50 then -- Maximum distance: 49
                continue
            end

            table.insert(Points, {Coordinates = Character:GetPivot() + (RootPart.Velocity / 5) + Direction.Unit * 1.15, Distance = Direction.Magnitude})
        end

        if #Points > 0 then
            table.sort(Points, function(First, Second)
                return First.Distance < Second.Distance
            end)

            table.insert(Points, {Coordinates = CFrame.new(LocalPlayer.Character:GetPivot().Position), Distance = 0})
            task.defer(Traverse, Points)
        end
    end

    return Old(...)
end))
