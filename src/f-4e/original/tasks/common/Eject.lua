---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.
---
local Class = require('base.Class')
local SayAction = require('actions.SayAction')
local Task = require('base.Task')
local EjectAction = require('actions.Eject')
local DelayAction = require('actions.DelayAction')

local Eject = Class(Task)

function Eject:Constructor(hi)
	Task.Constructor(self)

	-- most eject phrases are under 2s
	-- WSO ejection time is around 0.54s
	-- Pilot ejection time is around 1.392s

	local on_activation = function ()
		self:RemoveAllActions()

		self:AddAction(SayAction('phrases/ejectejecteject'))
		self:Require({voice = true, hands = true})
		self:AddAction(EjectAction:new())

	end

	self:AddOnActivationCallback(on_activation)
end

Eject:Seal()
return Eject
