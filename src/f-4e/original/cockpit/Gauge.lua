---// Gauge.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require('base.Class')
local Math = require('base.Math')

local Gauge = Class()

function Gauge:Constructor(init_data)
	assert(init_data)
	self.observation_name = init_data.observation_name
	self.connector = init_data.connector
	self.property = init_data.property
	self.precision = init_data.precision
	self.time_to_read = init_data.time_to_read
	self.requires_focus = init_data.requires_focus
	if self.requires_focus == nil then
		self.requires_focus = true
	end
	assert(self.connector)
	assert(self.property)
end

function Gauge:GetValue()
	if self.property and self.property:IsValid() then
		if self.precision then
			return Math.RoundTo(self.property.value, self.precision)
		else
			return self.property.value
		end
	end
end

function Gauge:CanObserve()
	local eyeballs = GetJester():GetEyeballs()
	if eyeballs and self.connector and self.connector:IsValid() then
		if self.requires_focus then
			return eyeballs:IsPointInFocus(self.connector:GetPositionBody())
		else
			return eyeballs:IsPointVisible(self.connector:GetPositionBody())
		end
	end
	return false
end

Gauge:Seal()

return Gauge
