local Class = require 'base.Class'
local Situation = require 'base.Situation'
local IsInAircraft = require 'conditions.IsInAircraft'
local UpdateJesterWheel = require 'behaviors.UpdateJesterWheel'
local ObserveAvtr = require 'behaviors.ObserveAvtr'
local ReportDamage = require 'behaviors.ReportDamage'
local Preflight = require 'behaviors.NFO.ground_ops.Preflight'

local InAircraft = Class(Situation)

InAircraft:AddActivationConditions(IsInAircraft.True:new())
InAircraft:AddDeactivationConditions(IsInAircraft.False:new())

function InAircraft:OnActivation()
	self:AddBehavior(UpdateJesterWheel)
	self:AddBehavior(ObserveAvtr)
	self:AddBehavior(ReportDamage)
	self:AddBehavior(Preflight)
end

function InAircraft:OnDeactivation()
	self:RemoveBehavior(UpdateJesterWheel)
	self:RemoveBehavior(ObserveAvtr)
	self:RemoveBehavior(ReportDamage)
	self:RemoveBehavior(Preflight)
end

InAircraft:Seal()
return InAircraft
