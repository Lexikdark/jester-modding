---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require 'base.Class'
local Condition = require 'base.Condition'

local IsAAR = {}
IsAAR.True = Class(Condition)
IsAAR.False = Class(Condition)

function IsAARCondition()
	local airborne = GetJester().awareness:GetObservation("airborne") or false
	if not airborne then
		return false
	end

	local aar_door_opened = GetProperty('/Fuel System', 'Air-Refuel Door Opened').value
	if not aar_door_opened then
		return false
	end

	local closest_tanker = GetJester().awareness:GetClosestFriendlyTanker()
	if closest_tanker == nil then
		return false
	end
	if closest_tanker.polar_ned.length > m(100) then
		return false
	end

	return true
end

function IsAAR.True:Check()
	return IsAARCondition()
end

function IsAAR.False:Check()
	return not IsAARCondition()
end

IsAAR.True:Seal()
IsAAR.False:Seal()
return IsAAR
