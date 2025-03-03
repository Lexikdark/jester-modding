
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.
--Landing callouts (alt, speed, etc) and comments about quality.

local Class = require 'base.Class'
local Situation = require 'base.Situation'
local InLandingConfig = require 'conditions.InLandingConfig'
local Landed = require 'conditions.Landed'
local Task = require('base.Task')
local LandingQualityComments = require 'behaviors.NFO.landing.CommentOnLanding'
local ReportAltitude = require 'behaviors.NFO.landing.ReportAltitude'
local LandingAdvisory = require 'behaviors.NFO.landing.LandingAdvisory'
local RecentlyOnGround = require 'conditions.RecentlyOnGround'
local PaveSpike = require('other.PaveSpike')
local RadarApi = require('radar.Api')

local Landing = Class(Situation)

Landing:AddActivationConditions(InLandingConfig.True:new())

Landing:AddDeactivationConditions(InLandingConfig.False:new())
Landing:AddDeactivationConditions(Landed())
Landing:AddDeactivationConditions(RecentlyOnGround.True:new())

function Landing:OnActivation()
	self:AddBehavior(LandingQualityComments)
	self:AddBehavior(ReportAltitude)
	self:AddBehavior(LandingAdvisory)

	GetJester():AddTask(PaveSpike.SetOperatingMode(Task:new(), "standby"))
	GetJester():AddTask(RadarApi.SetOperatingMode(Task:new(), "standby"))
end

function Landing:OnDeactivation()
	self:RemoveBehavior(LandingQualityComments)
	self:RemoveBehavior(ReportAltitude)
	self:RemoveBehavior(LandingAdvisory)
end

Landing:Seal()
return Landing
