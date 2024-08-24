local Iris = loadstring(game:HttpGet("https://raw.githubusercontent.com/theonlylegacy/Libraries/main/Linoria.lua"))()()
local Services = setmetatable({}, {__index = function(...)
	return game:GetService(select(2, ...))
end})

local Players = Services.Players
local ReplicatedStorage = Services.ReplicatedStorage
local CoreGui = Services.CoreGui
local ProximityPromptService = Services.ProximityPromptService
local Workspace = Services.Workspace

local Client = Players.LocalPlayer

local Server = Workspace:WaitForChild("Server", true)
local RoundHandler = Server:WaitForChild("RoundHandler", true)
local Mode = RoundHandler:WaitForChild("Mode", true)
local GameMode = RoundHandler:WaitForChild("GameMode", true)

local GlobalEvents = ReplicatedStorage:WaitForChild("GlobalEvents", true)
local HitPlayer = GlobalEvents:WaitForChild("HitPlayer", true)

local Ticks = {}
local Threads = {}
local Connections = {}
local Cheats = {
	["Infinite Stamina"] = false,
    ["Infinite Range"] = false,
    ["Instant Interact"] = false,
	["Kill Aura"] = false,
	["No Stun"] = false,
	["No Grab"] = false,
    ["Always Earn"] = false,
	["Automatic Earn"] = false,
	["Automatic Heal"] = false,
	["Highlight Monsters"] = false,
	["Highlight Objectives"] = false,
}

local ServerInfo = {
	RoundActive = false,
	RoundMode = "",
	Map = nil,
}

