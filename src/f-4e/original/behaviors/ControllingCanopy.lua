---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require('base.Class')
local Behavior = require('base.Behavior')
local StressReaction = require('base.StressReaction')
local Urge = require('base.Urge')
local Task = require('base.Task')

local ControllingCanopy = Class(Behavior)
local default_interval = s(4)

function ControllingCanopy:Constructor()
	Behavior.Constructor(self)

	local controllingCanopy = function()

		local is_pilot_sealed = GetJester().awareness:GetObservation("pilot_canopy_sealed")
		local is_wso_sealed = GetJester().awareness:GetObservation("wso_canopy_sealed")
		local has_said_canopy = GetJester().memory:GetSaidCanopy()

		if is_pilot_sealed and not is_wso_sealed then

			local task = Task:new():Click("WSO Canopy Handle", "OFF")
			task:Wait(s(8))
			    :Require({ hands = true, voice = true })

			if not has_said_canopy then
				task:Say('phrases/CanopyDownLightsOutAndStripesAligned')
				GetJester().memory:SetSaidCanopy(true)
			end

			GetJester():AddTask(task)

		elseif not is_pilot_sealed then
			local task = Task:new():Click("WSO Canopy Handle", "ON")
			GetJester():AddTask(task)

		end


	end

	self.check_urge = Urge:new({
		time_to_release = default_interval,
		on_release_function = controllingCanopy,
		stress_reaction = StressReaction.ignorance,
	})
	self.check_urge:Restart()

end

function ControllingCanopy:Tick()
	-- check urge
	self.check_urge:Tick()


end

ControllingCanopy:Seal()
return ControllingCanopy
