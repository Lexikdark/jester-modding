---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require 'base.Class'
local Condition = require 'base.Condition'
local Utilities = require 'base.Utilities'

local StartupState = Class(Condition)

function IsStartupState()

	local ground_speed = kt(0)
	if GetJester().awareness:GetObservation("ground_speed") ~= nil then
		ground_speed = GetJester().awareness:GetObservation("ground_speed")
	end
	local left_generator_switch = GetJester().awareness:GetObservation("gen_switch_left")
	local right_generator_switch = GetJester().awareness:GetObservation("gen_switch_right")
	local bus_power = GetJester().awareness:GetObservation("bus_power")
	local ins_aligned = GetJester().awareness:GetObservation("ins_alignment_state")
	local ready_for_alignment = GetJester().memory:GetReadyForInsAlignment()
	local ins_damaged = GetJester().awareness:GetObservation("ins_damaged")
	local is_realigning = GetJester().memory:GetRealigning()
	local realignment_complete = GetJester().memory:GetRealignmentComplete()

	if left_generator_switch == 2
			and right_generator_switch == 2
			and bus_power
			and ground_speed.value < 1
			and ins_aligned < 3
			and ready_for_alignment
			and not ins_damaged
			and not is_realigning
			and not realignment_complete then

		return true
	end
	return false
end

function StartupState:Check()
	return IsStartupState()
end
StartupState:Seal()

return StartupState