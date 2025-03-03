---// Copyright (c) 2024 Heatblur Simulations. All rights reserved.
---
local Class = require('base.Class')
local Interactions = require('base.Interactions')
local NavInteractions = require('tasks.navigation.NavInteractions')
local SayTask = require('tasks.common.SayTask')
local Task = require('base.Task')

local PerformNavFix = Class(Task)
PerformNavFix.distance = NM(10)
PerformNavFix.flying_towards_wpt = true

function PerformNavFix:Constructor( successful )
	Task.Constructor(self)

	local on_activation = function ()
		self:RemoveAllActions()

		if successful then
			Log("VIP Update Successful")
			local report_task = SayTask:new( 'misc/fixsuccess' )
			NavInteractions.ReleaseNavFix( report_task )
			report_task:SetPriority(1.5)
			report_task:Wait(s(0.3), { hands = true, voice = true })
			GetJester():AddTask( report_task )
		else
			Log("VIP Update NO success")
			local report_task = SayTask:new( 'misc/fixnosuccess' )
			report_task:SetPriority(1.1)
			NavInteractions.SetPositionUpdateSwitch(report_task, "normal")
			GetJester():AddTask( report_task )
		end
	end

	self:AddOnActivationCallback(on_activation)
end

PerformNavFix:Seal()
return PerformNavFix