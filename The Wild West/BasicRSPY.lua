-- missing most types, but should cover the most

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Global = require(ReplicatedStorage.SharedModules.Global)
local Exclude = {"CharUpdate", "UpdateCharacterSpring", "UpdateCharacterAnimation"}

function wrap_this_shit_homie(Callback)
    local Wrap = loadstring([=[return setfenv(function(...) return Oppornunity(...) end, setmetatable({["Oppornunity"] = (...)}, {__index = getfenv((...))}))]=])

    return Wrap(Callback)
end

function GetPath(Object)
    local Path = {}
    
    while Object.Parent do
        table.insert(Path, 1, string.find(Object.Name, " ") and `["{Object.Name}"]` or Object.Name)

        Object = Object.Parent
    end
    
    table.insert(Path, 1, Object.Name)
    Path[1] = "Game"

    return table.concat(Path, ".")
end

function Stringify(Table)
    local String = "{"
    local First = true
    
    for Index, Value in ipairs(Table) do
        if not First then
            String = String .. ", "
        end

        First = false

        if type(Value) == "table" then
            String = String .. "[" .. tostring(Index) .. "] = " .. Stringify(Value)
        elseif typeof(Value) == "Instance" then
            String = String .. "[" .. tostring(Index) .. "] = " .. GetPath(Value)
        elseif typeof(Value) == "Vector3" then
            String = String  .. "[" .. tostring(Index) .. "] = " .. `Vector3.new({Value.X}, {Value.Y}, {Value.Z})`
        elseif typeof(Value) == "CFrame" then
            String = String  .. "[" .. tostring(Index) .. "] = " .. `CFrame.new({Value:GetComponents()})`
        elseif typeof(Value) == "string" then
            String = String  .. "[" .. tostring(Index) .. "] = " .. `"{Value}"`
        elseif typeof(Value) == "number" then
            String = String  .. "[" .. tostring(Index) .. "] = " .. `{Value}`
        else
            String = String  .. "[" .. tostring(Index) .. "] = " .. tostring(Value)
        end
    end

    for Key, Value in pairs(Table) do
        if type(Key) ~= "number" then
            if not First then
                String = String .. ", "
            end

            First = false

            if type(Value) == "table" then
                String = String .. "[" .. "\"" .. tostring(Key) .. "\"] = " .. Stringify(Value)
            elseif typeof(Value) == "Instance" then
                String = String .. "[" .. "\"" .. tostring(Key) .. "\"] = " .. GetPath(Value)
            elseif typeof(Value) == "Vector3" then
                String = String .. "[" .. "\"" .. tostring(Key) .. "\"] = " .. `Vector3.new({Value.X}, {Value.Y}, {Value.Z})`
            elseif typeof(Value) == "CFrame" then
                String = String .. "[" .. "\"" .. tostring(Key) .. "\"] = " .. `CFrame.new({Value:GetComponents()})`
            elseif typeof(Value) == "string" then
                String = String .. "[" .. "\"" .. tostring(Key) .. "\"] = " .. `"{Value}"`
            elseif typeof(Value) == "number" then
                String = String .. "[" .. "\"" .. tostring(Key) .. "\"] = " .. `{Value}`
            else
                String = String .. "[" .. "\"" .. tostring(Key) .. "\"] = " .. tostring(Value)
            end
        end
    end
    
    String = String .. "}"
    return String
end

local Old = nil
Old = hookfunction(Global.Network.FireServer, wrap_this_shit_homie(function(Self, Method, ...)
    if not table.find(Exclude, Method) then
        local Array = table.pack(...)
        local String = ""

        for Index, Value in Array do
            if typeof(Value) == "Vector3" then
                String = String .. `Vector3.new({Value.X}, {Value.Y}, {Value.Z}), `
            elseif typeof(Value) == "CFrame" then
                String = String .. `CFrame.new({Value:GetComponents()}), `
            elseif typeof(Value) == "string" then
                String = String .. `"{Value}", `
            elseif typeof(Value) == "number" then
                String = String .. `{Value}, `
            elseif typeof(Value) == "Instance" and Value ~= nil then
                String = String .. `{GetPath(Value)}, `
            elseif typeof(Value) == "table" then
                String = String .. `{Stringify(Value)}, `
            else
                String = String .. `{tostring(Value)}, `
            end
        end

        print(`Network:FireServer("{Method}", {string.sub(String, 1, -3)})`)
	end

	return Old(Self, Method, ...)
end))
