---// SwitchAction.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.
---
local Class = require 'base.Class'
local Action = require 'base.Action'

local BasicAction = Class(Action)

BasicAction.name = 'BasicAction'

function BasicAction:Constructor(action_function, requires)
	Action.Constructor(self, requires or { hands = true })
	self.action_function = action_function
end

function BasicAction:Tick()
	if self.action_function then
		self.action_function()
	end
	self.finished = true
end

local mt = getmetatable(BasicAction)
mt.__call = function(self,...)
	return self:new(...)
end

BasicAction:Seal()

return BasicAction
