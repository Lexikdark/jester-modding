---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require 'base.Class'
local Condition = require 'base.Condition'

local RightEngineMasterSwitch = Class(Condition)

function IsRightEngineMasterSwitch()

	local right_engine_master_switch = GetJester().awareness:GetObservation("right_engine_master_switch")

	return right_engine_master_switch
end

function RightEngineMasterSwitch:Check()
	return IsRightEngineMasterSwitch()
end
RightEngineMasterSwitch:Seal()

return RightEngineMasterSwitch