
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

--Landed condition - important that it expires after based on a timer so we can sort
--Landing vs Takeoff behaviours, etc.

local Class = require 'base.Class'
local Condition = require 'base.Condition'
local Utilities = require 'base.Utilities'

local LANDED_EXPIRY_TIMER_LENGTH = s(45)
local landed_state_expiry_timer = LANDED_EXPIRY_TIMER_LENGTH

local Landed = Class(Condition)

local is_landed = false

function IsLanded()


	local wow = GetJester().awareness:GetObservation("landed") or false
	local speed = GetJester().awareness:GetObservation("ground_speed") or false

	if wow and speed < kt(50) then
		landed_state_expiry_timer = LANDED_EXPIRY_TIMER_LENGTH
		is_landed = true
		GetJester().memory:SetLastTimeLanded(Utilities.GetTime().mission_time)

	else
		landed_state_expiry_timer = landed_state_expiry_timer - Utilities.GetTime().dt
		if landed_state_expiry_timer <= s(0) then
			landed_state_expiry_timer = s(0) --prevent negative, not that it matters though?

			is_landed = false

		end
	end

	return is_landed

end

function Landed:Check()
	return IsLanded()
end

Landed:Seal()

return Landed
