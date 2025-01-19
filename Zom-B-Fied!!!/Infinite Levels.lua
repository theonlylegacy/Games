-- note: this resets when you leave, this only works because the remotes send your level from the client whenever you purchase something

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
LocalPlayer.Data.Level.Value = 9e9
