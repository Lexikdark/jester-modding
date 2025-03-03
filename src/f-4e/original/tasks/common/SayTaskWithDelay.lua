---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require('base.Class')
local SayAction = require('actions.SayAction')
local DelayAction = require('actions.DelayAction')
local Task = require('base.Task')

local SayTaskWithDelay = Class(Task)

function SayTaskWithDelay:Constructor(phrase, delaytime)
	Task.Constructor(self)
	self:AddAction(DelayAction(delaytime, {voice = true})) --TODO: Fix to not be blocking.
	self:AddAction(SayAction(phrase))
end

SayTaskWithDelay:Seal()
return SayTaskWithDelay
