---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require 'base.Class'
local Condition = require 'base.Condition'

local LeftGeneratorSwitch = Class(Condition)

function IsLeftGeneratorSwitch()

	local left_generator_switch = GetJester().awareness:GetObservation("gen_switch_left")

	if left_generator_switch == 2 then
		return true
	end

	return false
end

function LeftGeneratorSwitch:Check()
	return IsLeftGeneratorSwitch()
end
LeftGeneratorSwitch:Seal()

return LeftGeneratorSwitch