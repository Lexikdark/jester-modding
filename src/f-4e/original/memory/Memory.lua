local Class = require 'base.Class'
local FlightPlan = require 'memory.FlightPlan'
local MemoryObject = require 'memory.MemoryObject'
local Waypoint = require 'base.Waypoint'
local Utilities = require 'base.Utilities'
local Labels = require 'base.Labels'
local Navigate = require 'behaviors.NFO.navigation.Navigate'
local UpdateJesterWheel = require('behaviors.UpdateJesterWheel')

local Memory = Class()

Memory.objects = {}

Memory.active_flightplan = 0 --0 means no flightplan is active
Memory.memorized_last_active_wpt = { flightplan = 0, waypoint = 0 }
Memory.flightplan_1 = nil
Memory.flightplan_2 = nil
Memory.flightplans_were_initialized = false
Memory.last_changed_waypoint = -s(1000)
Memory.is_capping = false

Memory.last_time_on_ground = s(-500)
Memory.last_time_airborne = s(-500)
Memory.last_time_landed = s(-500)

Memory.has_said_autobots_rollout = false
Memory.has_asked_about_lowest_mission_altitude = false

Memory.alignment_is_done = false
Memory.ins_is_aligning = false
Memory.startup_complete = false
Memory.ready_for_alignment = false
Memory.asked_twice_for_alignment = false
Memory.user_initiates_alignment = false
Memory.start_alignment_option = false
Memory.full_alignment = false
Memory.bath_alignment = false
Memory.hdg_mem_alignment = false
Memory.alignment_aborted = false
Memory.has_said_canopy = false
Memory.has_been_airborne = false
Memory.is_realigning = false
Memory.start_realignment = false
Memory.realignment_complete = false
Memory.alignment_type_chosen = false

Memory.last_hard_landing_timestamp = s(0)
Memory.last_significant_oleo_rate_timestamp = s(0)
Memory.last_takeoff_timestamp = s(0)

Memory.damaged = false
Memory.critically_damaged = false
Memory.is_ejecting = false

Memory.jester_countermeasures_dispensing_allowed = true

function Memory:Constructor()
	self.flightplan_1 = FlightPlan:new()
	self.flightplan_2 = FlightPlan:new()
	self.is_ejecting = false
end

function Memory:LoadFlightplans()
	self.flightplan_1.waypoints = {}
	local waypoint_index = 1

	local flightplan_1_init = flightplan_1_init or {}
	for _, waypoint in ipairs(flightplan_1_init) do
		local lat = waypoint.latitude.value
		local lon = waypoint.longitude.value
		local hold = waypoint.hold
		local name = waypoint.name
		local type = waypoint.special_type

		local waypoint_new = Waypoint:new(lat, lon, hold or false, name or "", type)

		self:InsertNewWaypoint(1, waypoint_new)
		self:SetWaypointDesignation(1, waypoint_index, type)-- needs to be after insertion

		waypoint_index = waypoint_index + 1
	end
end

function Memory:CopyWaypoint(old_waypoint)
	local copied_waypoint = Waypoint:new(
			old_waypoint.latitude,
			old_waypoint.longitude,
			old_waypoint:GetHoldAt(),
			old_waypoint:GetWaypointName(),
			old_waypoint:GetSpecialWaypointType()
	)
	return copied_waypoint
end

function Memory:CopyWithoutDesignation(old_waypoint)
	local copied_waypoint = Waypoint:new(
			old_waypoint.latitude,
			old_waypoint.longitude,
			old_waypoint:GetHoldAt(),
			old_waypoint:GetWaypointName(),
			"DEFAULT"  -- Set the special type to DEFAULT
	)
	return copied_waypoint
end

function Memory:SetWaypointDesignation(flightplan_no, waypoint_no, designation)
	local flightplan = self:GetFlightPlan(flightplan_no)
	if flightplan then
		flightplan:SetDesignation(waypoint_no, designation)
	else
		io.stderr:write("Invalid flightplan number or waypoint index for setting designation\n")
	end
end

function Memory:GetCAPCounterpartWptNo(flightplan_no, waypoint_no)
	local flightplan = self:GetFlightPlan(flightplan_no)
	if flightplan then
		return flightplan:GetCAPPairCounterpartWptNo(waypoint_no)
	end
	return nil
end

