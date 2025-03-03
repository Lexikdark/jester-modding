---// SayContactOClock.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require('base.Class')
local Math = require('base.Math')
local SayAction = require('actions.SayAction')
local Task = require('base.Task')
local Utilities = require('base.Utilities')

local SayContactOClock = Class(Task)

function SayContactOClock:Constructor(contact)
	Task.Constructor(self)
	if contact then
		self.contact = contact
		local on_activation = function ()
			self:RemoveAllActions()

			if contact.polar_body and contact.polar_ned then
				local elevation_body = contact.polar_body.elevation
				local elevation_ned = contact.polar_ned.elevation
				if elevation_body > deg(50) and elevation_ned > deg(50) then
					self:AddAction(SayAction('spotting/high'))
				elseif elevation_body < deg(-50) and elevation_ned < deg(-50) then
					self:AddAction(SayAction('spotting/low'))
				else
					local azimuth = contact.polar_body.azimuth
					local azimuth360 = Math.Wrap360(azimuth)
					local o_clock = Utilities.AngleToOClock(azimuth360)
					local phrase = 'spotting/' .. o_clock .. 'oclock'
					if elevation_body > deg(25) and elevation_ned > deg(25) then
						phrase = phrase .. 'high'
					elseif elevation_body < deg(-25) and elevation_ned < deg(-25) then
						phrase = phrase .. 'low'
					end
					self:AddAction(SayAction(phrase))
				end
			end
		end
		self:AddOnActivationCallback(on_activation)
	else
		io.stderr:write("AddOnActivationCallback invalid contact\n")
	end
end

SayContactOClock:Seal()
return SayContactOClock
