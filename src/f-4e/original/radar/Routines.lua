---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Utilities = require('base.Utilities')
local Urge = require('base.Urge')
local StressReaction = require('base.StressReaction')
local Task = require('base.Task')
local Config = require('radar.Config')
local State = require('radar.State')
local Api = require('radar.Api')

local Routines = {}

Routines.update_targets_priority = Urge:new({
	time_to_release = s(1),
	on_release_function = function()
		Api.UpdateTargetsPriority()
	end,
	stress_reaction = StressReaction.fixation,
})
Routines.update_targets_priority:Restart()

Routines.forget_old_targets = Urge:new({
	time_to_release = s(3),
	on_release_function = function()
		Routines.ForgetOldTargets()
	end,
	stress_reaction = StressReaction.ignorance,
})
Routines.forget_old_targets:Restart()

Routines.check_iff = Urge:new({
	time_to_release = s(30),
	on_release_function = function()
		Routines.CheckIff()
	end,
	stress_reaction = StressReaction.ignorance,
})
Routines.check_iff:Restart()

Routines.update_close_bandit_awareness = Urge:new({
	time_to_release = s(2),
	on_release_function = function()
		Routines.UpdateCloseBanditAwareness()
	end,
	stress_reaction = StressReaction.fixation,
})
Routines.update_close_bandit_awareness:Restart()

function Routines.ForgetOldTargets()
	local current_time = Utilities.GetTime().mission_time
	for id, target in pairs(State.all_targets) do
		local memorized_for = current_time - target.last_hit_timestamp
		if memorized_for > Config.FORGET_OLD_TARGETS_AFTER or not IsObjectWithIdAlive(id) then
			Log("Forgetting target " .. tostring(id))
			State.all_targets[id] = nil
			State.processed_targets[id] = nil
			State.identified_targets[id] = nil
			State.unidentified_new_targets[id] = nil
		end
	end
end

function Routines.CheckIff()
	-- This is for Jester to appear more human, updating his "memory" of who is who
	-- and to assist the player who might look at the screen as well
	local no_iff_since = Utilities.GetTime().mission_time - State.last_iff_timestamp
	local is_wrong_phrase = State.current_phase == nil or State.current_phase == Config.phase.PREPARE_SCAN_PATTERN or State.current_phase == Config.phase.HANDLE_TARGET_LOCKING
	if no_iff_since < Config.WAIT_WITH_REGULAR_IFF_FOR or is_wrong_phrase then
		Log("Skipping pressing IFF")
		return
	end

	Log("Pressing IFF regular")
	local task = Api.ClickIffButton(Task:new())
	GetJester():AddTask(task)
end

function Routines.UpdateCloseBanditAwareness()
	for _, target in ipairs(State.bandits_by_priority_desc) do
		target = radar_targets[target.id] or target

		local last_seen_after = Utilities.GetTime().mission_time - target.last_hit_timestamp
		local is_recent_enough = last_seen_after < s(15)
		local is_close_enough = target.scan_range:ConvertTo(NM) < NM(10)
		local is_hostile = Api.IsHostile(target) -- Only trigger for confirmed bandits, not unknowns

		if is_recent_enough and is_close_enough and is_hostile then
			GetJester().awareness.has_close_radar_bandit = true
			return
		end
	end

	GetJester().awareness.has_close_radar_bandit = false
end

return Routines