function Memory:GetWptCapType(flightplan_no, waypoint_no)
	local flightplan = self:GetFlightPlan(flightplan_no)
	if flightplan then
		return flightplan:GetWptCapType(waypoint_no)
	end
	return 0  -- Not a CAP waypoint
end

function Memory:SetIsCapping( state )
	local is_change = state ~= self.is_capping
	self.is_capping = state

	if is_change then
		if state then
			Log("CAP Mode On")
		else
			Log("CAP Mode Off")
		end
	end

	local update_wheel_behaviour = GetJester().behaviors[UpdateJesterWheel]
	if update_wheel_behaviour ~= nil and is_change then
		update_wheel_behaviour:UpdateFlightplans()
	end
end

function Memory:GetIsCapping()
	return self.is_capping
end

function Memory:GetActiveWaypointType()
	local ftpln_no = self:GetActiveFlightPlanNumber()
	local wpt_no = self:GetActiveWaypointNumber()

	if ftpln_no and wpt_no then
		local waypoint = self:GetWaypoint(ftpln_no, wpt_no)
		if waypoint then
			return waypoint:GetSpecialWaypointType( )
		end
	end
	print("Invalid flightplan number or waypoint index provided")
	return nil
end

function Memory:GetActiveWptCAPType()
	local flightplan = self:GetActiveFlightPlan()
	if flightplan then
		local active_waypoint = flightplan.active_waypoint
		return flightplan:GetWptCapType(active_waypoint)
	end
	return 0  -- Not a CAP waypoint
end

function Memory:InsertNewWaypoint(flightplan_no, waypoint)
	local flightplan = self:GetFlightPlan(flightplan_no)
	if flightplan then
		local copied_waypoint = self:CopyWithoutDesignation(waypoint)
		flightplan:InsertNewWaypoint(copied_waypoint)
	else
		print("Invalid flightplan number provided: ", flightplan_no)
	end
end

function Memory:InsertWaypointAfter(flightplan_no, waypoint_no, new_waypoint)
	local flightplan = self:GetFlightPlan(flightplan_no)
	if flightplan and waypoint_no >= 0 and waypoint_no <= #flightplan.waypoints then
		local copied_waypoint = self:CopyWithoutDesignation(new_waypoint)
		flightplan:InsertWaypointAfter(waypoint_no, copied_waypoint)

		-- Adjust the memorized waypoint index if the new waypoint is inserted before the memorized one
		if self.memorized_last_active_wpt.flightplan == flightplan_no and waypoint_no < self.memorized_last_active_wpt.waypoint then
			self.memorized_last_active_wpt.waypoint = self.memorized_last_active_wpt.waypoint + 1
		end
	else
		Log("Invalid flightplan number or waypoint index for insertion")
		print("Invalid flightplan number or waypoint index for insertion")
	end
end

function Memory:InsertWaypointBefore(flightplan_no, waypoint_no, new_waypoint)
	local flightplan = self:GetFlightPlan(flightplan_no)
	if flightplan and waypoint_no > 0 and waypoint_no <= #flightplan.waypoints + 1 then
		local copied_waypoint = self:CopyWithoutDesignation(new_waypoint)
		flightplan:InsertWaypointBefore(waypoint_no, copied_waypoint)
		-- Adjust the memorized waypoint index if the new waypoint is inserted before the memorized one
		if self.memorized_last_active_wpt.flightplan == flightplan_no and waypoint_no < self.memorized_last_active_wpt.waypoint then
			self.memorized_last_active_wpt.waypoint = self.memorized_last_active_wpt.waypoint + 1
		end
	else
		print("Invalid flightplan number or waypoint index for insertion")
	end
end

function Memory:EditWaypoint(flightplan_no, waypoint_no, new_waypoint)
	local flightplan = self:GetFlightPlan(flightplan_no)
	if flightplan and waypoint_no > 0 and waypoint_no <= #flightplan.waypoints then
		local copied_waypoint = self:CopyWaypoint(new_waypoint)
		flightplan:EditWaypoint(waypoint_no, copied_waypoint)
	else
		print("Invalid flightplan number or waypoint index")
	end
end

function Memory:EditWaypointCoords(flightplan_no, waypoint_no, latitude, longitude)
	local flightplan = self:GetFlightPlan(flightplan_no)
	if flightplan then
		flightplan:EditWaypointCoords(waypoint_no, latitude, longitude)
	else
		print("Invalid flightplan number or waypoint index")
	end
