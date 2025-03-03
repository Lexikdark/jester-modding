---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require 'base.Class'
local Condition = require 'base.Condition'

local IsInAircraft = {}

IsInAircraft.True = Class(Condition)

function IsInAircraft.True:Check()
	return true
end

IsInAircraft.False = Class(Condition)

function IsInAircraft.False:Check()
	return false
end


return IsInAircraft
