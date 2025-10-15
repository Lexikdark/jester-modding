
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

-- Post takeoff advisory. Gear up, flaps up, etc. and if you forget -> Jester reminds you etc.

-- Buffer the state of the landing gear indicators every 0.3 seconds.
-- If there has been movement -> "Gear moving'". All three need to move to say this.
-- Same for the flaps.

-- When the gear indicators are up -> "Gear up"
-- When the flaps indicators are up -> "Flaps up"

-- If after e.g. 20 seconds one of the two is not up / in -> "Gear is still down.." or "Flaps are still down.."

-- TODO later; if the gear are de-synced from each-other -> one of them is stuck -> report the stuck one.

local Class = require('base.Class')
local Behavior = require('base.Behavior')
local SayTask = require('tasks.common.SayTask')
local SayTaskWithDelay = require ('tasks.common.SayTaskWithDelay')
local Utilities = require ('base.Utilities')
local Memory = require('memory.Memory')
local Timer = require 'base.Timer'

local PostTakeOffAdvisory = Class(Behavior)

local has_said_gear_moving = false
local has_said_gear_up = false
local has_said_flaps_moving = false
local has_said_flaps_up = false
local has_said_gear_still_down = false
local has_said_flaps_still_down = false

--If any of the two are still down by the time this thresshold is reached; comment on it..
local gear_still_down_threshold = s(15)
local flaps_still_down_threshold = s(15)

local gear_up_threshold = 0.1
local gear_moving_threshold = 0.9
local flaps_up_threshold = 0.15

function PostTakeOffAdvisory:Constructor()
	Behavior.Constructor(self)

	--[[
	self.remind_gear_timer = Timer:new(s(15), function()
		--Log("Something is still down")
		--self:RemindGearStillDown()
	end)

	self.remind_flaps_timer = Timer:new(s(15), function()
		--Log("Something is still down")
		--self:RemindFlapsStillDown()
	end) --]]

end

--If we haven't said the gear is up and it is still down; say gear is still down (remind the player).
--TODO: later; differentiate between stuck and reminding that the lever is down -> i.e. observe the lever.
function PostTakeOffAdvisory:RemindGearStillDown()

	if not has_said_gear_still_down and not has_said_gear_up then
		local gear_indicator_1 = GetJester().awareness:GetObservation("left_gear_indicator") or 0.0
		local gear_indicator_2 = GetJester().awareness:GetObservation("right_gear_indicator") or 0.0
		local gear_indicator_3 = GetJester().awareness:GetObservation("nose_gear_indicator") or 0.0

		if gear_indicator_1 < gear_up_threshold and gear_indicator_2 < gear_up_threshold and gear_indicator_3 < gear_up_threshold then
			return
		end

		local task = SayTask:new('checklists/gearisstilldown')
		GetJester():AddTask(task)
		has_said_gear_still_down = true
	end
end

--If we haven't said the flaps are up and they are still down; say flaps are stuck.
function PostTakeOffAdvisory:RemindFlapsStillDown()
	if not has_said_flaps_still_down and not has_said_flaps_up then

		local flaps_indicator = GetJester().awareness:GetObservation("flaps_indicator") or u(0.0)

		if flaps_indicator.value < flaps_up_threshold then
			return
		end

		local task = SayTask:new('checklists/flapsstuck')
		GetJester():AddTask(task)
		has_said_flaps_still_down = true
	end
end

function PostTakeOffAdvisory:Tick()
	local gear_indicator_1 = GetJester().awareness:GetObservation("left_gear_indicator") or 0.0
	local gear_indicator_2 = GetJester().awareness:GetObservation("right_gear_indicator") or 0.0
	local gear_indicator_3 = GetJester().awareness:GetObservation("nose_gear_indicator") or 0.0
	local flaps_indicator = GetJester().awareness:GetObservation("flaps_indicator") or u(0.0)

	--Gear moving
	if gear_indicator_1 < gear_moving_threshold and gear_indicator_2 < gear_moving_threshold and gear_indicator_3 < gear_moving_threshold then
		if not has_said_gear_moving then
			local task = SayTaskWithDelay:new('checklists/gearsmoving', s(1))
			Log("Post Takeoff: Gear moving.")
			GetJester():AddTask(task)
			has_said_gear_moving = true
		end
	end

	--Gear up
	if gear_indicator_1 < gear_up_threshold and gear_indicator_2 < gear_up_threshold and gear_indicator_3 < gear_up_threshold then
		if not has_said_gear_up then
			local task = SayTaskWithDelay:new('checklists/gearup', s(2))
			Log("Post Takeoff: Gear up.")
			GetJester():AddTask(task)
			has_said_gear_up = true
		end
	end

	--Flaps up
	if flaps_indicator.value < flaps_up_threshold then
		if not has_said_flaps_up then
			local task = SayTaskWithDelay:new('checklists/flapsup', s(2))
			Log("Post Takeoff: Flaps up.")
			GetJester():AddTask(task)
			has_said_flaps_up = true
		end
	end

end

PostTakeOffAdvisory:Seal()
return PostTakeOffAdvisory
