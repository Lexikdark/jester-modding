---// Copyright (c) 2024 Heatblur Simulations. All rights reserved.
---
local Class = require('base.Class')
local Interactions = require('base.Interactions')
local NavInteractions = require('tasks.navigation.NavInteractions')
local SayTask = require('tasks.common.SayTask')
local Task = require('base.Task')
local Waypoint = require('base.Waypoint')

local SwitchToNextTurnPointMSFS = Class(Task)
SwitchToNextTurnPointMSFS.is_nav_fix = false

function SwitchToNextTurnPointMSFS:Constructor( nav_fix )
	Task.Constructor(self)
	self.is_nav_fix = nav_fix or false

	local on_activation = function ()
		Log( "Switch To Next Turn Point Task Activated" ) --todo delete
		self:RemoveAllActions()

		local memory = GetJester().memory

		local wpt = rawget(_G, "msfs_next_wpt")

		if wpt and memory and wpt.wpt_active and wpt.latitude and wpt.longitude then
			local lat = wpt.latitude.value
			local lon = wpt.longitude.value
			local phrase = 'misc/nextturnpointsteeringset'
			if self.is_nav_fix then
				phrase = 'misc/newturnpointfixset'
			end
			memory:SetIsCapping( false )

			if lat and lon then
				local switching_task = Task:new( )
				switching_task = NavInteractions.SetNewActiveTGT2Coords( switching_task, lat, lon )
				switching_task:Require({ voice = true, hands = true })
				switching_task:Wait(s(0.4), { voice = true })
				switching_task:Say( phrase )
				GetJester():AddTask(switching_task)
			end
		end
		return
	end

	self:AddOnActivationCallback(on_activation)
end

SwitchToNextTurnPointMSFS:Seal()
return SwitchToNextTurnPointMSFS
