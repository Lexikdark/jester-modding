
local Class = require 'base.Class'
local ReportIAS = require 'behaviors.NFO.common.ReportIAS'
local Situation = require 'base.Situation'
local Merged = require 'conditions.Merged'
local Landed = require 'conditions.Landed'
local InLandingConfig = require 'conditions.InLandingConfig'
local DogfightAdvisory = require 'behaviors.NFO.WVR.DogfightAdvisory'

local Dogfight = Class(Situation)

Dogfight:AddActivationConditions(Merged.True:new())

Dogfight:AddDeactivationConditions(Merged.False:new())
Dogfight:AddDeactivationConditions(Landed())
Dogfight:AddDeactivationConditions(InLandingConfig.True:new())

function Dogfight:OnActivation()
	self:AddBehavior(DogfightAdvisory)
	--local report_ias = self:AddBehavior(ReportIAS)
	--report_ias:SetIASProperty(GetProperty('/WSO Mach And Airspeed Indicator/Gauge/Airspeed Needle Friction Component', 'Output'))
end

function Dogfight:OnDeactivation()
	self:RemoveBehavior(DogfightAdvisory)
end

Dogfight:Seal()

return Dogfight
