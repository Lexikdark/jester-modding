---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require 'base.Class'
local Situation = require 'base.Situation'
local LeftGenSwitch = require 'conditions.GeneratorSwitches.LeftGeneratorSwitch'
local RightGenSwitch = require 'conditions.GeneratorSwitches.RightGeneratorSwitch'
local OnRunway = require 'conditions.OnRunway'
local StartAircraft = require 'behaviors.StartAircraft'
local Airborne = require 'conditions.Airborne'

local StartUpState = require 'conditions.StartupState'

local StartUp = Class(Situation)

StartUp:AddActivationConditions(StartUpState())

StartUp:AddDeactivationConditions(Airborne.True:new())
StartUp:AddDeactivationConditions(LeftGenSwitch:Not():And(RightGenSwitch:Not()))

function StartUp:OnActivation()
	self:AddBehavior(StartAircraft)
end

function StartUp:OnDeactivation()
	self:RemoveBehavior(StartAircraft)
end

StartUp:Seal()
return StartUp