end

function Memory:EditWaypointName(flightplan_no, waypoint_no, name)
	local flightplan = self:GetFlightPlan(flightplan_no)
	if flightplan then
		flightplan:EditWaypointName(waypoint_no, name)
	else
		print("Invalid flightplan number or waypoint index")
	end
end

function Memory:EditWaypointDesignation(flightplan_no, waypoint_no, designation)
	local flightplan = self:GetFlightPlan(flightplan_no)
	if flightplan then
		flightplan:EditWaypointDesignation(waypoint_no, designation)
	else
		print("Invalid flightplan number or waypoint index")
	end
end

function Memory:EditWaypointIsHold(flightplan_no, waypoint_no, is_hold)
	local flightplan = self:GetFlightPlan(flightplan_no)
	if flightplan then
		flightplan:EditWaypointIsHold(waypoint_no, is_hold)
	else
		print("Invalid flightplan number or waypoint index")
	end
end

function Memory:DeleteWaypoint(flightplan_no, waypoint_no)
	local flightplan = self:GetFlightPlan(flightplan_no)
	if flightplan then
		flightplan:DeleteWaypoint(waypoint_no)
		-- Adjust the memorized waypoint index if the waypoint is deleted before the memorized one
		if self.memorized_last_active_wpt.flightplan == flightplan_no and waypoint_no < self.memorized_last_active_wpt.waypoint then
			self.memorized_last_active_wpt.waypoint = self.memorized_last_active_wpt.waypoint - 1
		elseif self.memorized_last_active_wpt.flightplan == flightplan_no and self.memorized_last_active_wpt.waypoint == waypoint_no and waypoint_no > #flightplan.waypoints then
			self.memorized_last_active_wpt.waypoint = 0
		end
	else
		print("Invalid flightplan number or waypoint index for deletion")
	end
end

function Memory:SetActiveFlightPlan(number)
	if number >= 0 and number <= 2 then
		self.active_flightplan = number
	else
		error("Invalid flightplan number")
	end
end

function Memory:SetActiveWaypoint(flightplan_no, waypoint_no)
	-- Deactivate the active waypoint from the other flightplan
	local other_flightplan_no = (flightplan_no == 1) and 2 or 1
	local other_flightplan = (other_flightplan_no == 1) and self.flightplan_1 or self.flightplan_2
	if other_flightplan ~= nil then
		other_flightplan.active_waypoint = 0
	end

	-- Activate the selected waypoint in the specified flightplan
	self:SetActiveFlightPlan(flightplan_no)
	local flightplan = self:GetActiveFlightPlan()
	if waypoint_no >= 0 and flightplan ~= nil and waypoint_no <= #flightplan.waypoints then
		flightplan.active_waypoint = waypoint_no
	else
		error("Invalid waypoint number")
	end
end

function Memory:SetHoldAtWaypoint(flightplan_no, waypoint_no, state)
	local flightplan = self:GetFlightPlan(flightplan_no)
	if flightplan then
		flightplan:SetHoldAtWaypoint(waypoint_no, state)
	else
		error("Invalid flightplan number")
	end
end

function Memory:SetWeAreDamaged(state)
	if type(state) ~= "boolean" then
		error("Invalid input: 'damaged' should be a boolean")
	end
	self.damaged = state
end

function Memory:SetWeAreCriticallyDamaged(state)
	if type(state) ~= "boolean" then
		error("Invalid input: 'damaged' should be a boolean")
	end
	self.critically_damaged = state
end

function Memory:GetWeAreDamaged()
	return self.damaged
end

function Memory:GetWeAreCriticallyDamaged()
	return self.critically_damaged
end

-- Returns the hold status of the specified waypoint
function Memory:ToggleHoldAtWaypoint(flightplan_no, waypoint_no)
	local flightplan = self:GetFlightPlan(flightplan_no)
	if flightplan then
		return flightplan:ToggleHoldAtWaypoint(waypoint_no)
	else
		error("Invalid flightplan number")
	end
end

