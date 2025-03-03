---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require 'base.Class'
local Condition = require 'base.Condition'

local InsAligned = Class(Condition)

function IsInsAligned()

	local ins_aligned = GetJester().awareness:GetObservation("ins_alignment_state")

	if ins_aligned == 3 then

		return true
	end
	return false
end

function InsAligned:Check()
	return IsInsAligned()
end

InsAligned:Seal()

return InsAligned