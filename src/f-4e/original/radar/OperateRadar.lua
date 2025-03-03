---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require('base.Class')
local Behavior = require('base.Behavior')
local Radar = require('radar.Radar')

local OperateRadar = Class(Behavior)

function OperateRadar:Constructor()
	Behavior.Constructor(self)
end

function OperateRadar:Tick()
	Radar.Tick()
end

OperateRadar:Seal()
return OperateRadar
