---// FlightPlan.lua
---// Copyright (c) 2024 Heatblur Simulations. All rights reserved.
local Class = require 'base.Class'

local FlightPlan = Class()

function FlightPlan:Constructor()
	self.waypoints = {}
	self.active_waypoint = 0
	self.cap_pairs = {}  -- Keeps track of CAP pairs
end

function FlightPlan:SetDesignation(index, designation)
	if index > 0 and index <= #self.waypoints then
		local waypoint = self.waypoints[index]

		-- If the current designation is CAP and the new designation is not CAP
		if waypoint:GetSpecialWaypointType() == "CAP" and designation ~= "CAP" then
			-- Find the pair and reset it
			for k, v in pairs(self.cap_pairs) do
				if v.cap1 == index then
					if v.cap2 then
						self.waypoints[v.cap2]:SetDesignation("DEFAULT")
					end
					self.cap_pairs[k] = nil
					break
				elseif v.cap2 == index then
					if v.cap1 then
						self.waypoints[v.cap1]:SetDesignation("DEFAULT")
					end
					self.cap_pairs[k] = nil
					break
				end
			end
		end

		if designation == "CAP" then
			-- Check if there's an existing CAP1 without a CAP2
			local cap1_exists = false
			for k, v in pairs(self.cap_pairs) do
				if v.cap1 == index or v.cap2 == index then
					io.stderr:write("Waypoint is already assigned as CAP1 or CAP2 in another pair\n")
					return
				end
				if v.cap1 and not v.cap2 then
					cap1_exists = true
					self:SetCAP2Waypoint(index)
					waypoint:SetDesignation(designation)
					return
				end
			end
			-- If no CAP1 exists without a CAP2, set as CAP1
			if not cap1_exists then
				self:SetCAP1Waypoint(index)
			end
		else
			-- Set the designation to the new type
			waypoint:SetDesignation(designation)
		end
	else
		io.stderr:write("Invalid waypoint index for setting designation\n")
	end
end

function FlightPlan:SetCAP1Waypoint(index)
	if index > 0 and index <= #self.waypoints then
		-- Ensure the waypoint is not already assigned as CAP2 in any pair
		for _, v in pairs(self.cap_pairs) do
			if v.cap2 == index then
				io.stderr:write("Waypoint is already assigned as CAP2 in another pair\n")
				return
			end
		end
		-- Ensure the waypoint is not already assigned as CAP1 in any pair
		for k, v in pairs(self.cap_pairs) do
			if v.cap1 == index then
				io.stderr:write("Waypoint is already assigned as CAP1 in another pair\n")
				return
			end
		end
		self.waypoints[index].special_type = "CAP"
		self.cap_pairs[index] = {cap1 = index, cap2 = nil}
	else
		io.stderr:write("Invalid waypoint index for CAP1\n")
	end
end

function FlightPlan:SetCAP2Waypoint(index)
	if index > 0 and index <= #self.waypoints then
		-- Ensure the waypoint is not already assigned as CAP1 or CAP2 in any pair
		for k, v in pairs(self.cap_pairs) do
			if v.cap1 == index or v.cap2 == index then
				io.stderr:write("Waypoint is already assigned as CAP in another pair\n")
				return
			end
		end
		-- Find the last CAP1 without a CAP2 and pair it
		for k, v in pairs(self.cap_pairs) do
			if not v.cap2 then
				if v.cap1 == index then
					io.stderr:write("Waypoint cannot be paired as CAP2 with itself as CAP1\n")
					return
				end
				self.waypoints[index].special_type = "CAP"
				self.cap_pairs[k].cap2 = index
				return
			end
		end
		io.stderr:write("No available CAP1 found to pair with CAP2\n")
	else
		io.stderr:write("Invalid waypoint index for CAP2\n")
	end
end

function FlightPlan:GetCAPPairCounterpartWptNo(index)
	for k, v in pairs(self.cap_pairs) do
		if v.cap1 == index then
			return v.cap2  -- Return the index of the CAP2 counterpart
		elseif v.cap2 == index then
			return v.cap1  -- Return the index of the CAP1 counterpart
		end
	end
	return nil  -- No pair found
end

function FlightPlan:GetWptCapType(waypoint_no)
	for k, v in pairs(self.cap_pairs) do
		if v.cap1 == waypoint_no then
			return 1
		elseif v.cap2 == waypoint_no then
			return 2
		end
	end
	return 0  -- Not a CAP waypoint
end

function FlightPlan:GetHasACAPCounterpart(index)
	if self.cap_pairs[index] then
		return self.cap_pairs[index].cap1 and self.cap_pairs[index].cap2
	else
		for k, v in pairs(self.cap_pairs) do
			if v.cap1 == index or v.cap2 == index then
				return v.cap1 and v.cap2
			end
		end
	end
	return false
end

function FlightPlan:GetNextWaypointIndex(current_index)
	if current_index and current_index > 0 and current_index < #self.waypoints then
		return current_index + 1
	end
	return nil -- Return nil if there's no valid next waypoint
end

function FlightPlan:InsertNewWaypoint(waypoint)
	table.insert( self.waypoints, waypoint )
end

function FlightPlan:InsertWaypointAfter(waypoint_no, new_waypoint)
	if waypoint_no >= 0 and waypoint_no <= #self.waypoints then
		table.insert(self.waypoints, waypoint_no + 1, new_waypoint)
		if self.active_waypoint and waypoint_no < self.active_waypoint then
			self.active_waypoint = self.active_waypoint + 1
		end
		self:UpdateCAPIndices(waypoint_no + 1, 1)
	else
		io.stderr:write("Invalid waypoint index for insertion\n")
	end
end

