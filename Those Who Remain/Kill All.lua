-- This kicks you after you do it a couple of times
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local RE = ReplicatedStorage.RE
local Entities = Workspace.Entities
local Infected = Entities.Infected

local Haystack = Infected:GetChildren()
for Index = 1, #Haystack do
    local Infectee = Haystack[Index]
    local Bullets = {}

    Bullets[#Bullets + 1] = {
        AI = Infectee,
        Velocity = Vector3.new(Random.new():NextNumber(-5, 7), Random.new():NextNumber(-0.1, 0.2), Random.new():NextNumber(-2, 3))
    }

    for Number = 1, 10 do -- Noot Nen Nimes
        RE:FireServer("aa", Bullets)
    end
end