function Memory:SetHoldAtWaypoint(flightplan_no, waypoint_no, state)
	if type(state) ~= "boolean" then
		error("State must be a boolean value")
	end

	local flightplan = nil
	if flightplan_no == 1 then
		flightplan = self:GetFlightPlan1()
	elseif flightplan_no == 2 then
		flightplan = self:GetFlightPlan2()
	else
		error("Invalid flightplan number")
	end

	if flightplan ~= nil and waypoint_no > 0 and waypoint_no <= #flightplan.waypoints then
		local wpt = flightplan.waypoints[waypoint_no]
		if wpt ~= nil then
			wpt:SetHoldAt( state )
			return wpt:GetHoldAt()
		end
	else
		error("Invalid waypoint number")
	end
end

function Memory:SetSaidCanopy(has_said)
	self.has_said_canopy = has_said
end

function Memory:GetSaidCanopy()
	return self.has_said_canopy
end

function Memory:SetFullAlignment(alignment)
	self.full_alignment = alignment
end

function Memory:GetFullAlignment()
	return self.full_alignment
end

function Memory:SetAlignmentTypeChosen(value)
	self.alignment_type_chosen = true
end

function Memory:GetAlignmentTypeChosen()
	return self.alignment_type_chosen
end

function Memory:SetBathAlignment(alignment)

	self.bath_alignment = alignment
end

function Memory:GetBathAlignment()
	return self.bath_alignment
end

function Memory:SetHdgMemAlignment(alignment)
	self.hdg_mem_alignment = alignment
end

function Memory:GetHdgMemAlignment()
	return self.hdg_mem_alignment
end

function Memory:SetAlignmentAborted(aborted)
	self.alignment_aborted = aborted
end

function Memory:GetAlignmentAborted()
	return self.alignment_aborted
end

function Memory:SetStartupComplete(startup)
	self.startup_complete = startup
end

function Memory:GetStartupComplete()
	return self.startup_complete
end

function Memory:SetStartAlignmentOption(option)
	self.start_alignment_option = option
end

function Memory:GetStartAlignmentOption()
	return self.start_alignment_option
end

function Memory:SetReadyForInsAlignment(ready)
	self.ready_for_alignment = ready
end

function Memory:GetReadyForInsAlignment()
	return self.ready_for_alignment
end

function Memory:SetUserInitiatesAlignment(option)
	self.user_initiates_alignment = option
end

function Memory:GetUserInitiatesAlignment()
	return self.user_initiates_alignment
end

function Memory:SetRealigning(value)
	self.is_realigning = value
end

function Memory:GetRealigning()
	return self.is_realigning
end

function Memory:SetStartRealigning(start)
	self.start_realignment = start
end

function Memory:GetStartRealignment()
	return self.start_realignment
end

function Memory:SetRealignmentComplete(value)
	self.realignment_complete = value

end

function Memory:GetRealignmentComplete()
	return self.realignment_complete
end

function Memory:SetLastHighOleoRateTimestamp(last_oleo_rate_timestamp)
	self.last_significant_oleo_rate_timestamp = last_oleo_rate_timestamp
end

function Memory:SetLastHardLandingTimestamp(last_hard_landing_time)
	self.last_hard_landing_timestamp = last_hard_landing_time
end

function Memory:SetLastTimeLanded(last_time_landed)
	self.last_time_landed = last_time_landed
end

function Memory:GetLastTimeLanded()
	return self.last_time_landed
end

function Memory:GetLastHardLandingTimestamp()
	return self.last_hard_landing_timestamp
end

function Memory:SetHasAskedAboutLowestAltitude(has_asked)
	self.has_asked_about_lowest_mission_altitude = has_asked
end

function Memory:HasAskedAboutLowestAltitude()
	return self.has_asked_about_lowest_mission_altitude
end

function Memory:SetJesterCountermeasuresDispensingAllowed(state)
    self.jester_countermeasures_dispensing_allowed = state
end

function Memory:GetJesterCountermeasuresDispensingAllowed()
    return self.jester_countermeasures_dispensing_allowed
end

function Memory:DisactivateFlightplan()
	-- Store the last active waypoint and flight plan number
	local active_flightplan = self:GetActiveFlightPlan()
	if active_flightplan then
		self.memorized_last_active_wpt.waypoint = active_flightplan.active_waypoint
		self.memorized_last_active_wpt.flightplan = self.active_flightplan
	end

	-- Deactivate the flight plan
	self.active_flightplan = 0
	self.flightplan_1.active_waypoint = 0
	self.flightplan_2.active_waypoint = 0
	self.is_capping = false

	local navigate_behaviour = GetJester().behaviors[Navigate]
	if navigate_behaviour ~= nil then
		navigate_behaviour:ResetCAPVariables()
	end
