---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require 'base.Class'
local Condition = require 'base.Condition'

local LeftGeneratorSwitchExt = Class(Condition)

function IsLeftGeneratorSwitchExt()

	local left_generator_switch_ext = GetJester().awareness:GetObservation("gen_switch_left")

	if left_generator_switch_ext == 0 then
		return true
	end

	return false
end

function LeftGeneratorSwitchExt:Check()
	return IsLeftGeneratorSwitchExt()
end

LeftGeneratorSwitchExt:Seal()

return LeftGeneratorSwitchExt