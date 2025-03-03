---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require 'base.Class'
local Condition = require 'base.Condition'

local LeftEngineMasterSwitch = Class(Condition)

function IsLeftEngineMasterSwitch()

	local left_engine_master_switch = GetJester().awareness:GetObservation("left_engine_master_switch")

	return left_engine_master_switch
end

function LeftEngineMasterSwitch:Check()
	return IsLeftEngineMasterSwitch()
end
LeftEngineMasterSwitch:Seal()

return LeftEngineMasterSwitch