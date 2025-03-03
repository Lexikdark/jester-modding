
---// ReportClosestWVRThreat.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require('base.Class')
local Behavior = require('base.Behavior')
local Math = require('base.Math')
local SayContactOClock = require('tasks.WVR.SayContactOClock')
local Urge = require('base.Urge')
local Utilities = require('base.Utilities')
local StressReaction = require('base.StressReaction')
local Sentence = require 'voice.Sentence'
local SayTask = require('tasks.common.SayTask')
local Constants = require 'base.Constants'
local Labels = require 'base.Labels'

local DogfightAdvisory = Class(Behavior)

DogfightAdvisory.last_contact_polar_body = nil

local default_report_threat_interval = s(8)
local encouraging_phrase_interval = s(15)
local under_threat_phrase_interval = s(6)

local contacts_to_announce = {}

DogfightAdvisory.advisory_speak_function = nil

local analysis_interval_timer = s(0)
local analysis_interval = s(2)
local report_interval_timer = s(0)
local altitude_call_timeout = s(5)
local last_said_altitude = ft(0)

local allow_altitude_callout = true

local has_said_15000ft = false
local has_said_10000ft = false
local has_said_5000ft = false
local has_said_3000ft = false
local has_said_1000ft = false
local has_said_500ft = false
local has_said_200ft = false
local has_said_watch_the_deck = false

local previously_announced_phrase = ''

--Normal is just the standard call, under threat is when someone's on our six
--Bandit on nose is when we're on the bandit's six.
local dogfight_reporting_modes =
{
	NORMAL = 1,
	UNDER_THREAT = 2,
	BANDIT_ON_NOSE = 3
}

local dogfight_mode = dogfight_reporting_modes.NORMAL
local prev_dogfight_mode = dogfight_reporting_modes.NORMAL --Buffered state.

function DogfightAdvisory:Constructor()
	Behavior.Constructor(self)
end


--Standard callout; not on the ass of another bandit nor one on our ass.
--I.e., "We've got one at 2 oclock and the other's at 5 oclock high."
--~every 5 seconds; or if the threat has moved significantly. -----------------------------------------------------------
function DogfightAdvisory:SayStandardAdvisory(contacts_to_announce)

	allow_altitude_callout = true

	--Sentence: He's at our 2 o'clock (closest) and if n > 1 "and the other ones' at 5 o'clock high."
	local jester = GetJester()

	--Single threat, single sentence.
	if #contacts_to_announce == 1 then
		local hi_or_lo = ''
		if contacts_to_announce[1].polar_body.elevation > deg(25) and contacts_to_announce[1].polar_ned.elevation > deg(25) then
			hi_or_lo = 'high'
		elseif contacts_to_announce[1].polar_body.elevation < deg(-25) and contacts_to_announce[1].polar_ned.elevation < deg(-25) then
			hi_or_lo = 'low'
		end

		local single_phrase = 'spotting/bfm' .. Utilities.AngleToOClock(Math.Wrap360(contacts_to_announce[1].polar_body.azimuth)) .. 'oclock' .. hi_or_lo
		if single_phrase == previously_announced_phrase then
			return
		end

		--If the new phrase is the same as the previous one; then don't say it at all.
		if single_phrase ~= previously_announced_phrase then
			local say_task = SayTask:new(single_phrase)
			jester:AddTask(say_task)
		end

		--Set announced to true as if it's been visible in dogfight.. well.. it's been visible.
		contacts_to_announce[1].announced = true
		contacts_to_announce[1].announced_timestamp = Utilities.GetTime().mission_time
		jester.awareness:AddOrUpdateContact(contacts_to_announce[1])

		Log("Dogfight: Reporting single bandit!")
		Log(tostring(single_phrase))
	end

	--Two close bandits; we call both.
	if #contacts_to_announce > 1 then

		local closest_hi_or_lo = ''
		if contacts_to_announce[1].polar_body.elevation > deg(25) and contacts_to_announce[1].polar_ned.elevation > deg(25) then
			closest_hi_or_lo = 'high'
		elseif contacts_to_announce[1].polar_body.elevation < deg(-25) and contacts_to_announce[1].polar_ned.elevation < deg(-25) then
			closest_hi_or_lo = 'low'
		end

		local second_hi_or_lo = ''
		if contacts_to_announce[2].polar_body.elevation > deg(25) and contacts_to_announce[2].polar_ned.elevation > deg(25) then
			second_hi_or_lo = 'high'
		elseif contacts_to_announce[2].polar_body.elevation < deg(-25) and contacts_to_announce[2].polar_ned.elevation < deg(-25) then
			second_hi_or_lo = 'low'
		end

		local first_phrase = 'spotting/bfm' .. Utilities.AngleToOClock(Math.Wrap360(contacts_to_announce[1].polar_body.azimuth)) .. 'oclock' .. closest_hi_or_lo
		local second_phrase = 'spotting/bfmand' .. Utilities.AngleToOClock(Math.Wrap360(contacts_to_announce[2].polar_body.azimuth)) .. 'oclock' .. second_hi_or_lo
		local say_task = SayTask:new(Sentence(first_phrase, second_phrase))
		jester:AddTask(say_task)
		Log("Dogfight: Reporting two bandits!")
		Log(tostring(first_phrase))
		Log(tostring(second_phrase))

		--Set as announced..
		contacts_to_announce[1].announced = true
		contacts_to_announce[2].announced = true

		contacts_to_announce[1].announced_timestamp = Utilities.GetTime().mission_time
		contacts_to_announce[2].announced_timestamp = Utilities.GetTime().mission_time
		jester.awareness:AddOrUpdateContact(contacts_to_announce[1])
		jester.awareness:AddOrUpdateContact(contacts_to_announce[2])--To force Touch().

	end
