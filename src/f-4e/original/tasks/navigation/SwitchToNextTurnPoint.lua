---// Copyright (c) 2024 Heatblur Simulations. All rights reserved.
---
local Class = require('base.Class')
local Interactions = require('base.Interactions')
local NavInteractions = require('tasks.navigation.NavInteractions')
local SayTask = require('tasks.common.SayTask')
local UpdateJesterWheel = require('behaviors.UpdateJesterWheel')
local Task = require('base.Task')
local Waypoint = require('base.Waypoint')

local SwitchToNextTurnPoint = Class(Task)
local Navigate = nil

function SwitchToNextTurnPoint:Constructor()
	Task.Constructor(self)

	local on_activation = function ()
		self:RemoveAllActions()

		local memory = GetJester().memory
		local flightplan = memory:GetActiveFlightPlan()
		local next_wpt_bool = false
		local next_wpt = nil

		-- Check if currently capping and handle CAP waypoint switch
		if memory:GetIsCapping() then
			if Navigate ~= nil and Navigate:GetCAPTimeHasLeft() then
				next_wpt_bool = memory:SwitchToNextWptAfterCAP2()
				if next_wpt_bool then
					Navigate:ResetCAPVariables()
				end
			else
				next_wpt_bool = memory:SwitchToNextCAPWaypoint()
			end
		end

		if not next_wpt_bool then
			next_wpt_bool = memory:SwitchToNextTurnPoint()
		end

		next_wpt = memory:GetActiveWaypoint()

		if flightplan ~= nil and next_wpt_bool == true and next_wpt ~= nil then

			local wpt_special_type = next_wpt:GetSpecialWaypointType( )

			local phrases = {
				DEFAULT = 'misc/nextturnpointsteeringset',
				CAP = 'misc/newturnpointcapstationset',
				IP = 'misc/newturnpointipset',
				TARGET = 'misc/newturnpointtargetset',
				VIP = 'misc/newturnpointfixset',
				VIP_SILENT = 'misc/nextturnpointsteeringset',
				FENCE_IN = 'misc/newturnpointfenceinset',
				FENCE_OUT = 'misc/newturnpointfenceoutset',
				HOMEBASE = 'misc/newturnpointhomeset',
			}

			local phrase = phrases[wpt_special_type] or phrases.DEFAULT
			if wpt_special_type == "CAP" and memory:GetActiveWaypointHasCAPCounterpart() then
				if memory:GetIsCapping() then
					local cap_type = memory:GetActiveWptCAPType()
					if cap_type == 1 then
						phrase = 'misc/newturnpointbacktocaponeset'
					elseif cap_type == 2 then
						phrase = 'misc/newturnpointbacktocaptwoset'
					end
				else
					memory:SetIsCapping( true )
				end
			else
				memory:SetIsCapping( false )
			end

			local switching_task = Task:new( )

			local next_latitude = next_wpt.latitude
			local next_longitude = next_wpt.longitude
			switching_task = NavInteractions.SetNewActiveTGT2Coords( switching_task, next_latitude, next_longitude )
			switching_task:Require({ voice = true, hands = true })
			switching_task:Wait(s(0.4), { voice = true })
			switching_task:Say( phrase )
			GetJester():AddTask(switching_task)
			local update_wheel_behaviour = GetJester().behaviors[UpdateJesterWheel]
			if update_wheel_behaviour ~= nil then
				update_wheel_behaviour:UpdateFlightplans()
			end
			return
		end
	end

	self:AddOnActivationCallback(on_activation)
end

function SwitchToNextTurnPoint:SetNavigateInstance( navigate_in )
	if navigate_in ~= nil then
		Navigate = navigate_in
	else
		io.stderr:write("Nav instance is NIL\n")
	end
end

SwitchToNextTurnPoint:Seal()
return SwitchToNextTurnPoint
