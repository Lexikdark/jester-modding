
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

--Climbout after takeoff, so cleanup calls and anything else immediately post takeoff.

local Class = require 'base.Class'
local Situation = require 'base.Situation'
local Landed = require 'conditions.Airborne'
local TakeoffAdvisory = require 'behaviors.NFO.takeoff.TakeOffAdvisory'
local OnRunwayCondition = require 'conditions.OnRunway'
local JustTookOff = require 'conditions.JustTookOff'
local PostTakeOffAdvisory = require 'behaviors.NFO.takeoff.PostTakeOffAdvisory'

local TakeOff = Class(Situation)

TakeOff:AddActivationConditions(JustTookOff.True:new())

TakeOff:AddDeactivationConditions(JustTookOff.False:new())

function TakeOff:OnActivation()
	Log("Take Off: Just took off!")
	self:AddBehavior(PostTakeOffAdvisory)
end

function TakeOff:OnDeactivation()
	Log("Take Off: Just Took off Expired")
	self:RemoveBehavior(PostTakeOffAdvisory)
end

TakeOff:Seal()
return TakeOff
