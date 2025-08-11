---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

-- TODO: sudden pressure change can be sensed with ears

local Class = require('base.Class')
local Behavior = require('base.Behavior')
local Urge = require('base.Urge')
local StressReaction = require('base.StressReaction')
local SayTask = require('tasks.common.SayTask')

local ObserveCockpitPressureIndicator = Class(Behavior)
ObserveCockpitPressureIndicator.wrong_pressure_duration = min(0);
ObserveCockpitPressureIndicator.pressure_loss_identified = false;

local default_interval = min(0.5)

function GetAltitude()
	return GetJester().awareness:GetObservation("barometric_altitude")
end

function GetCockpitPressure()
	return GetJester().awareness:GetObservation("cockpit_pressure") -- indicator shows from 0 to 50k ft
end

function ObserveCockpitPressureIndicator:IsCockpitPressureWrong()
	if self.altitude < ft(23100) then
		-- cockpit pressure should be 8000ft
		return self.cockpit_pressure > ft(10000)
	else
		-- cockpit pressure should follow a curve from flight manual (around 24000ft at altitude of 60000ft)
		return self.cockpit_pressure > (self.altitude / 2) -- I think it's a good rule of thumb
	end
end

function ObserveCockpitPressureIndicator:Constructor()
	Behavior.Constructor(self)

	local check_gauge = function()
		self.altitude = GetAltitude()
		self.cockpit_pressure = GetCockpitPressure()

        if self:IsCockpitPressureWrong() then
            self.wrong_pressure_duration = self.wrong_pressure_duration + default_interval
        else
            self.wrong_pressure_duration = min(0)
        end

		local pressure_loss = self.wrong_pressure_duration >= min(2)

		if (pressure_loss and not self.pressure_loss_identified) then
			self.pressure_loss_identified = true
			local task = SayTask:new('phrases/WeveLostCabinPressure')
			GetJester():AddTask(task)
			return { task }
		elseif (not pressure_loss and self.pressure_loss_identified) then
			self.pressure_loss_identified = false
		end
	end

	self.check_urge = Urge:new({
		time_to_release = default_interval,
		on_release_function = check_gauge,
		stress_reaction = StressReaction.ignorance,
	})
	self.check_urge:Restart()
end

function ObserveCockpitPressureIndicator:Tick()
	if self.check_urge then
		self.check_urge:Tick()
	end
end

ObserveCockpitPressureIndicator:Seal()
return ObserveCockpitPressureIndicator
