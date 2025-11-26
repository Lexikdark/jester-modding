---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Utilities = require('base.Utilities')
local Math = require('base.Math')
local Config = require('radar.Config')
local State = require('radar.State')

local Api = {}

function Api.SelectRadarScreen(task)
	return task:ClickFast("Screen Mode", Config.screen_mode.radar, true)
end

function Api.IsPowered()
	local power_state = GetJester():GetCockpit():GetManipulator("Radar Power"):GetState() or "OFF"
	return power_state == "OPER" or power_state == "EMER"
end

function Api.SetOperatingMode(task, mode)
	Api.SelectRadarScreen(task)
	   :ClickFast("Radar Mode", Config.mode.map, true)
	   :ClickFast("Radar Scan Type", State.pilot_requested_scan_type, true)
	   :ClickFast("Radar Range", State.pilot_requested_range, true)

	if mode == "ready" then
		task:ClickFast("Radar Power", "OPER", true)
	elseif mode == "standby" then
		task:ClickFast("Radar Power", "STBY", true)
	end
	return task
end

function Api.IsInDogfightMode()
	local cage_mode = GetProperty("/Radar/Fire Control System Low Frequency", "caged mode").value or false
	local caa_mode = GetProperty("/Radar/Fire Control System Low Frequency", "caa mode").value or false
	return cage_mode or caa_mode
end

function Api.IsRegularCageMode()
	local cage_mode = GetProperty("/Radar/Fire Control System Low Frequency", "caged mode").value or false
	local caa_mode = GetProperty("/Radar/Fire Control System Low Frequency", "caa mode").value or false
	return cage_mode and not caa_mode
end

function Api.IsBoresightMode()
	return GetJester():GetCockpit():GetManipulator("Radar Mode"):GetState() == Config.mode.boresight
end

function Api.GetCurrentGainCoarse()
	local default_coarse_setting = 0.6
	return GetJester():GetCockpit():GetManipulator("Radar Gain Coarse"):GetState() or default_coarse_setting
end

function Api.GetCurrentAntennaElevation()
	local current_degrees = GetProperty("/Radar/Fire Control System Low Frequency", "antenna elevation").value or deg(0)
	return current_degrees:ConvertTo(deg)
end

function Api.IsInTrackState()
	local current_state = GetProperty("/Radar/Fire Control System Low Frequency", "current state").value
	return current_state == Config.state_type.track
end

function Api.AreRadarMissilesReady()
	local radar_lamp_intensity = GetProperty("/Weapons/Weapons Lamps/Radar Guided Selected Lamp/Filament", "Light Intensity").value
	if not radar_lamp_intensity then
		return false
	end
	return radar_lamp_intensity.value > 0.5
end

function Api.HasSkinTrack()
	return GetProperty("/Radar/Digital Scan Converter Group Screen", "Skin Track").value or false
end

function Api.GetCurrentDisplayRange()
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

function Api.GetLockedTargetRange()
	-- 0 to 1
	local normalized_range = GetProperty("/Radar/Digital Scan Converter Group Screen", "Target Range").value or 0.5
	return Api.GetCurrentDisplayRange() * normalized_range
end

function Api.FindLockedTargetOrNil()
	if not Api.IsInTrackState() then
		return nil
	end

	local target_range = Api.GetLockedTargetRange()
	local locked_target
	local locked_target_distance
	for _, target in pairs(radar_targets) do
		if not locked_target then
			locked_target = target
			locked_target_distance = Math.Abs(target_range - locked_target.scan_range)
		end

		local candidate_distance = Math.Abs(target_range - target.scan_range)
		if candidate_distance < locked_target_distance then
			locked_target = target
			locked_target_distance = candidate_distance
		end
	end

	if not locked_target or locked_target_distance > NM(2) then
		return nil
	end

	return locked_target
end

function Api.ClickIffButton(task)
	State.last_iff_timestamp = Utilities.GetTime().mission_time
	return task:ClickShort("Antenna Challenge", "ON")
end

function Api.ClickApx76IffOnly(task)
	State.last_iff_timestamp = Utilities.GetTime().mission_time
	return task:ClickShort("APX-76 Test Challenge", "negative")
end

