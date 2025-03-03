
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require 'base.Class'
local Condition = require 'base.Condition'

local OnGround = Class(Condition)

function IsOnGround()
	local on_gnd = GetJester().awareness:GetObservation("landed")

	if on_gnd then
		return true
	end

	return false
end

function OnGround:Check()
	return IsOnGround()
end

OnGround:Seal()

return OnGround
