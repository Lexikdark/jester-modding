---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require 'base.Class'
local Condition = require 'base.Condition'

local IsHighAltitude = {}

local altimeter = '/WSO Servoed Altimeter/Altitude Meter/Output Calculator'
IsHighAltitude.altimeter_property = GetProperty(altimeter, 'Altitude Needle')

IsHighAltitude.True = Class(Condition)
IsHighAltitude.False = Class(Condition)



local function GetAltitude()
	return IsHighAltitude.altimeter_property.value or ft(5000)
end

function IsHighAltitude.True:Check()
	return GetAltitude() > ft(10000)
end

function IsHighAltitude.False:Check()
	return GetAltitude() < ft(9000)
end

IsHighAltitude.True:Seal()
IsHighAltitude.False:Seal()
return IsHighAltitude
