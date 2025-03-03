local Class = require 'base.Class'
local Situation = require 'base.Situation'
local Task = require 'base.Task'
local Airborne = require 'conditions.Airborne'
local ObserveFuel = require 'behaviors.ObserveFuel'
local ObserveCockpitPressureIndicator = require 'behaviors.NFO.ObserveCockpitPressureIndicator'
local Navigate = require 'behaviors.NFO.navigation.Navigate'
local OperatePaveSpike = require 'behaviors.OperatePaveSpike'
local OperateRadar = require 'radar.OperateRadar'
local MoveRadarCursor = require 'radar.MoveRadarCursor'
local MoveRadarAntenna = require 'radar.MoveRadarAntenna'
local ReportWVRContacts = require 'behaviors.NFO.WVR.ReportWVRContacts'
local PrepareDscg = require 'behaviors.PrepareDscg'
local ReportTraffic = require 'behaviors.NFO.common.ReportTraffic'
local ObserveRWR = require 'behaviors.ObserveRWR'
local ReportMissiles = require 'behaviors.ReportMissiles'
local CountermeasuresDispensing = require 'behaviors.CountermeasuresDispensing'

local Flight = Class(Situation)

Flight:AddActivationConditions(Airborne.True:new())
Flight:AddDeactivationConditions(Airborne.False:new())

function Flight:OnActivation()
	self:AddBehavior(ObserveFuel)
	self:AddBehavior(ObserveCockpitPressureIndicator)
	self:AddBehavior(Navigate)
	self:AddBehavior(OperatePaveSpike)
	self:AddBehavior(OperateRadar)
	self:AddBehavior(MoveRadarCursor)
	self:AddBehavior(MoveRadarAntenna)
	self:AddBehavior(ReportWVRContacts)
	self:AddBehavior(PrepareDscg)
	self:AddBehavior(ReportTraffic)
	self:AddBehavior(ObserveRWR)
	self:AddBehavior(ReportMissiles)
	self:AddBehavior(CountermeasuresDispensing)

	local task = Task:new()
	        :Click("Chaff Mode", "PROG")
			:Click("Flare Mode", "PROG")
	GetJester():AddTask(task)
end

function Flight:OnDeactivation()
	self:RemoveBehavior(ObserveFuel)
	self:RemoveBehavior(ObserveCockpitPressureIndicator)
	self:RemoveBehavior(Navigate)
	self:RemoveBehavior(OperatePaveSpike)
	self:RemoveBehavior(OperateRadar)
	self:RemoveBehavior(MoveRadarCursor)
	self:RemoveBehavior(MoveRadarAntenna)
	self:RemoveBehavior(ReportWVRContacts)
	self:RemoveBehavior(PrepareDscg)
	self:RemoveBehavior(ReportTraffic)
	self:RemoveBehavior(ObserveRWR)
	self:RemoveBehavior(ReportMissiles)
	self:RemoveBehavior(CountermeasuresDispensing)
end

Flight:Seal()
return Flight
