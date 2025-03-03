---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Utilities = require 'base.Utilities'
local Math = require 'base.Math'

local BraCalls = {}

function BraCalls.RadarBearingPhrase(bearing)
	-- Phrases are "radar/leftfortydegrees" or "radar/rightfifteendegrees" in steps of 5 (5, 10, 15, ..., 55, "gimbal")
	local bearing_deg = math.floor(Math.Clamp(bearing:ConvertTo(deg), deg(-60), deg(60)).value)

	local direction = "right"
	if bearing_deg < 0 then
		direction = "left"
	end

	local bearing_abs = math.abs(bearing_deg)
	-- 5 increments, e.g. 13->10 and 16->215
	local tens = math.floor(bearing_abs / 10)
	local ones = bearing_abs % 10
	if ones < 5 then
		bearing_abs = tens * 10
	else
		bearing_abs = tens * 10 + 5
	end

	if bearing_abs < 5 then
		bearing_abs = 5
	elseif bearing_abs > 55 then
		bearing_abs = 60
	end

	local bearing_text = Utilities.NumberToText(tostring(bearing_abs)) .. "degrees"
	if bearing_abs == 60 then
		bearing_text = "gimbal"
	end

	return "radar/" .. direction .. bearing_text
end

function BraCalls.RangePhrase(range)
	local range_nm = math.floor(Math.Clamp(range:ConvertTo(NM), NM(1), NM(195)).value)

	-- 5 increments, e.g. 213->210 and 216->215
	if range_nm > 115 then
		local without_last_digit = math.floor(range_nm / 10)
		local last_digit = range_nm % 10
		if last_digit < 5 then
			range_nm = without_last_digit * 10
		else
			range_nm = without_last_digit * 10 + 5
		end
	end

	return "misc/" .. tostring(range_nm) .. "miles"
end

function BraCalls.AltitudePhrase(altitude, use_angels)
	altitude = Math.Clamp(altitude:ConvertTo(ft), ft(1), ft(60000))
	if use_angels then
		local altitude_angels = math.floor(altitude.value / 1000.0)
		-- e.g. angels/angelsthirtytwo
		return "angels/angels" .. Utilities.NumberToText(altitude_angels, true)
	end

	local altitude_text
	if altitude <= ft(100) then
		altitude_text = "50"
	elseif altitude < ft(2500) then
		-- 100 steps
		altitude_text = tostring(math.floor(altitude.value / 100) * 100)
	elseif altitude < ft(27000) then
		-- 500 steps
		local altitude_raw = math.floor(altitude.value / 1000) * 1000
		if altitude.value % 1000 >= 500 then
			altitude_raw = altitude_raw + 500
		end
		altitude_text = tostring(altitude_raw)
	else
		-- 1000 steps
		altitude_text = tostring(math.floor(altitude.value / 1000) * 1000)
	end
	-- e.g. angels/51000ft
	return "angels/" .. altitude_text .. "ft"
end

function BraCalls.IntroduceContactPhrase(identification, group_size, do_continue_sentence)
	local phrase = "contacts_iff/"

	if do_continue_sentence then
		phrase = phrase .. "anda"
	else
		phrase = phrase .. "wevegota"
	end

	if identification == RadarTargetIdentification.FRIENDLY then
		phrase = phrase .. "friend"
	elseif identification == RadarTargetIdentification.HOSTILE then
		phrase = phrase .. "ban"
	else
		phrase = phrase .. "bog"
	end

	if group_size == 2 then
		phrase = phrase .. "2ship"
	elseif group_size == 3 then
		phrase = phrase .. "3ship"
	elseif group_size == 4 then
		phrase = phrase .. "4ship"
	elseif group_size > 4 then
		phrase = phrase .. "gorilla"
	end

	return phrase .. "bra"
end

function BraCalls.IntroduceUnidentifiedContactPhrase(is_multiple_contacts, is_only_contact_on_screen)
	local phrase = "contacts_iff/wehave"

	if is_only_contact_on_screen then
		if is_multiple_contacts then
			phrase = phrase .. "newbogeys"
		else
			phrase = phrase .. "anewbogey"
		end
	else
		if is_multiple_contacts then
			phrase = phrase .. "multiplebogeys"
		else
			phrase = phrase .. "onebogey"
		end
	end

	return phrase
end

return BraCalls
