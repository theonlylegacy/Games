---@diagnostic disable: undefined-field
-- The game rarely gets new content + I'm pretty sure that this is all patched by now

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Stats = game:GetService("Stats")

local Camera = Workspace.CurrentCamera
local Entities = Workspace.Entities
local Characters = Workspace.Characters
local Missions = Workspace.Missions

local Modules = ReplicatedStorage.Modules
local Events = ReplicatedStorage.Events

local LocalPlayer = Players.LocalPlayer

local JailModule = require(Modules.Client.Char.Jailed)
local MapModule = require(Modules.Client.SpellBook.Catagories.Map)
local ApparateModule = require(Modules.Client.Char.Dash.DashApparate)
local CrateModule = require(Modules.Client.UI.CrateSpinner)

local DashEvent = Events.DashEvent
local MoneyDropEvent = Events.MoneyDropEvent
local TrinketSellEvent = Events.TrinketSellEvent

local Library = loadstring(http.request({
    Url = "https://raw.githubusercontent.com/theonlylegacy/Cloud/refs/heads/main/Salmon%20Client/Library.lua", 
    Method = "GET",
}).Body)()

local Notify = loadstring(http.request({
    Url = "https://raw.githubusercontent.com/theonlylegacy/Cloud/refs/heads/main/Salmon%20Client/Notify.lua", 
    Method = "GET",
}).Body)()

local Ping = loadstring(http.request({
    Url = "https://raw.githubusercontent.com/theonlylegacy/Cloud/refs/heads/main/Assets/Ping.lua", 
    Method = "GET",
}).Body)

local UIObjects = {}
local Spells = {"Stupendo", "Aquarcia", "Ignis", "Ignisium", "Bombarda", "Inlisus", "Electrificus", "Abra Kedabra", "Vocare Enarma", "Imperum", "Araneacidus"}
local Lightning = {"Inlisus", "Electrificus"}
local Guns = {"Vocare Machinam"}

local Cache = {
    Casting = "",
    MouseLocation = Vector2.zero,

    Crates = {},
}

local Vars = {
    AimbotTargetting = "Player",
    WandAimbot = false,
    WandAimbotFOV = 0,
    SpellAimbot = false,
    OnlyLightning = false,
    SpellAimbotFOV = 0,
    SpellWallbang = false,
    AntiArrest = false,
    MapApparate = false,
    SpeedModifier = false,
    SpeedMultiplier = 0,
    SpeedMaximum = 0,
    MapOutlaws = false,
    InstantSpin = false,
    NotifyChest = false,
}

