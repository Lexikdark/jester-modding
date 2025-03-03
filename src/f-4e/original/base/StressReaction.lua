---// StressReaction.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local StressReaction = {
	not_set = 0, -- not_set is equal to random -> it will be randomly assigned to a non-zero value
	random = 0,
	paralyze = -2, -- minimal or no progress on completing the tasks or filling the urge progress bar
	ignorance = -1, -- reduced progress on a given task/urge
	fixation = 1, -- tunnel vision and focus on a given task/urge
	obsession = 2, -- the type of panic that results in focusing almost entirely on a give activity
}

setmetatable(StressReaction, {
	__index = function (_, key)
		error(tostring(key).." is not a valid StressReaction", 2)
	end,
	__newindex = function ()
		error("StressReaction is read_only", 2)
	end
})

return StressReaction
