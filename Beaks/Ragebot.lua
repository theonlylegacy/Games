-- sero.. make a ragebot for this game

local RunService = Game:GetService("RunService")
local Players = Game:GetService("Players")
local ReplicatedStorage = Game:GetService("ReplicatedStorage")

local Regions = Workspace.Regions
local LocalPlayer = Players.LocalPlayer

local RunService = Game:GetService("RunService")
local Players = Game:GetService("Players")
local ReplicatedStorage = Game:GetService("ReplicatedStorage")

local Regions = Workspace.Regions
local LocalPlayer = Players.LocalPlayer
local Packages = ReplicatedStorage.Packages
local Assets = ReplicatedStorage.Assets
local Darts = Assets.Darts

local Aether = require(Packages.Aether)

local DataController = Aether.GetController("DataController")
local GunController = Aether.GetController("GunController")
local BirdController = Aether.GetController("BirdController")

local Net = require(Aether.GetUtil("Net"))
local FastCastRedux = require(Aether.GetUtil("FastCastRedux"))
local SmoothShiftLock = require(Aether.GetUtil("SmoothShiftLock"))
local Guns = require(Aether.GetConfig("Guns"))


local GunSE = Net:RemoteEvent("GunSE")
local FastCaster = FastCastRedux.new()

local Objects = {Storage = {}}
local Records = {
	Times = {},
	Hits = {},
	Tracers = {},
}

function Objects:Create(Name, Type, Properties)
	local Object = Instance.new(Type)
	Object.Name = Name
	
	for Key, Value in Properties do 
		Object[Key] = Value
	end
	
	Objects.Storage[Object] = Object
	return Object
end

function Objects:Remove(Obj)
	for Key, Object in Objects.Storage do 
		if Object == Obj then 
			Object:Destroy()
			Objects.Storage[Object] = nil
			
			break
		end
	end
end

