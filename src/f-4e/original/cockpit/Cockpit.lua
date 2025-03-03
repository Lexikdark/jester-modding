---// Cockpit.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require('base.Class')
local Gauge = require('cockpit.Gauge')
local Manipulator = require('cockpit.Manipulator')

local Cockpit = Class()

Cockpit.gauges = {}
Cockpit.manipulators = {}
Cockpit.observation_map = {}

function Cockpit:AddGauge(name, gauge_init)
	assert(gauge_init)
	local gauge = Gauge:new(gauge_init)
	self.gauges[name] = gauge
	if gauge.observation_name then
		self.observation_map[gauge.observation_name] = gauge
	end
end

function Cockpit:AddManipulator(name, manipulator_init)
	assert(manipulator_init)
	local manipulator = Manipulator:new(manipulator_init)
	self.manipulators[name] = manipulator
end

function Cockpit:GetManipulator(name)
	return self.manipulators[name]
end

function Cockpit:Tick()
	local awareness = GetJester().awareness
	for observation_name, gauge in pairs(self.observation_map) do
		if gauge:CanObserve() then
			local value = gauge:GetValue()
			awareness:AddOrUpdateObservation(observation_name, value)
		end
	end
end

Cockpit:Seal()

return Cockpit
