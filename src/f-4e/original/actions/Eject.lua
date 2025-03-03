---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.
---
local Class = require 'base.Class'
local Action = require 'base.Action'
local Interactions = require('base.Interactions')

local Eject = Class(Action)

Eject.name = 'eject'
Eject:RequiresHands()

function Eject:Tick()
	ClickRaw(Interactions.devices.EJECTION_SEAT_SYSTEM, Interactions.device_commands.WSO_EJECT_INSTANT, 1)
	self.finished = true
end

local mt = getmetatable(Eject)
mt.__call = function(self,...)
	return self:new(...)
end

Eject:Seal()

return Eject
