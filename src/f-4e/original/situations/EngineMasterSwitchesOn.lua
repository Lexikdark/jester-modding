---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require 'base.Class'
local Situation = require 'base.Situation'
local LeftEngineMasterSwitch = require 'conditions.EngineControlSwitches.LeftEngineMasterSwitch'
local RightEngineMasterSwitch = require 'conditions.EngineControlSwitches.RightEngineMasterSwitch'
local LeftGeneratorSwitch = require 'conditions.GeneratorSwitches.LeftGeneratorSwitch'
local RightGeneratorSwitch = require 'conditions.GeneratorSwitches.RightGeneratorSwitch'
local LeftGeneratorSwitchExt = require 'conditions.GeneratorSwitches.LeftGeneratorSwitchExt'
local RightGeneratorSwitchExt = require 'conditions.GeneratorSwitches.RightGeneratorSwitchExt'
local Airborne = require 'conditions.Airborne'
local Task = require 'base.Task'
local StartINSTask = require('tasks.start.StartINS')

local EngineMasterSwitchesOn = Class(Situation)


EngineMasterSwitchesOn:AddActivationConditions(LeftEngineMasterSwitch():And(RightEngineMasterSwitch())
		:And(LeftGeneratorSwitch():Or(LeftGeneratorSwitchExt))
		:And(RightGeneratorSwitch():Or(RightGeneratorSwitchExt())))

EngineMasterSwitchesOn:AddDeactivationConditions(Airborne.True:new())

function EngineMasterSwitchesOn:OnActivation()
	local ins_aligned = GetJester().awareness:GetObservation("ins_alignment_state")
	local alignment_type_chosen = GetJester().memory:GetAlignmentTypeChosen()

	if not alignment_type_chosen
	and ins_aligned < 3 then

		local task = Task:new():Wait( s(2), { voice = true }):NextTask(StartINSTask:new())
		GetJester():AddTask(task)

	end

	end


function EngineMasterSwitchesOn:OnDeactivation()

end

EngineMasterSwitchesOn:Seal()
return EngineMasterSwitchesOn