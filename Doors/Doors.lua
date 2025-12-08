local Doors = {
    Rooms = { },
    Signals = { },
};

local Workspace = Game:GetService("Workspace");
local RunService = Game:GetService("RunService");

local CurrentCamera = Workspace.CurrentCamera;
local CurrentRooms = Workspace.CurrentRooms;

function Doors:GetPool()
    local Pool = { };
    
    for Index = 1, #self.Rooms do
        local Room = self.Rooms[Index];
        local Assets = Room.Assets:GetChildren();
        local Door = Room.Door;

        table.insert(Pool, { Room = Room, Assets = Assets, Door = Door });
    end;

    return Pool;
end;

function Doors:GetActiveRooms()
    local Active = table.create(0);
    local Pool = self:GetPool();

    for Index = #Pool - 1, #Pool do
        Active[#Active + 1] = Pool[Index];
    end;

    return Active;
end;

function Doors:OnOpen(callback)
    local Signal = { };

    rawset(Signal, "Type", "Opened")
    rawset(Signal, "Index", #self.Signals + 1);
    rawset(Signal, "Callback", callback);

    function Signal:Fire(...)
        task.defer(pcall, self.Callback, ...);
    end;

    function Signal:Disconnect()
        table.remove(Doors.Signals, self.Index);
    end;

    self.Signals[#self.Signals + 1] = Signal;
    return Signal;
end;

function Doors:Added(room)
    local Number = tonumber(room.Name) - 1;
    local Room = CurrentRooms[tostring(Number)];

    if not Number then
        return;
    end;

    for _, Signal in self.Signals do
        if Signal.Type ~= "Opened" then
            continue;
        end;
        
        Signal:Fire({ 
            Room = Room, 
            Number = Number 
        });
    end;
end;

function Doors:Step()
    rawset(self, "Rooms", CurrentRooms:GetChildren());
end;

RunService.RenderStepped:Connect(function(...)
    Doors:Step(...);
end);

CurrentRooms.ChildAdded:Connect(function(...)
    Doors:Added(...);
end);

return Doors;
