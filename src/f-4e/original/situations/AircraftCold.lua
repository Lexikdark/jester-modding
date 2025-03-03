---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

-- Detect an aircraft cold state and reset startup_complete memory

local Class = require 'base.Class'
local Situation = require 'base.Situation'
local LeftEngineMasterSwitch = require 'conditions.EngineControlSwitches.LeftEngineMasterSwitch'
local RightEngineMasterSwitch = require 'conditions.EngineControlSwitches.RightEngineMasterSwitch'
local LeftGenSwitch = require 'conditions.GeneratorSwitches.LeftGeneratorSwitch'
local RightGenSwitch = require 'conditions.GeneratorSwitches.RightGeneratorSwitch'

local AircraftCold = Class(Situation)

AircraftCold:AddActivationConditions(LeftGenSwitch:Not():And(RightGenSwitch:Not():And(RightEngineMasterSwitch:Not():And(LeftEngineMasterSwitch:Not() ) ) ) )

AircraftCold:AddDeactivationConditions(LeftGenSwitch():And(RightGenSwitch():And(RightEngineMasterSwitch():And(LeftEngineMasterSwitch() ) ) ) )

function AircraftCold:OnActivation()
	GetJester().memory:SetStartupComplete(false)
	GetJester().memory:SetAlignmentTypeChosen(false)
end

function AircraftCold:onDeactivation()
end

AircraftCold:Seal()
return AircraftCold