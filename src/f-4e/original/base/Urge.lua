---// Urge.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require('base.Class')
local Utilities = require('base.Utilities')
local StressReaction = require('base.StressReaction')

local Urge = Class()
Urge.time_to_release = s(0)
Urge.time_to_release_sigma_percent = percent(20)
Urge.time_to_release_left = s(0)
Urge.gain_rate_multiplier = 1
Urge.on_release_function = nil
Urge.on_release_task_class = nil
Urge.disable_auto_restart = false
Urge.released = false
Urge.release_tasks = nil

function Urge:Constructor(init_data)
	self.time_to_release = init_data.time_to_release or s(0)
	self.on_release_function = init_data.on_release_function
	self.on_release_task_class = init_data.on_release_task_class
	self.time_to_release_sigma_percent = init_data.time_to_release_sigma_percent or percent(20)
	self.stress_reaction = init_data.stress_reaction or StressReaction.random
end

function Urge:DisableAutoRestart()
	self.disable_auto_restart = true
end

function Urge:EnableAutoRestart()
	self.disable_auto_restart = false
end

function Urge:Release()
	self.released = true
	if self.on_release_function then
		local release_function_result = self.on_release_function(self)
		if type(release_function_result) == 'table' then
			local result_mt = getmetatable(release_function_result)
			if result_mt and result_mt.instance_class then
				self.release_tasks = {release_function_result}
			else
				self.release_tasks = release_function_result
			end
		else
			self.release_tasks = nil
		end
	elseif self.on_release_task_class then
		self.release_tasks = {self.on_release_task_class:new()}
	end
	if not self.release_tasks and not self.disable_auto_restart then
		self:Restart()
	end
end

function Urge:SetTimeToRelease(time_to_release)
	self.time_to_release = time_to_release
end

function Urge:SetTimeToReleaseSigmaPercent(time_to_release_sigma_percent)
	self.time_to_release_sigma_percent = time_to_release_sigma_percent
end

function Urge:SetGainRateMultiplier(gain_rate_multiplier)
	self.gain_rate_multiplier = gain_rate_multiplier
end

function Urge:SetStressReaction(stress_reaction)
	self.stress_reaction = stress_reaction
end

function Urge:Restart()
	self.time_to_release_left = NormalDistribution.new(self.time_to_release, self.time_to_release * self.time_to_release_sigma_percent)()
	self.released = false
	self.release_tasks = nil
end

function Urge:Tick()
	local dt = Utilities.GetTime().dt
	self.time_to_release_left = self.time_to_release_left - (dt * self.gain_rate_multiplier)
	if self.time_to_release_left <= s(0) then
		if not self.release_tasks and not self.released then
			self:Release()
		end

		if self.release_tasks then
			local any_task_not_finished = false
			for _, task in pairs(self.release_tasks) do
				any_task_not_finished = any_task_not_finished or task:IsFinished()
			end
			if not any_task_not_finished then
				self:Restart()
			end
		end
	end
end

Urge:Seal()
return Urge
