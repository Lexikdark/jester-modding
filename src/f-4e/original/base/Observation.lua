---// Observation.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require('base.Class')
local Math = require('base.Math')
local Utilities = require('base.Utilities')

local Observation = Class()

local default_time_to_invalidate = s(18)

Observation.time_to_invalidate = default_time_to_invalidate

function Observation:Update(data)
	if data ~= nil then
		if type(data) ~= 'table' then
			if self.precision then
				self.value = Math.RoundTo(data, self.precision)
			else
				self.value = data
			end
		else
			self.time_to_invalidate = data.time_to_invalidate or self.time_to_invalidate or default_time_to_invalidate
			self.precision = data.precision or self.precision
			if self.precision then
				self.value = Math.RoundTo(data.value, self.precision)
			else
				self.value = data.value
			end
			self.update_task_creator = data.update_task_creator
		end
		self.time_stamp = Utilities.GetTime().mission_time
		self.valid_until = self.time_stamp + self.time_to_invalidate
	else
		self.value = nil
	end
end

function Observation:Clear()
	self.value = nil
end

-- init_data possible fields
-- .value
-- .time_to_invalidate
-- .precision
-- .update_task_creator
function Observation:Constructor(init_data)
	self:Update(init_data)
end

function Observation:Tick()
	if not self.valid_until or self.valid_until < Utilities.GetTime().mission_time then
		self.value = nil
	end
end

function Observation:IsValid()
	return self.value ~= nil
end

function Observation:GetValue()
	return self.value
end

function Observation:GetTimePastSinceObservation()
	if self:IsValid() and self.time_stamp then
		return Utilities.GetTime().mission_time - self.time_stamp
	end
end

function Observation:GetUpdateTaskCreator()
	return self.update_task_creator
end

Observation:Seal()
return Observation
