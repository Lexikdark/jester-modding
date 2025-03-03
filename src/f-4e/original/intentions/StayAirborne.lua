---// StayAirborne.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Airborne = require 'conditions.Airborne'
local Class = require 'base.Class'
local DoNotCrash = require 'plans.DoNotCrash'
local Intention = require 'base.Intention'
local OnGround = require 'conditions.OnGround'
local StayinAlive = require 'plans.StayinAlive'

local StayAirborne = Class(Intention)

StayAirborne:AddActivationConditions(Airborne.True:new())
StayAirborne:AddDeactivationConditions(OnGround())

function StayAirborne:OnActivation()
	self:AddPlan(DoNotCrash)
	self:AddPlan(StayinAlive)
end

function StayAirborne:OnDeactivation()
	self:RemoveAllPlans()
end

StayAirborne:Seal()

return StayAirborne
