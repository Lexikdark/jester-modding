---
--- Directional calls: centerline - and later glideslope.
--- Too Fast / too slow calls for landing
--- Any other generalized advisory calls in landing situation.
---
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require('base.Class')
local Behavior = require('base.Behavior')
local Urge = require('base.Urge')
local StressReaction = require('base.StressReaction')
local SayTask = require('tasks.common.SayTask')
local SayTaskWithDelay = require('tasks.common.SayTaskWithDelay')
local Awareness = require('memory.Awareness')
local Utilities = require ('base.Utilities')
local EjectTask = require('tasks.common.Eject')

local LandingAdvisory = Class(Behavior)
local report_slow_or_fast_interval = s(14)

local sinkrate_timer = s(999)
local sinkrate_report_deadzone = s(10)
local has_ejected = false
local checklist_timer = s(0)
local checklist_timer_fire = s(3)

function LandingAdvisory:Constructor()

    local has_said_checklist = false
    local has_said_off_runway_shit = false

    Behavior.Constructor(self)

    local fast_or_slow_callout = function()

            local touching_ground = GetJester().awareness:GetObservation("touching_ground")
            if touching_ground then
                return
            end

            local airspeed = GetJester().awareness:GetObservation("indicated_airspeed")

            if airspeed > kt(350) then
                local task = SayTask:new('phrases/youretoofast')
                GetJester():AddTask(task)
                return { task }
            end

            if airspeed < kt(80) then
                local task = SayTask:new('phrases/youretooslow')
                GetJester():AddTask(task)
                return { task }
            end
        return
    end

    self.say_fast_slow_urge = Urge:new({
                time_to_release = report_slow_or_fast_interval,
                on_release_function = fast_or_slow_callout,
                stress_reaction = StressReaction.fixation,
            })
    self.say_fast_slow_urge:Restart()

end

function LandingAdvisory:Eject()
    local eject_task = EjectTask:new()
    eject_task:SetPriority(3)
    GetJester():AddTask(eject_task)
    has_ejected = true
end

--Make JESTER eject and stuff if you're about to bork the landing.
function LandingAdvisory:DangerousLandingStuff()

    --If vertical velocity is really high; comment on it.
    local velocity_vector = jester.awareness:GetObservation("gods_velocity_ned")
    local airspeed = jester.awareness:GetObservation("indicated_airspeed")
    local vertical_velocity = velocity_vector.z
    local fwd_velocity = velocity_vector.x

    local pitch = jester.awareness:GetObservation("gods_pitch")
    local roll = jester.awareness:GetObservation("gods_roll")
    local altitude = jester.awareness:GetObservation("barometric_altitude")

    --High sinkrate and nose pointing up (i.e. not intentionally diving downwards): "Watch the sinkrate!"
    if vertical_velocity.value > 25 and sinkrate_timer > sinkrate_report_deadzone and pitch > deg(-5) then
        local task = SayTask:new('phrases/WatchSinkRate')
        GetJester():AddTask(task)
        Log("Landing: Commenting on high sinkrate.")
        sinkrate_timer = s(0)
    end

    sinkrate_timer = sinkrate_timer + Utilities.GetTime().dt

    --Ejection cases:
    -- High sinkrate, low airspeed, eject. This is a failed landing for sure.
    if vertical_velocity.value > 35 and airspeed < kt(110) and time_to_impact < s(3) and time_to_impact > s(1) and not has_ejected then
        Log("landing gone wrong due to high VVI, low airspeed, and low TTI, eject!")
        self:Eject()
    end

    --[[
    -- High sinkrate and in the deadzone vis-a-vis ground - eject
    local time_to_impact = jester.awareness:GetObservation("time_to_ground_impact")
    if vertical_velocity.value > 25 and time_to_impact > s(1) and time_to_impact < s(3) and not has_ejected then
        Log("landing gone wrong due to time to death, eject!")
        self:Eject()
    end --]]

    --If we're rolled past 90, eject.
    --[[ Commenting for now as airshows are not possible atm..
    if roll > deg(100) and not has_ejected and altitude < ft(2000) then
        Log("landing gone wrong due to excessive roll, eject!")
        self:Eject()
    end --]]

end

function LandingAdvisory:Tick()

    if has_ejected then
        return
    end

    local airspeed = GetJester().awareness:GetObservation("indicated_airspeed")
    local touching_ground = GetJester().awareness:GetObservation("touching_ground")
    local on_runway = GetJester().awareness:GetObservation("on_runway")

    if self.say_fast_slow_urge then
        self.say_fast_slow_urge:Tick()
    end

    checklist_timer = checklist_timer + Utilities.GetTime().dt

    --Gear, pressure, bla checklist thing.
    local distance_to_airfield = GetJester().awareness:GetObservation("distance_to_nearest_airfield")
    if not self.has_said_checklist and checklist_timer > checklist_timer_fire then
        local task = SayTask:new('checklists/prelandingchecklist')
        GetJester():AddTask(task)
        self.has_said_checklist = true
    end

    --If we're not on the runway and at decent speed; that's very bad.
    --DISABLED FOR NOW DUE TO VARIETY OF BUGS, primarily due to ED reporting the thresholds of the RWY as.. not runway.
    if not self.has_said_off_runway_shit and airspeed > kt(70) and touching_ground and not on_runway then
        --local shittask = SayTask:new('phrases/ShitShitShit')
        --Log("Saying shit shit shit because we were over 70 kts and off the runway.")
        --GetJester():AddTask(shittask) --inhibiting this for now as it happens every time we taxi.
        --self.has_said_off_runway_shit = true
    end

    self:DangerousLandingStuff()

end

LandingAdvisory:Seal()
return LandingAdvisory
