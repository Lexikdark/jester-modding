local Class = require 'base.Class'
local Situation = require 'base.Situation'
local AlwaysOn = require 'conditions.AlwaysOn'
local Intention = require 'base.Intention'
local DoAlwaysTestPlan = require 'plans.DoAlwaysTestPlan'

local DoAlways = Class(Intention)

DoAlways:AddActivationConditions(AlwaysOn.True:new())
DoAlways:AddDeactivationConditions(AlwaysOn.False:new())

function DoAlways:OnActivation()
	self:AddPlan(DoAlwaysTestPlan)
end

function DoAlways:OnDeactivation()
end

DoAlways:Seal()
return DoAlways
