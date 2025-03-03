
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

--Takeoff advisory calls and other shit.

local Class = require 'base.Class'
local Situation = require 'base.Situation'
local Landed = require 'conditions.Landed'
local TakeoffAdvisory = require 'behaviors.NFO.takeoff.TakeOffAdvisory'
local OnRunwayCondition = require 'conditions.OnRunway'

local TakeOff = Class(Situation)

TakeOff:AddActivationConditions(OnRunwayCondition.True:new())

TakeOff:AddDeactivationConditions(OnRunwayCondition.False:new())

function TakeOff:OnActivation()
    self:AddBehavior(TakeoffAdvisory)
end

function TakeOff:OnDeactivation()
    self:RemoveBehavior(TakeoffAdvisory)
end

TakeOff:Seal()
return TakeOff
