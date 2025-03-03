---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.
---
local Class = require('base.Class')
local Math = require('base.Math')
local SayAction = require('actions.SayAction')
local Task = require('base.Task')

local SayFuelQuantity = Class(Task)

function SayFuelQuantity:Constructor(fuel_quantity)
	Task.Constructor(self)

	local on_activation = function()
		self:RemoveAllActions()

		local fuel_quantity_hundreds = Math.FloorTo(fuel_quantity:ConvertTo(lb), lb(100))

		if fuel_quantity_hundreds > lb(20500) then
			self:AddAction(SayAction('misc/20500fuel'))
		elseif fuel_quantity_hundreds > lb(1500) then
			-- Steps of 500, e.g. 1500, 2000, 2500, ..., 20000, 20500

			-- Round to '500
			local lower_limit = Math.FloorTo(fuel_quantity:ConvertTo(lb), lb(1000)) -- e.g. 12,000
			local center_limit = lower_limit + lb(500) -- e.g. 12,500

			local nearest_quantity
			if fuel_quantity_hundreds < center_limit then
				nearest_quantity = lower_limit
			else
				nearest_quantity = center_limit
			end

			local phrase = 'misc/' .. nearest_quantity.value .. 'fuel'
			self:AddAction(SayAction(phrase))
		elseif fuel_quantity_hundreds > lb(100) then
			-- Steps of 100, e.g. 100, 200, 300, ..., 1400, 1500
			local phrase = 'misc/' .. fuel_quantity_hundreds.value .. 'fuel'
			self:AddAction(SayAction(phrase))
		else
			self:AddAction(SayAction('misc/outoffuel'))
		end
	end

	self:AddOnActivationCallback(on_activation)
end

SayFuelQuantity:Seal()
return SayFuelQuantity
