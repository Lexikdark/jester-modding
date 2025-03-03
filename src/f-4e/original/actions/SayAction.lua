---// SayAction.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require 'base.Class'
local Action = require 'base.Action'
local Sentence = require 'voice.Sentence'
local Voice = require 'voice.Voice'

local SayAction = Class(Action)

-- override
SayAction:RequiresVoice()
SayAction.name = 'SayAction'
SayAction.started = false
-- new
SayAction.sentence = Sentence:new()

SayAction.Constructor = function(self,...)
	for _, v in ipairs({...}) do
		self.sentence:Append(v)
	end
end

function SayAction:Tick()
	if self.finished then
		return
	end
	if self.started then
		if not self.sentence:IsBeingSpoken() then
			self.finished = true
		end
	else
		local voice = GetJester().voice
		if voice:IsSpeaking() then
			return
		end
		voice:Say(self.sentence)
		self.started = true
	end
end

function SayAction:Restart()
	self.finished = false
	self.started = false
	self.sentence:Stop()
end

function SayAction:Stop()
	self.finished = true
	self.sentence:Stop()
end

local mt = getmetatable(SayAction)
mt.__call = function(self,...)
	return self:new(...)
end

SayAction:Seal()

return SayAction
