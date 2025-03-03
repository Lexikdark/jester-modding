---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require 'base.Class'
local Situation = require 'base.Situation'
local LeftGenSwitch = require 'conditions.GeneratorSwitches.LeftGeneratorSwitch'
local RightGenSwitch = require 'conditions.GeneratorSwitches.RightGeneratorSwitch'
local OnRunway = require 'conditions.OnRunway'
local Airborne = require 'conditions.Airborne'
local StartupState = require 'conditions.StartupState'
local Task = require 'base.Task'
local AskIfReadyForAlignment = require 'behaviors.AskIfReadyForAlignment'

local PowerOnAndOnGroundCondition = require 'conditions.PowerOnAndOnGround'

local PowerOnAndOnGround = Class(Situation)

PowerOnAndOnGround:AddActivationConditions(PowerOnAndOnGroundCondition())

PowerOnAndOnGround:AddDeactivationConditions(StartupState())
PowerOnAndOnGround:AddDeactivationConditions(PowerOnAndOnGroundCondition:Not())
PowerOnAndOnGround:AddDeactivationConditions(OnRunway.True:new())
PowerOnAndOnGround:AddDeactivationConditions(Airborne.True:new())
PowerOnAndOnGround:AddDeactivationConditions(LeftGenSwitch:Not():And(RightGenSwitch:Not()))

function PowerOnAndOnGround:OnActivation()
	self:AddBehavior(AskIfReadyForAlignment)
end

function PowerOnAndOnGround:OnDeactivation()
	self:RemoveBehavior(AskIfReadyForAlignment)
end

PowerOnAndOnGround:Seal()
return PowerOnAndOnGround
