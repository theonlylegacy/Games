-- R6 only so far

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local CurrentCamera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Utility = {} do
    function Utility:Connect(Signal, Callback)
        return Signal:Connect(Callback)
    end

    function Utility:GetPlayers()
        local Array = {}
        
        for Index, Player in Players:GetChildren() do
            local Character = Player.Character or nil
            local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid") or nil
            local RootPart = Humanoid and Humanoid.RootPart or nil

            if Player ~= LocalPlayer and Character and Humanoid and RootPart then
                table.insert(Array, {
                    Player = Player,
                    Character = Character,
                    Humanoid = Humanoid,
                    RootPart = RootPart,
                })
            end
        end

        return Array
    end

    function Utility:GetScreenPosition(Coordinates)
        local Position, WithinBounds = CurrentCamera:WorldToViewportPoint(Coordinates)

        if WithinBounds then
            return Vector2.new(Position.X, Position.Y)
        end
    end

    function Utility:GetOffsets(Character, RigType)
        local Array = {}

        if RigType == Enum.HumanoidRigType.R6 then
            local Head = Character:FindFirstChild("Head")
            local Torso = Character:FindFirstChild("Torso")
            local LeftArm = Character:FindFirstChild("Left Arm")
            local RightArm = Character:FindFirstChild("Right Arm")
            local LeftLeg = Character:FindFirstChild("Left Leg")
            local RightLeg = Character:FindFirstChild("Right Leg")

            if Head and Torso and LeftArm and RightArm and LeftLeg and RightLeg then
                Array.Head = Utility:GetScreenPosition(Head.Position)
            
                Array.Neck = Utility:GetScreenPosition(Torso.Position + Vector3.new(0, Torso.Size.Y / 2, 0))
                Array.Waist = Utility:GetScreenPosition(Torso.Position - Vector3.new(0, Torso.Size.Y / 2, 0))
    
                Array.LeftShoulder = Utility:GetScreenPosition((Torso.CFrame * CFrame.new(-Torso.Size.X / 3, Torso.Size.Y / 2.25, 0)).Position)
                Array.RightShoulder = Utility:GetScreenPosition((Torso.CFrame * CFrame.new(Torso.Size.X / 3, Torso.Size.Y / 2.25, 0)).Position)
    
                Array.LeftHand = Utility:GetScreenPosition(LeftArm.LeftGripAttachment.WorldPosition)
                Array.RightHand = Utility:GetScreenPosition(RightArm.RightGripAttachment.WorldPosition)
    
                Array.LeftFoot = Utility:GetScreenPosition(LeftLeg.LeftFootAttachment.WorldPosition)
                Array.RightFoot = Utility:GetScreenPosition(RightLeg.RightFootAttachment.WorldPosition)
            end
        end

        return Array
    end
end

Utility:Connect(DrawingImmediate.new(), function(Renderer)
    for Index, Data in Utility:GetPlayers() do
        local Offsets = Utility:GetOffsets(Data.Character, Data.Humanoid.RigType)

        if Offsets.Head and Offsets.Neck and Offsets.Waist and Offsets.LeftShoulder and Offsets.RightShoulder and Offsets.LeftHand and Offsets.RightHand and Offsets.LeftFoot and Offsets.RightFoot then
            local Color = Color3.fromRGB(255, 255, 255)

            Renderer.Line(Offsets.Head, Offsets.Neck, Color, 1, 1)
            Renderer.Line(Offsets.Neck, Offsets.Waist, Color, 1, 1)
            
            Renderer.Line(Offsets.Neck, Offsets.LeftShoulder, Color, 1, 1)
            Renderer.Line(Offsets.Neck, Offsets.RightShoulder, Color, 1, 1)

            Renderer.Line(Offsets.LeftShoulder, Offsets.LeftHand, Color, 1, 1)
            Renderer.Line(Offsets.RightShoulder, Offsets.RightHand, Color, 1, 1)

            Renderer.Line(Offsets.Waist, Offsets.LeftFoot, Color, 1, 1)
            Renderer.Line(Offsets.Waist, Offsets.RightFoot, Color, 1, 1)
        end
    end
end)
