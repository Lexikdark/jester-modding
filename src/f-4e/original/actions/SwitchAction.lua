---// SwitchAction.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.
---
local Class = require 'base.Class'
local Action = require 'base.Action'
local Utilities = require 'base.Utilities'

local SwitchAction = Class(Action)

local default_delay_time = s(1.0)
local default_delay_sigma = s(0.2)
local delay_time_distribution = NormalDistribution.new(default_delay_time, default_delay_sigma)

local function GetDelayTime()
	return delay_time_distribution()
end

SwitchAction.name = 'SwitchAction'
SwitchAction.delay_time = s(0)
SwitchAction.timer = s(0)
SwitchAction:RequiresHands()

function SwitchAction:Constructor(manipulator_name, state_name, delay_time)
	self.manipulator_name = manipulator_name
	self.state_name = state_name
	self.delay_time = delay_time or GetDelayTime()
end

function SwitchAction:Tick()
	self.timer = self.timer + Utilities.GetTime().dt
	if self.timer >= self.delay_time then
		local cockpit = GetJester().cockpit
		if cockpit then
			local manipulator = cockpit:GetManipulator(self.manipulator_name)
			if manipulator then
				Log("  --Click '" .. self.manipulator_name .. "': " .. self.state_name)
				if not manipulator:SetState(self.state_name) then
					io.stderr:write("Unable to set state " .. self.state_name .. " for manipulator " .. self.manipulator_name .. "\n")
				end
			else
				io.stderr:write("Manipulator " .. self.manipulator_name .. " doesn't exist\n")
			end
		end
		self.finished = true
	end
end

function SwitchAction:Restart()
	self.timer = s(0)
end

local mt = getmetatable(SwitchAction)
mt.__call = function(self,...)
	return self:new(...)
end

SwitchAction:Seal()

return SwitchAction
