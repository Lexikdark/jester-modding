---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require('base.Class')
local Math = require('base.Math')
local SayAction = require('actions.SayAction')
local Task = require('base.Task')

local green_zone_radius = ft(3) -- green zone is about 3ft in all directions, see https://i.imgur.com/a5PGZsZ.png

local SayAarDrifting = Class(Task)

local direction = {
    aft = "Aft",
    down = "Down",
    forward = "Forward",
    up = "Up",
    center = "LookingGood"
}

local GetDirectionFrom = function(body_vector)
    if body_vector:GetLength() < green_zone_radius then
        return direction.center
    end

    local x = body_vector.x -- Forward/Aft
    local z = body_vector.z -- Down/Up
    local absX = Math.Abs(x)
    local absZ = Math.Abs(z)

    -- Choose biggest steering axis (ignoring Left/Right)
    if absX > absZ then
        if x > ft(0) then
            return direction.aft
        else
            return direction.forward
        end
    else
        if z > ft(0) then
            return direction.up
        else
            return direction.down
        end
    end
end

local DirectionToPhrase = function(dir)
    if dir == direction.center then
        return "refueling/LookingGood"
    end

    return "refueling/Drifting_" .. dir
end

function SayAarDrifting:Execute()
    local dir = GetDirectionFrom(self.steering_body_vector)
    local is_same_dir_as_before = self.previous_steering_body_vector ~= nil and GetDirectionFrom(self.previous_steering_body_vector) == dir
    if is_same_dir_as_before then
        -- Do not repeat the previous callout again
        return
    end

    local phrase = DirectionToPhrase(dir)
    self:AddAction(SayAction(phrase))
end

function SayAarDrifting:Constructor(steering_body_vector, previous_steering_body_vector)
    Task.Constructor(self)
    self.steering_body_vector = steering_body_vector
    self.previous_steering_body_vector = previous_steering_body_vector

    self:AddOnActivationCallback(function()
        self:RemoveAllActions()
        self:Execute()
    end)
end

SayAarDrifting:Seal()
return SayAarDrifting
