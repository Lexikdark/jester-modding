---// SaySpeed.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.
---
local Class = require('base.Class')
local Math = require('base.Math')
local SayAction = require('actions.SayAction')
local Task = require('base.Task')
local Utilities = require('base.Utilities')

local SaySpeed = Class(Task)

function SaySpeed:Constructor(speed, previous_speed)
	Task.Constructor(self)

	local on_activation = function ()
		local speed_tens_kt = Math.RoundTo(speed:ConvertTo(kt), kt(10))

		if previous_speed then
			local previous_speed_tens_kt = Math.RoundTo(previous_speed:ConvertTo(kt), kt(10))
			if speed_tens_kt == previous_speed_tens_kt then
				-- Do not repeat the previous callout again
				return
			end
		end

		if speed_tens_kt < kt(100) then
			self:AddAction(SayAction('awareness/wereslow'))
		elseif speed_tens_kt > kt(600) then
			self:AddAction(SayAction('awareness/werefast'))
		else
			local phrase = 'awareness/' .. Utilities.NumberToText(speed_tens_kt.value)
			self:AddAction(SayAction(phrase))
		end
	end

	self:AddOnActivationCallback(on_activation)
end

SaySpeed:Seal()
return SaySpeed
