---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require('base.Class')
local Behavior = require('base.Behavior')
local Urge = require('base.Urge')
local StressReaction = require('base.StressReaction')
local SayTask = require('tasks.common.SayTask')

local default_oxygen_quantity = L(10)
local oxygen_rate = L(1) / h(2)
local default_interval = min(15)
local oxygen_quantity_meter = '/WSO Cockpit/WSO Left Console/Oxygen and Cabin Pressure Altimeter Panel/Oxygen Quantity Gauge/Oxygen Quantity Meter'

local ObserveOxygenGauge = Class(Behavior)
ObserveOxygenGauge.oxygen_quantity = default_oxygen_quantity

function GetOxygenQuantity()
	-- 0 to 10 liters
	return GetProperty(oxygen_quantity_meter, 'Oxygen Quantity Indication').value or default_oxygen_quantity
end

function OxygenForRemainingTime(time)
	return time * oxygen_rate
end

function ObserveOxygenGauge:Constructor()
	Behavior.Constructor(self)

	local check_gauge = function()
		self.oxygen_quantity = GetOxygenQuantity()
		if (self.oxygen_quantity < OxygenForRemainingTime(h(2))) then
			local task = SayTask:new('phrases/WereLowOnOxygen')
			GetJester():AddTask(task)
			return { task }
		end
	end

	self.check_urge = Urge:new({
		time_to_release = default_interval,
		on_release_function = check_gauge,
		stress_reaction = StressReaction.ignorance,
	})
	self.check_urge:Restart()
end

function ObserveOxygenGauge:Tick()
	if self.check_urge then
		if self.oxygen_quantity < OxygenForRemainingTime(min(30)) then
			-- TODO Ejection tolerance
			self.check_urge:SetStressReaction(StressReaction.obsession)
			self.check_urge:SetGainRateMultiplier(3)
		elseif self.oxygen_quantity < OxygenForRemainingTime(h(1)) then
			self.check_urge:SetStressReaction(StressReaction.fixation)
			self.check_urge:SetGainRateMultiplier(1.5)
		elseif self.oxygen_quantity < OxygenForRemainingTime(h(2)) then
			self.check_urge:SetStressReaction(StressReaction.ignorance)
			self.check_urge:SetGainRateMultiplier(1)
		end

		self.check_urge:Tick()
	end
end

ObserveOxygenGauge:Seal()
return ObserveOxygenGauge
