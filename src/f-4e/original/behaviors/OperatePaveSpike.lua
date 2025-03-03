---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require('base.Class')
local Behavior = require('base.Behavior')
local PaveSpike = require('other.PaveSpike')
local Utilities = require 'base.Utilities'

local OperatePaveSpike = Class(Behavior)

function OperatePaveSpike:Constructor()
    Behavior.Constructor(self)
end

function OperatePaveSpike:Tick()
    PaveSpike.Tick(Utilities.GetTime().dt)
end

OperatePaveSpike:Seal()
return OperatePaveSpike
