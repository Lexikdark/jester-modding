---// SayAltitude.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.
---
local Class = require('base.Class')
local SayAction = require('actions.SayAction')
local SayRandomAction = require('actions.SayRandomAction')
local Task = require('base.Task')
local Timer = require 'base.Timer'

local SayApproachAltitude = Class(Task)

local max_delay_time = s(0.5)

SayApproachAltitude.thousand_ft = ft(1000)
SayApproachAltitude.five_hundred_ft = ft(500)
SayApproachAltitude.four_hundred_ft = ft(400)
SayApproachAltitude.three_hundred_ft = ft(300)
SayApproachAltitude.two_hundred_ft = ft(200)
SayApproachAltitude.one_hundred_ft = ft(100)
SayApproachAltitude.fifty_ft = ft(50)
SayApproachAltitude.thirty_ft = ft(30)
SayApproachAltitude.ten_ft = ft(10)

function SayApproachAltitude:Constructor( altitude )
	Task.Constructor(self)

	self.delayed = false
	self.delay_timer = Timer:new(max_delay_time, function()
		self.delayed = true
	end)

	local on_activation = function ()
		self:RemoveAllActions()

		if self.delay_timer then
			self.delay_timer:Kill()
			self.delay_timer = nil
		end

		if altitude and not self.delayed then
			if altitude == self.thousand_ft then
				self:AddAction(SayAction('checklists/1000ft'))
			elseif altitude == self.five_hundred_ft then
				self:AddAction(SayAction('checklists/500ft'))
			elseif altitude == self.four_hundred_ft then
				self:AddAction(SayAction('checklists/400ft'))
			elseif altitude == self.three_hundred_ft then
				self:AddAction(SayAction('checklists/300ft'))
			elseif altitude == self.two_hundred_ft then
				self:AddAction(SayAction('checklists/200ft'))
			elseif altitude == self.one_hundred_ft then
				self:AddAction(SayAction('checklists/100ft'))
			elseif altitude == self.fifty_ft then
				self:AddAction(SayAction('checklists/50ft'))
			elseif altitude == self.thirty_ft then
				self:AddAction(SayAction('checklists/30ft'))
			elseif altitude == self.ten_ft then
				local calls = {{'checklists/10ft', percent(97)}, {'checklists/retard', percent(3)}}
				self:AddAction(SayRandomAction( calls ))
			end
		end
	end
	self:AddOnActivationCallback(on_activation)
end

SayApproachAltitude:Seal()
return SayApproachAltitude
