---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.
--Landing callouts (alt, speed, etc) and comments about quality.

local Class = require 'base.Class'
local Situation = require 'base.Situation'

local OnRunway = require 'conditions.OnRunway'
local OnGround = require 'conditions.OnGround'
local TaxiAdvisory = require 'behaviors.NFO.ground_ops.TaxiAdvisory'
local BeforeTakeoffPlanning = require 'behaviors.NFO.ground_ops.BeforeTakeoffPlanning'

local Taxiing = Class(Situation)

Taxiing:AddActivationConditions(OnGround())

Taxiing:AddDeactivationConditions(OnRunway.True:new())
Taxiing:AddDeactivationConditions(OnGround:Not())

-- This triggers also on cold-spawn with engines and power out
function Taxiing:OnActivation()
	self:AddBehavior(TaxiAdvisory)
	self:AddBehavior(BeforeTakeoffPlanning)
end

function Taxiing:OnDeactivation()
	self:RemoveBehavior(TaxiAdvisory)
	self:RemoveBehavior(BeforeTakeoffPlanning)
end

Taxiing:Seal()
return Taxiing
