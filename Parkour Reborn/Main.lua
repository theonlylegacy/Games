--// I know that it is a very unique way of putting it and now i see that this script isnt the best
--[[
Working on: Rewrite
Features: {{

CLIENT TAB
Entity:
    Infinite Respawns
    Infinite Actions
    Always Perfect
    Always Momentum
    Fast Slide
    Fly
    No Damage (God mode)

Animation Select:
    Play
    Fidgets (Shiver, Stetch, Leg Stretch, Jumping Jacks, Shadow Jog?, Wipe Shoe)

Travel Select:
    Travel
    Destinations (Julian, Derek, Petra)

Player Select
    Highlight Entity
    Travel to Entity
    Travel to Checkpoint
    Players

Grappler:
    Fast Pull
    Always Swing
    Infinite Ammo
    Infinite Distance
    Instant Reach

WORLD TAB
Farm:
    Valuables
    Deliveries
    Auto Sell
    Auto Loot

SETTINGS TAB
Internal:
    Unload
    Cache (Running Thread(s), Running Connection(s))
}}
]]

local Linoria = loadstring(request({Url = "https://raw.githubusercontent.com/theonlylegacy/Libraries/main/Linoria.lua", Method = "GET"}).Body){}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local UserInputService = game:GetService("UserInputService")

local Client = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local FrameworkEnv = getsenv(ReplicatedFirst.Framework)
local MainSettings = debug.getupvalue(FrameworkEnv.loadCharacter, 5)
local GrapplerSettings = debug.getupvalue(FrameworkEnv.loadCharacter, 11).grappler
local CharacterSettings = debug.getupvalue(FrameworkEnv.loadCharacter, 6)

local ScriptEnv = {
    Signals = {},
    Funcs = {},
    Storage = {},
    Values = {
        Target,
        Character = {WalkSpeed = 12},
        Gear = {Force = 35, Distance = 90, Speed = 300}
    },
}

function ScriptEnv.Funcs:Teleport(Position)
    if Client.Character and Client.Character:FindFirstChild("HumanoidRootPart") then
        Client.Character.HumanoidRootPart.CFrame = CFrame.new(Position)
    end
end

function ScriptEnv.Funcs:ModifyValue(Boolean, TargetValue, Value)
    if Boolean then
        ScriptEnv.Storage[TargetValue] = GrapplerSettings[TargetValue]
        GrapplerSettings[TargetValue] = Value
    elseif (not Boolean) then
        GrapplerSettings[TargetValue] = ScriptEnv.Storage[TargetValue]
    end
end

function ScriptEnv.Funcs:DumpData(Player)
    local DataFolder = ReplicatedStorage.PlayerData[Player.Name]
    local RuntimeFolder = ReplicatedStorage.PlayerRuntimeData[Player.Name]

    if DataFolder and RuntimeFolder then
        local Records = {}
        for _, Record in next, DataFolder.Records.TimeTrials:GetChildren() do
            if Record.Value ~= 0 then
                Records[workspace.TimeTrials[Record.Name]:GetAttribute("DisplayName")] = math.floor(Record.Value)
            end
        end

        local RecordString = ""
        table.foreach(Records, function(Trial, Value)
            if RecordString ~= "" then
                RecordString = `{RecordString} {Trial}: {Value}`
            else
                RecordString = `{Trial}: {Value}`
            end
        end)

        writefile(`{Player.Name}-{crypt.generatebytes(16)} data.txt`, `Level: {DataFolder.Level.Value}\nRank: {RuntimeFolder.Rank.Value}\nCredits: {RuntimeFolder.Credits.Value}\nTokens: {DataFolder.Tokens.Value}\nTrial times: [{RecordString}]\nParty: [{DataFolder.Party.Value}]`)
    end
end

