---// DogfightCondition.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

-- In Combat or Danger - i.e. if we're in HI.

local Class = require 'base.Class'
local Condition = require 'base.Condition'
local awareness = require 'memory.Awareness'

local InCombatOrDanger = {}

InCombatOrDanger.True = Class(Condition)
InCombatOrDanger.False = Class(Condition)

function AreWeInCombatOrDanger()

	local in_combat_or_danger = GetJester().awareness:GetInCombatOrDanger() or false

	if in_combat_or_danger then
		return true
	end

	return false

end

function InCombatOrDanger.True:Check()
	return InCombatOrDanger.AreWeInCombatOrDanger()
end

function InCombatOrDanger.False:Check()
	return not InCombatOrDanger.AreWeInCombatOrDanger()
end

InCombatOrDanger.True:Seal()
InCombatOrDanger.False:Seal()

return InCombatOrDanger