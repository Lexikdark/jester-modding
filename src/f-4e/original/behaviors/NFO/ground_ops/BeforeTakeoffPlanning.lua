---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require('base.Class')
local Behavior = require('base.Behavior')
local MinimumAltitudePlanning = require('tasks.navigation.MinimumAltitudePlan')
local Utilities = require('base.Utilities')
local Task = require('base.Task')
local PaveSpike = require('other.PaveSpike')
local RadarApi = require('radar.Api')
require('memory.Memory')

local BeforeTakeoffPlanning = Class(Behavior)
BeforeTakeoffPlanning.has_prepared_taxi_equipment = false

local taxiing_timer = s(0)
local fix_hotspawn_deadzone_timer = s(5)

function BeforeTakeoffPlanning:Constructor()
	Behavior.Constructor(self)
end

function BeforeTakeoffPlanning:Tick()

	local on_runway = GetJester().awareness:GetObservation("on_runway")

	local has_been_airborne = GetJester().memory:GetHasBeenAirborne()

	-- Hot spawn airborne, never ask for now so set as true.
	if spawn_data.hot_start_in_air or on_runway or has_been_airborne then
		GetJester().memory:SetHasAskedAboutLowestAltitude(true)
	end

	--Do nothing for 5 seconds because DCS jumping suspension on spawn and shit causes the speedgate to run..
	fix_hotspawn_deadzone_timer = fix_hotspawn_deadzone_timer - Utilities.GetTime().dt
	if fix_hotspawn_deadzone_timer > s(0) then
		return
	end

	local airspeed = kt(0)
	if GetJester().awareness:GetObservation("ground_speed") then
		airspeed = GetJester().awareness:GetObservation("ground_speed")
	else
		return
	end

	--If we've taxii'd for 10 seconds; trigger minimum altitude QnA.
	if not GetJester().memory:HasAskedAboutLowestAltitude() then
		if airspeed > kt(5) then
			taxiing_timer = taxiing_timer + Utilities.GetTime().dt
		else
			taxiing_timer = s(0)
		end
		if taxiing_timer > s(25) then
			if airspeed < kt(60) then
				--This check is to avoid the planning if you're speeding on a taxiway or something like a madman.
				GetJester():AddTask(MinimumAltitudePlanning:new())
				GetJester().memory:SetHasAskedAboutLowestAltitude(true)
			end
		end
	end

	if airspeed > kt(5) and not self.has_prepared_taxi_equipment then
		GetJester():AddTask(PaveSpike.SetOperatingMode(Task:new(), "standby"))
		GetJester():AddTask(RadarApi.SetOperatingMode(Task:new(), "standby"))
		self.has_prepared_taxi_equipment = true
	end

end

BeforeTakeoffPlanning:Seal()
return BeforeTakeoffPlanning
