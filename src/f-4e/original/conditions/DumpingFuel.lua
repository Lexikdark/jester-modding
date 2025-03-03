---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require 'base.Class'
local Condition = require 'base.Condition'

local DumpingFuel = {}
DumpingFuel.True = Class(Condition)
DumpingFuel.False = Class(Condition)

function IsDumpingFuel()
	return GetJester().awareness:GetObservation("Fuel Dumping") or false
end

function DumpingFuel.True:Check()
	return IsDumpingFuel()
end

function DumpingFuel.False:Check()
	return not IsDumpingFuel()
end

DumpingFuel.True:Seal()
DumpingFuel.False:Seal()
return DumpingFuel
