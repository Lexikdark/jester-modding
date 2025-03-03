---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require 'base.Class'
local Condition = require 'base.condition'

local AlignmentRestartingCondition = Class(Condition)

function IsAlignmentRestarting()

	local restart_wanted = GetJester().memory:GetStartRealignment()
	local left_generator_switch = GetJester().awareness:GetObservation("gen_switch_left")
	local right_generator_switch = GetJester().awareness:GetObservation("gen_switch_right")
	local bus_power = GetJester().awareness:GetObservation("bus_power")
	local ins_aligned = GetJester().awareness:GetObservation("ins_alignment_state")
	local realignment_complete = GetJester().memory:GetRealignmentComplete()

	if left_generator_switch == 2
			and right_generator_switch == 2
			and bus_power
			and restart_wanted == true
			and ins_aligned == 3
			and not realignment_complete then


		return true

	end



	return false
end

function AlignmentRestartingCondition:Check()
	return IsAlignmentRestarting()
end
AlignmentRestartingCondition:Seal()

return AlignmentRestartingCondition