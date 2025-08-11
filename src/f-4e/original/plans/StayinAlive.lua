---// StayinAlive.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require('base.Class')
local Plan = require('base.Plan')
local EjectTask = require('tasks.common.Eject')
local Math = require('base.Math')
local Utilities = require ('base.Utilities')

local StayinAlive = Class(Plan)

local vv_normal_threshold = ft(9000) / min(1)
local vv_stall_threshold = ft(6000) / min(1)
local flat_spin_vv_normal_threshold = ft(4000) / min(1)
local flat_spin_angular_rate_threshold = deg(30) / s(1)
local ejecting_timer_threshold = s(0.2)
local stall_timer_increase_time_to_impact_threshold = s(2)
local spin_timer_increase_time_to_impact_threshold = s(7)
local time_to_impact_normal_threshold = s(1.1)
local time_to_impact_stall_threshold = s(3.2) --s(5.8)
local time_to_impact_spin_threshold = s(4.2) --s(10)
local g_elongate_time_to_crash_threshold = u(1.4)
local g_elongate_time_to_crash_stall_threshold = u(1.8)
local inverted_timer_threshold = s(2)
local heavy_damage_timer_threshold = s(4)

local max_aoa_limit = deg(23)

StayinAlive.eject_timer = s(0)
StayinAlive.spin_timer = s(0)
StayinAlive.stall_timer = s(0)
StayinAlive.heavy_damage_timer = s(0)
StayinAlive.inverted_timer = s(0)

function StayinAlive:Constructor()
	Plan.Constructor(self)
end

function StayinAlive:Tick()
	self:MonitorEjection()
end

local EjectNow = function( log_mssg )
	if not GetJester().memory:GetIsEjecting( ) then
		local eject_task = EjectTask:new()
		eject_task:SetPriority(2)
		Log( log_mssg )
		GetJester():AddTask(eject_task)
		GetJester().memory:SetIsEjecting( true )
	end
end

function StayinAlive:MonitorEjection()

	-- Going to check if we've initiated ejection from LandingAdvisory, which is a special case re Ejection.
	-- Otherwise, it "doubles up" and JESTER does weird shit atm.
	local landing_advisory_behaviour = GetJester().behaviors[LandingAdvisory] or false
	if landing_advisory_behaviour then
		if landing_advisory_behaviour.has_ejected then
			return
		end
	end

	local dogfight = GetJester().behaviors[DogfightAdvisory] or false

	local jester = GetJester()
	local velocity_vector = jester.awareness:GetObservation("gods_velocity_ned")
	local vertical_velocity = (velocity_vector and velocity_vector.z) or mps(0)
	local g_force = jester.awareness:GetObservation("g_force")
	local aoa = jester.awareness:GetObservation("angle_of_attack") or deg(0)
	local angular_velocity = jester.awareness:GetObservation("gods_angular_velocity_body")
	local angular_rate = (angular_velocity and angular_velocity.z) or deg(0) / s(1)
	local inverted = jester.awareness:GetObservation("is_inverted") or false

	--local were_damaged = jester.memory:GetWeAreDamaged()
	local were_critically_damaged = jester.memory:GetWeAreCriticallyDamaged()
	local stalling = aoa > max_aoa_limit

	local vv_threshold = vv_normal_threshold
	local time_to_impact_threshold = time_to_impact_normal_threshold

	if dogfight then
		time_to_impact_threshold = s(0.2) --disable almost fully
		stall_timer_increase_time_to_impact_threshold = s(5)
	end

	local spin = false
	local log_message = "Eject! Going to hit the ground"
	if self.stall_timer > stall_timer_increase_time_to_impact_threshold then
		time_to_impact_threshold = time_to_impact_stall_threshold
		vv_threshold = vv_stall_threshold
		g_elongate_time_to_crash_threshold = g_elongate_time_to_crash_stall_threshold
		log_message = "Eject! Stalling!"
	elseif self.spin_timer > spin_timer_increase_time_to_impact_threshold then
		time_to_impact_threshold = time_to_impact_spin_threshold
		spin = true
		vv_threshold = vv_stall_threshold
		log_message = "Eject! Spinning!"
	end

	if angular_rate ~= nil and Math.Abs(angular_rate) > flat_spin_angular_rate_threshold and vertical_velocity ~= nil and vertical_velocity > flat_spin_vv_normal_threshold then
		-- flat spin
		self.spin_timer = self.spin_timer + Utilities.GetTime().dt
	elseif self.spin_timer > s(0) then
		self.spin_timer = self.spin_timer - Utilities.GetTime().dt
	end

	if inverted then
		self.inverted_timer = self.inverted_timer + Utilities.GetTime().dt
	else
		self.inverted_timer = s(0)
	end

	if stalling and vertical_velocity ~= nil and vertical_velocity > vv_stall_threshold then
		self.stall_timer = self.stall_timer + Utilities.GetTime().dt
	else
		self.stall_timer = s(0)
	end

	if were_critically_damaged then
		self.heavy_damage_timer = self.heavy_damage_timer + Utilities.GetTime().dt
	else
		self.heavy_damage_timer = s(0)
	end

	local ejecting_condition = false

	local flying_inverted = inverted_timer_threshold < self.inverted_timer

	local time_to_impact = jester.awareness:GetObservation("time_to_ground_impact")

	if self.heavy_damage_timer > heavy_damage_timer_threshold then
		EjectNow( "Eject! Heavy Damage!" )
	elseif vertical_velocity ~= nil and vertical_velocity > vv_threshold and g_force ~= nil and not flying_inverted and time_to_impact then
		if not spin then
			if g_force > g_elongate_time_to_crash_threshold then
				time_to_impact = time_to_impact * g_force
			end
		end
		if time_to_impact ~= nil and time_to_impact < time_to_impact_threshold then
			ejecting_condition = true
		end
	end

	if ejecting_condition then
		self.eject_timer = self.eject_timer + Utilities.GetTime().dt
	else
		self.eject_timer = s(0)
	end

	if self.eject_timer > ejecting_timer_threshold then
		log_message = string.format("%s - Time to impact = %.2f seconds, AOA = %.2f degrees, G-force = %.2f", log_message, time_to_impact.value or 0, aoa.value or 0, g_force.value or 0)
		EjectNow( log_message )
	end
end

ListenTo("proxy_eject", "StayinAlive", function(task, arg)
	EjectNow( "Eject! Proxy command." )
end)

StayinAlive:Seal()
return StayinAlive
