---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require 'base.Class'
local Condition = require 'base.Condition'

local IsBombing = {}
IsBombing.True = Class(Condition)
IsBombing.False = Class(Condition)

function IsBombingCondition()
	local airborne = GetJester().awareness:GetObservation("airborne") or false
	if not airborne then
		return false
	end

	local delivery_mode = GetJester():GetCockpit():GetManipulator("Delivery Mode"):GetState() or "OFF"
	if delivery_mode == "OFF" or delivery_mode == "AGM45" then
		return false
	end

	local weapon_selection = GetJester():GetCockpit():GetManipulator("Weapon Selection"):GetState() or "C"
	if weapon_selection ~= "BOMBS" and weapon_selection ~= "RCKTS_DISP" and weapon_selection ~= "A" then
		return false
	end

	local master_arm = GetJester():GetCockpit():GetManipulator("Master Arm"):GetState() or "OFF"
	if master_arm ~= "ON" then
		return false
	end

	return true
end

function IsBombing.True:Check()
	return IsBombingCondition()
end

function IsBombing.False:Check()
	return not IsBombingCondition()
end

IsBombing.True:Seal()
IsBombing.False:Seal()
return IsBombing
