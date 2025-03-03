---// DelayAction.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.
---
local Class = require 'base.Class'
local Action = require 'base.Action'
local Utilities = require 'base.Utilities'

local DelayUntilAction = Class(Action)

DelayUntilAction.name = 'DelayUntilAction'
DelayUntilAction.timer = s(0)

DelayUntilAction.Constructor = function(self, predicate, max_delay, requires)
	Action.Constructor(self, requires or { hands = true })
	self.predicate = predicate
	self.max_delay = max_delay or min(60)
end

function DelayUntilAction:Tick()
	if self.timer == s(0) then
		Log("  --Delaying until condition")
	end

	self.timer = self.timer + Utilities.GetTime().dt
	if self.predicate() or self.timer > self.max_delay then
		self.finished = true
	end
end

function DelayUntilAction:Restart()
	self.timer = s(0)
end

local mt = getmetatable(DelayUntilAction)
mt.__call = function(self,...)
	return self:new(...)
end

DelayUntilAction:Seal()
return DelayUntilAction