local function CreateKey(Watermark)
	local Characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
	local Key = Watermark .. ": 0x"

	for Length = 1, 8 do
		local Number = math.random(1, #Characters)
		Key = Key .. string.sub(Characters, Number, Number)
	end

	return Key
end

local function AddThread(Function)
	local Key = CreateKey("THREAD")
	Threads[Key] = task.spawn(Function)

	return Threads[Key]
end

local function RemoveThread(Key)
	if Threads[Key] then
		task.cancel(Threads[Key])
	end
end

local function AddConnection(Connection)
	local Key = CreateKey("CONNECTION")
	Connections[Key] = Connection

	return Connections[Key]
end

local function RemoveConnection(Key)
	if Connections[Key] then
		Connections[Key]:Disconnect()
	end
end

local function GetMonsters()
	local Monsters = {}
    local PrimaryMonster = RoundHandler.PlrMonster.Value 
    local SecondaryMonster = RoundHandler.PlrMonster2.Value

    if PrimaryMonster ~= nil then
        Monsters[#Monsters + 1] = PrimaryMonster
    end

    if SecondaryMonster ~= nil then
        Monsters[#Monsters + 1] = SecondaryMonster
    end

	return Monsters
end

local function FireProximityPrompt(ProximityPrompt, Amount)
	if ProximityPrompt:IsA("ProximityPrompt") then
		local Time = ProximityPrompt.HoldDuration
		ProximityPrompt.HoldDuration = 0

		for Number = 1, Amount do
			ProximityPrompt:InputHoldBegin()
			ProximityPrompt:InputHoldEnd()
		end

		ProximityPrompt.HoldDuration = Time
	end
end

local function PlaceHighlight(Parent, Color)
	local Object = Instance.new("Part")
	Object.Position = Parent:GetPivot().Position
	Object.Size = Vector3.new(1.5, 1.5, 1.5)
	Object.Transparency = 0
	Object.Anchored = true
	Object.CanCollide = false
	Object.Name = "IrisHighlight"
	Object.Parent = Parent

	local Highlight = Instance.new("Highlight")
	Highlight.FillColor = Color
	Highlight.OutlineColor = Color
	Highlight.FillTransparency = 0
	Highlight.Parent = Object
end

local function Hit(Part, Sound)
	if Ticks.Hit == nil then
		Ticks.Hit = tick()
	end

	if tick() - Ticks.Hit >= 1.4 then
		HitPlayer:FireServer(Part, "RosemaryAttack", Sound, "RosemaryDamage")
		Ticks.Hit = nil
	end
end

local MainThread = AddThread(function()
	while true do
		ServerInfo.RoundActive = Mode.Value ~= "Intermission"
		ServerInfo.RoundMode = GameMode.Value
		ServerInfo.Map = Workspace:FindFirstChild("Map")

		do
			local Character = Client.Character
			local Torso = Character and Character:FindFirstChild("Torso")
			local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")
			local Aspects = Character and Character:FindFirstChild("Aspects")
            local IsPlayer = Character and Character:FindFirstChild("IsPlayer")
			local Monsters = GetMonsters()
	
			if Aspects then
				if Cheats["Infinite Stamina"] and Aspects:FindFirstChild("Stamina") and Aspects.Stamina:FindFirstChild("Max") then
					Aspects.Stamina.Value = Aspects.Stamina.Max.Value - 1 --Detection matter
				end

				if Cheats["No Stun"] then
					if Aspects:FindFirstChild("Stunned") then
						Aspects.Stunned.Value = false
					end

					if Aspects:FindFirstChild("DanceMeter") then
						Aspects.DanceMeter.Value = 0
					end
				end

				if Cheats["No Grab"] then
					if Aspects:FindFirstChild("BeingGrabbed") then
						Aspects.BeingGrabbed.Value = nil
					end

					if Aspects:FindFirstChild("GrabDLY") then
						Aspects.GrabDLY.Value = false
					end

					if Aspects:FindFirstChild("BeingJumpscared") then
						Aspects.BeingJumpscared.Value = false
					end
				end

				if Cheats["Automatic Heal"] and Aspects:FindFirstChild("Health") and Aspects.Health:FindFirstChild("Max") then
					if Aspects.Health.Value < Aspects.Health.Max.Value then
						for _, Descendant in Character:GetDescendants() do
							if Descendant:IsA("RemoteEvent") and Descendant.Name == "HealSelf" then
								Descendant:FireServer()
							end
						end
					end
				end

				if table.find(Monsters, Client) then
					for Index, Player in Players:GetPlayers() do
						if table.find(Monsters, Player) or not Player.Character or Player.Character and not Player.Character:FindFirstChild("Aspects") then
							continue
						end

						if Cheats["Kill Aura"] then
							local Distance = (HumanoidRootPart.Position - Player.Character.HumanoidRootPart.Position).Magnitude
							local Sounds = {
								[1] = Torso.Hit1,
								[2] = Torso.Hit2,
								[3] = Torso.Hit3,
								[4] = Torso.Hit4,
							}

							if Player.Character.Aspects:FindFirstChild("Alive") and Player.Character.Aspects.Alive.Value == true and Distance <= 13 then
								Hit(Player.Character.Head, Sounds[math.random(1, #Sounds)])
							end
						end

						if Cheats["Highlight Objectives"] then
							if Player.Character:FindFirstChild("IrisHighlight") then
								continue
							end

							local Highlight = Instance.new("Highlight")
							Highlight.FillColor = Color3.fromRGB(0, 255, 0)
							Highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
							Highlight.FillTransparency = 0
							Highlight.Name = "IrisHighlight"
							Highlight.Parent = Player.Character
						else
							if not Player.Character:FindFirstChild("IrisHighlight") then
								continue
							end

							Player.Character.IrisHighlight:Destroy()
						end
					end
				end
			end

            if IsPlayer then
                if Cheats["Always Earn"] and IsPlayer:FindFirstChild("CanEarn") and Client:FindFirstChild("PlayerGui") then
                    for _, Descendant in Client.PlayerGui:GetDescendants() do
                        if Descendant:IsA("RemoteEvent") and Descendant.Name == "EarnSwap" and Descendant.Parent.Name == "EarningBar" then
                            Descendant:FireServer(true)
                        end
                    end
                end

				if Cheats["Automatic Earn"] and Client:FindFirstChild("CoinsToGive") and Client:FindFirstChild("PlayerGui") then
					for _, Descendant in Client.PlayerGui:GetDescendants() do
                        if Descendant:IsA("RemoteEvent") and Descendant.Name == "GiveTime" and Descendant.Parent.Name == "WorkGui" and Client.CoinsToGive.Value < 55 then
                            Descendant:FireServer(55 - Client.CoinsToGive.Value)
                        end
                    end
				end
            end

			if #Monsters > 0 then
				for Index, Player in Monsters do
					if Player == Client or not Player.Character or Player.Character and not Player.Character:FindFirstChild("Aspects") then
						continue
					end

					if Cheats["Highlight Monsters"] and Aspects then
						if Player.Character:FindFirstChild("IrisHighlight") then
							continue
						end

						local Highlight = Instance.new("Highlight")
						Highlight.FillColor = Color3.fromRGB(255, 0, 0)
						Highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
						Highlight.FillTransparency = 0
						Highlight.Name = "IrisHighlight"
						Highlight.Parent = Player.Character
					else
						if not Player.Character:FindFirstChild("IrisHighlight") then
							continue
						end
						
						Player.Character.IrisHighlight:Destroy()
					end
				end
			end

			if ServerInfo.Map then
				local PrimaryObjectives = ServerInfo.Map:FindFirstChild("ObjectiveInteract")
				local SecondaryObjectives = ServerInfo.Map:FindFirstChild("ObjectiveInteract2")

				if PrimaryObjectives then
					for _, Descendant in PrimaryObjectives:GetDescendants() do
                        local ProximityPrompt = Descendant:FindFirstChildOfClass("ProximityPrompt")

						if not ProximityPrompt then
							if Descendant:FindFirstChild("IrisHighlight") then
								Descendant.IrisHighlight:Destroy()
							end

							continue
						end

                        if Cheats["Infinite Range"] and Aspects and not table.find(Monsters, Client) then
                            ProximityPrompt.MaxActivationDistance = 9e9
                        else
                            ProximityPrompt.MaxActivationDistance = 4
                        end

						if Cheats["Highlight Objectives"] and Aspects and not table.find(Monsters, Client) then
							if not Descendant:FindFirstChild("IrisHighlight") then
								PlaceHighlight(Descendant, Color3.fromRGB(0, 255, 0))
							end
						else
							if Descendant:FindFirstChild("IrisHighlight") then
								Descendant.IrisHighlight:Destroy()
							end
						end
					end
				end

				if SecondaryObjectives then
					for _, Descendant in SecondaryObjectives:GetDescendants() do
                        local ProximityPrompt = Descendant:FindFirstChildOfClass("ProximityPrompt")

						if not ProximityPrompt then
							if Descendant:FindFirstChild("IrisHighlight") then
								Descendant.IrisHighlight:Destroy()
							end

							continue
						end

                        if Cheats["Infinite Range"] and Aspects and not table.find(Monsters, Client) then
                            ProximityPrompt.MaxActivationDistance = 9e9
                        else
                            ProximityPrompt.MaxActivationDistance = 4
                        end

						if Cheats["Highlight Objectives"] and Aspects and not table.find(Monsters, Client) then
							if not Descendant:FindFirstChild("IrisHighlight") then
								PlaceHighlight(Descendant, Color3.fromRGB(255, 255, 0))
							end
						else
							if Descendant:FindFirstChild("IrisHighlight") then
								Descendant.IrisHighlight:Destroy()
							end
						end
					end
				end
			end
		end

		task.wait()
	end
end)

AddConnection(ProximityPromptService.PromptButtonHoldBegan:Connect(function(ProximityPrompt)
	if Cheats["Instant Interact"] then
		FireProximityPrompt(ProximityPrompt, 2)
	end
end))

local Window = Iris:CreateWindow({Title = CreateKey("Iris"), Center = true, AutoShow = true, TabPadding = 15}) do
	local Main = Window:AddTab("Main") do
		local MainGroupbox = Main:AddLeftGroupbox("Groupbox") do
			MainGroupbox:AddToggle("", {
				Text = "Infinite Stamina", 
				Default = Cheats["Infinite Stamina"], 
				Callback = function(Boolean) 
					Cheats["Infinite Stamina"] = Boolean
				end
			})
	
			MainGroupbox:AddToggle("", {
				Text = "Infinite Range", 
				Default = Cheats["Infinite Range"], 
				Callback = function(Boolean) 
					Cheats["Infinite Range"] = Boolean
				end
			})
	
			MainGroupbox:AddToggle("", {
				Text = "Instant Interact", 
				Default = Cheats["Instant Interact"], 
				Callback = function(Boolean) 
					Cheats["Instant Interact"] = Boolean
				end
			})
	
			MainGroupbox:AddToggle("", {
				Text = "Kill Aura", 
				Default = Cheats["Kill Aura"], 
				Callback = function(Boolean) 
					Cheats["Kill Aura"] = Boolean
				end
			})
	
			MainGroupbox:AddToggle("", {
				Text = "No Stun", 
				Default = Cheats["No Stun"], 
				Callback = function(Boolean) 
					Cheats["No Stun"] = Boolean
				end
			})
	
			MainGroupbox:AddToggle("", {
				Text = "No Grab", 
				Default = Cheats["No Grab"], 
				Callback = function(Boolean) 
					Cheats["No Grab"] = Boolean
				end
			})
	
			MainGroupbox:AddToggle("", {
				Text = "Always Earn", 
				Default = Cheats["Always Earn"], 
				Callback = function(Boolean) 
					Cheats["Always Earn"] = Boolean
				end
			})
	
			MainGroupbox:AddToggle("", {
				Text = "Automatic Earn", 
				Default = Cheats["Automatic Earn"], 
				Callback = function(Boolean) 
					Cheats["Automatic Earn"] = Boolean
				end
			})
	
			MainGroupbox:AddToggle("", {
				Text = "Automatic Heal", 
				Default = Cheats["Automatic Heal"], 
				Callback = function(Boolean) 
					Cheats["Automatic Heal"] = Boolean
				end
			})
	
			MainGroupbox:AddToggle("", {
				Text = "Highlight Monsters", 
				Default = Cheats["Highlight Monsters"], 
				Callback = function(Boolean) 
					Cheats["Highlight Monsters"] = Boolean
				end
			})
	
			MainGroupbox:AddToggle("", {
				Text = "Highlight Objectives", 
				Default = Cheats["Highlight Objectives"], 
				Callback = function(Boolean) 
					Cheats["Highlight Objectives"] = Boolean
				end
			})
		end
	end

	local Settings = Window:AddTab("Settings") do
		local SettingsGroupbox = Settings:AddLeftGroupbox("Groupbox") do
			SettingsGroupbox:AddLabel("Hide"):AddKeyPicker("", {
				Default = "",
				Text = "",
				NoUI = true,
				Callback = function(Value)
					task.spawn(Iris.Toggle)
				end
			})

			SettingsGroupbox:AddButton({
				Text = "Unload", 
				DoubleClick = true,
				Func = function()
					for Index, Boolean in Cheats do
						Cheats[Index] = false
					end
			
					task.wait(0.1)
			
					for Key, Thread in Threads do
						RemoveThread(Key)
					end
			
					for Key, Connection in Connections do
						RemoveConnection(Key)
					end
			
					CoreGui.imgui:Destroy()
					table.clear(Threads)
					table.clear(Connections)
					table.clear(Cheats)
					table.clear(ServerInfo)
				end
			})
		end
	end
end
