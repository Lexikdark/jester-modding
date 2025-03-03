---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require('base.Class')
local SwitchAction = require('actions.SwitchAction')
local Task = require('base.Task')

local SwitchTask = Class(Task)
SwitchTask.action = nil

function SwitchTask:Constructor(manipulator_name, state_name)
	Task.Constructor(self)
	if not state_name ~= nil and manipulator_name ~= nil then
		self.action = SwitchAction(manipulator_name, state_name)
		self:AddAction(self.action)
		return
	end
	error("Switch task manipulator name: " .. manipulator_name .. " or state name: " .. state_name .. " is NIL." )
end

SwitchTask:Seal()
return SwitchTask
