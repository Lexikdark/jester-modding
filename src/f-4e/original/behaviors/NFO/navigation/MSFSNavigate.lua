---// Copyright (c) 2024 Heatblur Simulations. All rights reserved.

local Class = require('base.Class')
local Behavior = require('base.Behavior')
local Urge = require('base.Urge')
local NavInteractions = require('tasks.navigation.NavInteractions')
local PerformNavFix = require('tasks.navigation.PerformNavFix')
local SwitchToNextTurnPointMSFS = require('tasks.navigation.SwitchToNextTurnPointMSFS')
local StressReaction = require('base.StressReaction')
local SayTask = require('tasks.common.SayTask')
local SwitchTask = require('tasks.common.SwitchTask')
local Task = require('base.Task')
local Utilities = require('base.Utilities')
local Waypoint = require('base.Waypoint')

local default_distance = NM(20)
local default_change_threshold = NM(2)
local bdhi_distance_meter = '/Bearing Distance Heading Indicator/BDHI Meter'
local nav_comp_relay = '/Navigation Computer Relay'

local MSFSNavigate = Class(Behavior)
MSFSNavigate.distance = default_distance
MSFSNavigate.flying_towards_wpt = true
MSFSNavigate.waypoint = nil
MSFSNavigate.next_waypoint = nil
MSFSNavigate.is_holding = false
MSFSNavigate.next_wp_awaits = false
MSFSNavigate.reported_15NM = false
MSFSNavigate.reported_10NM = false
MSFSNavigate.reported_5NM = false
MSFSNavigate.reported_2NM = false

MSFSNavigate.position_fix_awaiting = false
MSFSNavigate.min_flyover_distance = NM(10)
MSFSNavigate.fix_awaiting_time = s(0)

local last_change_next_waypoint_threshold_time = s(2)
local last_change_waypoint_threshold_time = s(10)
local last_change_waypoint_prepare_fix_threshold_time = s(4)
local fix_awaiting_time_threshold = s(2)
local fix_successful_distance_threshold = NM(0.15)
local resetting_flags_distance_threshold = NM(2)

function MSFSNavigate:GetDistance()
	local waypoint = self.waypoint
	if waypoint == nil then
		return m(0)
	end
	local wpt_type = waypoint:GetSpecialWaypointType()

	if not wpt_type then
		io.stderr:write("Invalid WPT Type\n")
	end

	if wpt_type == "VIP" or wpt_type == "VIP_SILENT" then
		local function CalculateDistance(lat1, lon1, lat2, lon2)
			local radius = 6371 * 1000 -- Earth's radius in meters
			local dLat = lat2 - lat1
			local dLon = lon2 - lon1
			local lLat = dLat * radius
			local lLon = dLon * radius * math.cos(lat2)
			local distance = math.sqrt( lLat * lLat + lLon * lLon )
			return m( distance )
		end

		local latitude = jester.awareness:GetObservation("latitude")
		local longitude = jester.awareness:GetObservation("longitude")
		if latitude and latitude.value and longitude and longitude.value then
			local distance = CalculateDistance(latitude.value, longitude.value, math.rad(waypoint.latitude), math.rad(waypoint.longitude))
			return distance
		else
			io.stderr:write("Failed to retrieve latitude or longitude observations\n")
			return m(0)
		end
	else
		local property = GetProperty(bdhi_distance_meter, 'Distance Indication')
		if property and property:IsValid() then
			return property.value
		else
			io.stderr:write("Navigate BDHI Distance property invalid\n")
		end
	end
end

function MSFSNavigate:GetFlyingTowardsWpt()
	return self.flying_towards_wpt
end

function MSFSNavigate:GetIsInOffsetMode()
	local property = GetProperty(nav_comp_relay, 'Target Insert Signal')
	if property and property:IsValid() then
		return property.value
	else
		io.stderr:write("Navigate Target Insert Signal property invalid\n")
		return false
	end
end

function MSFSNavigate:TrySwitchingWaypoint()
	--Log("Try Switching Waypoint")
	if self.next_waypoint then
		local is_nav_fix = self.next_waypoint:GetSpecialWaypointType( ) == "VIP" or false
		local current_time = Utilities.GetTime().mission_time:ConvertTo(s)
		local memory = GetJester().memory
		if self.is_holding == false and memory and (current_time - memory:GetLastChangedWaypointTime()) > last_change_next_waypoint_threshold_time then
			if self.next_waypoint then
				self.waypoint = Waypoint:new(
						self.next_waypoint.latitude,
						self.next_waypoint.longitude,
						false,
						self.next_waypoint:GetWaypointName(),
						"DEFAULT"
				)
			end

			local task = SwitchToNextTurnPointMSFS:new( is_nav_fix )
			GetJester():AddTask(task)
			memory:UpdateLastChangedWaypointTime()
			self.next_wp_awaits = false
			return { task }
		else
			self.next_wp_awaits = true
		end
	end
