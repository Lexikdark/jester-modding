---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require('base.Class')
local Behavior = require('base.Behavior')
local Urge = require('base.Urge')
local StressReaction = require('base.StressReaction')
local SayTask = require('tasks.common.SayTask')

local default_interval = min(1)
local avtr_mode = {
	off = "OFF",
	standby = "STANDBY",
	record = "RECORD",
}

local ObserveAvtr = Class(Behavior)
ObserveAvtr.has_called_out_eot = false

local IsEndOfTapeLight = function()
	return GetProperty('/Airborne Video Tape Recorder (AVTR)', 'End Of Tape Light').value or false
end

function ObserveAvtr:Constructor()
	Behavior.Constructor(self)

	local check_avtr = function()
		local tasks = {}

		if IsEndOfTapeLight() then
			if not self.has_called_out_eot then
				local task = SayTask:new('phrases/AVTR_Full')
									:Wait(s(5))
									:Click("AVTR Mode", avtr_mode.off)
				GetJester():AddTask(task)
				tasks[#tasks + 1] = task

				self.has_called_out_eot = true
			end
		else
			if self.has_called_out_eot then
				-- Cassette was reset
				self.has_called_out_eot = false
			end
		end

		return tasks
	end

	self.check_urge = Urge:new({
		time_to_release = default_interval,
		on_release_function = check_avtr,
		stress_reaction = StressReaction.ignorance,
	})
	self.check_urge:Restart()
end

function ObserveAvtr:Tick()
	if self.check_urge then
		self.check_urge:Tick()
	end
end

ObserveAvtr:Seal()
return ObserveAvtr
