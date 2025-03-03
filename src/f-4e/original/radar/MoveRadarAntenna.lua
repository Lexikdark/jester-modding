---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require('base.Class')
local Math = require('base.Math')
local Behavior = require('base.Behavior')
local Interactions = require('base.Interactions')

local MoveRadarAntenna = Class(Behavior)

local radar_state_type = {
	off = 0,
	standby = 1,
	search = 2,
	auto_acquisition = 3,
	acquisition = 4,
	track = 5
}
local ANTENNA_OVER_DESIRED_DEGREES_THRESHOLD = deg(0.005)

MoveRadarAntenna.is_active = false
MoveRadarAntenna.target = nil
MoveRadarAntenna.artificial_target = nil
MoveRadarAntenna.is_antenna_moving = false
MoveRadarAntenna.current_antenna_degrees = deg(0) -- -60° to +60°
MoveRadarAntenna.desired_antenna_degrees = deg(0) -- -60° to +60°

function MoveRadarAntenna:Constructor()
	Behavior.Constructor(self)
end

function MoveRadarAntenna:GetAntennaDegreesForPosition(range, altitude, is_altitude_relative)
	local relative_altitude
	if is_altitude_relative then
		relative_altitude = altitude
	else
		local own_altitude = GetJester().awareness:GetObservation("barometric_altitude") or ft(25000)
		relative_altitude = altitude - own_altitude -- e.g. 10k ft means look up, -5k ft means look down
	end

	local degrees = math.deg(math.atan2(relative_altitude:ConvertTo(ft).value, range:ConvertTo(ft).value))
	return deg(degrees)
end

function MoveRadarAntenna:GetAntennaDiff()
	return Math.Abs(self.current_antenna_degrees - self.desired_antenna_degrees)
end

function MoveRadarAntenna:IsAntennaOverDesired()
	return self:GetAntennaDiff() < ANTENNA_OVER_DESIRED_DEGREES_THRESHOLD
end

function MoveRadarAntenna:IsActive()
	local cockpit = GetJester():GetCockpit()

	local screen_mode = cockpit:GetManipulator("Screen Mode"):GetState() or "off"
	if screen_mode ~= "radar" then
		return false
	end

	local power = cockpit:GetManipulator("Radar Power"):GetState() or "OFF"
	if power ~= "OPER" and power ~= "EMER" then
		return false
	end

	local mode = cockpit:GetManipulator("Radar Mode"):GetState() or "TV"
	if mode ~= "RDR" and mode ~= "MAP" and mode ~= "AIR_GND" then
		return false
	end

	local radar_state = GetProperty("/Radar/Fire Control System Low Frequency", "current state").value
	if radar_state ~= radar_state_type.search
			and radar_state ~= radar_state_type.auto_acquisition
			and radar_state ~= radar_state_type.acquisition then
		return false
	end

	local caa_mode = GetProperty("/Radar/Fire Control System Low Frequency", "caa mode").value or false
	if caa_mode then
		return false
	end

	return true
end

-- slew_y: -1 is wheel down, +1 is wheel up, moving the antenna in the corresponding direction
function MoveRadarAntenna:PlaceAntennaWheelAt(slew_y)
	-- Bypass Jesters task system to ensure it always executes immediately
	-- and does not interfere with other tasks in the queue.
	-- We will spawn these tasks very frequently and do not want them to fill up Jesters task queue, blocking other things.
	self.is_antenna_moving = slew_y ~= 0

	ClickRaw(Interactions.devices.RADAR, Interactions.device_commands.RADAR_ANTENNA_HAND_CONTROL_ELEVATION, slew_y)
end

function MoveRadarAntenna:StopAntennaMovement()
	if self.is_antenna_moving then
		self:PlaceAntennaWheelAt(0)
	end
end

function MoveRadarAntenna:UpdateTargetData()
	if self.target then
		self.target = radar_targets[self.target.id] or self.target
	end
end

function MoveRadarAntenna:UpdateAntennaData()
	local antenna_degrees = GetProperty("/Radar/Fire Control System Low Frequency", "antenna elevation").value
	if antenna_degrees then
		self.current_antenna_degrees = antenna_degrees:ConvertTo(deg) -- -60° to +60°
	else
		self.current_antenna_degrees = deg(0)
	end

	local current_target = self.target or self.artificial_target
	if current_target then
		self.desired_antenna_degrees = self:GetAntennaDegreesForPosition(current_target.scan_range, current_target.cheat_altitude, current_target.is_altitude_relative)
	else
		-- Move back to center
		self.desired_antenna_degrees = deg(0)
	end
end

function MoveRadarAntenna:MoveAntennaToDesired()
	local diff_deg = self:GetAntennaDiff()
	local speed_y = 1.0

	-- Prevent overshooting and smooth out by scaling speed by distance
	local scale_factor = Math.ClampedLerp(0.0025, 1.0, 0,  3, diff_deg.value)
	speed_y = speed_y * scale_factor

	-- Direction
	if self.desired_antenna_degrees < self.current_antenna_degrees then
		speed_y = -speed_y
	end

	self:PlaceAntennaWheelAt(speed_y)
end

function MoveRadarAntenna:Tick()
	if not self:IsActive() then
		if self.is_active then
			self:StopAntennaMovement()
		end

		self.is_active = false
		return
	end
	self.is_active = true

	self:UpdateTargetData()
	self:UpdateAntennaData()

	if self:IsAntennaOverDesired() then
		if self.is_antenna_moving then
			self:StopAntennaMovement()
		end
		return
	end

	self:MoveAntennaToDesired()
end

function MoveRadarAntenna:FollowTarget(target)
	if target == nil then
		self:ClearTarget()
		return
	end

	local is_different_target = not (self.target and self.target.id == target.id)
	self.target = target
	self.artificial_target = nil

	if is_different_target then
		self:UpdateAntennaData()
	end
end

function MoveRadarAntenna:MoveAntennaTo(range, altitude, is_altitude_relative)
	self.artificial_target = {
		scan_range = range:ConvertTo(NM),
		cheat_altitude = altitude:ConvertTo(ft),
		is_altitude_relative = is_altitude_relative,
	}
	self.target = nil

	self:UpdateAntennaData()
end

function MoveRadarAntenna:ClearTarget()
	local had_a_target = self.target or self.artificial_target
	self.target = nil
	self.artificial_target = nil

	if had_a_target then
		self:UpdateAntennaData()
	end
end

MoveRadarAntenna:Seal()
return MoveRadarAntenna