end

function MSFSNavigate:SetWptAsNavFix()
	if self.waypoint then
		self.waypoint:SetDesignation( "VIP" )
		return true
	end
	return false
end

function MSFSNavigate:SetHoldAtNextWpt( )
	if self.waypoint then
		self.is_holding = true
		return true
	end
	return false
end

function MSFSNavigate:ResumeNav( )
	local return_val = false
	if self.is_holding then
		self.is_holding = false
		return_val = true
	end
	if self.waypoint and self.next_wp_awaits then
		self:TrySwitchingWaypoint()
		return_val = true
	end
	return return_val
end

function MSFSNavigate:UpdateNextWaypoint()
	local wpt = rawget(_G, "msfs_next_wpt")

	--Log("Update next wpt")

	if wpt and wpt.wpt_active and wpt.latitude and wpt.longitude then
		local lat = wpt.latitude.value
		local lon = wpt.longitude.value

		if lat and lon then
			--Log( string.format("Next Wpt Updated, lat : %.2f deg, lon: %.2f deg", lat or 0, lon or 0) )
			self.next_waypoint = Waypoint:new( lat, lon, false, "MSFS Wpt", "DEFAULT" )
			local is_curr_vip = ( self.waypoint and self.waypoint.GetSpecialWaypointType
					and self.waypoint:GetSpecialWaypointType() == "VIP" ) or false
			if not is_curr_vip then
				self:TrySwitchingWaypoint()
			else
				self.next_wp_awaits = true
			end
		end
	end
end

function MSFSNavigate:Constructor()
	Behavior.Constructor(self)
	NavInteractions:SetNavigateInstance(self)

	self.initialized = false

	local check_distance = function()
		local cockpit = GetJester():GetCockpit()
		local memory = GetJester().memory

		local bdhi_mode = cockpit:GetManipulator("BDHI Mode"):GetState()
		if bdhi_mode ~= nil then
			if bdhi_mode ~= "NAV_COMP" then
				memory:UpdateLastChangedWaypointTime()
				local task = SwitchTask:new("BDHI Mode", "NAV_COMP")
				GetJester():AddTask(task)
				return { task }
			end
		end

		local new_distance = self:GetDistance()
		self.flying_towards_wpt = new_distance < self.distance
		self.distance = new_distance

		local function MonitorPrepareNavFix( )
			local current_time = Utilities.GetTime().mission_time:ConvertTo(s)

			if memory and self.distance < default_change_threshold and not self.position_fix_awaiting
					and self.flying_towards_wpt
					and (current_time - GetJester().memory:GetLastChangedWaypointTime()) > last_change_waypoint_prepare_fix_threshold_time then
				if self.waypoint ~= nil then
					local task = Task:new()
					GetJester():AddTask(NavInteractions.PrepareNavFix( task, self.waypoint.latitude, self.waypoint.longitude ))
					self.position_fix_awaiting = true
					return { task }
				end
			end
		end

		local function CheckReportingDistanceToWaypoint(  )
			local current_time = Utilities.GetTime().mission_time:ConvertTo(s)

			if self.waypoint then
				local wpt_type = self.waypoint:GetSpecialWaypointType()

				local phrases = {
					IP = { ['15'] = 'misc/ipfifteenmiles', ['10'] = 'misc/iptenmiles', ['5'] = 'misc/ipfivemiles', ['2'] = 'misc/iptwomiles' },
					VIP = { ['10'] = 'misc/fixtenmiles', ['5'] = 'misc/fixfivemiles' },
					TARGET = { ['10'] = 'misc/targettenmiles', ['5'] = 'misc/targetfivemiles', ['2'] = 'misc/targettwomiles' },
					FENCE_IN = { ['5'] = 'misc/fenceinfivemiles' },
					FENCE_OUT = { ['5'] = 'misc/fenceoutfivemiles' },
					HOMEBASE = { ['2'] = 'misc/homebase' },
					CAP = { ['2'] = 'misc/capstationarrive' },--report just once when capping
				}

				for distance, phrase in pairs(phrases[wpt_type] or {}) do
					if self.distance < NM(tonumber(distance) + 0.6) and self.distance >= NM(tonumber(distance) - 0.5)
							and self.flying_towards_wpt
							and not self['reported_' .. distance .. 'NM']
							and (current_time - memory:GetLastChangedWaypointTime()) > last_change_waypoint_threshold_time then
						self['reported_' .. distance .. 'NM'] = true
						local report_task = SayTask:new(phrase)
						GetJester():AddTask(report_task)
						return { report_task }
					end
				end

				-- Resetting flags
				local all_distances = {'15', '10', '5', '2'}
				for _, distance in ipairs(all_distances) do
					local nm_distance = NM(tonumber(distance))
					if self.distance > nm_distance + resetting_flags_distance_threshold or self.distance < nm_distance - resetting_flags_distance_threshold then
						local flag_key = 'reported_' .. distance .. 'NM'
						if self[flag_key] then
							self[flag_key] = false
						end
					end
				end

			end
		end

		if self.distance and self.waypoint and not self:GetIsInOffsetMode() then
			local wpt_type = self.waypoint:GetSpecialWaypointType()
			local report_task = CheckReportingDistanceToWaypoint()
			if report_task then return report_task end
			if wpt_type == "VIP" or wpt_type == "VIP_SILENT" then
				return MonitorPrepareNavFix( )
			end
		end
	end

	self.check_distance_urge = Urge:new({
		time_to_release = s(10),
		on_release_function = check_distance,
		stress_reaction = StressReaction.ignorance,
	})
	self.check_distance_urge:Restart()
