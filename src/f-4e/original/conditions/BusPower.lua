---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require 'base.Class'
local Condition = require 'base.Condition'

local BusPower = Class(Condition)

function IsBusPower()

	local bus_power = GetJester().awareness:GetObservation("bus_power")

	if bus_power then

		return true
	end

	return false
end

function BusPower:Check()
	return IsBusPower()
end
BusPower:Seal()

return BusPower