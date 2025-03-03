---// Phrase.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

require 'base.Base'
local Class = require 'base.Class'

local Phrase = Class()

Phrase.text = ''
Phrase.file_path = ''
Phrase.direct_sample_collection = nil
Phrase.direct_sample_collection_missing = false
Phrase.radio_sample_collection = nil
Phrase.radio_sample_collection_missing = false
Phrase.sample_in_use = nil

Phrase.Constructor = function(self, file_path, text)
	self.file_path = file_path
	self.text = text or file_path
	local mt = getmetatable(self)
	mt.__concat = function(a, b)
		local Sentence = require 'voice.Sentence'
		local s = Sentence:new(a, b)
		return s
	end
	mt.__tostring = function(arg)
		return arg.text
	end
end

local function ConditionalMakeDirectSample(phrase)
	if not phrase.direct_sample_collection then
		if Sound then
			phrase.direct_sample_collection = Sound.GetDirectSoundSampleCollection(phrase.file_path)
		else
			io.stderr:write("Jester sound functions not ready.\n")
		end
		if not phrase.direct_sample_collection then
			phrase.direct_sample_collection_missing = true
			io.stderr:write("Jester sound sample missing: " .. phrase.file_path .. "\n")
		end
	end
end

local function ConditionalMakeRadioSample(phrase)
	if not phrase.radio_sample_collection then
		if Sound then
			phrase.radio_sample_collection = Sound.GetRadioSoundSampleCollection(phrase.file_path)
		else
			io.stderr:write("Jester sound functions not ready.\n")
		end
		if not phrase.radio_sample_collection then
			phrase.radio_sample_collection_missing = true
			io.stderr:write("Jester sound sample missing: " .. phrase.file_path .. "\n")
		end
	end
end

function Phrase:IsBeingSpoken()
	if self.sample_in_use and self.sample_in_use:IsPlaying() then
		return true
	end
	return false
end

function Phrase:Say()
	if self:IsBeingSpoken() then
		return
	end
	local jester = GetJester()

	local allowed_to_talk = jester:GetCockpit():GetManipulator("Allowed to Talk"):GetState()
	if (allowed_to_talk ~= "ON") then
		return
	end

	voice = jester.voice
	local intensity = nil
	if voice:IsHighIntensity() then
		intensity = Sound.Intensity.high
	else
		intensity = Sound.Intensity.low
	end
	if voice:UsingIntercom() then
		ConditionalMakeRadioSample(self)
		if self.radio_sample_collection then
			self.sample_in_use = self.radio_sample_collection:GetRandomSample(intensity)
		end
	else
		ConditionalMakeDirectSample(self)
		if self.direct_sample_collection then
			self.sample_in_use = self.direct_sample_collection:GetRandomSample(intensity)
		end
	end
	if self.sample_in_use then
		self.sample_in_use:Play()
	end
end

function Phrase:Stop()
	if self.sample_in_use then
		self.sample_in_use:Stop()
	end
end

local mt = getmetatable(Phrase)
mt.__call = function(self,...)
	return self:new(...)
end

Phrase:Seal()

return Phrase
