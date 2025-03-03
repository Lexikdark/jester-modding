---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require('base.class')
local Task = require('base.Task')

local StartNavComp = Class(Task)

function StartNavComp:Constructor()
	Task.Constructor(self)

	self:Click("WSO Ground Power Switch", "OFF")
	    :ClickSequenceFast("Nav Panel Function", "STBY",
			"TARGET_1",
			"TARGET_2",
			"RESET",
			"TARGET_2",
			"TARGET_1",
			"STBY")
end

StartNavComp:Seal()
return StartNavComp
