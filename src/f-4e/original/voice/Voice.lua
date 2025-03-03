---// Voice.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require 'base.Class'
local Phrase = require 'voice.Phrase'
local Sentence = require 'voice.Sentence'
local Timer = require 'base.Timer'

local Voice = Class()

Voice.high_intensity = true
Voice.sentence = nil
Voice.current_phrase = nil
Voice.current_phrase_index = 1
Voice.mic_switch_used = false
Voice.mic_switch_off_timer = nil

local mic_switch_off_default_time = s(0.5)
local mic_switch_off_time_sigma = s(0.15)
local mic_switch_off_time_distribution = NormalDistribution.new(mic_switch_off_default_time, mic_switch_off_time_sigma)

function Voice:IsSpeaking()
	return self.sentence ~= nil
end

function Voice:UsingIntercom()
	return true
end

function Voice:IsHighIntensity()

	--Check awareness for whether we are in combat or danger; if yes; we go to HI.
	if GetJester().awareness:GetInCombatOrDanger() then
		self.high_intensity = true
	else
		self.high_intensity = false
	end
	return self.high_intensity
end

function Voice:Say(arg)
	self:Stop()
	if Class.IsInstanceOf(arg, Sentence) then
		self.sentence = arg
	elseif Class.IsInstanceOf(arg, Phrase) then
		self.sentence = Sentence(arg)
	else
		io.stderr:write("Voice Say is neither a sentence nor a phrase\n")
	end
	self.sentence.being_spoken = true
end

function Voice:Stop()
	if self.sentence then
		self.sentence.being_spoken = false
	end
	if self.current_phrase then
		self.current_phrase:Stop()
		self.current_phrase = nil
	end
	self.sentence = nil
end

function Voice:Tick()
	if not self.sentence then
		return
	end
	if not self.current_phrase then
		self.current_phrase_index = 1
		if self.current_phrase_index > #self.sentence.phrases then
			self.sentence.being_spoken = false
			self.sentence = nil
		else
			self.sentence.being_spoken = true
			self.current_phrase = self.sentence.phrases[self.current_phrase_index]
			Log("  --Say: " .. self.current_phrase.text)
			self.current_phrase:Say()
		end
	elseif not self.current_phrase:IsBeingSpoken() then
		self.current_phrase_index = self.current_phrase_index + 1
		if self.current_phrase_index > #self.sentence.phrases then
			self.current_phrase = nil
			self.sentence.being_spoken = false
			self.sentence = nil
		else
			self.current_phrase = self.sentence.phrases[self.current_phrase_index]
			Log("  --Say: " .. self.current_phrase.text)
			self.current_phrase:Say()
		end
	end
	if self:IsSpeaking() then
		if self.mic_switch_off_timer then
			self.mic_switch_off_timer:Kill()
			self.mic_switch_off_timer = nil
		end
		if not self.mic_switch_used then
			Sound.SetMicSwitchState(true)
			self.mic_switch_used = true
		end
	else
		if self.mic_switch_used and not self.mic_switch_off_timer then
			local switch_off_time = mic_switch_off_time_distribution()
			self.mic_switch_off_timer = Timer:new(switch_off_time, function()
				Sound.SetMicSwitchState(false)
				self.mic_switch_used = false
			end)
		end
	end
end

Voice:Seal()

return Voice
