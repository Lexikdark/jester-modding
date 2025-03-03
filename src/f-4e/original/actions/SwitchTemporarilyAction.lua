---// SwitchTemporarilyAction.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.
---
local Class = require 'base.Class'
local Action = require 'base.Action'
local Utilities = require 'base.Utilities'

local SwitchTemporarilyAction = Class(Action)

local default_delay_time = s(1.0)
local default_delay_sigma = s(0.2)
local default_hold_time = s(0.2)
local default_hold_sigma = s(0.04)
local delay_time_distribution = NormalDistribution.new(default_delay_time, default_delay_sigma)
local hold_time_distribution = NormalDistribution.new(default_hold_time, default_hold_sigma)

local function GetDelayTime()
	return delay_time_distribution()
end

local function GetHoldTime()
	return hold_time_distribution()
end

SwitchTemporarilyAction.name = 'SwitchTemporarilyAction'
SwitchTemporarilyAction.delay_time = s(0)
SwitchTemporarilyAction.timer = s(0)
SwitchTemporarilyAction:RequiresHands()

function SwitchTemporarilyAction:Constructor(manipulator_name, state_name, hold_time, delay_time)
	self.manipulator_name = manipulator_name
	self.state_name = state_name
	self.hold_time = hold_time or GetHoldTime()
	self.delay_time = delay_time or GetDelayTime()
end

function SwitchTemporarilyAction:Tick()
	self.timer = self.timer + Utilities.GetTime().dt
	if self.release_time and self.timer >= self.release_time then
		if self.release_state then
			if not self.manipulator:SetState(self.release_state) then
				io.stderr:write("Unable to set state " .. self.release_state .. " for manipulator " .. self.manipulator_name .. "\n")
			end
		end
		self.finished = true
	end
	if self.release_time == nil and self.timer >= self.delay_time then
		self.release_time = self.timer + self.hold_time
		local cockpit = GetJester().cockpit
		if cockpit then
			local manipulator = cockpit:GetManipulator(self.manipulator_name)
			if manipulator then
				local current_state = manipulator:GetState()
				if current_state ~= '' then
					self.release_state = current_state
					self.manipulator = manipulator

					Log("  --Click temp '" .. self.manipulator_name .. "': " .. self.state_name)
					if not manipulator:SetState(self.state_name) then
						io.stderr:write("Unable to set state " .. self.state_name .. " for manipulator " .. self.manipulator_name .. "\n")
						self.finished = true
					end
				else
					io.stderr:write("Unable to get state from manipulator " .. self.manipulator_name .. "\n")
					self.finished = true
				end
			else
				io.stderr:write("Manipulator " .. self.manipulator_name .. " doesn't exist\n")
				self.finished = true
			end
		end
	end
end

function SwitchTemporarilyAction:Restart()
	if self.release_time ~= nil then
		self.timer = s(0)
	end
end

local mt = getmetatable(SwitchTemporarilyAction)
mt.__call = function(self,...)
	return self:new(...)
end

SwitchTemporarilyAction:Seal()

return SwitchTemporarilyAction
