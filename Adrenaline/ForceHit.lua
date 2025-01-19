local ReplicatedStorage = cloneref(game:FindService("ReplicatedStorage"))
local UserInputService = cloneref(game:FindService("UserInputService"))
local RunService = cloneref(game:FindService("RunService"))
local Workspace = cloneref(game:FindService("Workspace"))
local Players = cloneref(game:FindService("Players"))

local PlayerMemory = require(ReplicatedStorage.Modules.Shared.Communications.PlayerMemory)
local BulletHandler = require(ReplicatedStorage.Modules.Client.Handlers.BulletHandler)
local ClientObjectManager = require(ReplicatedStorage.Modules.Client.Classes.ClientObjectManager)
local Network = require(ReplicatedStorage.Modules.Shared.Utility.Network)

local NewParameters = RaycastParams.new()
NewParameters.FilterDescendantsInstances = {Workspace.CurrentCamera, Workspace.Map.BulletIgnore, Workspace.Ragdolls} -- Couldn't be asked to add the rest
NewParameters.FilterType = Enum.RaycastFilterType.Exclude

local CurrentCamera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

do
    CastRay = function(Origin, Destination, Parameters) -- It's from the game
        local Direction = Destination - Origin
        local Result = Workspace:Raycast(Origin, Direction, Parameters)
        local Object = Result and Result.Instance

        if Result and Object.CollisionGroup ~= "Ragdolls" then
            local Character = Object:FindFirstAncestorWhichIsA("Model")
            
            if Character and (Character:HasTag("Character") and Character:GetAttribute("State") == "Alive") then
                return true
            end
        end

        return false
    end

    ScreenPoint = function(Destination)
        local Point, Visible = CurrentCamera:WorldToScreenPoint(Destination)

        if Visible then
            return Vector2.new(Point.X, Point.Y)
        end

        return nil
    end

    GetActiveWeapon = function()
        local Data = getupvalue(ClientObjectManager.GetClientObject, 1)

        for _, Module in Data do
            if Module.ObjectClassName == "Gun" and Module.IsEquipped and tostring(Module.Instance.Owner.Value) == LocalPlayer.Name then
                return Module
            end
        end
    
        return nil
    end

    GetNew = function(Radius) -- I'm getting tired of all the GetClosestPlayer shit
        local New = {Character = nil, Hitbox = nil, Distance = Radius}
        local Haystack = Players:GetPlayers()
        
        table.remove(Haystack, 1)

        for Index = 1, #Haystack do
            local Player = Haystack[Index]
            local Character = Player.Character

            local State = Character and Character:GetAttribute("State")
            local Head = Character and Character:FindFirstChild("Head") or nil

            if not (Player.Team ~= LocalPlayer.Team and State == "Alive" and Head and not Character:HasTag("Protected")) then
                continue
            end

            local Result = CastRay(CurrentCamera.CFrame.Position, Head.Position, NewParameters)
            local Mouse = UserInputService:GetMouseLocation()
            local Screen = ScreenPoint(Head.Position)
            local Distance = Screen and Screen - Mouse or 360

            if not (Result and Screen and Distance.Magnitude < New.Distance) then
                continue
            end

            New.Character = Character
            New.Hitbox = Head
            New.Distance = Distance.Magnitude
        end

        return New
    end
end

local Old = Network.FireServer
Network.FireServer = function(Self, Method, ...)
    local Array = table.pack(...)

    if Method == "RegisterBullet" then
        local New = GetNew(360 / CurrentCamera.FieldOfView * 80) -- Dynamic FOV

        if New and New.Character then
            local Weapon = GetActiveWeapon()
			
            Old(Self, Method, table.unpack(Array))
            Old(Self, "BulletHitTarget", getupvalue(BulletHandler, 1), New.Character, New.Hitbox, New.Hitbox.Position, Weapon.Source.Penetration)
        end
    end

    return Old(Self, Method, table.unpack(Array))
end
