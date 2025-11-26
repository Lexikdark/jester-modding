---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require('base.Class')
local Behavior = require('base.Behavior')
local StressReaction = require('base.StressReaction')
local Urge = require('base.Urge')
local Task = require('base.Task')

local CopyPilotCanopy = Class(Behavior)

function CopyPilotCanopy:Constructor()
	Behavior.Constructor(self)
	local routine = function()
		--Log("Checking Canopy")
		local is_pilot_open = GetJester().awareness:GetObservation("pilot_canopy_open")
		local is_wso_open = GetJester().awareness:GetObservation("wso_canopy_open")
		local has_said_canopy = GetJester().memory:GetSaidCanopy()

		if not is_pilot_open and is_wso_open then
			--Log("Closing canopy")
			local task = Task:new():Click("WSO Canopy Handle", "OFF")

			if not has_said_canopy then
				task:Wait(s(8))
						:Require({ hands = true, voice = true })
						:Say('phrases/CanopyDownLightsOutAndStripesAligned')
				GetJester().memory:SetSaidCanopy(true)
			end

			GetJester():AddTask(task)
		elseif is_pilot_open and not is_wso_open then
			--Log("Opening canopy")
			local task = Task:new():Click("WSO Canopy Handle", "ON")
			GetJester():AddTask(task)
		end
	end

	self.check_urge = Urge:new({
		time_to_release = s(4),
		on_release_function = routine,
		stress_reaction = StressReaction.ignorance,
	})
	self.check_urge:Restart()
end

function CopyPilotCanopy:Tick()
	self.check_urge:Tick()
end

CopyPilotCanopy:Seal()
return CopyPilotCanopy
