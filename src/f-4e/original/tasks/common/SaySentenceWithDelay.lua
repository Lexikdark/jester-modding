---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require('base.Class')
local SayAction = require('actions.SayAction')
local DelayAction = require('actions.DelayAction')
local Task = require('base.Task')
local Sentence = require('voice.Sentence')

local SaySentenceWithDelay = Class(Task)

function SaySentenceWithDelay:Constructor(sentence, delaytime)
	Task.Constructor(self)
	local on_activation = function()
		self:RemoveAllActions()

		self:AddAction(DelayAction(delaytime, {voice = true})) --TODO: Fix to not be blocking.
		self:AddAction(SayAction(unpack(sentence)))
	end
	self:AddOnActivationCallback(on_activation)
end

SaySentenceWithDelay:Seal()
return SaySentenceWithDelay
