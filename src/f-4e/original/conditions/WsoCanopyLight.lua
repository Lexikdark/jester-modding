---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.
---
local Class = require 'base.Class'
local Condition = require 'base.Condition'

local WsoCanopyLight = Class(Condition)

function IsWsoCanopyLight()

	local wso_canopy_light = GetJester().awareness:GetObservation("wso_canopy_light")

	if wso_canopy_light then

		return true

	end

	return false
end

function WsoCanopyLight:Check()
	return IsWsoCanopyLight()
end
WsoCanopyLight:Seal()

return WsoCanopyLight