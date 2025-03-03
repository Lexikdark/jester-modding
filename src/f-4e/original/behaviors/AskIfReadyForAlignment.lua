---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require('base.Class')
local Behavior = require('base.Behavior')
local StressReaction = require('base.StressReaction')
local SayReadyForInsAlignment = require('tasks.start.SayReadyForInsAlignment')
local Urge = require('base.Urge')
local Utilities = require('base.Utilities')

local AskIfReadyForAlignment = Class(Behavior)
local default_interval = s(10)
local has_asked_for_alignment = 0
local timer_second_question = s(0)

function AskIfReadyForAlignment:Constructor()
	Behavior.Constructor(self)

	local askIfReady = function()
		local ins_damaged = GetJester().awareness:GetObservation("ins_damaged")
		local has_asked_twice = GetJester().memory:GetUserInitiatesAlignment()


		if has_asked_for_alignment < 1 and not has_asked_twice and not ins_damaged then

			local task = SayReadyForInsAlignment:new()
			GetJester():AddTask(task)
			has_asked_for_alignment = has_asked_for_alignment + 1
		elseif has_asked_for_alignment == 1 and not has_asked_twice and timer_second_question > s(60) then
			local task = SayReadyForInsAlignment:new()
			GetJester():AddTask(task)
			has_asked_for_alignment = has_asked_for_alignment + 1
			GetJester().memory:SetStartAlignmentOption(true)
		end

		if has_asked_for_alignment == 2 and not ins_damaged then
			GetJester().memory:SetUserInitiatesAlignment(true)

		end

	end

	self.check_urge = Urge:new({
		time_to_release = default_interval,
		on_release_function = askIfReady,
		stress_reaction = StressReaction.ignorance,
	})
	self.check_urge:Restart()

end

function AskIfReadyForAlignment:Tick()
	-- check urge
	self.check_urge:Tick()
	timer_second_question = timer_second_question + Utilities.GetTime().dt

end

AskIfReadyForAlignment:Seal()
return AskIfReadyForAlignment
