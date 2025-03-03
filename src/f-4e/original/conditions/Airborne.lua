---// Airborne  .lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require 'base.Class'
local Condition = require 'base.Condition'
local Utilities = require 'base.Utilities'

local Airborne = {}
Airborne.True = Class(Condition)
Airborne.False = Class(Condition)

function IsAirborne()

	return GetJester().awareness:GetObservation("airborne") or false

end

function Airborne.True:Check()
	return IsAirborne()
end

function Airborne.False:Check()
	return not IsAirborne()
end

Airborne.True:Seal()
Airborne.False:Seal()
return Airborne
