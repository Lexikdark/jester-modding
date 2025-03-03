---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require('base.Class')
local Behavior = require('base.Behavior')
local Urge = require('base.Urge')
local StressReaction = require('base.StressReaction')
local SaySpeed = require('tasks.common.SaySpeed')

local arbcs = '/Weapons/ARBCS System/ARBCS'

local AssistBombing = Class(Behavior)
AssistBombing.previous_speed = kt(0)

local IsPullUpLight = function()
	return GetProperty(arbcs, 'Pull-Up Light').value or false
end

local IsLabsTone = function()
	return GetProperty(arbcs, 'Pull-Up Tone Playing').value or false
end

local IsApproaching = function()
	local delivery_mode = GetJester():GetCockpit():GetManipulator("Delivery Mode"):GetState() or "OFF"

	if delivery_mode == "LOFT" or delivery_mode == "OS" or delivery_mode == "TLAD" or delivery_mode == "TL" then
		return IsPullUpLight()
	end

	if delivery_mode == "TGT_FIND" or delivery_mode == "L" or delivery_mode == "OFFSET" then
		return IsLabsTone()
	end

	-- No meaningful assistance for INST_OS, DIRECT, DT, DL, as Jester does not know when the attack begins
	return false
end

local GetTrueAirspeed = function()
	return GetJester().awareness:GetObservation("TAS") or kt(400)
end

function AssistBombing:CalloutSpeed()
	if not IsApproaching() then
		return
	end

	local current_speed = GetTrueAirspeed()

	local task = SaySpeed:new(current_speed, self.previous_speed)
	GetJester():AddTask(task)

	self.previous_speed = current_speed
end

function AssistBombing:Constructor()
	Behavior.Constructor(self)

	self.callout_speed = Urge:new({
		time_to_release = s(5),
		on_release_function = function()
			self:CalloutSpeed()
		end,
		stress_reaction = StressReaction.fixation,
	})
	self.callout_speed:Restart()
end

function AssistBombing:Tick()
	if self.callout_speed then
		self.callout_speed:Tick()
	end
end

AssistBombing:Seal()
return AssistBombing
