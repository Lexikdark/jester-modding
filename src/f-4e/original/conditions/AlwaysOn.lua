---// AlwaysOn  .lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require 'base.Class'
local Condition = require 'base.Condition'
local Utilities = require 'base.Utilities'

local AlwaysOn = {}
AlwaysOn.True = Class(Condition)
AlwaysOn.False = Class(Condition)

function IsAlwaysOn()
	return true
end

function AlwaysOn.True:Check()
	return IsAlwaysOn()
end

function AlwaysOn.False:Check()
	return not IsAlwaysOn()
end

AlwaysOn.True:Seal()
AlwaysOn.False:Seal()
return AlwaysOn
