---// SwitchAction.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.
---
local Class = require 'base.Class'
local Action = require 'base.Action'

local BarrierAction = Class(Action)

BarrierAction.name = 'BarrierAction'

-- requires: table with bool entries "hands", "eyes", "voice"
function BarrierAction:Constructor(requires)
	Action.Constructor(self, requires or { hands = true })
end

function BarrierAction:Tick()
	self.finished = true
end

local mt = getmetatable(BarrierAction)
mt.__call = function(self,...)
	return self:new(...)
end

BarrierAction:Seal()

return BarrierAction
