local Class = require 'base.Class'
local Situation = require 'base.Situation'
local Task = require 'base.Task'
local IsBombing = require 'conditions.IsBombing'
local AssistBombing = require 'behaviors.AssistBombing'

local Bombing = Class(Situation)

Bombing:AddActivationConditions(IsBombing.True:new())
Bombing:AddDeactivationConditions(IsBombing.False:new())

function Bombing:OnActivation()
	self:AddBehavior(AssistBombing)
end

function Bombing:OnDeactivation()
	self:RemoveBehavior(AssistBombing)
end

Bombing:Seal()
return Bombing
