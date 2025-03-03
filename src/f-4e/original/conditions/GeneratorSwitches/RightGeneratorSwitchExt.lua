---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.
---
local Class = require 'base.Class'
local Condition = require 'base.Condition'

local RightGeneratorSwitchExt = Class(Condition)

function IsRightGeneratorSwitchExt()

	local right_generator_switch_ext = GetJester().awareness:GetObservation("gen_switch_right")

	if right_generator_switch_ext == 0 then
		return true
	end

	return false
end

function RightGeneratorSwitchExt:Check()
	return IsRightGeneratorSwitchExt()
end
RightGeneratorSwitchExt:Seal()

return RightGeneratorSwitchExt