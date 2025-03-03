---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require 'base.Class'
local Condition = require 'base.condition'

local CanopiesDifferent = Class(Condition)

function IsCanopiesDifferent()
	local is_pilot_sealed = GetJester().awareness:GetObservation("pilot_canopy_sealed")
	local is_wso_sealed = GetJester().awareness:GetObservation("wso_canopy_sealed")

	return is_pilot_sealed ~= is_wso_sealed

end

function CanopiesDifferent:Check()
	return IsCanopiesDifferent()
end

CanopiesDifferent:Seal()

return CanopiesDifferent