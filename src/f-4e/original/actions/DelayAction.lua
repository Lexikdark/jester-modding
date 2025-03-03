---// DelayAction.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.
---
local Class = require 'base.Class'
local Action = require 'base.Action'
local Utilities = require 'base.Utilities'

local DelayAction = Class(Action)

DelayAction.name = 'DelayAction'
DelayAction.delay_time = s(0)
DelayAction.timer = s(0)

DelayAction.Constructor = function(self, delay_time, requires)
	Action.Constructor(self, requires or { hands = true })
	self.delay_time = Real.new(delay_time)
end

function DelayAction:Tick()
	if self.timer == s(0) then
		Log("  --Delaying for: " .. tostring(self.delay_time:ConvertTo(s).value) .. "s")
	end

	self.timer = self.timer + Utilities.GetTime().dt
	if self.timer >= self.delay_time then
		self.finished = true
	end
end

function DelayAction:Restart()
	self.timer = s(0)
end

local mt = getmetatable(DelayAction)
mt.__call = function(self,...)
	return self:new(...)
end

DelayAction:Seal()

return DelayAction
