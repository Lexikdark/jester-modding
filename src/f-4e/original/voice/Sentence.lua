---// Sentence.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require 'base.Class'
local Phrase = require 'voice.Phrase'

local Sentence = Class()

Sentence.priorities = {
	joke = -1,
	status = 0,
	safety = 1,
	critical = 2,
}

Sentence.priority = Sentence.priorities.status

Sentence.phrases = {}
Sentence.being_spoken = false

function Sentence:Append(arg)
	if Class.IsInstanceOf(arg, Sentence) then
		for _, v in ipairs(arg.phrases) do
			self:Append(v)
		end
	elseif Class.IsInstanceOf(arg, Phrase) then
		table.insert(self.phrases, arg)
	else
		table.insert(self.phrases, Phrase:new(arg))
	end
end

function Sentence:IsBeingSpoken()
	return self.being_spoken
end

function Sentence:Stop()
	local voice = GetJester().voice
	if voice.sentence == self then
		voice:Stop()
	end
end

Sentence.Constructor = function(self,...)
	for _, v in ipairs({...}) do
		self:Append(v)
	end

	local mt = getmetatable(self)
	mt.__tostring = function(arg)
		local result = tostring(arg.phrases[1] or '')
		for i = 2, #arg.phrases do
			result = result .. ' ' .. tostring(arg.phrases[i])
		end
		return result
	end
end

local mt = getmetatable(Sentence)
mt.__call = function(self,...)
	return self:new(...)
end

Sentence:Seal()

return Sentence
