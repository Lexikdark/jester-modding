---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require('base.Class')
local Behavior = require('base.Behavior')
local Urge = require('base.Urge')
local StressReaction = require('base.StressReaction')
local SayTask = require('tasks.common.SayTask')

local default_interval = min(4) -- the entire fuel is gone in roughly 15min

local RemindDumpingFuel = Class(Behavior)

function RemindDumpingFuel:Constructor()
	Behavior.Constructor(self)

	local remind = function()
		local task = SayTask:new('misc/dumpingfuel')
		GetJester():AddTask(task)
		return { task }
	end

	self.check_urge = Urge:new({
		time_to_release = default_interval,
		on_release_function = remind,
		stress_reaction = StressReaction.ignorance,
	})
	self.check_urge:Restart()
end

function RemindDumpingFuel:Tick()
	if self.check_urge then
		self.check_urge:Tick()
	end
end

RemindDumpingFuel:Seal()
return RemindDumpingFuel
