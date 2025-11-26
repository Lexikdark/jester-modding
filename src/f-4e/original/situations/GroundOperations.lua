---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

-- Close Canopy when either taxiing or pilot closes his canopy

local Class = require 'base.Class'
local Situation = require 'base.Situation'
local Airborne = require 'conditions.Airborne'
local CopyPilotCanopy = require 'behaviors.CopyPilotCanopy'

local GroundOperations = Class(Situation)

GroundOperations:AddActivationConditions(Airborne.False:new())
GroundOperations:AddDeactivationConditions(Airborne.True:new())

function GroundOperations:OnActivation()
	GetJester().memory:SetSaidCanopy(false)
	self:AddBehavior(CopyPilotCanopy)
end

function GroundOperations:onDeactivation()
	GetJester().memory:SetSaidCanopy(false)
	self:RemoveBehavior(CopyPilotCanopy)
end

GroundOperations:Seal()
return GroundOperations
