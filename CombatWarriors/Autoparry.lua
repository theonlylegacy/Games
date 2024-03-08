local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local Client = Players.LocalPlayer
local Storage = {}
local SwingFlags = {"slash", "swing", "sword"}

function GetAssetInfo(ID) --not made by me
    local Success, Info = pcall(function()
        return MarketplaceService:GetProductInfo(ID)
    end)
    
    if Success then
        return Info
    end

    return {Name = ""}
end

function Parry()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
    RunService.RenderStepped:Wait()
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
end

function ConnectParry(Player)
    local function ConnectCharacter(Character)
        local Humanoid = Character:FindFirstChildWhichIsA("Humanoid") or Character:WaitForChild("Humanoid", true)
        Humanoid.AnimationPlayed:Connect(function(AnimationTrack)
            if (not Storage[AnimationTrack.Animation.AnimationId]) then
                Storage[AnimationTrack.Animation.AnimationId] = GetAssetInfo(AnimationTrack.Animation.AnimationId:match("%d+")) --not made by me
            end

            local Animation = Storage[AnimationTrack.Animation.AnimationId].Name
            local CRoot = Client.Character and Client.Character:FindFirstChild("HumanoidRootPart")
            local PRoot = Character and Character:FindFirstChild("HumanoidRootPart")
            local PTool = Character and Character:FindFirstChildWhichIsA("Tool")

            if CRoot and PRoot and PTool and PTool:FindFirstChild("Hitboxes") then
                for _, Part in pairs(PTool.Hitboxes:GetChildren()) do
                    local Distance = (Part.Position - CRoot.Position).Magnitude
                    local VerticalDistance = (Vector3.new(CRoot.Position.X, Part.Position.Y, CRoot.Position.Z) - CRoot.Position).Magnitude

                    if Distance <= 6.5 and VerticalDistance <= 1.25 then
                        for _, Flag in next, SwingFlags do
                            if string.find(string.lower(Animation), Flag) then
                                pcall(Parry)
                            end
                        end

                        break
                    end
                end
            end
        end)
    end

    if Player.Character then 
        ConnectCharacter(Player.Character) 
    end
    Player.CharacterAdded:Connect(ConnectCharacter)
end

for _, Player in next, Players:GetChildren() do
    if Player ~= Client then
        ConnectParry(Player)
    end
end

Players.PlayerAdded:Connect(ConnectParry)
