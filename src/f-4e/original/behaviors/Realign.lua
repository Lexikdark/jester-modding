---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require('base.Class')
local Behavior = require('base.Behavior')
local StressReaction = require('base.StressReaction')
local Urge = require('base.Urge')
local Task = require('base.Task')
local Utilities = require('base.Utilities')
local Interactions = require('base.Interactions')
local SayTask = require('tasks.common.SayTask')

local RestartingAlignment = Class(Behavior)
local default_interval = s(2)


function RestartingAlignment:Constructor()
	Behavior.Constructor(self)

	local is_aligning = false

	local restartAlignment = function()
		local align_light_blinking = GetJester().awareness:GetObservation("align_light_blinking")
		local is_realigning = GetJester().memory:GetRealigning()
		local realignment_complete = GetJester().memory:GetRealignmentComplete()

		if not is_realigning and not is_aligning and not realignment_complete then
			Log("Realignment started")
			ClickRaw(Interactions.devices.INS_AN_ASN_63, Interactions.device_commands.INS_WSO_ALIGN_MODE_COVER, 0) -- Needs to disable the hdg mem switch in case it would be on
			GetJester().memory:SetRealigning(true)
			is_aligning = true
			local task = Task:new():Click("INS Mode Knob", "ALIGN")
			GetJester():AddTask(task)
		end

		if align_light_blinking and is_realigning then
			Log("Realignment done")
			local task = Task:new():Click("INS Mode Knob", "NAV")
					:Say('phrases/realignmentcomplete')
			GetJester():AddTask(task)
			GetJester().memory:SetRealignmentComplete(true)
			GetJester().memory:SetRealigning(false)
			GetJester().memory:SetStartRealigning(false)
			is_aligning = false
		end

	end

	self.check_urge = Urge:new({
		time_to_release = default_interval,
		on_release_function = restartAlignment,
		stress_reaction = StressReaction.ignorance,
	})
	self.check_urge:Restart()

end

function RestartingAlignment:Tick()
	self.check_urge:Tick()
end

RestartingAlignment:Seal()
return RestartingAlignment
