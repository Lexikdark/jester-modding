---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.
---
local Class = require 'base.Class'
local Condition = require 'base.Condition'

local RightGeneratorSwitch = Class(Condition)

function IsRightGeneratorSwitch()

	local right_generator_switch = GetJester().awareness:GetObservation("gen_switch_right")

	if right_generator_switch == 2 then
		return true
	end

	return false
end

function RightGeneratorSwitch:Check()
	return IsRightGeneratorSwitch()
end
RightGeneratorSwitch:Seal()

return RightGeneratorSwitch