end

function Memory:SwitchToNextTurnPoint()
	local flightplan = self:GetActiveFlightPlan()
	if not flightplan then
		return false -- No active flight plan
	end

	local current_waypoint = flightplan.active_waypoint
	if current_waypoint > 0 and current_waypoint < #flightplan.waypoints then
		flightplan.active_waypoint = current_waypoint + 1
		-- cancels hold at old waypoint
		flightplan.waypoints[current_waypoint].hold = false
		return true -- Successfully switched to the next waypoint
	else
		return false -- No more waypoints in the flight plan
	end
end

function Memory:SwitchToNextCAPWaypoint()
	local flightplan = self:GetActiveFlightPlan()
	if not flightplan then
		return false -- No active flight plan
	end

	local current_waypoint = flightplan.active_waypoint
	if current_waypoint > 0 and current_waypoint <= #flightplan.waypoints then
		local current_type = flightplan:GetWptCapType(current_waypoint)
		if current_type == 1 or current_type == 2 then
			local counterpart = self:GetCAPCounterpartWptNo(self.active_flightplan, current_waypoint)
			if counterpart then
				flightplan.active_waypoint = counterpart
				return true
			end
		end
	end
	return false -- Not a CAP waypoint or no counterpart found
end

function Memory:SwitchToNextWptAfterCAP2()
	local flightplan = self:GetActiveFlightPlan()
	if flightplan then
		local current_wpt_index = flightplan.active_waypoint
		if current_wpt_index and current_wpt_index > 0 then
			local current_cap_type = flightplan:GetWptCapType(current_wpt_index)
			if current_cap_type == 1 or current_cap_type == 2 then
				-- Get the counterpart for CAP1 or ensure it is CAP2
				local target_wpt_index = current_cap_type == 1 and flightplan:GetCAPPairCounterpartWptNo(current_wpt_index) or current_wpt_index

				if target_wpt_index then
					-- Now find the waypoint immediately following CAP2
					local next_wpt_index = flightplan:GetNextWaypointIndex(target_wpt_index)
					if next_wpt_index then
						self:SetActiveWaypoint(self.active_flightplan, next_wpt_index)
						return true -- Successful switch
					end
				end
			end
		end
	end
	return false -- Return false if the switch is not successful
end

function Memory:GetHasACAPCounterpart(flightplan_no, waypoint_no)
	local flightplan = self:GetFlightPlan(flightplan_no)
	if flightplan then
		return flightplan:GetHasACAPCounterpart(waypoint_no)
	end
	return false
end

function Memory:GetActiveWaypointHasCAPCounterpart()
	local flightplan = self:GetActiveFlightPlan()
	local active_waypoint = flightplan and flightplan.active_waypoint or nil
	if flightplan and active_waypoint then
		return self:GetHasACAPCounterpart(self:GetActiveFlightPlanNumber(), active_waypoint)
	end
	return false
end

function Memory:UpdateLastChangedWaypointTime()
	local current_time = Utilities.GetTime().mission_time:ConvertTo(s)
	self.last_changed_waypoint = current_time
end

function Memory:GetLastChangedWaypointTime()
	return self.last_changed_waypoint
end

function Memory:SetHasSaidAutobotsRollout( has_said )
	self.has_said_autobots_rollout = has_said
end

function Memory:GetHasSaidAutobotsRollout()
	return self.has_said_autobots_rollout
end

function Memory:UpdateLastTimeOnGround()
	local is_on_ground = GetJester().awareness:GetObservation("on_ground")
	if is_on_ground then
		last_time_on_ground = Utilities.GetTime().mission_time
	end
end


function Memory:UpdateLastTimeAirborne()
	local is_airborne = GetJester().awareness:GetObservation("airborne")
	if is_airborne then
		self.last_time_airborne = Utilities.GetTime().mission_time
	end
end

function Memory:UpdateHasBeenAirborne()
	local is_airborne = GetJester().awareness:GetObservation("airborne")
	if is_airborne then
		self.has_been_airborne = true
	end
end

