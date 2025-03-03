
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require 'base.Class'
local Condition = require 'base.Condition'

local IsNearAnAirport = {}
IsNearAnAirport.True = Class(Condition)
IsNearAnAirport.False = Class(Condition)

function IsNearAnAirportCondition()

	local closest_airport = GetJester().awareness:GetObservation("distance_to_nearest_airfield") or false
	if closest_airport > m(5000) then
		return false
	end

	return true
end

function IsNearAnAirport.True:Check()
	return IsNearAnAirportCondition()
end

function IsNearAnAirport.False:Check()
	return not IsNearAnAirportCondition()
end

IsNearAnAirport.True:Seal()
IsNearAnAirport.False:Seal()
return IsNearAnAirport