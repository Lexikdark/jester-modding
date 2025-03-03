local Class = require 'base.Class'
local Situation = require 'base.Situation'
local IsHighAltitude = require 'conditions.IsHighAltitude'
local ObserveOxygenGauge = require 'behaviors.NFO.ObserveOxygenGauge'

local HighAltitudeFlight = Class(Situation)

HighAltitudeFlight:AddActivationConditions(IsHighAltitude.True:new())
HighAltitudeFlight:AddDeactivationConditions(IsHighAltitude.False:new())

function HighAltitudeFlight:OnActivation()
	self:AddBehavior(ObserveOxygenGauge)
end

function HighAltitudeFlight:OnDeactivation()
	self:RemoveBehavior(ObserveOxygenGauge)
end

HighAltitudeFlight:Seal()
return HighAltitudeFlight