end

-- Encouraging Advisory -----------------------------------------------------------
-- i.e.; "Get him!" "Blast that sucker!"
-- Say it only ONCE per changing into this phase or simply rarely.
function DogfightAdvisory:SayEncouragingPhrase(contacts_to_announce)

	if not contacts_to_announce or #contacts_to_announce < 1 then
		return
	end

	local jester = GetJester()

	local phrase = 'spotting/wereonhissix'
	local say_task = SayTask:new(phrase)
	jester:AddTask(say_task)

	allow_altitude_callout = true

	--Set announced to true.
	contacts_to_announce[1].announced = true
	contacts_to_announce[1].announced_timestamp = Utilities.GetTime().mission_time
	jester.awareness:AddOrUpdateContact(contacts_to_announce[1])
end


--I.e. "he's on our six!" "closing" "coming right" "coming left"
function DogfightAdvisory:SayOnOurSix(contacts_to_announce)

	if not contacts_to_announce or #contacts_to_announce < 1 then
		return
	end

	local jester = GetJester()

	local phrase = 'spotting/hesonoursix'
	local say_task = SayTask:new(phrase)
	jester:AddTask(say_task)
	allow_altitude_callout = false
	Log("Dogfight: On our six!")

	--Set announced to true.
	contacts_to_announce[1].announced = true
	contacts_to_announce[1].announced_timestamp = Utilities.GetTime().mission_time
	jester.awareness:AddOrUpdateContact(contacts_to_announce[1])

end


