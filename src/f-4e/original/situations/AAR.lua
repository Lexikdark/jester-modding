local Class = require 'base.Class'
local Situation = require 'base.Situation'
local Task = require('base.Task')
local IsAAR = require 'conditions.IsAAR'
local AssistAAR = require 'behaviors.AssistAAR'
local PrepareDscg = require('behaviors.PrepareDscg')
local RadarApi = require('radar.Api')

local AAR = Class(Situation)

AAR:AddActivationConditions(IsAAR.True:new())
AAR:AddDeactivationConditions(IsAAR.False:new())

function AAR:OnActivation()
	self:AddBehavior(AssistAAR)
	GetJester():AddTask(RadarApi.SetOperatingMode(Task:new(), "standby"))
end

function AAR:OnDeactivation()
	self:RemoveBehavior(AssistAAR)
	GetJester().behaviors[PrepareDscg]:ClearModes()
end

AAR:Seal()
return AAR