function Api.GetTargetIdentification(target_id)
	local identification = RadarTargetIdentification.UNKNOWN

	local target = State.all_targets[target_id]
	if target then
		identification = target.identification
	end

	if identification == RadarTargetIdentification.UNKNOWN then
		-- Fallback to current screen state
		target = radar_targets[target_id]
		if target then
			identification = target.identification
		end
	end

	return identification
end

function Api.IsBandit(target_id)
	local identification = Api.GetTargetIdentification(target_id)
	return identification == RadarTargetIdentification.HOSTILE or identification == RadarTargetIdentification.UNKNOWN
end

function Api.IsHostile(target_id)
	return Api.GetTargetIdentification(target_id) == RadarTargetIdentification.HOSTILE
end

function Api.IsNeutral(target_id)
	return Api.GetTargetIdentification(target_id) == RadarTargetIdentification.NEUTRAL
end

function Api.IsFriendly(target_id)
	return Api.GetTargetIdentification(target_id) == RadarTargetIdentification.FRIENDLY
end

function Api.IsTargetHigherPriorityThan(target, other_target)
	-- TODO Perhaps also factor in closure rate
	    local r1 = target.scan_range:ConvertTo(NM).value
        local r2 = other_target.scan_range:ConvertTo(NM).value
        return r1 < r2
end

function Api.AreTargetsClose(first, second)
	local azimuth_diff = Math.Abs(first.scan_azimuth - second.scan_azimuth)
	local range_diff = Math.Abs(first.scan_range - second.scan_range)
	return azimuth_diff < deg(10) and range_diff < NM(5)
end

function Api.GetAltitudeFromSlantRange(slant_range)
	local antenna_elevation_rad_raw = Api.GetCurrentAntennaElevation():ConvertTo(rad).value
	local slant_range_ft_raw = slant_range:ConvertTo(ft).value

	local altitude_delta_ft_raw = math.sin(antenna_elevation_rad_raw) * slant_range_ft_raw
	local own_altitude = GetJester().awareness:GetObservation("barometric_altitude") or med_alt
	return own_altitude + ft(altitude_delta_ft_raw)
end

function Api.HasUnprocessedContacts()
	for id, _ in pairs(State.identified_targets) do
		if State.processed_targets[id] == nil then
			return true
		end
	end

	return false
end

