local uis = game:GetService("UserInputService")
local plrs = game:GetService("Players")
local cc = workspace.CurrentCamera
local lp = plrs.LocalPlayer

local getnearesthit = function()
    local curdist = 9e9
    local cur = nil
    local mousepos = uis.GetMouseLocation(uis)

    for _, plr in plrs.GetPlayers(plrs) do
        if plr == lp then
            continue
        end

        local char = plr.Character or nil
        local rootpart = char and char.FindFirstChild(char, "HumanoidRootPart") or nil

        if rootpart then
            local pos, vis = cc.WorldToViewportPoint(cc, rootpart.Position)

            if vis then
                local dist = (Vector2.new(pos.x, pos.y) - mousepos).magnitude

                if dist < curdist then
                    cur = char.Head
                    curdist = dist
                end
            end
        end
    end

    return cur
end

local __namecall = nil
__namecall = hookmetamethod(game, "__namecall", function(self, ...)
    local array = table.pack(...)
    
    if typeof(array[1]) == "table" and array[1].type == "fire" then
        local firepoint = array[1].firePoint
        local hitpart = getnearesthit()
        
        if hitpart then
            task.delay(0.018, function()
                self.FireServer(self, {
                    ["type"] = "hit",
                    ["position"] = hitpart.Position,
                    ["sendTime"] = tick(),
                    ["hitPosition"] = hitpart.Position + Vector3.new(-1.028961181640625, 0.5313396453857422, 0.183135986328125),
                    ["hit"] = hitpart,
                    ["surface"] = Vector3.new(-0.9929430484771729, 0.000013464938092511147, -0.11859212070703506),
                    ["actualDistance"] = 1.1724426746368408,
                    ["fixedDirection"] = Vector3.new(-10.03924560546875, 0.5795917510986328, -8.159027099609375),
                    ["direction"] = Vector3.new(0.733782172203064, -0.004262599628418684, 0.6793715953826904),
                })
            end)
        end
    end

    if typeof(array[1]) == "string" and (string.find(array[1], "Restricted error") or string.find(array[1], "CoreGui")) then
        return
    end

    return __namecall(self, ...)
end)
