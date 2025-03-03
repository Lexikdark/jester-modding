---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require('base.Class')
local Math = require('base.Math')
local SayAction = require('actions.SayAction')
local Task = require('base.Task')

local SayAarSteering = Class(Task)

local direction = {
    aft = "Aft",
    down = "Down",
    forward = "Forward",
    up = "Up",
}

local GetDirDistFrom = function(body_vector)
    local x = body_vector.x -- Forward/Aft
    local z = body_vector.z -- Down/Up
    local absX = Math.Abs(x)
    local absZ = Math.Abs(z)

    -- Choose biggest steering axis (ignoring Left/Right)
    local dir
    local dist
    if absX > absZ then
        if x < ft(0) then
            dir = direction.aft
        else
            dir = direction.forward
        end
        dist = absX
    else
        if z < ft(0) then
            dir = direction.up
        else
            dir = direction.down
        end
        dist = absZ
    end

    return {
        dir = dir,
        dist = dist,
    }
end

local DistToPhraseText = function(dist)
    local dist_ft = math.floor(dist:ConvertTo(ft).value)

    if dist_ft < 1 then
        return "1"
    end

    -- 10, 15, 20
    if dist_ft > 10 then
        if dist_ft < 15 then
            return "10"
        elseif dist_ft < 20 then
            return "15"
        else
            return "20"
        end
    end

    -- 1 to 10
    return tostring(dist_ft)
end

local PhraseFrom = function(body_vector)
    local dir_dist = GetDirDistFrom(body_vector)
    local dist = DistToPhraseText(dir_dist.dist)

    if dir_dist.dir == direction.aft and Dice.new(2):Roll() > 1 then
        -- aft direction has two call variations "Aft" and "Back"
        dir_dist.dir = "Back"
    end

    return "refueling/" .. dir_dist.dir .. "_" .. dist .. "_Feet"
end

function SayAarSteering:Execute()
    local dist = self.steering_body_vector:GetLength()
    if dist < ft(1) or dist > ft(25) then
        -- Outside of reasonable limits to comment on
        return
    end

    local phrase = PhraseFrom(self.steering_body_vector)
    local is_same_phase_as_before = self.previous_steering_body_vector ~= nil and PhraseFrom(self.previous_steering_body_vector) == phrase
    if is_same_phase_as_before then
        -- Do not repeat the previous callout again
        return
    end

    self:AddAction(SayAction(phrase))
end

function SayAarSteering:Constructor(steering_body_vector, previous_steering_body_vector)
    Task.Constructor(self)
    self.steering_body_vector = steering_body_vector
    self.previous_steering_body_vector = previous_steering_body_vector

    self:AddOnActivationCallback(function()
        self:RemoveAllActions()
        self:Execute()
    end)
end

SayAarSteering:Seal()
return SayAarSteering
