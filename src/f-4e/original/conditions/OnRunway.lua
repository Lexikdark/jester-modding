
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require 'base.Class'
local Condition = require 'base.Condition'

local OnRunway = {}
OnRunway.True = Class(Condition)
OnRunway.False = Class(Condition)

function IsOnRunway()

    local on_rwy = GetJester().awareness:GetObservation("on_runway")

    if on_rwy then
        return true
    end

    return false
end

function OnRunway.True:Check()
    return IsOnRunway()
end

function OnRunway.False:Check()
    return not IsOnRunway()
end

OnRunway.True:Seal()
OnRunway.False:Seal()
return OnRunway