
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require('base.Class')
local Behavior = require('base.Behavior')
local Memory = require('memory.Memory')
local Task = require('base.Task')
local Utilities = require ('base.Utilities')

local helmet_check_interval = s(5)
local helmet_timer = s(0)

local Preflight = Class(Behavior)

function Preflight:Constructor()
	Behavior.Constructor(self)
end

function Preflight:Tick()

	helmet_timer = helmet_timer + Utilities.GetTime().dt
	if helmet_timer > helmet_check_interval then

		local jester_helmet_on = GetJester().awareness:GetObservation("wso_helmet_on")
		local pilot_helmet_on = GetJester().awareness:GetObservation("pilot_helmet_on")

		--Jester follows player helmet. OFF vs ON is a bit wonky because of the backend switch.
		if not jester_helmet_on and pilot_helmet_on then
			local task = Task:new():Click("Equip Helmet", "OFF")
			GetJester():AddTask(task)
		end

		if jester_helmet_on and not pilot_helmet_on then
			local task = Task:new():Click("Equip Helmet", "ON")
			GetJester():AddTask(task)
		end
		helmet_timer = s(0)
	end

end

Preflight:Seal()
return Preflight
