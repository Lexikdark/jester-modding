
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
CountermeasuresDispensing.initial_chaff_quantity = 0
CountermeasuresDispensing.initial_flare_quantity = 0
CountermeasuresDispensing.chaff_desired = 0
CountermeasuresDispensing.flare_desired = 0
CountermeasuresDispensing.last_press_time_stamp = Utilities.GetTime().mission_time - s(999)
CountermeasuresDispensing.chaff_flare_mode = 0
CountermeasuresDispensing.initial_flare_mode = 0

function CountermeasuresDispensing:Constructor()
	Behavior.Constructor(self)
end

function CountermeasuresDispensing:SinglePress()
	local task = Task:new()
	task:Click("Dispense Button", "ON")
    task:Click("Dispense Button", "OFF", s(0.2), true)
    GetJester():AddTask(task)
end

function CountermeasuresDispensing:SetVariablesForDispensing(chaff, flare)
    self.initial_chaff_quantity = GetJester().awareness:GetObservation("chaff_counter")
    self.initial_flare_quantity = GetJester().awareness:GetObservation("flare_counter")
    self.chaff_desired = chaff
    self.flare_desired = flare
    self.initial_chaff_mode = GetJester():GetCockpit():GetManipulator("Chaff Mode"):GetState()
    self.initial_flare_mode = GetJester():GetCockpit():GetManipulator("Flare Mode"):GetState()
end

-- dispensing according to current settings
function CountermeasuresDispensing:StartDispensing()
    if not self.dispensing_in_progress then
        self:SetVariablesForDispensing(3,3)
        self.dispensing_in_progress = true
    end
end

-- dispensing after temporarily disabling flare
function CountermeasuresDispensing:StartDispensingChaff()
    if not self.dispensing_in_progress then
        self:SetVariablesForDispensing(3,0)

        local task = Task:new()
        task:Click("Flare Mode", "OFF")
        GetJester():AddTask(task)

        self.dispensing_in_progress = true
    end
end

-- dispensing after temporarily disabling chaff
function CountermeasuresDispensing:StartDispensingFlare()
    if not self.dispensing_in_progress then
        self:SetVariablesForDispensing(0,3)

        local task = Task:new()
        task:Click("Chaff Mode", "OFF")
        GetJester():AddTask(task)

        self.dispensing_in_progress = true
    end
end

function CountermeasuresDispensing:StopDispensing()
    local task = Task:new()
    task:Click("Chaff Mode", self.initial_chaff_mode)
    task:Click("Flare Mode", self.initial_flare_mode)
    GetJester():AddTask(task)

    self.dispensing_in_progress = false
end

function CountermeasuresDispensing:Tick()
    local time_since_last_press = Utilities.GetTime().mission_time - self.last_press_time_stamp

    if self.dispensing_in_progress and time_since_last_press > s(1) then
        local chaff_quantity = GetJester().awareness:GetObservation("chaff_counter")
        local flare_quantity = GetJester().awareness:GetObservation("flare_counter")

        local chaff_dispensed = self.initial_chaff_quantity - chaff_quantity
        local flare_dispensed = self.initial_flare_quantity - flare_quantity

        local chaff_done = chaff_dispensed >= self.chaff_desired or chaff_quantity == 0
        local flare_done = flare_dispensed >= self.flare_desired or flare_quantity == 0

        if chaff_done and flare_done then
            self:StopDispensing()
        else
            self:SinglePress()
            self.last_press_time_stamp = Utilities.GetTime().mission_time
        end
    end
end

CountermeasuresDispensing:Seal()
return CountermeasuresDispensing
