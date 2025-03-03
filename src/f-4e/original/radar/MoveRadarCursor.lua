---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require('base.Class')
local Math = require('base.Math')
local Utilities = require('base.Utilities')
local Behavior = require('base.Behavior')
local Interactions = require('base.Interactions')

local MoveRadarCursor = Class(Behavior)

local radar_state_type = {
	off = 0,
	standby = 1,
	search = 2,
	auto_acquisition = 3,
	acquisition = 4,
	track = 5
}
local CURSOR_OVER_DESIRED_DISTANCE_THRESHOLD = 0.008

MoveRadarCursor.is_active = false
MoveRadarCursor.target = nil
MoveRadarCursor.artificial_target = nil
MoveRadarCursor.is_cursor_moving = false
MoveRadarCursor.current_cursor_x = 0 -- -1 to +1
MoveRadarCursor.current_cursor_y = 0 -- -1 to +1
MoveRadarCursor.desired_cursor_x = 0 -- -1 to +1
MoveRadarCursor.desired_cursor_y = 0 -- -1 to +1
MoveRadarCursor.predict_lead = false
MoveRadarCursor.azimuth_lead = deg(0)
MoveRadarCursor.range_lead = NM(0)
MoveRadarCursor.applied_lead_timestamp = nil
MoveRadarCursor.use_range_only = false

function MoveRadarCursor:Constructor()
	Behavior.Constructor(self)
end

function MoveRadarCursor:GetCurrentDisplayRange()
	local display_range_index = GetProperty("/Radar/Digital Scan Converter Group Screen", "Display Range").value or 2

	if display_range_index == 0 then
		return NM(5)
	elseif display_range_index == 1 then
		return NM(10)
	elseif display_range_index == 2 then
		return NM(25)
	elseif display_range_index == 3 then
		return NM(50)
	elseif display_range_index == 4 then
		return NM(100)
	elseif display_range_index == 5 then
		return NM(200)
	end

	return NM(50)
end

function MoveRadarCursor:GetCursorXForAzimuth(azimuth)
	-- [-60°, +60°] -> [-1, +1]
	azimuth = Math.Clamp(azimuth:ConvertTo(deg), deg(-60), deg(60))
	return azimuth.value / 60
end

function MoveRadarCursor:GetCursorYForRange(range)
	-- e.g. [0 nm, 50 nm] -> [-1, +1]
	range = range:ConvertTo(NM)
	return (range.value / self:GetCurrentDisplayRange().value) * 2 - 1
end

function MoveRadarCursor:GetCursorDiff()
	local diff_x = Math.Abs(self.current_cursor_x - self.desired_cursor_x)
	local diff_y = Math.Abs(self.current_cursor_y - self.desired_cursor_y)
	local diff_length = math.sqrt(diff_x * diff_x + diff_y * diff_y)
	return diff_x, diff_y, diff_length
end

function MoveRadarCursor:IsCursorOverDesired()
	local _, _, diff_length = self:GetCursorDiff()
	return diff_length < CURSOR_OVER_DESIRED_DISTANCE_THRESHOLD
end

function MoveRadarCursor:IsActive()
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
	if mode ~= "RDR" and mode ~= "MAP" and mode ~= "AIR_GND" and mode ~= "BST" then
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

-- slew_x: -1 is stick and cursor left, +1 is stick and cursor right
-- slew_y: -1 is stick down but cursor up, +1 is stick up but cursor down
function MoveRadarCursor:PlaceStickAt(slew_x, slew_y)
	-- Bypass Jesters task system to ensure it always executes immediately
	-- and does not interfere with other tasks in the queue.
	-- We will spawn these tasks very frequently and do not want them to fill up Jesters task queue, blocking other things.
	self.is_cursor_moving = slew_x ~= 0 or slew_y ~= 0

	ClickRaw(Interactions.devices.RADAR, Interactions.device_commands.RADAR_ANTENNA_HAND_CONTROL_SLEW_X, slew_x)
	ClickRaw(Interactions.devices.RADAR, Interactions.device_commands.RADAR_ANTENNA_HAND_CONTROL_SLEW_Y, slew_y)
end

function MoveRadarCursor:ResetLead()
	self.azimuth_lead = deg(0)
	self.range_lead = NM(0)
	self.applied_lead_timestamp = nil
end

function MoveRadarCursor:ComputeTargetLead()
	local last_hit_timestamp = self.target.last_hit_timestamp:ConvertTo(s)
	local did_sweep_recently = not self.applied_lead_timestamp or self.applied_lead_timestamp < last_hit_timestamp
	if did_sweep_recently then
		self:ResetLead()
	end
	if not self.applied_lead_timestamp then
		self.applied_lead_timestamp = last_hit_timestamp
	end

	local now_timestamp = Utilities.GetTime().mission_time
	local time_since_last_hit = now_timestamp - last_hit_timestamp
	if time_since_last_hit > s(1) then
		-- Pause lead if data is old, else the cursor will run into the corners
		return
	end

	local time_since_update = now_timestamp - self.applied_lead_timestamp
	self.applied_lead_timestamp = now_timestamp:ConvertTo(s)

	-- Estimate target yaw rate based on own ship yaw rate
	local own_angular_velocity = GetJester().awareness:GetObservation("gods_angular_velocity_ned")
	local yaw_rate = degps(0)
	if own_angular_velocity then
		yaw_rate = -1 * own_angular_velocity.z:ConvertTo(degps) -- inverse because if own ship steers right, contact goes left on the screen
	end
	self.azimuth_lead = self.azimuth_lead + (time_since_update * yaw_rate)

	self.range_lead = self.range_lead + (time_since_update * self.target.estimated_vc)
