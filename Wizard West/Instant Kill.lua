-- this is patched so it doesn't matter I guess

local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Missions = workspace.Missions
local Mouse = LocalPlayer:GetMouse()
local CurrentSpell = ""
local Spells = { -- I whitelisted certain spells that have aimbot and shit, you may add your own spells
    "Stupendo",
    "Bombarda",
    "Ignis",
    "Ignisium",
}

local GetTarget = function()
    local Target = nil
    local BestDistance = 300

    for k, v in Players:GetPlayers() do
        local Character = v.Character or nil
        local RootPart = Character and Character:FindFirstChild("HumanoidRootPart") or nil

        if v ~= LocalPlayer and RootPart then
            local Position, OnScreen = Camera:WorldToViewportPoint(RootPart.Position)
            local Distance = (Vector2.new(Position.X, Position.Y) - UserInputService:GetMouseLocation()).Magnitude

            if OnScreen and Distance < BestDistance then
                Target = v
                BestDistance = Distance
            end
        end
    end

    return Target
end

local __namecall = nil
__namecall = hookmetamethod(game, "__namecall", function(Self, ...)
    local Array = table.pack(...)
    local Method = getnamecallmethod()

    if Method == "FireServer" and Self.Name == "ToolListnerEvent" then -- do you ever spell your remote events right? electric state was even worse bro
        CurrentSpell = Array[4].Name -- VERY SHIT IMPLEMENTATION, I WAS GOING TO FIX THIS BUT IT GOT PATCHED BY THIS JEW
    end

    if Method == "FireServer" and Self.Name == "SpellClientFire" and table.find(Spells, CurrentSpell) then
        task.spawn(function() -- I was going to implement some sort of garbage collector for threads.. Stay bricked task scheduler
            while Self and Self.Parent do
                local Target = GetTarget()

                for Index = 1, 10 do
                    Self.FireServer(Self, Target and Array[1] or Mouse.Hit.p, Array[2], Target and Target.Character or nil)
                end

                task.wait()
            end
        end)
    end

    return __namecall(Self, table.unpack(Array))
end)