do
    Pivot = function(Character, Coordinates)
        Character:PivotTo(Coordinates)
        sethiddenproperty(LocalPlayer, "GameplayPaused", false)
    end

    Raycast = function(Start, End, Character)
        local RaycastParameters = RaycastParams.new()
        RaycastParameters.FilterDescendantsInstances = {Entities, Character}
        RaycastParameters.FilterType = Enum.RaycastFilterType.Exclude
    
        return Workspace.Raycast(Workspace, Start, (End - Start).Unit * 5000, RaycastParameters)
    end

    FetchPlayerInFOV = function(Targetting, MaxDistance, MouseLocation)
        local Current = {
            Character = nil,
            Distance = MaxDistance,
        }

        if Targetting == "Player" then
            for Index, Character in Characters.GetChildren(Characters) do
                local Player = Players.FindFirstChild(Players, Character.Name) or nil
                local RootPart = Character and Character.PrimaryPart or nil
    
                if Player ~= LocalPlayer and RootPart then
                    local ScreenPosition, OnScreen = Camera.WorldToViewportPoint(Camera, RootPart.Position)
                    local Distance = (Vector2.new(ScreenPosition.X, ScreenPosition.Y) - MouseLocation).Magnitude
    
                    if OnScreen and Distance < Current.Distance then
                        Current.Character = Character
                        Current.Distance = Distance
                    end
                end
            end 
        elseif Targetting == "NPC" then
            for Index, Character in Missions.GetDescendants(Missions) do
                local RootPart = Character.FindFirstChild(Character, "HumanoidRootPart") or nil

                if RootPart then
                    local ScreenPosition, OnScreen = Camera.WorldToViewportPoint(Camera, RootPart.Position)
                    local Distance = (Vector2.new(ScreenPosition.X, ScreenPosition.Y) - MouseLocation).Magnitude
    
                    if OnScreen and Distance < Current.Distance then
                        Current.Character = Character
                        Current.Distance = Distance
                    end
                end
            end
        end
    
        return Current.Character
    end

    GenerateKey = function(Watermark, Length)
        local Key = string.format("%s: ", Watermark)
        local Alphabet = "ABCDEFGHIJKLMNOPQRSTUVXYZ1234567890"

        for Number = 1, Length do
            local Index = math.random(1, #Alphabet)
            local Letter = string.sub(Alphabet, Index, Index)

            Key = string.format("%s%s", Key, Letter)
        end

        return Key
    end

    UpdateCrates = function()
        local List = {}

        for Index, Crate in Entities:GetChildren() do
            local LootGiver = Crate:FindFirstChild("LootGiver") or nil
            local Opened = LootGiver and LootGiver:GetAttribute("Opened") or nil
            local MaxCanOpen = LootGiver and LootGiver:GetAttribute("MaxCanOpen") or nil
            local OpenedBy = LootGiver and LootGiver:GetAttribute("OpenedBy") or nil
            local OpenedList = OpenedBy and string.split(OpenedBy, ",") or nil
    
            if table.find({"WagonLoot", "Infantry"}, Crate.Name) and (Opened and MaxCanOpen and Opened < MaxCanOpen or MaxCanOpen and not Opened) and (OpenedList and not table.find(OpenedList, LocalPlayer.Name) or not OpenedBy) then
                if not Crate:GetAttribute("ID") then
                    Crate:SetAttribute("ID", GenerateKey("Crate", 8))
                end
                
                table.insert(List, Crate:GetAttribute("ID"))
            end
        end

        return List
    end
end

Entities.DescendantAdded:Connect(function(Descendant)
    if Vars.NotifyChest and Descendant.Name == "WagonLoot" then
        Notify.new("Crate has spawned", 1)
    end
end)

UserInputService.InputEnded:Connect(function(Input)
    if UserInputService:GetFocusedTextBox() then
        return
    end

    if Vars.MapApparate and Input.UserInputType == Enum.UserInputType.MouseButton1 then
        local Character = LocalPlayer.Character or nil
        local DashCD = Character and Character:GetAttribute("DashCD") or 0
        local DashStamina = Character and Character:GetAttribute("DashStamina") or 0

        local MapUI = getupvalue(MapModule.ShowCatagory, 1)
        local MouseConnection = MapUI and getconnection(MapUI.Frame.ImageLabel.ImageButton.MouseButton1Up, 1) or nil
        local MapToWorld = MouseConnection and getupvalue(MouseConnection.Function, 3) or nil

        if Character and Workspace:GetServerTimeNow() > DashCD and DashStamina >= 33 and MapUI.Enabled and MapToWorld and not MapModule.CheckIfApparating() then
            local WorldPosition = MapToWorld()
            MapModule.ShowCatagory()

            pcall(LocalPlayer.RequestStreamAroundAsync, LocalPlayer, WorldPosition) -- basically load in everything so that I don't fall through the map lmao
            pcall(LocalPlayer.RequestStreamAroundAsync, LocalPlayer, WorldPosition + Vector3.yAxis * 100)
            pcall(LocalPlayer.RequestStreamAroundAsync, LocalPlayer, WorldPosition - Vector3.yAxis * 100)

            local Result = Raycast(WorldPosition + Vector3.yAxis * 800, WorldPosition - Vector3.yAxis * 800, Character)
            if Result then
                DashEvent:FireServer("DashForward")

                task.wait(0.1)

                Character:PivotTo(CFrame.new(Result.Position + Vector3.yAxis * 3))
                ApparateModule.ApparateVFX(Character, nil, true)
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    Cache.MouseLocation = UserInputService:GetMouseLocation()

    if UIObjects["Crate Dropdown"] then
        UIObjects["Crate Dropdown"]:Update(UpdateCrates())
    end

    if Vars.AntiArrest and LocalPlayer:GetAttribute("Jailed") then
        JailModule.ToggleJailed()
    end

    if Vars.MapOutlaws then
        local PlayerGui = LocalPlayer.PlayerGui or nil
        local Map = PlayerGui and PlayerGui:FindFirstChild("Map") or nil
        local Frame = Map and Map:FindFirstChild("Frame") or nil
        local ImageLabel = Frame and Frame:FindFirstChild("ImageLabel") or nil

        if ImageLabel then
            for _, Icon in ImageLabel:GetChildren() do
                if Icon.Name == "PlayerMarker" and not Icon.Crown.Visible then
                    local Player = nil do
                        for Name, Marker in getupvalue(MapModule.UpdatePositions, 3) do
                            if Marker == Icon then
                                Player = Players:FindFirstChild(Name) or nil
                            end
                        end
                    end
                    
                    if Player and (Player:GetAttribute("Bounty") or 0) > 0 then
                        Icon.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                    end
                end
            end
        end
    end
end)

local Old = nil
Old = hookfunction(CrateModule.BeginSpin, function(...)
    local Array = table.pack(...)

    if Vars.InstantSpin then
        Array[4] = 0
    end

    return Old(table.unpack(Array))
end)

local Old = nil
Old = hookmetamethod(game, "__newindex", function(Self, Index, Value)
    if Vars.SpeedModifier and Self:IsA("LinearVelocity") and Index == "VectorVelocity" and LocalPlayer.Character:GetAttribute("JetPacking") == "Broom" then
        local NewVelocity = Value * Vars.SpeedMultiplier

        if NewVelocity.Magnitude > Vars.SpeedMaximum then
            Value = NewVelocity.Unit * Vars.SpeedMaximum
        end

        Value = NewVelocity
    end

    return Old(Self, Index, Value)
end)

local Old = nil
Old = hookmetamethod(game, "__namecall", function(Self, ...)
    local Array = table.pack(...)
    local Method = getnamecallmethod()

    if Method == "FireServer" and Self.Name == "ToolListnerEvent" then
        Cache.Casting = typeof(Array[4]) == "Instance" and Array[4].Name or ""
    end

    if Vars.WandAimbot and Method == "FireServer" and Self.Name == "ToolListnerEvent" and Array[1] == "Activate" then
        local Character = FetchPlayerInFOV(Vars.AimbotTargetting, Vars.WandAimbotFOV, Cache.MouseLocation)
        local RootPart = Character and Character.PrimaryPart or nil

        if Character and RootPart then
            Array[2] = RootPart.Position
            -- Array[3] = RootPart.Position
            Array[5] = {RootPart.Position}
            Array[6] = {
                {
                    RootPart,
                    RootPart.Position,
                    Vector3.new(-0.86, 0, -0.49),
                    "Humanoid",
                }
            }

            Array[7] = {Character.Humanoid}
        end
    end

    if Vars.SpellAimbot and Method == "FireServer" and Self.Name == "SpellClientFire" and table.find(Spells, Cache.Casting) then
        local Character = FetchPlayerInFOV(Vars.AimbotTargetting, Vars.SpellAimbotFOV, Cache.MouseLocation)
        local RootPart = Character and Character.PrimaryPart or nil

        if Character and RootPart then
            Array[1] = RootPart.Position
            Array[3] = Character

            if Vars.OnlyLightning and not table.find(Lightning, Cache.Casting) then
                return Old(Self, table.unpack(Array))
            end

            if Vars.SpellWallbang then
                local Result = Raycast(Array[1], Array[1] + Vector3.yAxis * 20, Character)

                if Result then
                    Array[2] = Result.Position + Result.Normal * Vector3.yAxis
                else
                    Array[2] = Array[1] + Vector3.yAxis * 20
                end
                
                if RootPart.Velocity.Magnitude > 2 then
                    Array[2] = RootPart.Position - RootPart.Velocity / 6
                end
            end
        end
    end

    if Vars.SpellAimbot and Method == "FireServer" and Self.Name == "ClientFire" and table.find(Guns, Cache.Casting) then
        local Character = FetchPlayerInFOV(Vars.AimbotTargetting, Vars.SpellAimbotFOV, Cache.MouseLocation)
        local RootPart = Character and Character.PrimaryPart or nil

        if Character and RootPart then
            Array[1] = RootPart.Position

            if Vars.SpellWallbang then
                local Result = Raycast(Array[1], Array[1] + Vector3.yAxis * 20, Character)

                if Result then
                    Array[2] = Result.Position + Result.Normal * Vector3.yAxis
                else
                    Array[2] = Array[1] + Vector3.yAxis * 20
                end
                
                if RootPart.Velocity.Magnitude > 2 then
                    Array[2] = RootPart.Position - RootPart.Velocity / 6
                end
            end
        end
    end

    return Old(Self, table.unpack(Array))
end)

local Menu = Library.new("Salmon Client") do
    local Tabs = Menu.WindowTab("Window")

    local Combat = Tabs.SideTab("Combat", 2.8) do
        local Global = Combat.Section("Global") do
            Global.Dropdown("Targetting", {"Player", "NPC"}, function(Value)
                Vars.AimbotTargetting = Value
            end)
        end

        local Wand = Combat.Section("Wand") do
            Wand.Toggle("Aimbot", function(Boolean)
                Vars.WandAimbot = Boolean
            end)

            Wand.Slider("Aimbot FOV", 0, 360, Vars.WandAimbotFOV, function(Int)
                Vars.WandAimbotFOV = Int
            end)
        end

        local Spells = Combat.Section("Spells") do
            Spells.Toggle("Aimbot", function(Boolean)
                Vars.SpellAimbot = Boolean
            end)

            Spells.Toggle("Only Lightning", function(Boolean) -- Something I did just because I wanted to use infinite range on electrificus and inlisus
                Vars.OnlyLightning = Boolean
            end)

            Spells.Slider("Aimbot FOV", 0, 360, Vars.SpellAimbotFOV, function(Int)
                Vars.SpellAimbotFOV = Int
            end)

            Spells.Toggle("Wallbang", function(Boolean)
                Vars.SpellWallbang = Boolean
            end)
        end
    end
    
    local World = Tabs.SideTab("World", 2.8) do
        local Character = World.Section("Character") do
            Character.Toggle("Anti Arrest", function(Boolean)
                Vars.AntiArrest = Boolean
            end)

            Character.Toggle("Map Apparate", function(Boolean)
                Vars.MapApparate = Boolean
            end)
        end

        local Broom = World.Section("Broom") do
            Broom.Toggle("Speed Modifier", function(Boolean)
                Vars.SpeedModifier = Boolean
            end)

            Broom.Slider("Multiplier", 0, 5, Vars.SpeedMultiplier, function(Int)
                Vars.SpeedMultiplier = Int
            end)

            Broom.Slider("Maximum", 0, 350, Vars.SpeedMaximum, function(Int)
                Vars.SpeedMaximum = Int
            end)
        end

        local Visuals = World.Section("Visuals") do
            Visuals.Toggle("Map Outlaws", function(Boolean)
                Vars.MapOutlaws = Boolean
            end)

            Visuals.Toggle("Instant Spin", function(Boolean)
                Vars.InstantSpin = Boolean
            end)

            Visuals.Toggle("Notify Crate", function(Boolean)
                Vars.NotifyChest = Boolean
            end)

            UIObjects["Crate Dropdown"] = Visuals.Dropdown("Chests", {}, function(Value)
                local Character = LocalPlayer.Character or nil
                local RootPart = Character and Character.PrimaryPart or nil

                if Character and RootPart then
                    for Index, Crate in Entities:GetChildren() do
                        local LootGiver = Crate:FindFirstChild("LootGiver") or nil
                        local ID = Crate:GetAttribute("ID") or nil
    
                        if LootGiver and ID == Value then
                            local Coordinates = Character:GetPivot()   

                            for Number = 1, 30 do
                                Pivot(Character, Crate:GetPivot() - Vector3.yAxis * 8)

                                task.wait()
                            end
            
                            RootPart.Anchored = true
            
                            fireproximityprompt(Crate.LootGiver)
                            task.wait(0.5)
            
                            RootPart.Anchored = false
                            Pivot(Character, Coordinates)
                        end
                    end
                end
            end)
        end
    end
    
    local Configuration = Tabs.SideTab("Configuration", 2.8) do
        local UI = Configuration.Section("UI") do
            UI.Button("Rejoin", function()
                Notify.new("Rejoining", 1)

                TeleportService:TeleportToPlaceInstance(Game.PlaceId, Game.JobId)
            end)
        end
    end
end

Ping(function()
    if Stats.Network.ServerStatsItem["Data Ping"]:GetValue() > 110 then
        Notify.new("High ping detected", 2)
    end
end)
