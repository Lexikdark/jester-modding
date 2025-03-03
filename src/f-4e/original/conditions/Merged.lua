---// DogfightCondition.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

--Merged with a bandit?
local Class = require 'base.Class'
local Condition = require 'base.Condition'
local JesterConstants = require 'base.Constants'

local Merged = {}

Merged.True = Class(Condition)

function Merged.True:Check()
	local closest_bandit = GetJester().awareness:GetClosestAirThreat() or false
	if closest_bandit then
		if closest_bandit.polar_body.length:ConvertTo(NM) < JesterConstants.dogfight_distance then
			return true
		end
	end
	return false
end

Merged.False = Class(Condition)

function Merged.False:Check()
	local closest_bandit = GetJester().awareness:GetClosestAirThreat() or false
	if closest_bandit then
		if closest_bandit.polar_body.length:ConvertTo(NM) > JesterConstants.dogfight_distance then
			return true
		end
	end
end


return Merged
