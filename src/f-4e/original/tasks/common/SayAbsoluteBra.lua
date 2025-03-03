---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require('base.Class')
local Math = require('base.Math')
local Utilities = require('base.Utilities')
local SayAction = require('actions.SayAction')
local Task = require('base.Task')

local SayAbsoluteBra = Class(Task)

local BearingToPhrase = function(bearing)
	local bearing_deg_text = tostring(math.floor(Math.Clamp(bearing:ConvertTo(deg), deg(0), deg(359)).value))
	local digits = string.len(bearing_deg_text)
	if digits == 1 then
		bearing_deg_text = "00" + bearing_deg_text
	elseif digits == 2 then
		bearing_deg_text = "0" + bearing_deg_text
	end

	local first = Utilities.NumberToText(string.sub(bearing_deg_text, 1, 1))
	local second = Utilities.NumberToText(string.sub(bearing_deg_text, 2, 2))
	local third = Utilities.NumberToText(string.sub(bearing_deg_text, 3, 3))

	-- e.g. HSI/twotwothree
	return "HSI/" .. first .. second .. third
end

local RangeToPhrase = function(range)
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

local AltitudeToPhrase = function(altitude, use_angels)
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

-- E.g. 006, 10 miles, angels 5
function SayAbsoluteBra:Constructor(bearing, range, altitude, use_angels)
	Task.Constructor(self)
	local on_activation = function()
		self:RemoveAllActions()
		local bearing_phrase = BearingToPhrase(bearing)
		local range_phrase = RangeToPhrase(range)
		local altitude_phrase = AltitudeToPhrase(altitude, use_angels)

		self:AddAction(SayAction('HSI/BRAA', bearing_phrase, range_phrase, altitude_phrase))
	end
	self:AddOnActivationCallback(on_activation)
end

SayAbsoluteBra:Seal()
return SayAbsoluteBra
