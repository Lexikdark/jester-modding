---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require('base.Class')
local SwitchTemporarilyAction = require('actions.SwitchTemporarilyAction')
local Task = require('base.Task')

local SwitchTemporarilyTask = Class(Task)
SwitchTemporarilyTask.action = nil

function SwitchTemporarilyTask:Constructor(manipulator_name, state_name, hold_time)
	Task.Constructor(self)
	self.action = SwitchTemporarilyAction(manipulator_name, state_name, hold_time)
	self:AddAction(self.action)
end

SwitchTemporarilyTask:Seal()
return SwitchTemporarilyTask
