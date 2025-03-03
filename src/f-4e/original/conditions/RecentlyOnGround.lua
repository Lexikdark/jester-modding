
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require 'base.Class'
local Condition = require 'base.Condition'
local Utilities = require 'base.Utilities'
local Memory = require 'memory.Memory'

local WasRecentlyOnGround = {}
WasRecentlyOnGround.True = Class(Condition)
WasRecentlyOnGround.False = Class(Condition)

local recently_on_ground_threshhold = s(120) --2 minutes? for pattern work.

function RecentlyOnGround()

	local time_since_on_ground = GetJester().memory:GetTimeSinceOnGround()
	if not time_since_on_ground then
		return false
	end

	if time_since_on_ground < recently_on_ground_threshhold then
		return true
	end

	return false

end

function WasRecentlyOnGround.True:Check()
	return RecentlyOnGround()
end

function WasRecentlyOnGround.False:Check()
	return not RecentlyOnGround()
end

WasRecentlyOnGround.True:Seal()
WasRecentlyOnGround.False:Seal()
return WasRecentlyOnGround