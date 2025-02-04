-- furry slayer lyfestyle (fuck the furries)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Utility = {}

local CurrentCamera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

do
    function Utility:FilterTanks()
        local Tanks = {}
        local Haystack = Workspace.GetChildren(Workspace)

        for Index = 1, #Haystack do
            local Tank = Haystack[Index]
            local Alive = Tank.FindFirstChild(Tank, "Alive") or nil
            local Immunity = Tank.FindFirstChild(Tank, "Immunity") or nil
            local Owner = Tank.FindFirstChild(Tank, "Owner") or nil

            if not (Alive and Alive.Value and Immunity and not Immunity.Value and Owner) then
                continue
            end

            local Player = Players.FindFirstChild(Players, Owner.Value) or nil

            if not (Player and Player.Team ~= LocalPlayer.Team) then
                continue
            end

            Tanks[Owner.Value] = Tank
        end

        return Tanks
    end
end

local Old = nil
Old = hookmetamethod(game, "__namecall", function(Self, ...)
    local Array = table.pack(...)
    local Method = getnamecallmethod()

    if Method == "FireServer" and Self.Name == "MouseClicked" then
        local Tank = nil
        local Closest = math.huge

        for Name, Model in Utility:FilterTanks() do
            local PrimaryPart = Model.PrimaryPart
            local Distance = (PrimaryPart.CFrame.Position - CurrentCamera.CFrame.Position).Magnitude

            if Distance >= Closest then
                continue
            end

            Tank = Model
            BestDistance = Distance
        end

        if Tank then
            local RearPlate = Tank.FindFirstChild(Tank, "Rear", true) -- this is all really crucial to make sure that you inflict damage during 99% of all your hits
            local Origin = RearPlate.CFrame.Position + Vector3.new(0, 0.1, 0)
            local Destination = RearPlate.CFrame.Position

            -- im too lazy to change this
            Old(Self, table.unpack({ 
                [1] = 1,
                [2] = CFrame.new(Origin),
                [3] = 1,
                [4] = nil,
                [5] = nil,
                [6] = nil,
                [7] = nil,
                [8] = 1, -- Selected ammunition
            }))

            Old(Self, table.unpack({
                [1] = 3,
                [2] = {},
                [3] = CFrame.new(Origin),
                [4] = CFrame.new(Origin, Destination),
                [5] = Tank.Owner.Value,
                [6] = 1,
                [7] = nil,
                [8] = 1, -- Selected ammunition
            }))

            return
        end
    end

    return Old(Self, table.unpack(Array))
end)