end

function MoveRadarCursor:StopCursorMovement()
	if self.is_cursor_moving then
		self:PlaceStickAt(0, 0)
	end
end

function MoveRadarCursor:UpdateTargetData()
	if self.target then
		self.target = radar_targets[self.target.id] or self.target
	end
end

function MoveRadarCursor:UpdateCursorData()
	local cursor_x = GetProperty("/Radar/Digital Scan Converter Group Screen", "TDC X").value
	if cursor_x then
		self.current_cursor_x = cursor_x.value -- -1 to 1
	else
		self.current_cursor_x = 0
	end

	local cursor_y = GetProperty("/Radar/Digital Scan Converter Group Screen", "TDC Y").value
	if cursor_y then
		self.current_cursor_y = cursor_y.value -- -1 to 1
	else
		self.current_cursor_y = 0
	end

	local current_target = self.target or self.artificial_target
	if current_target then
		if self.predict_lead then
			self:ComputeTargetLead()
		end

		if self.use_range_only then
			self.desired_cursor_x = 0
		else
			self.desired_cursor_x = self:GetCursorXForAzimuth(current_target.scan_azimuth + self.azimuth_lead)
		end
		self.desired_cursor_y = self:GetCursorYForRange(current_target.scan_range + self.range_lead)
	else
		-- Move back to center
		self.desired_cursor_x = 0
		self.desired_cursor_y = 0
	end
end

function MoveRadarCursor:MoveCursorToDesired()
	local diff_x, diff_y, diff_length = self:GetCursorDiff()

	-- Adjust speed dynamically based on ratio so the cursor moves on a direct line and not zig-zag
	local speed_x
	local speed_y
	if diff_x > diff_y then
		speed_x = 1
		speed_y = diff_y / diff_x
	else
		speed_x = diff_x / diff_y
		speed_y = 1
	end

	-- Prevent overshooting and smooth out by scaling speed by distance
	local scale_factor = Math.ClampedLerp(0.2, 1.0, 0, 0.2, diff_length)
	speed_x = speed_x * scale_factor
	speed_y = speed_y * scale_factor

	-- Direction
	if self.desired_cursor_x < self.current_cursor_x then
		speed_x = -speed_x
	end
	if self.desired_cursor_y < self.current_cursor_y then
		speed_y = -speed_y
	end

	self:PlaceStickAt(speed_x, -speed_y) -- cursor vs stick movement is y-axis inverted
end

function MoveRadarCursor:Tick()
	if not self:IsActive() then
		if self.is_active then
			self:StopCursorMovement()
		end

		self.is_active = false
		return
	end
	self.is_active = true

	self:UpdateTargetData()
	self:UpdateCursorData()

	if self:IsCursorOverDesired() then
		if self.is_cursor_moving then
			self:StopCursorMovement()
		end
		return
	end

	self:MoveCursorToDesired()
end

-- predict_lead: optional, false by default. Cursor is moved ahead of return
--   based on target movement to predict the actual target position in between sweeps
-- use_range_only: optional, false by default. If set, target azimuth will be ignored and the cursor is always set to 0 degrees.
function MoveRadarCursor:FollowTarget(target, predict_lead, use_range_only)
	if target == nil then
		self:ClearTarget()
		return
	end

	local is_different_target = not (self.target and self.target.id == target.id)
	self.target = target
	self.artificial_target = nil
	self.predict_lead = predict_lead or false
	self.use_range_only = use_range_only or false

	if not self.predict_lead then
		self:ResetLead()
	end

	if is_different_target then
		self:ResetLead()

		self:UpdateCursorData()
	end
end

function MoveRadarCursor:MoveCursorTo(azimuth, range)
	self.artificial_target = {
		scan_azimuth = azimuth:ConvertTo(deg),
		scan_range = range:ConvertTo(NM),
	}
	self.target = nil
	self.predict_lead = false
	self.use_range_only = false

	self:ResetLead()
	self:UpdateCursorData()
end

function MoveRadarCursor:ClearTarget()
	local had_a_target = self.target or self.artificial_target
	self.target = nil
	self.artificial_target = nil
	self.predict_lead = false
	self.use_range_only = false
	self:ResetLead()

	if had_a_target then
		self:UpdateCursorData()
	end
end

MoveRadarCursor:Seal()
return MoveRadarCursor
