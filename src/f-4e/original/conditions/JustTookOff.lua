
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.
local Class = require 'base.Class'
local Condition = require 'base.Condition'
local Utilities = require 'base.Utilities'

local JustTookOff = {}
JustTookOff.True = Class(Condition)
JustTookOff.False = Class(Condition)

local just_took_off_expiry_timer = s(0)
local EXPIRY_LENGTH = s(30)
local just_took_off = false

function just_took_off_from_ground()

	--We just took off, if we've recently been in Landed state, and we're airborne.
	local airborne = GetJester().awareness:GetObservation("airborne") or false
	local last_time_landed = GetJester().memory:GetLastTimeLanded()
	local time_since_landed = Utilities.GetTime().mission_time - last_time_landed

	just_took_off = false

	if time_since_landed < s(45) and airborne then
		just_took_off = true
	end

	--[[
	--We expire the just took off condition with a timer; so that we have time to do some post takeoff shit.
	if just_took_off then
		just_took_off_expiry_timer = just_took_off_expiry_timer + Utilities.GetTime().dt
		if just_took_off_expiry_timer > EXPIRY_LENGTH then
			just_took_off = false
			just_took_off_expiry_timer = s(0)
		end
	end --]]

	return just_took_off
end

function JustTookOff.True:Check()
	return just_took_off_from_ground()
end

function JustTookOff.False:Check()
	return not just_took_off_from_ground()
end

JustTookOff.True:Seal()
JustTookOff.False:Seal()
return JustTookOff