function ScriptEnv.Funcs:Initiate(Func, Bool)
    local Funcs = {
        ["InfiniteCapacity"] = function(Boolean)
            if Boolean then
                ScriptEnv.Storage["Ammo"] = GrapplerSettings.ammo
                ScriptEnv.Signals["InfiniteCapacity"] = RunService.RenderStepped:Connect(function()
                    GrapplerSettings.ammo = ScriptEnv.Storage["Ammo"]
                end)
            elseif (not Boolean) then
                if ScriptEnv.Signals["InfiniteCapacity"] and ScriptEnv.Signals["InfiniteCapacity"].Connected then
                    ScriptEnv.Signals["InfiniteCapacity"]:Disconnect()
                end
            end
        end,

        ["SwingFunc"] = function(Boolean)
            if Boolean then
                ScriptEnv.Signals["SwingFunc"] = RunService.RenderStepped:Connect(function()
                    GrapplerSettings.canSwingOn = true
                end)
            elseif (not Boolean) then
                if ScriptEnv.Signals["SwingFunc"] and ScriptEnv.Signals["SwingFunc"].Connected then
                    ScriptEnv.Signals["SwingFunc"]:Disconnect()
                end
            end
        end,

        ["InfiniteRespawns"] = function(Boolean)
            if Boolean then
                ScriptEnv.Storage["Budget"] = MainSettings.respawnBudget
                ScriptEnv.Signals["InfiniteRespawns"] = RunService.RenderStepped:Connect(function()
                    MainSettings.respawnBudget = 100
                end)
            elseif (not Boolean) then
                if ScriptEnv.Signals["InfiniteRespawns"] and ScriptEnv.Signals["InfiniteRespawns"].Connected then
                    ScriptEnv.Signals["InfiniteRespawns"]:Disconnect()
                end

                MainSettings.respawnBudget = ScriptEnv.Storage["Budget"]
            end
        end,

        ["WalkSpeed"] = function(Boolean)
            if Boolean then
                ScriptEnv.Storage["WalkSpeed"] = CharacterSettings.WalkSpeed
                ScriptEnv.Signals["WalkSpeed"] = RunService.RenderStepped:Connect(function()
                    CharacterSettings.WalkSpeed = ScriptEnv.Values.Character.WalkSpeed
                end)
            elseif (not Boolean) then
                if ScriptEnv.Signals["WalkSpeed"] and ScriptEnv.Signals["WalkSpeed"].Connected then
                    ScriptEnv.Signals["WalkSpeed"]:Disconnect()
                end

                CharacterSettings.WalkSpeed = ScriptEnv.Storage["WalkSpeed"]
            end
        end,

        ["FastSlide"] = function(Boolean)
            if Boolean then
                for _, Table in next, getgc(true) do
                    if type(Table) == "table" and rawget(Table, "powerslide") then
                        local Slide = rawget(Table, "powerslide")

                        if type(Slide) == "table" and Slide.active ~= nil then
                            ScriptEnv.Signals["FastSlide"] = RunService.RenderStepped:Connect(function()
                                if Client.Character and Client.Character:FindFirstChild("HumanoidRootPart") and Slide.active then
                                    local RootPart = Client.Character.HumanoidRootPart

                                    RootPart.Velocity = RootPart.Velocity + (RootPart.CFrame.LookVector * 8)
                                end
                            end)

                            break
                        end
                    end
                end
            elseif (not Boolean) then
                if ScriptEnv.Signals["FastSlide"] and ScriptEnv.Signals["FastSlide"].Connected then
                    ScriptEnv.Signals["FastSlide"]:Disconnect()
                end
            end
        end,
    }

    Funcs[Func](Bool)
end

function ScriptEnv.Funcs:PlayFidget(AssetId)
    if Client.Character and Client.Character:FindFirstChildWhichIsA("Humanoid") then
        local Humanoid = Client.Character:FindFirstChildWhichIsA("Humanoid")
        local Animation = Instance.new("Animation")
        Animation.AnimationId = AssetId

        local Track = Humanoid:LoadAnimation(Animation)
        Track:Play()

        ScriptEnv.Signals[Animation:GetDebugId()] = Track.Stopped:Connect(function()
            Animation:Destroy()
            ScriptEnv.Signals[Animation:GetDebugId()]:Disconnect()
            ScriptEnv.Signals[Animation:GetDebugId()] = nil
        end)

        while ScriptEnv.Signals[Animation:GetDebugId()] and ScriptEnv.Signals[Animation:GetDebugId()].Connected and RunService.RenderStepped:Wait() do
            if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.D) then
                if Track.IsPlaying then
                    Track:Stop()
                end
            end

            if Client.Character and Client.Character:FindFirstChildWhichIsA("Humanoid") then
                if Client.Character.Humanoid.Health == 0 then
                    if Track.IsPlaying then
                        Track:Stop()
                    end
                end
            else
                if Track.IsPlaying then
                    Track:Stop()
                end
            end
        end
    end
end

table.insert(ScriptEnv.Signals, RunService.RenderStepped:Connect(function()
    MainSettings = debug.getupvalue(FrameworkEnv.loadCharacter, 5)
    GrapplerSettings = debug.getupvalue(FrameworkEnv.loadCharacter, 11).grappler
    CharacterSettings = debug.getupvalue(FrameworkEnv.loadCharacter, 6)
end))