function Api.UpdateTargetsPriority()
	local bandits = {}
	local not_bandits = {}
	for id, target in pairs(State.all_targets) do
		target = radar_targets[id] or target
		if Api.IsBandit(id) then
			bandits[#bandits + 1] = target
		else
			not_bandits[#not_bandits + 1] = target
		end
	end
	table.sort(bandits, Api.IsTargetHigherPriorityThan)
	table.sort(not_bandits, Api.IsTargetHigherPriorityThan)

	State.bandits_by_priority_desc = bandits
	State.not_bandits_by_priority_desc = not_bandits
end

function Api.GetUnprocessedSameIdentityContactsCloseTo(reference_target)
	local group = {}
	group[#group + 1] = reference_target

	local is_bandit = Api.IsBandit(reference_target.id)
	local is_neutral = Api.IsNeutral(reference_target.id)
	local is_friendly = Api.IsFriendly(reference_target.id)

	for id, target in pairs(State.identified_targets) do
		target = radar_targets[id] or target -- prefer latest data if available
		if State.processed_targets[id] == nil then
			local are_same_identity = (is_bandit and Api.IsBandit(id))
					or (is_neutral and Api.IsNeutral(id))
					or is_friendly and Api.IsFriendly(id)

			if id ~= reference_target.id and are_same_identity and Api.AreTargetsClose(reference_target, target) then
				group[#group + 1] = target
			end
		end
	end

	return group
end

function Api.GetNextUnprocessedContactGroup()
	local bandit_candidate
	local neutral_candidate
	local friendly_candidate

	-- Find highest priority bandit and friendly
	for id, target in pairs(State.identified_targets) do
		target = radar_targets[id] or target -- prefer latest data if available
		if State.processed_targets[id] == nil then
			if Api.IsBandit(target.id) then
				if bandit_candidate == nil or Api.IsTargetHigherPriorityThan(target, bandit_candidate) then
					bandit_candidate = target
				end
			elseif Api.IsNeutral(target.id) then
				if neutral_candidate == nil or Api.IsTargetHigherPriorityThan(target, neutral_candidate) then
					neutral_candidate = target
				end
			else
				if friendly_candidate == nil or Api.IsTargetHigherPriorityThan(target, friendly_candidate) then
					friendly_candidate = target
				end
			end
		end
	end

	local candidate = bandit_candidate or neutral_candidate or friendly_candidate
	if candidate then
		return Api.GetUnprocessedSameIdentityContactsCloseTo(candidate)
	end

	return {}
end

function Api.GetSingleBanditOnScreenOrNil()
	local single_target
	for id, target in pairs(State.all_targets) do
		target = radar_targets[id] or target -- prefer latest data if available

		local last_seen_after = Utilities.GetTime().mission_time - target.last_hit_timestamp
		local is_recent_enough = last_seen_after < s(3)
		local is_bandit = Api.IsBandit(target.id)
		if is_recent_enough and is_bandit then
			if single_target ~= nil then
				-- Found a second bandit
				return nil
			end

			single_target = target
		end
	end
	return target
end

function Api.GetNextBanditOrNil(reference_target)
	if not reference_target then
		return Api.GetHighestPriorityBanditOrNil()
	end

	local pick_next_bandit = false
	for id, target in pairs(State.all_targets) do
		target = radar_targets[id] or target -- prefer latest data if available
		local is_bandit = Api.IsBandit(target.id)

		if pick_next_bandit and is_bandit then
			return target
		end

		if id == reference_target.id then
			pick_next_bandit = true
		end
	end

	-- Fallback on first bandit if either reference was not found or no bandit after reference anymore
	for id, target in pairs(State.all_targets) do
		target = radar_targets[id] or target -- prefer latest data if available
		local is_bandit = Api.IsBandit(target.id)

		if is_bandit then
			return target
		end
	end

	return nil
end

function Api.GetHighestPriorityBanditOrNil()
	for _, target in ipairs(State.bandits_by_priority_desc) do
		local is_still_known = State.all_targets[target.id] ~= nil
		if is_still_known then
			return radar_targets[target.id] or target
		end
	end
	return nil
end

function Api.GetTargetForAutoFocusOrNil()
	for _, target in ipairs(State.bandits_by_priority_desc) do
		local is_still_known = State.all_targets[target.id] ~= nil
		local is_close = target.scan_range:ConvertTo(NM) < Config.FOCUS_BANDIT_CLOSER_THAN

		local last_seen_after = Utilities.GetTime().mission_time - target.last_hit_timestamp
		local is_recent_enough = last_seen_after < s(3)

		if is_still_known and is_close and is_recent_enough then
			return radar_targets[target.id] or target
		end
	end
	return nil
end

function Api.GetTargetForBoresightCageOrNil()
	local high_prio_bandit
	local high_prio_non_bandit
	-- in BORESIGHT or CAGE/BORESIGHT the amount of targets on screen is so small that its okay to search fully each tick
	for id, target in pairs(radar_targets) do
		local last_seen_after = Utilities.GetTime().mission_time - target.last_hit_timestamp
		local is_recent_enough = last_seen_after < s(3)

		if is_recent_enough and IsObjectWithIdAlive(id) then
			if Api.IsBandit(id) then
				if not high_prio_bandit or Api.IsTargetHigherPriorityThan(target, high_prio_bandit) then
					high_prio_bandit = target
				end
			else
				if not high_prio_non_bandit or Api.IsTargetHigherPriorityThan(target, high_prio_non_bandit) then
					high_prio_non_bandit = target
				end
			end
		end
	end

	return high_prio_bandit or high_prio_non_bandit
end

function Api.SelectRangeFor(task, slant_range)
	slant_range = slant_range:ConvertTo(NM)
	local current_range = GetJester():GetCockpit():GetManipulator("Radar Range"):GetState() or Config.range.nm_50

	-- Inc/Dec thresholds must be different to ensure it does not constantly toggle when a target flies at the edge
	local increase_factor = 0.9
	local decrease_factor = 0.75

	-- Move the range in the right direction until it stabilizes
	local previous_range = current_range
	for _ = 1, 7 do
		-- Steps are to ensure it cannot run forever in presence of bugs
		local next_range = previous_range
		if previous_range == Config.range.nm_5 and slant_range > increase_factor * NM(5) then
			next_range = Config.range.nm_10
		elseif previous_range == Config.range.nm_10 then
			if slant_range > increase_factor * NM(10) then
				next_range = Config.range.nm_25
			elseif slant_range < decrease_factor * NM(5) then
				next_range = Config.range.nm_5
			end
		elseif previous_range == Config.range.nm_25 then
			if slant_range > increase_factor * NM(25) then
				next_range = Config.range.nm_50
			elseif slant_range < decrease_factor * NM(10) then
				next_range = Config.range.nm_10
			end
		elseif previous_range == Config.range.nm_50 then
			if slant_range > increase_factor * NM(50) then
				next_range = Config.range.nm_100
			elseif slant_range < decrease_factor * NM(25) then
				next_range = Config.range.nm_25
			end
		elseif previous_range == Config.range.nm_100 then
			if slant_range > increase_factor * NM(100) then
				next_range = Config.range.nm_200
			elseif slant_range < decrease_factor * NM(50) then
				next_range = Config.range.nm_50
			end
		elseif previous_range == Config.range.nm_200 and slant_range < decrease_factor * NM(100) then
			next_range = Config.range.nm_100
		end

		local has_stabilized = previous_range == next_range
		if has_stabilized then
			break
		end
		previous_range = next_range
	end

	if previous_range ~= current_range then
		task:ClickFast("Radar Range", previous_range)
	end

	return task
end

function Api.SelectIdentification(first, second)
	if first == RadarTargetIdentification.HOSTILE or second == RadarTargetIdentification.HOSTILE then
		return RadarTargetIdentification.HOSTILE
	elseif first == RadarTargetIdentification.FRIENDLY or second == RadarTargetIdentification.FRIENDLY then
		return RadarTargetIdentification.FRIENDLY
	elseif first == RadarTargetIdentification.NEUTRAL or second == RadarTargetIdentification.NEUTRAL then
		return RadarTargetIdentification.NEUTRAL
	else
		return RadarTargetIdentification.UNKNOWN
	end
end

function Api.IdentificationToString(identification)
	if identification == RadarTargetIdentification.UNKNOWN then
		return "UNKNOWN"
	elseif identification == RadarTargetIdentification.FRIENDLY then
		return "FRIENDLY"
	elseif identification == RadarTargetIdentification.NEUTRAL then
		return "NEUTRAL"
	elseif identification == RadarTargetIdentification.HOSTILE then
		return "HOSTILE"
	end
	return "ERROR"
end

function Api.TargetToString(target)
	return "Target " .. tostring(target.id)
			.. ": " .. Api.IdentificationToString(target.identification)
			.. ", rng " .. tostring(math.floor(target.scan_range:ConvertTo(NM).value))
			.. ", az " .. tostring(math.floor(target.scan_azimuth:ConvertTo(deg).value))
			.. ", alt " .. tostring(math.floor(target.cheat_altitude:ConvertTo(ft).value))
			.. ", number_of_hits " .. tostring(target.number_of_hits)
			.. ", found_in_acq_trk " .. tostring(target.found_in_acq_or_trk)
			.. ", grazing_angle " .. tostring(math.floor(target.grazing_angle:ConvertTo(deg).value))
end

function Api.LockTargetUnderCursor(task)
	return task:ClickSequenceFast("Antenna Trigger",
			"RELEASED",
			"HALF_ACTION",
			"FULL_ACTION",
			"HALF_ACTION",
			"RELEASED")
end

function Api.UnlockTarget(task)
	return task:ClickSequenceFast("Antenna Trigger",
			"RELEASED",
			"HALF_ACTION",
			"RELEASED")
end

function Api.PrepareDiveToss(task)
	return Api.SelectRadarScreen(task)
	          :ClickFast("Radar Mode", Config.mode.air_to_ground, true)
	          :ClickFast("Radar Range", Config.range.nm_10, true)
	          :ClickFast("Radar Gain Coarse", 0.5, true)
end

return Api
