---// Navigation.lua
---// Copyright (c) 2024 Heatblur Simulations. All rights reserved.

local Class = require('base.Class')

local Waypoint = Class()
	Waypoint.latitude = 0.0
	Waypoint.longitude = 0.0
	Waypoint.hold = false
	Waypoint.name = ""
	Waypoint.special_type = "DEFAULT"

	Waypoint.SpecialTypes = {
		DEFAULT = "DEFAULT",
		CAP = "CAP",
		IP = "IP",
		TARGET = "Target",
		VIP = "VIP",  -- Visual Identification Point
		VIP_SILENT = "VIP Silent",  -- Nav fix without the voice phrases
		FENCE_IN = "Fence In",
		FENCE_OUT = "Fence Out",
		HOMEBASE = "Homebase",
		ALTERNATE = "Alternate"
	}

function Waypoint:Constructor( latitude_in, longitude_in, hold_in, name_in, designation_in )
	-- Set coordinates
	self.latitude = tonumber(string.format("%.3f", latitude_in or 0.0))
	self.longitude = tonumber(string.format("%.3f", longitude_in or 0.0))
	local designation = designation_in or "DEFAULT"

	-- Set hold status
	self.hold = hold_in or false

	-- Set waypoint name
	self.name = name_in or ""

	-- Set designation
	if Waypoint.SpecialTypes[designation] then
		self.special_type = designation
	else
		io.stderr:write("Invalid waypoint designation: " .. tostring(designation) .. "\n")
		self.special_type = Waypoint.SpecialTypes.DEFAULT
	end
end

function Waypoint:SetCoordinates( latitude_in, longitude_in )
	self.longitude = tonumber(string.format("%.3f", longitude_in))
	self.latitude = tonumber(string.format("%.3f", latitude_in))
end

function Waypoint:SetDesignation( designation )
	if Waypoint.SpecialTypes[designation] then
		self.special_type = designation
	else
		io.stderr:write("Invalid waypoint designation: " .. tostring(designation) .. "\n")
		self.special_type = Waypoint.SpecialTypes.DEFAULT
	end
end

function Waypoint:SetHoldAt( hold_ )
	self.hold = hold_
end

function Waypoint:SetName( name_ )
	self.name = name_
end

function Waypoint:ToggleHoldAt( )
	self.hold = not self.hold
end

function Waypoint:GetHoldAt( )
	return self.hold
end

function Waypoint:GetSpecialWaypointType( )
	return self.special_type
end

function Waypoint:GetWaypointName( )
	return self.name
end

Waypoint:Seal()
return Waypoint

