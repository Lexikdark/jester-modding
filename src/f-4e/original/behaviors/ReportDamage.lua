---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.
local Class = require('base.Class')
local Behavior = require('base.Behavior')
local Interactions = require('base.Interactions')
local SayTask = require('tasks.common.SayTask')
local Utilities = require('base.Utilities')

local ReportDamage = Class(Behavior)
ReportDamage.last_time_reported = s(-500)

local reporting_damage_min_interval = s(60)

local critical_cells = {55, --tail
                        35, --Left wing in
                        36 --Right wing in
    }

function ReportDamage:Constructor()
    Behavior.Constructor(self)
end

function ReportDamage:ReportInjury()
    local task = SayTask:new('spotting/iamhit')
    task:SetPriority(2)
    GetJester():AddTask(task)
end

function ReportDamage:ReportDamage()
    local current_time = Utilities.GetTime().mission_time:ConvertTo(s)
    local touching_ground = GetJester().awareness:GetObservation("touching_ground") or false
    if (current_time - self.last_time_reported) > reporting_damage_min_interval and not touching_ground then
        local jester = GetJester()
        local heavy_damage = jester.memory:GetWeAreCriticallyDamaged()
        local g_force = jester.awareness:GetObservation("g_force") or u(1.0)
        local g_force_threshod = u(10.0)
        local task
        if heavy_damage then
            task = SayTask:new('damage/heavydamage')
        elseif g_force > g_force_threshod then
            return
        else
            task = SayTask:new('spotting/werehit')
        end
        task:SetPriority(2)
        GetJester():AddTask(task)
        self.last_time_reported = current_time
    end
end

ListenTo("injured", "ReportDamage", function(task, value)
    local jester = GetJester()
    if jester and jester.behaviors[ReportDamage] then
        jester.behaviors[ReportDamage]:ReportInjury()
    end
end)

ListenTo("damaged", "ReportDamage", function(task, value)
    local damage_report_threshold = 0.2
    local critical_damage_threshold = 0.99

    if type(value) == "string" then
        local cell_id_str, damage_size_str = value:match("([^;]+);([^;]+)")
        local cell_id = tonumber(cell_id_str)
        local damage_size = tonumber(damage_size_str)

        if damage_size ~= nil then
            for _, critical_cell in ipairs(critical_cells) do
                if cell_id == critical_cell and damage_size > critical_damage_threshold then --Critical damage received
                    jester.memory:SetWeAreCriticallyDamaged(true)
                end
            end
        end

        local jester = GetJester()
        if damage_size ~= nil and damage_size > damage_report_threshold and jester.behaviors[ReportDamage] then
            jester.memory:SetWeAreDamaged(true)
            jester.behaviors[ReportDamage]:ReportDamage()
        end

    end
end)

ListenTo("repair", "ReportDamage", function(task, value)
    local memory = GetJester().memory
    memory:SetWeAreDamaged(false)
    memory:SetWeAreCriticallyDamaged(false)
end)

ReportDamage:Seal()
return ReportDamage