end

function MSFSNavigate:Tick()
	if not self.initialized then
		self:Initialize()
	end

	if self.check_distance_urge and self.waypoint ~= nil then
		if self.distance < NM(5) then
			self.check_distance_urge:SetGainRateMultiplier(5)
		elseif self.distance < default_distance then
			self.check_distance_urge:SetGainRateMultiplier(2)
		else
			self.check_distance_urge:SetGainRateMultiplier(0.5)
		end

		self.check_distance_urge:Tick()
	end

	if self.waypoint then
		local wpt_type = self.waypoint:GetSpecialWaypointType()
		if ( wpt_type == "VIP" or wpt_type == "VIP_SILENT" ) and self.position_fix_awaiting then
			self:MonitorNavFix( )
		end
	end
end

function MSFSNavigate:Initialize()
	self:UpdateNextWaypoint()
	self.initialized = true
end

function MSFSNavigate:MonitorNavFix()
	self.fix_awaiting_time = self.fix_awaiting_time + Utilities.GetTime().dt
	self:ObserveClosing()

	if not self.flying_towards_wpt and self.fix_awaiting_time > fix_awaiting_time_threshold then
		local fix_successful = self.min_flyover_distance < fix_successful_distance_threshold
		self.position_fix_awaiting = false
		Log( string.format( "Finishing Nav fix. Distance: %.2f m", self.min_flyover_distance.value ) )
		self:ResetFlyoverMinDistance()
		self.fix_awaiting_time = s(0)

		local finish_fix_task = PerformNavFix:new( fix_successful )
		GetJester():AddTask(finish_fix_task)
		if fix_successful and self.next_wp_awaits then
			local switch_wpt_task = self:TrySwitchingWaypoint( )
		end
	end
end


function MSFSNavigate:ObserveClosing()
	local new_distance = self:GetDistance()
	self.flying_towards_wpt = new_distance <= self.distance
	self.distance = new_distance

	if self.distance < self.min_flyover_distance then
		self.min_flyover_distance = self.distance
		--Log( string.format( "Closing. Distance: %.2f", self.distance.value ) )
	end
end

function MSFSNavigate:ResetFlyoverMinDistance()
	self.min_flyover_distance = NM(10)
end

function MSFSNavigate:ResetFlyoverVariables()
	self.position_fix_awaiting = false
	self.min_flyover_distance = NM(10)
	self.fix_awaiting_time = s(0)
end

function MSFSNavigate:ResetNavigationVariables()
	self:ResetFlyoverVariables()
	self:ResetCAPVariables()
end

function MSFSNavigate:ResetCAPVariables()
end

function MSFSNavigate:SetCAPTimeLeft(time)
end

function MSFSNavigate:GetCAPTimeHasLeft()
	return true
end

ListenTo("msfsnav_wpt_updated", "MSFSNavigate", function(task)
	local navigate_behaviour = GetJester().behaviors[MSFSNavigate]
	if navigate_behaviour ~= nil then
		navigate_behaviour:UpdateNextWaypoint( )
	end
end)

MSFSNavigate:Seal()
return MSFSNavigate
