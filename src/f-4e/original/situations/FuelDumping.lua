local Class = require 'base.Class'
local Situation = require 'base.Situation'
local DumpingFuel = require 'conditions.DumpingFuel'
local RemindDumpingFuel = require 'behaviors.RemindDumpingFuel'

local FuelDumping = Class(Situation)

FuelDumping:AddActivationConditions(DumpingFuel.True:new())
FuelDumping:AddDeactivationConditions(DumpingFuel.False:new())

function FuelDumping:OnActivation()
	self:AddBehavior(RemindDumpingFuel)
end

function FuelDumping:OnDeactivation()
	self:RemoveBehavior(RemindDumpingFuel)
end

FuelDumping:Seal()
return FuelDumping