function FlightPlan:InsertWaypointBefore(waypoint_no, new_waypoint)
	if waypoint_no > 0 and waypoint_no <= #self.waypoints + 1 then
		table.insert(self.waypoints, waypoint_no, new_waypoint)
		if self.active_waypoint and waypoint_no <= self.active_waypoint then
			self.active_waypoint = self.active_waypoint + 1
		end
		self:UpdateCAPIndices(waypoint_no, 1)
	else
		io.stderr:write("Invalid waypoint index for insertion\n")
	end
end

function FlightPlan:EditWaypoint(waypoint_no, new_waypoint)
	if waypoint_no > 0 and waypoint_no <= #self.waypoints then
		self.waypoints[waypoint_no] = new_waypoint
	else
		io.stderr:write("Invalid waypoint index")
	end
end

function FlightPlan:EditWaypointCoords(index, latitude, longitude)
	if index > 0 and index <= #self.waypoints then
		local waypoint = self.waypoints[index]
		if waypoint then
			waypoint.latitude = latitude
			waypoint.longitude = longitude
			-- Preserves other properties such as hold status
		else
			io.stderr:write("Waypoint not found in flightplan")
		end
	else
		io.stderr:write("Invalid waypoint index")
	end
end

function FlightPlan:EditWaypointName(index, name)
	if index > 0 and index <= #self.waypoints then
		local waypoint = self.waypoints[index]
		if waypoint then
			waypoint:SetName( name )
		else
			io.stderr:write("Waypoint not found in flightplan")
		end
	else
		io.stderr:write("Invalid waypoint index")
	end
end

function FlightPlan:EditWaypointDesignation(index, designation)
	if index > 0 and index <= #self.waypoints then
		local waypoint = self.waypoints[index]
		if waypoint then
			waypoint:SetDesignation( designation )
		else
			io.stderr:write("Waypoint not found in flightplan")
		end
	else
		io.stderr:write("Invalid waypoint index")
	end
end

function FlightPlan:EditWaypointIsHold(index, hold)
	if index > 0 and index <= #self.waypoints then
		local waypoint = self.waypoints[index]
		if waypoint then
			waypoint:SetHoldAt( hold )
		else
			io.stderr:write("Waypoint not found in flightplan")
		end
	else
		io.stderr:write("Invalid waypoint index")
	end
end

function FlightPlan:DeleteWaypoint(waypoint_no)
	if waypoint_no and waypoint_no > 0 and waypoint_no <= #self.waypoints then
		local cap_pair_to_remove = nil

		-- Check if the waypoint is part of a CAP pair and mark the pair for removal
		if self.cap_pairs[waypoint_no] then
			cap_pair_to_remove = self.cap_pairs[waypoint_no]
		else
			for k, v in pairs(self.cap_pairs) do
				if v.cap2 == waypoint_no then
					cap_pair_to_remove = v
					break
				end
			end
		end

		-- If it's part of a CAP pair, change the counterpart to "DEFAULT" and remove the pair
		if cap_pair_to_remove then
			if cap_pair_to_remove.cap1 and self.waypoints[cap_pair_to_remove.cap1] then
				self.waypoints[cap_pair_to_remove.cap1].special_type = "DEFAULT"
			end
			if cap_pair_to_remove.cap2 and self.waypoints[cap_pair_to_remove.cap2] then
				self.waypoints[cap_pair_to_remove.cap2].special_type = "DEFAULT"
			end
			self.cap_pairs[cap_pair_to_remove.cap1] = nil
		end

		-- Remove the waypoint
		table.remove(self.waypoints, waypoint_no)

		-- Adjust the active_waypoint index if necessary
		if self.active_waypoint and waypoint_no < self.active_waypoint then
			self.active_waypoint = self.active_waypoint - 1
		elseif self.active_waypoint == waypoint_no and waypoint_no > #self.waypoints then
			-- If the deleted waypoint was the active one and it was the last waypoint, set active_waypoint to 0
			self.active_waypoint = 0
		end

		-- Update CAP indices
		self:UpdateCAPIndices(waypoint_no, -1)
	else
		io.stderr:write("Invalid waypoint index for deletion: ", waypoint_no)
	end
end

function FlightPlan:SetHoldAtWaypoint(waypoint_no, state)
	if waypoint_no > 0 and waypoint_no <= #self.waypoints then
		local wpt = self.waypoints[waypoint_no]
		if wpt then
			wpt:SetHoldAt(state)
		else
			io.stderr:write("Waypoint not found in flightplan")
		end
	else
		io.stderr:write("Invalid waypoint index")
	end
end

function FlightPlan:ToggleHoldAtWaypoint(waypoint_no)
	if waypoint_no > 0 and waypoint_no <= #self.waypoints then
		local wpt = self.waypoints[waypoint_no]
		if wpt then
			wpt:ToggleHoldAt()
			return wpt:GetHoldAt()
		else
			io.stderr:write("Waypoint not found in flightplan")
		end
	else
		io.stderr:write("Invalid waypoint index")
	end
end

function FlightPlan:UpdateCAPIndices(start_index, offset)
	local new_cap_pairs = {}
	for k, v in pairs(self.cap_pairs) do
		local new_cap1, new_cap2 = k, v.cap2
		if v.cap1 and v.cap1 >= start_index then
			new_cap1 = v.cap1 + offset
		end
		if v.cap2 and v.cap2 >= start_index then
			new_cap2 = v.cap2 + offset
		end
		if new_cap1 and new_cap1 > 0 and new_cap1 <= #self.waypoints and (not new_cap2 or (new_cap2 > 0 and new_cap2 <= #self.waypoints)) then
			new_cap_pairs[new_cap1] = {cap1 = new_cap1, cap2 = new_cap2}
		end
	end
	self.cap_pairs = new_cap_pairs
end

FlightPlan:Seal()
return FlightPlan