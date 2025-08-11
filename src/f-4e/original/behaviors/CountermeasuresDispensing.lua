
---// CountermeasuresDispensing.lua
---// Copyright (c) 2024 Heatblur Simulations. All rights reserved.

-- Use countermeasures (chaff + flare), triggered from other places

local Class = require('base.Class')
local Behavior = require('base.Behavior')
local Math = require('base.Math')
local Urge = require('base.Urge')
local Utilities = require('base.Utilities')
local StressReaction = require('base.StressReaction')
local Task = require('base.Task')
local SayTask = require('tasks.common.SayTask')
local SayTaskWithDelay = require ('tasks.common.SayTaskWithDelay')
local Labels = require 'base.Labels'
local Sentence = require 'voice.Sentence'
local Constants = require 'base.Constants'
local SaySentenceWithDelay = require 'tasks.common.SaySentenceWithDelay'

local CountermeasuresDispensing = Class(Behavior)

CountermeasuresDispensing.dispensing_in_progress = false
CountermeasuresDispensing.presses = 0
CountermeasuresDispensing.last_press_time_stamp = Utilities.GetTime().mission_time - s(999)
CountermeasuresDispensing.chaff_flare_mode = 0
CountermeasuresDispensing.initial_flare_mode = 0

function CountermeasuresDispensing:Constructor()
	Behavior.Constructor(self)
end

function CountermeasuresDispensing:SinglePress()
	local task = Task:new()
	task:ClickShortFast("Dispense Button", "ON")
	task:SetPriority(2)
    GetJester():AddTask(task)
    self.last_press_time_stamp = Utilities.GetTime().mission_time
    self.presses = self.presses + 1
end

function CountermeasuresDispensing:SetVariablesForDispensing()
    self.initial_chaff_mode = GetJester():GetCockpit():GetManipulator("Chaff Mode"):GetState()
    self.initial_flare_mode = GetJester():GetCockpit():GetManipulator("Flare Mode"):GetState()
    self.presses = 0
    self.dispensing_in_progress = true
end

-- dispensing according to current settings
function CountermeasuresDispensing:StartDispensing()
    if not self.dispensing_in_progress then
        self:SetVariablesForDispensing()
    end
end

-- dispensing after temporarily disabling flare
function CountermeasuresDispensing:StartDispensingChaff()
    if not self.dispensing_in_progress then
        local task = Task:new()
        task:Click("Flare Mode", "OFF")
        task:SetPriority(3)
        GetJester():AddTask(task)
        Log('CountermeasuresDispensing | Disable Flare')

        self:SetVariablesForDispensing()
    end
end

-- dispensing after temporarily disabling chaff
function CountermeasuresDispensing:StartDispensingFlare()
    if not self.dispensing_in_progress then
        local task = Task:new()
        task:Click("Chaff Mode", "OFF")
        task:SetPriority(3)
        GetJester():AddTask(task)

        self:SetVariablesForDispensing()
    end
end

function CountermeasuresDispensing:StopDispensing()
    local task = Task:new()
    task:Click("Chaff Mode", self.initial_chaff_mode)
    task:Click("Flare Mode", self.initial_flare_mode)
    GetJester():AddTask(task)

    local chaff_mode_correct = GetJester():GetCockpit():GetManipulator("Chaff Mode"):GetState() == self.initial_chaff_mode
    local flare_mode_correct = GetJester():GetCockpit():GetManipulator("Flare Mode"):GetState() == self.initial_flare_mode

    if chaff_mode_correct and flare_mode_correct then
        self.dispensing_in_progress = false
    end
end

function CountermeasuresDispensing:Tick()
    local time_since_last_press = Utilities.GetTime().mission_time - self.last_press_time_stamp

    if self.dispensing_in_progress and time_since_last_press > s(1) then
        if self.presses >= 3 then
            Log('CountermeasuresDispensing | StopDispensing()')
            self:StopDispensing()
        else
            Log('CountermeasuresDispensing | SinglePress()')
            self:SinglePress()
        end
    end
end

CountermeasuresDispensing:Seal()
return CountermeasuresDispensing