local Window = Linoria:CreateWindow({Title = "Parkour Reborn", Center = true, AutoShow = true, TabPadding = 15, Size = UDim2.fromOffset(750, 610)}) do
    local Movement = Window:AddTab("Movement") do
        local Character = Movement:AddLeftGroupbox("Character") do
            Character:AddToggle("", {Text = "Infinite Respawns", Default = false, Callback = function(Boolean) ScriptEnv.Funcs:Initiate("InfiniteRespawns", Boolean) end})
            Character:AddToggle("", {Text = "Fast Slide", Default = false, Callback = function(Boolean) ScriptEnv.Funcs:Initiate("FastSlide", Boolean) end})
            Character:AddToggle("", {Text = "WalkSpeed", Default = false, Callback = function(Boolean) ScriptEnv.Funcs:Initiate("WalkSpeed", Boolean) end})
            Character:AddSlider("", {Text = "Amount", Default = ScriptEnv.Values.Character.WalkSpeed, Min = 12, Max = 150, Rounding = 0, Compact = true, Callback = function(Number) ScriptEnv.Values.Character.WalkSpeed = Number end})
        end

        local Grappler = Movement:AddLeftGroupbox("Grappler") do
            Grappler:AddToggle("", {Text = "Infinite Capacity", Default = false, Callback = function(Boolean) ScriptEnv.Funcs:Initiate("InfiniteCapacity", Boolean) end})
            Grappler:AddToggle("", {Text = "Swing Function", Default = false, Callback = function(Boolean) ScriptEnv.Funcs:Initiate("SwingFunc", Boolean) end})
            Grappler:AddToggle("", {Text = "Force", Default = false, Callback = function(Boolean) ScriptEnv.Funcs:ModifyValue(Boolean, "pullForce", ScriptEnv.Values.Gear.Force) end})
            Grappler:AddSlider("", {Text = "Amount", Default = ScriptEnv.Values.Gear.Force, Min = 35, Max = 500, Rounding = 0, Compact = true, Callback = function(Number) ScriptEnv.Values.Gear.Force = Number end})
            Grappler:AddToggle("", {Text = "Distance", Default = false, Callback = function(Boolean) ScriptEnv.Funcs:ModifyValue(Boolean, "maxDistance", ScriptEnv.Values.Gear.Distance) end})            
            Grappler:AddSlider("", {Text = "Amount", Default = ScriptEnv.Values.Gear.Distance, Min = 90, Max = 15000, Rounding = 0, Compact = true, Callback = function(Number) ScriptEnv.Values.Gear.Distance = Number end})
            Grappler:AddToggle("", {Text = "Speed", Default = false, Callback = function(Boolean) ScriptEnv.Funcs:ModifyValue(Boolean, "speed", ScriptEnv.Values.Gear.Speed) end})
            Grappler:AddSlider("", {Text = "Amount", Default = ScriptEnv.Values.Gear.Speed, Min = 300, Max = 5000, Rounding = 0, Compact = true, Callback = function(Number) ScriptEnv.Values.Gear.Speed = Number end})
        end

        local Fidgets = Movement:AddLeftGroupbox("Fidgets") do
            Fidgets:AddButton({Text = "Shiver", Func = function() ScriptEnv.Funcs:PlayFidget("rbxassetid://15883465786") end})
            Fidgets:AddButton({Text = "Stretch", Func = function() ScriptEnv.Funcs:PlayFidget("rbxassetid://9756264915") end})
            Fidgets:AddButton({Text = "Jump", Func = function() ScriptEnv.Funcs:PlayFidget("rbxassetid://9756117735") end})
            Fidgets:AddButton({Text = "Jog", Func = function() ScriptEnv.Funcs:PlayFidget("rbxassetid://9756062346") end})
            Fidgets:AddButton({Text = "Shoe", Func = function() ScriptEnv.Funcs:PlayFidget("rbxassetid://9756398015") end})
        end
    end

    local PlayerList = Window:AddTab("Player List") do
        local List = PlayerList:AddMiddleGroupbox("List") do
            List:AddDropdown("List", {SpecialType = "Player", Compact = true, Callback = function(Player) if Player == nil then return end ScriptEnv.Values.Target = Players[Player] end})
            List:AddBlank(160)
            List:AddButton({Text = "Teleport to checkpoint", Func = function() ScriptEnv.Funcs:Teleport(workspace.World.Checkpoints[tostring(ReplicatedStorage.PlayerRuntimeData[ScriptEnv.Values.Target.Name].Checkpoint.Value)].Model.Blinky.Position) end})
            List:AddButton({Text = "Dump data", Func = function() ScriptEnv.Funcs:DumpData(ScriptEnv.Values.Target) end})
        end
    end

    local Settings = Window:AddTab("Settings") do
        local Panel = Settings:AddLeftGroupbox("Panel") do
            Panel:AddLabel("Hide"):AddKeyPicker("", {Text = "", Default = "", NoUI = true, Callback = function() task.spawn(Linoria.Toggle) end})
            Panel:AddToggle("Keybinds", {Text = "Keybinds", Default = false, Callback = function(Boolean) Linoria.KeybindFrame.Visible = Boolean end})
        end
    end
end