local GetEntitylist = function(Type)
    local Tabel = nil

	for _, Folder in Regions:GetChildren() do
		local ClientBirds = Folder:FindFirstChild(Type) or nil
		local Children = ClientBirds and ClientBirds:GetChildren() or nil

		if not (Children and #Children > 0) then
			continue
		end

		Tabel = Children
	end

    return Tabel
end

local CreateBeam = function(Origin, Destination)
	local Attachment0 = Objects:Create("StartAttachment", "Attachment", {
		Position = Origin,
		Parent = Workspace.Terrain,
	})

	local Attachment1 = Objects:Create("GoalAttachment", "Attachment", {
		Position = Destination,
		Parent = Workspace.Terrain,
	})

	local Beam = Objects:Create("TracerBeam", "Beam", {
		Enabled = true,
		FaceCamera = true,
		Texture = "rbxassetid://7136858729",
		TextureSpeed = 0,
		TextureLength = 1,
		LightEmission = 1,
		LightInfluence = 1,
		CurveSize0 = 0,
		CurveSize1 = 0,
		ZOffset = -1,
		Width0 = 0.5,
		Width1 = 0.5,
		Transparency = NumberSequence.new(0),
		Color = ColorSequence.new(Color3.fromRGB(0, 255, 255), Color3.new(0, 0, 0)),
		Attachment0 = Attachment0,
		Attachment1 = Attachment1,
		Parent = Workspace,
	})

	table.insert(Records.Tracers, {
		Time = tick(),
		LifeTime = 3,
		Width = 0.5,
		Beam = Beam,
		Objects = {Attachment0, Attachment1, Beam},
	})
end

local HitSound = function(SoundId)
	local Sound = Instance.new("Sound")
	Sound.SoundId = string.format("rbxassetid://%d", SoundId)
	Sound.Volume = 1
	Sound.Parent = Workspace
	Sound:Play()

	Sound.Ended:Once(function()
		Sound:Destroy()
	end)
end

Regions.DescendantRemoving:Connect(function(Bird)
	if not Records.Hits[Bird] then
		return
	end
	
	Records.Hits[Bird] = nil
end)

RunService.RenderStepped:Connect(function()
	local Character = LocalPlayer.Character or nil
	local Root = Character and Character:FindFirstChild("HumanoidRootPart") or nil

	if Character and Root then
		GunController:ConnectTorsoMovement(false)

		Root.CFrame = Root.CFrame * CFrame.Angles(0, 2, 0)
	end

	if #Records.Tracers > 0 then
		if not Records.Times["Tracers -> Update"] then
			Records.Times["Tracers -> Update"] = os.clock() + 0.05
		end

		if os.clock() >= Records.Times["Tracers -> Update"] then
			for Index, Data in Records.Tracers do
				local DestroyTime = Data.Time + Data.LifeTime
				local TimeLeft = DestroyTime - tick()

				if TimeLeft > 0 and TimeLeft <= Data.Width * 10 * 0.05 and Data.Beam then
					local Beam = Data.Beam

					Beam.Width0 = math.max(Beam.Width0 - Data.Width / 10, 0)
					Beam.Width1 = math.max(Beam.Width1 - Data.Width / 10, 0)
				elseif TimeLeft <= 0 then
					for _, Object in Data.Objects do
						Objects:Remove(Object)
					end
	
					table.remove(Records.Tracers, Index)
				end
			end

			Records.Times["Tracers -> Update"] = nil
		end
	end
end)

RunService.RenderStepped:Connect(function()
	local Character = LocalPlayer.Character or nil
	local Pivot = Character and Character:GetPivot() or nil
	local Tool = Character and Character:FindFirstChildOfClass("Tool")
	if not (Character and Pivot and Tool and Tool:FindFirstChild("Gun")) then
		return
	end

	local Entitylist = GetEntitylist("ClientBirds")
	if not (Entitylist and typeof(Entitylist) == "table") then
		return
	end

	table.sort(Entitylist, function(First, Second)
		local FirstRoot = First.PrimaryPart
		local SecondRoot = Second.PrimaryPart

		if not (FirstRoot and SecondRoot) then
			return
		end

		local FirstDistance = (FirstRoot.Position - Pivot.Position).Magnitude
		local SecondDistance = (SecondRoot.Position - Pivot.Position).Magnitude

		return FirstDistance < SecondDistance
	end)

	for Bird, Value in Records.Hits do
		local Data = select(2, BirdController:GetBirdModel(Bird:GetAttribute("Id")))
		local Root = Bird.PrimaryPart

		if Data and Data:GetAttribute("Health") <= 0 then
			Records.Hits[Bird] = nil

			continue
		end

		if not Records.Times["Gun -> Shot"] then
			Records.Times["Gun -> Shot"] = os.clock() + 0.015
		end
		
		if os.clock() >= Records.Times["Gun -> Shot"] then
			local Destination = Root.Position

			GunSE:FireServer("BulletFired", Tool, vector.create(Destination.X, Destination.Y, Destination.Z), "Dart")
			GunSE:FireServer("BirdHit", Tool, vector.create(Destination.X, Destination.Y, Destination.Z), Bird:GetAttribute("Id"), "Dart")
	
			Records.Times["Gun -> Shot"] = nil
		end

		return
	end

	for Index = 1, #Entitylist do
		local Bird = Entitylist[Index]
		local Data = select(2, BirdController:GetBirdModel(Bird:GetAttribute("Id")))
		local Root = Bird.PrimaryPart

		if not (Bird:GetAttribute("CurrentlyVisible") and Data and Data:GetAttribute("Health") > 0 and Root) then
			continue
		end

		if not Records.Times["Gun -> Shot"] then
			Records.Times["Gun -> Shot"] = os.clock() + 0.015
		end
		
		if os.clock() >= Records.Times["Gun -> Shot"] then
			local Destination = Root.Position

			GunSE:FireServer("BulletFired", Tool, vector.create(Destination.X, Destination.Y, Destination.Z), "Dart")
			GunSE:FireServer("BirdHit", Tool, vector.create(Destination.X, Destination.Y, Destination.Z), Bird:GetAttribute("Id"), "Dart")

			Records.Hits[Bird] = true
			Records.Times["Gun -> Shot"] = nil
		end
	end
end)

Net:Connect("OnBirdShot", function(...)
	local Character = LocalPlayer.Character
	local Tool = Character:FindFirstChildOfClass("Tool")
	local ClientBird, ServerBird = BirdController:GetBirdModel(select(1, ...))
	local Root = ClientBird.PrimaryPart

	CreateBeam(Tool.Gun.SmokePart.Position, Root.Position)
	HitSound(8726881116)
end)
