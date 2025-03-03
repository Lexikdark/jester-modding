---// Action.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require 'base.Class'

local Action = Class()

Action.name = ''
Action.finished = false
Action.estimated_time_to_finish = s(0)
Action.requires = {}

-- requires: table with bool entries "hands", "eyes", "voice"
function Action:Constructor(requires)
	if requires then
		self.requires = requires
	end
end

function Action:Tick() -- overridable
end

function Action:Restart() -- overridable
end

function Action:IsFinished()
	return self.finished
end

function Action:RequiresHands()
	self.requires.hands = true
end

function Action:RequiresEyes()
	self.requires.eyes = true
end

function Action:RequiresVoice()
	self.requires.voice = true
end

function Action:AreHandsRequired()
	return self.requires.hands
end

function Action:AreEyesRequired()
	return self.requires.eyes
end

function Action:IsVoiceRequired()
	return self.requires.voice
end

local mt = getmetatable(Action)
mt.__call = function(self,...)
	return self:new(...)
end


Action:Seal()

return Action
