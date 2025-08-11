---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require('base.Class')
local Behavior = require('base.Behavior')
local StressReaction = require('base.StressReaction')
local StartNavComp = require('tasks.start.StartNavComp')
local Task = require('base.Task')
local Interactions = require('base.Interactions')
local SayTask = require('tasks.common.SayTask')
local Urge = require('base.Urge')
local StartINSTask = require('tasks.start.StartINS')

local StartAircraft = Class(Behavior)
local default_interval = s(4)

function StartAircraft:Constructor()
	Behavior.Constructor(self)

	local startup_in_progress = false
	local step_one_done = false
	local step_two_done = false
	local ins_aligned = GetJester().awareness:GetObservation("ins_alignment_state")

	local startAircraft = function()
		local tasks = {}
		ins_aligned = GetJester().awareness:GetObservation("ins_alignment_state")
		local startup_complete = GetJester().memory:GetStartupComplete()
		local full_alignment_wanted = GetJester().memory:GetFullAlignment()
		local bath_alignment_wanted = GetJester().memory:GetBathAlignment()
		local hdg_mem_alignment_wanted = GetJester().memory:GetHdgMemAlignment()
		local alignment_aborted = GetJester().memory:GetAlignmentAborted()
		local alignment_type_chosen = GetJester().memory:GetAlignmentTypeChosen()
		local heat_light_status = GetJester().awareness:GetObservation("heat_light")
		local align_light_blinking = GetJester().awareness:GetObservation("align_light_blinking")
		local align_light_stdy = GetJester().awareness:GetObservation("align_light_stdy")
		local RWR_is_on = GetJester().awareness:GetObservation("wso_rwr_system_power")
		local ins_damaged = GetJester().awareness:GetObservation("ins_damaged")

		if not alignment_type_chosen
				and not startup_complete
				and not startup_in_progress
				and not ins_damaged then
			-- State: Start INS alignment
			local task = Task:new():Wait( s(2), { voice = true }):NextTask(StartINSTask:new())
			GetJester():AddTask(task)
			tasks[#tasks + 1] = task
		end

		if ins_aligned < 3 -- Alignment state 3 is fully aligned INS
				and not startup_complete
				and not startup_in_progress
				and not ins_damaged
				and alignment_type_chosen then

			startup_in_progress = true
			-- State: Start navigation computer
			local task = StartNavComp:new()
			GetJester():AddTask(task)
			tasks[#tasks + 1] = task


		elseif ins_aligned < 3
				and not startup_complete
				and startup_in_progress
				and full_alignment_wanted
				and not alignment_aborted then

			if not step_one_done then

				local task = Task:new()
						:Wait( s(0.5), { hands = true })
						:Click("INS Mode Knob", "STBY")
				GetJester():AddTask(task)
				tasks[#tasks + 1] = task
				step_one_done = true
				heat_light_status = true -- hacky way to step over the first check because the check is done before light goes on
			end

			if not heat_light_status and step_one_done and not step_two_done then
				local task = Task:new():Click("INS Mode Knob", "ALIGN")
				GetJester():AddTask(task)
				tasks[#tasks + 1] = task
				step_two_done = true
			end
			if align_light_blinking and step_two_done then
				local task = Task:new():Click("INS Mode Knob", "NAV")
				GetJester():AddTask(task)
				tasks[#tasks + 1] = task
			end

		elseif ins_aligned < 3
				and not startup_complete
				and startup_in_progress
				and bath_alignment_wanted
				and not alignment_aborted then
			if not step_one_done then
				ClickRaw(Interactions.devices.INS_AN_ASN_63, Interactions.device_commands.INS_WSO_ALIGN_MODE_COVER, 0) -- Needs to disable the hdg mem switch in case it would be on
				local task = Task:new()
						:Click("INS Mode Knob", "STBY", s(0.1), true)
						:Wait( s(2.0), { hands = true })
						:Click("INS Mode Knob", "ALIGN", s(0.1), true)
				GetJester():AddTask(task)
				tasks[#tasks + 1] = task
				step_one_done = true
			end

			if align_light_stdy and step_one_done then
				local task = Task:new():Click("INS Mode Knob", "NAV")
				GetJester():AddTask(task)
				tasks[#tasks + 1] = task
			end

		elseif ins_aligned < 3
				and not startup_complete
				and startup_in_progress
				and hdg_mem_alignment_wanted
				and not alignment_aborted then
			if not step_one_done then
				local task = Task:new()
						:Click("INS Mode Knob", "STBY", s(0.1), true)
						:Wait( s(2.0), { hands = true })
						:Click("INS Mode Knob", "ALIGN", s(0.1), true)
				GetJester():AddTask(task)
				tasks[#tasks + 1] = task
				step_one_done = true
			end
			
			if align_light_blinking and step_one_done then
				local task = Task:new()
				           :Click("INS Mode Knob", "NAV")
						   :Wait( s(0.5), { hands = true })
				           :Click("Align Mode Knob", "OFF")
				GetJester():AddTask(task)
				tasks[#tasks + 1] = task
				ClickRaw(Interactions.devices.INS_AN_ASN_63, Interactions.device_commands.INS_WSO_ALIGN_MODE_COVER, 0)
			end
		end

		if not startup_complete and ins_aligned == 3 and startup_in_progress then
			-- State: Start rest of the systems
			local task = SayTask:new('phrases/AlignmentCompleted')
			GetJester():AddTask(task)
			tasks[#tasks + 1] = task
			ClickRawKnob(Interactions.devices.TACAN_AN_ARN_118, Interactions.device_commands.RIO_TACAN_Function_Selector, 3, 5)
			ClickRaw(Interactions.devices.OXYGENSYSTEM, Interactions.device_commands.OXYGENSYSTEM_RIO_Set_Ox_Supply_TOGGLE, 1)
			task = Task:new():Click("Radio Mode", "TR_G_ADF")
			GetJester():AddTask(task)
			tasks[#tasks + 1] = task
			if not RWR_is_on then
				task = Task:new():Click("WSO RWR System Power Button", "ON")
				GetJester():AddTask(task)
				tasks[#tasks + 1] = task
			end

			task = Task:new():Click("Combat-Tree Mode 2", "positive")
					:Click("Combat-Tree Mode 3", "positive")
			GetJester():AddTask(task)
			tasks[#tasks + 1] = task

			startup_in_progress = false
			GetJester().memory:SetFullAlignment(false)
			GetJester().memory:SetBathAlignment(false)
			GetJester().memory:SetHdgMemAlignment(false)
			step_one_done = false
			GetJester():AddTask(SayTask:new('phrases/readytotaxi'))
		elseif not startup_complete and alignment_aborted and startup_in_progress then
			local task = Task:new():Click("INS Mode Knob", "NAV")
			GetJester():AddTask(task)
			task = SayTask:new('phrases/youborkedthealign')
			GetJester():AddTask(task)
			tasks[#tasks + 1] = task
			ClickRawKnob(Interactions.devices.TACAN_AN_ARN_118, Interactions.device_commands.RIO_TACAN_Function_Selector, 3, 5)
			ClickRaw(Interactions.devices.OXYGENSYSTEM, Interactions.device_commands.OXYGENSYSTEM_RIO_Set_Ox_Supply_TOGGLE, 1)
			task = Task:new():Click("Radio Mode", "TR_G_ADF")
			GetJester():AddTask(task)
			tasks[#tasks + 1] = task
			if not RWR_is_on then
				task = Task:new():Click("WSO RWR System Power Button", "ON")
				GetJester():AddTask(task)
				tasks[#tasks + 1] = task
			end

			task = Task:new():Click("Combat-Tree Mode 2", "positive")
			           :Click("Combat-Tree Mode 3", "positive")
			GetJester():AddTask(task)
			tasks[#tasks + 1] = task

			startup_in_progress = false
			GetJester().memory:SetFullAlignment(false)
			GetJester().memory:SetBathAlignment(false)
			GetJester().memory:SetHdgMemAlignment(false)
			GetJester().memory:SetAlignmentAborted(false)
			GetJester().memory:SetStartAlignmentOption(false)
			GetJester().memory:SetUserInitiatesAlignment(false)
			GetJester().memory:SetStartupComplete(true)
			step_one_done = false
			GetJester():AddTask(SayTask:new('phrases/readytotaxi'))
		end

		return tasks

	end

	self.check_urge = Urge:new({
		time_to_release = default_interval,
		on_release_function = startAircraft,
		stress_reaction = StressReaction.ignorance,
	})
	self.check_urge:Restart()

end

function StartAircraft:Tick()
	-- check urge
	self.check_urge:Tick()

	local ground_speed = GetJester().awareness:GetObservation("ground_speed")
	local ins_aligned = GetJester().awareness:GetObservation("ins_alignment_state")

	if ground_speed > kt(1) and ins_aligned < 3 then
		GetJester().memory:SetAlignmentAborted(true)
	end

end

StartAircraft:Seal()
return StartAircraft
