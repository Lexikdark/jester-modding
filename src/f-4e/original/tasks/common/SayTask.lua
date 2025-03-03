---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require('base.Class')
local SayAction = require('actions.SayAction')
local Task = require('base.Task')

local SayTask = Class(Task)
SayTask.from_jester_dialog = false
SayTask.phrase = nil
SayTask.action = nil

function SayTask:Constructor(phrase)
	Task.Constructor(self)
	self.phrase = phrase
	local on_activation = function()
		if not self.action then
			self.action = SayAction(phrase)
			self:AddAction(self.action)
		end
	end
	self:AddOnActivationCallback(on_activation)
end

function SayTask:Stop()
	if self.action ~= nil then
		self.action:Stop()
	end
end

SayTask:Seal()
return SayTask
