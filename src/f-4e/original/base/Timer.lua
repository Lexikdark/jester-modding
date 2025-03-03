---// Timer.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Utilities = require 'base.Utilities'

local Timer = {}

local timers = {}

function Timer:new(set_time, alarm_function)
	now = Utilities.GetTime()
	obj =
	{
		set_time = set_time,
		start_time = now.mission_time,
		alarm_time = now.mission_time + set_time,
		alarm_function = alarm_function,
		active = true
	}
	self.__index = self
	setmetatable(obj, self)
	table.insert(timers, obj)
	return obj
end

function Timer:GetSetTime()
	return self.set_time
end

function Timer:ReplaceSetTime(t)
	self.set_time = t
	self.alarm_time = self.start_time + t
end

function Timer:Disable()
	self.active = false
	self.ReplaceSetTime(s(0))
end

function Timer:Kill()
	self.to_be_killed = true
end

function Timer.Tick()
	t = Utilities.GetTime().mission_time
	table.sort(timers, function(a, b) return (a.alarm_time > b.alarm_time) or (not a.to_be_killed and b.to_be_killed) end)
	for i, v in ipairs(timers) do
		if v.alarm_time >= t or v.to_be_killed then
			if v.active then
				v.alarm_function()
			end
			timers[i] = nil
		end
	end
end

return Timer