function Memory:GetHasBeenAirborne()
	return self.has_been_airborne
end

function Memory:GetTimeSinceOnGround()
	return Utilities.GetTime().mission_time - self.last_time_on_ground
end

function Memory:GetTimeSinceAirborne()
	return Utilities.GetTime().mission_time - self.last_time_airborne
end

function Memory:CreateNewObject()
	local object = MemoryObject:new()
	table.insert(self.objects, object)
	return object
end

function Memory:GetCompatibleObjects(contact)
	local compatible_objects = {}
	for _, v in pairs(self.objects) do
		if (v.true_id or contact.true_id) and v.true_id == contact.true_id then
			table.insert(compatible_objects, v)
		end
	end
	return compatible_objects
end

function Memory:GetActiveFlightPlanNumber()
	return self.active_flightplan
end

function Memory:GetFlightplanNameString( fltpln_no )
	if fltpln_no == 1 then
		return "Primary Flight Plan"
	elseif fltpln_no == 2 then
		return "Secondary Flight Plan"
	end
	return "N/A"
end

function Memory:GetIsActiveTurnPointHold()
	local active_tp = self:GetActiveWaypoint()
	if active_tp ~= nil and active_tp:GetHoldAt() then
		return true
	end
	return false
end

function Memory:GetMemorizedLastActiveWptData()
	return self.memorized_last_active_wpt
end

function Memory:GetActiveFlightPlan()
	if self.active_flightplan == 1 then
		return self.flightplan_1
	elseif self.active_flightplan == 2 then
		return self.flightplan_2
	else
		return nil -- Return nil when no active flightplan
	end
end

function Memory:GetFlightPlan( no )
	if no == 1 then
		return self.flightplan_1
	elseif no == 2 then
		return self.flightplan_2
	else
		error("Invalid Flightplan number")
	end
end

function Memory:GetFlightPlan1()
	return self.flightplan_1
end

function Memory:GetFlightPlan2()
	return self.flightplan_2
end

function Memory:GetActiveWaypointNumber()
	local flightplan = self:GetActiveFlightPlan()
	if flightplan ~= nil then
		return flightplan.active_waypoint
	else
		return 0 -- No active waypoint or no active flight plan
	end
end

function Memory:GetActiveWaypoint()
	local flightplan = self:GetActiveFlightPlan()
	if flightplan and flightplan.active_waypoint > 0 then
		return flightplan.waypoints[flightplan.active_waypoint]
	else
		return nil -- No active waypoint or no active flight plan
	end
end

function Memory:GetWaypoint(flightplan_no, waypoint_no)
	local flightplan = (flightplan_no == 1) and self.flightplan_1 or self.flightplan_2
	if flightplan and waypoint_no > 0 and waypoint_no <= #flightplan.waypoints then
		return flightplan.waypoints[waypoint_no]
	else
		print("Invalid flightplan number or waypoint index")
		return nil
	end
end

function Memory:SetIsEjecting( state )
	self.is_ejecting = state
end

function Memory:GetIsEjecting()
	return self.is_ejecting
end

--Memory decay -- we need to forget or decay some memory, so we can re-call or re-announce objects.
function Memory:DecayMemories()
	for _, v in pairs(self.objects) do

		--Expire WVR callout if not seen for 2 min.
		if Utilities.GetTime().mission_time - v.last_seen_time_stamp > s(120) then
			v.announced = false
		end

		--Expire traffic call if not seen for some minutes.
		if Utilities.GetTime().mission_time - v.last_seen_time_stamp > s(420) then
			v.announced_traffic = false
		end

		--Add other decay here.
	end
end

function Memory:InitializeFlightplans()
	self:LoadFlightplans()
	if flightplan_1_init ~= nil then
		self.flightplans_were_initialized = true
		local flightplan = self:GetFlightPlan1()
		if #flightplan.waypoints > 0 then
			self:SetActiveWaypoint( 1, 1 )
		end
	end
end


function Memory:Tick()

	self:UpdateLastTimeOnGround()
	self:UpdateLastTimeAirborne()
	if not self.has_been_airborne then
		self:UpdateHasBeenAirborne()
	end

	self:DecayMemories() --Entropy.

	if not self.flightplans_were_initialized then
		self:InitializeFlightplans()
	end

end

Memory:Seal()

return Memory
