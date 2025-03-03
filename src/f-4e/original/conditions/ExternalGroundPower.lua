---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require 'base.Class'
local Condition = require 'base.condition'

local ExternalGroundPower = Class(Condition)

function IsExternalGroundPower()

	local ext_ground_power = GetJester().awareness:GetObservation("ground_crew_external_power")

	if ext_ground_power then
		return true
	end
	return false
end

function ExternalGroundPower:Check()
	return IsExternalGroundPower()
end

ExternalGroundPower:Seal()

return ExternalGroundPower