-- Analyze Situation -- Are we under threat, or is it just a normal DF, or are we on someone's ass exclusively?
-- We return the contacts to report based on this and set the current dogfight mode.
-----------------------------------------------------------
function DogfightAdvisory:AnalyzeSituationAndGetContactsToAnnounce()

	--Iterate over the air threats within dogfight range; and decide which mode we're in.
	--Then return those contacts based on what the situation actually is; and feed them to the advisory functions.

	local jester = GetJester()
	local threats = jester.awareness:GetAirThreats() or false

	local something_on_six = false  --If we have a bandit pretty close on our ass and closing/facing us and JESTER sees him.
	local standard_threat = false   --Just a standard dogfight threat, i.e. not on our ass.
	local on_someones_six = false   --If we're on the ass of a bandit..

	if not threats or #threats < 1 then
		return                      --No threat or table nil/empty. Return early.
	end

	local threats_on_ass = {}
	local normal_threats = {}
	local threats_in_front = {}

	local big_plane_threat_limit = m(25) --Big planes should not constitute a threat when on our ass.

	for _, threat in ipairs (threats) do
		if threat.polar_ned.length:ConvertTo(NM) < Constants.dogfight_distance then

			--If it's an older contact, we don't have up-to-date location info on it so we can't call it.
			if Utilities.GetTime().mission_time - threat.last_seen_time_stamp > s(2) then
				return
			end

			local threat_azimuth = threat.polar_body.azimuth:ConvertTo(deg)
			local threat_elevation = threat.polar_body.elevation:ConvertTo(deg)
			local threat_velocity = threat.velocity_ned

			--We check the dotproduct of the vector between us and the threat. If they are quite similar; that means the threat is facing us.
			local threat_position_normalized = threat.position_ned:GetNormalized()
			local threat_vel_normalized = threat_velocity:GetNormalized()
			local dotproduct = threat_position_normalized:DotProduct(threat_vel_normalized)

			--The threat is on our ass and facing us.
			if Math.Abs(threat_azimuth) > deg(140) and threat_elevation < deg(40) and threat.size < big_plane_threat_limit and dotproduct.value < -0.75 then
				if not threat:Is(Labels.Tanker) then --less than 25m to avoid IL-76 being a threat.
					table.insert(threats_on_ass, threat)
					something_on_six = true
				end

			--The threat is on our nose, i.e. we're on his ass or it's head on. (TODO actually check head-on here.)
			elseif Math.Abs(threat_azimuth) < deg(20) and Math.Abs(threat_elevation) < deg(30) then
				on_someones_six = true  --TODO headon.
				table.insert(threats_in_front, threat)

			else
				--The threat is in a normal dogfight orientation or is big and lumbering even if on our ass.
				table.insert(normal_threats, threat)
				standard_threat = true
			end
		end
	end

	--Ultimately; we simply return a table of contacts to report and set the right mode.
	if #threats_on_ass > 0 then
		dogfight_mode = dogfight_reporting_modes.UNDER_THREAT
		return threats_on_ass

	elseif #normal_threats > 0 then
		dogfight_mode = dogfight_reporting_modes.NORMAL
		Utilities.AppendTable(normal_threats, threats_in_front) --Append frontal targets to call out both.
		return normal_threats

	elseif #threats_in_front then
		dogfight_mode = dogfight_reporting_modes.BANDIT_ON_NOSE
		return threats_in_front
	end
end

-- Main Tick function.
function DogfightAdvisory:Tick()

	local jester = GetJester()
	local altitude = jester.awareness:GetObservation("barometric_altitude")

	--Analyze the situation at an interval for performance. Should always run quicker than any reporting interval!
	analysis_interval_timer = analysis_interval_timer + Utilities.GetTime().dt
	if analysis_interval_timer >= analysis_interval then
		contacts_to_announce = {} --Remove gunk just in case.
		contacts_to_announce = self:AnalyzeSituationAndGetContactsToAnnounce() or false
		analysis_interval_timer = s(0)
	end

	if not contacts_to_announce or #contacts_to_announce < 1 then
		return
	end

	--Set the right reporting interval based on which DF mode we're in..
	local active_interval_level = s(0)
	if dogfight_mode == dogfight_reporting_modes.NORMAL then
		active_interval_level = default_report_threat_interval
	elseif dogfight_mode == dogfight_reporting_modes.BANDIT_ON_NOSE then
		active_interval_level = encouraging_phrase_interval
	elseif dogfight_mode == dogfight_reporting_modes.UNDER_THREAT then
		active_interval_level = under_threat_phrase_interval
	end

	--If the interval has not passed; return early, otherwise we continue on, set the right function, and make jester speak.
	report_interval_timer = report_interval_timer + Utilities.GetTime().dt
	if report_interval_timer < active_interval_level then
		return;
	end
	report_interval_timer = s(0)

	--Set the appropriate advisory function depending on which mode we're in.
	self.advisory_speak_function = function()
		if dogfight_mode == dogfight_reporting_modes.NORMAL then
			self:SayStandardAdvisory(contacts_to_announce)
		elseif dogfight_mode == dogfight_reporting_modes.BANDIT_ON_NOSE then
			self:SayEncouragingPhrase(contacts_to_announce)
		elseif dogfight_mode == dogfight_reporting_modes.UNDER_THREAT then
			self:SayOnOurSix(contacts_to_announce)
		end
	end

	--Make Jesterboi speak and set the contacts spoken to announced.
	self:advisory_speak_function()

	--TODO Here: altitude advisories.

	--[[
	if Math.IsWithin(altitude, ft(15050), ft(14950)) and not has_said_15000ft then
		local phrase = 'spotting/15000ft'
		local say_task = SayTask:new(phrase)
		jester:AddTask(say_task)
		has_said_15000ft = true
	end --]]

end

DogfightAdvisory:Seal()
return DogfightAdvisory
