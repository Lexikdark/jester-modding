---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

-- Close Canopy when either taxiing or pilot closes his canopy

local Class = require 'base.Class'
local Situation = require 'base.Situation'
local OnRunway = require 'conditions.OnRunway'
local CanopiesDifferent = require 'conditions.CanopiesDifferent'
local Airborne = require 'conditions.Airborne'
local ControllingCanopy = require 'behaviors.ControllingCanopy'

local CloseCanopy = Class(Situation)

CloseCanopy:AddActivationConditions(CanopiesDifferent())

CloseCanopy:AddDeactivationConditions(Airborne.True:new())
CloseCanopy:AddDeactivationConditions(CanopiesDifferent:Not())


function CloseCanopy:OnActivation()
	GetJester().memory:SetSaidCanopy(false)
	self:AddBehavior(ControllingCanopy)
end

function CloseCanopy:onDeactivation()
	GetJester().memory:SetSaidCanopy(false)
	self:RemoveBehavior(ControllingCanopy)
end

CloseCanopy:Seal()
return CloseCanopy