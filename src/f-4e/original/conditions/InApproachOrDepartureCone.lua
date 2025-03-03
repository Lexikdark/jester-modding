---// DogfightCondition.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.


-- CRASHES AT THE MOMENT!!!! BEWARE --Nick

local Class = require 'base.Class'
local Condition = require 'base.Condition'
local awareness = require 'memory.Awareness'

local OnApproach = {}

OnApproach.True = Class(Condition)
OnApproach.False = Class(Condition)

function AreWeOnApproach()

	local in_approach_cone = GetJester().awareness:GetObservation("in_approach_cone") or false

	if in_approach_cone then
		return in_approach_cone
	end
	return false
end

function OnApproach.True:Check()
	return OnApproach.AreWeOnApproach()
end

function OnApproach.False:Check()
	return not OnApproach.AreWeOnApproach()
end

OnApproach.True:Seal()
OnApproach.False:Seal()

return OnApproach