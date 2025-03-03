---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.
-- Behaviour for commenting on too high speed while taxiing, etc, here.

local Class = require 'base.Class'
local Situation = require 'base.Situation'
local ConditionLanded = require 'conditions.Landed'
local Task = require('base.Task')

local Landed = Class(Situation)

Landed:AddActivationConditions(ConditionLanded:New())

Landed:AddDeactivationConditions(ConditionLanded:Not())

function Landed:OnActivation()
	GetJester().memory:SetStartupComplete(false)
	GetJester().memory:SetAlignmentTypeChosen(false)
end

function Landed:OnDeactivation()

end

Landed:Seal()
return Landed