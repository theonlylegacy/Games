local function Format(Number)
	assert(type(Number) == "number", "argument #1 expects a number")
	
	local String = string.reverse(tostring(Number))
	local Formatted = ""
	local CurrentNumber = 0

	for Number = 1, #String do
		CurrentNumber = CurrentNumber + 1
		Formatted = Formatted .. string.sub(String, Number, Number)

		if CurrentNumber == 3 and Number ~= #String then
			Formatted = Formatted .. ","
			CurrentNumber = 0
		end
	end

	return string.reverse(Formatted)
end

local Number = 100000
local Formatted = Format(Number)
print(Formatted) --> 100,000
