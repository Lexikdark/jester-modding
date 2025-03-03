---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require 'base.Class'
local Situation = require 'base.Situation'
local Airborne = require 'conditions.Airborne'
local AlignmentRestartingCondition = require 'conditions.AlignmentRestartingCondition'
local RestartingAlignment = require 'behaviors.Realign'

local AlignmentRestart = Class(Situation)

AlignmentRestart:AddActivationConditions(AlignmentRestartingCondition())

AlignmentRestart:AddDeactivationConditions(Airborne.True:new())
AlignmentRestart:AddDeactivationConditions(AlignmentRestartingCondition:Not())

function AlignmentRestart:OnActivation()
		self:AddBehavior(RestartingAlignment)
end

function AlignmentRestart:OnDeactivation()
		self:RemoveBehavior(RestartingAlignment)
end

AlignmentRestart:Seal()
return AlignmentRestart
