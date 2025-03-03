
---// ReportWVRContacts.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

-- Report relevant WVR bandits, bogeys, friendlies and dying aircraft.

local Class = require('base.Class')
local Behavior = require('base.Behavior')
local Math = require('base.Math')
local Urge = require('base.Urge')
local Utilities = require('base.Utilities')
local StressReaction = require('base.StressReaction')
local SayTask = require('tasks.common.SayTask')
local SayTaskWithDelay = require ('tasks.common.SayTaskWithDelay')
local Labels = require 'base.Labels'
local Sentence = require 'voice.Sentence'
local Constants = require 'base.Constants'
local SaySentenceWithDelay = require 'tasks.common.SaySentenceWithDelay'

local ReportWVRContacts = Class(Behavior)

local unannounced_contacts = {}
local announcement_timer = s(0)
local announcement_frequency = s(7)
local time_since_spawn = s(0)
local reporting_spawn_deadzone = s(10) --Any contacts within this time will be marked as reported, but not actually reported vocally by JESTER.

local first_announcement_tick = true

function ReportWVRContacts:Constructor()
	Behavior.Constructor(self)
end


--Helper Functions --------------------------------------------
--Returns the matching contact in the provided table; if it exists.
function ReportWVRContacts:FindMatchingContact(awareness_contacts, contact)
	for _, v in pairs(awareness_contacts) do
		if (v.true_id or contact.true_id) and v.true_id == contact.true_id then
			return v
		end
	end
end


--Check if we're within our thresholds for azimuth and elevation between two contacts and ensure same coalition.
function ReportWVRContacts:AreContactsGroup(azimuth_threshold, elevation_threshold, contact1, contact2)

	if (contact1:Is(Labels.friendly) and contact2:Is(Labels.friendly))
			or (contact1:Is(Labels.hostile) and contact2:Is(Labels.hostile)) or
				(contact1:Is(Labels.neutral) and contact2:Is(Labels.neutral)) then

		local azimuth_delta = Math.Abs(Math.Wrap180(contact1.polar_body.azimuth:ConvertTo(deg) - contact2.polar_body.azimuth:ConvertTo(deg)))
		local elevation_delta = Math.Abs(contact1.polar_body.elevation:ConvertTo(deg) - contact2.polar_body.elevation:ConvertTo(deg))

		return azimuth_delta < azimuth_threshold and elevation_delta < elevation_threshold

	end

	return false

end


-- DEAD CONTACTS ANNOUNCER; including for friendlies - "Bandit is going down!" & "Friendly is going down!" - Always runs.
-----------------------------------------------------------
function ReportWVRContacts:AnnounceDeadAircraft(contacts)
	for _, contact in pairs(contacts) do
		if contact:Is(Labels.dead) and not contact.announced_dead and contact.polar_ned.length < NM(3) then

			if(contact:Is(Labels.hostile)) then

				if contact.polar_ned.length < NM(0.4) then
					local dual_sentence = { 'spotting/splash', 'contacts_iff/banditdown'}
					local task = SaySentenceWithDelay:new(dual_sentence, s(1))
					GetJester():AddTask(task)
				else
					local task = SayTaskWithDelay:new('contacts_iff/banditdown', s(2))
					GetJester():AddTask(task)
				end
			end

			if(contact:Is(Labels.friendly)) then
				local task = SayTaskWithDelay:new('contacts_iff/friendlydown', s(2))
				GetJester():AddTask(task)
			end

			contact.announced_dead = true
			GetJester().awareness:AddOrUpdateContact(contact)   --Force update of the sense per grover.

		end
	end
end


-- UNANNOUNCED GROUPING AND SORTING ------------------------------------
-- Group contacts into groups if azimuth and elevation are within thresholds.
-- Do not call every tick. We want to make sure close together contacts enter our awareness "bubble" before we start grouping them.
-- Returns Groups - a table of contacts grouped which we then use to call out contacts.
function ReportWVRContacts:SortAndGroupContacts(contacts)

	-- Clear the unannounced contacts table to refresh it from the Awareness contacts.
	unannounced_contacts = {}
	local debug_group_info = false

	-- Copy unannounced contacts from Awareness to local data
	for _, contact in pairs(contacts) do
		if not contact.announced then
			table.insert(unannounced_contacts, contact)
		else
			return { } --No unannounced contacts, return empty table.
		end
	end

	-- Group contacts based on azimuth and elevation thresholds.
	local azimuth_grouping_threshold = deg(30)
	local elevation_grouping_threshold = deg(30)
	local groups = {}   --Table to hold grouped contacts.
	local grouped = {}  --Grouped flags to avoid regrouping.

	for i, contact1 in ipairs(unannounced_contacts) do
		if not grouped[i] then
			local group = {contact1}
			grouped[i] = true

			for j, contact2 in ipairs(unannounced_contacts) do
				if i ~= j and self:AreContactsGroup(azimuth_grouping_threshold, elevation_grouping_threshold, contact1, contact2) then
					table.insert(group, contact2)
					grouped[j] = true
				end
			end
			table.insert(groups, group)
		end
	end

	--Debug Logging of grouped contacts.
	if debug_group_info then
		for i, group in ipairs(groups) do
			Log("Group " .. i .. ":")
			for _, contact in ipairs(group) do
				Log("Contact: " .. tostring(contact.type))
			end
		end
	end

	return groups
end


-- Gather the data required to construct as sentence from a contact - used in both group and single ship sentence construction.
function ReportWVRContacts:GetRelevantContactData(contact)

	if contact then

		local contact_callout_data = {}

		local debug_contact_announcement = false

		contact_callout_data.contact_oclock_phrase = Utilities.GetOClockPhrase(contact.polar_body, contact.polar_ned)
		contact_callout_data.contact_distance_phrase = Utilities.GetDistancePhrase(contact.polar_ned)
		contact_callout_data.ac_type_string = tostring(contact.type)

		--Check if the aircraft type has a phrase from our aircraft phrase list; if not, we will just announce it generically sans type.
		contact_callout_data.aircraft_type_has_phrase = false
		contact_callout_data.aircraft_type_voice_phrase = "none"

		local aircraft_type_phrase_data = Utilities.GetAircraftPhrase(contact_callout_data.ac_type_string) or false
		if aircraft_type_phrase_data then
			contact_callout_data.aircraft_type_has_phrase = true
			contact_callout_data.aircraft_type_voice_phrase = aircraft_type_phrase_data.phrase

			if(debug_contact_announcement) then
				Log("Aircraft Type has phrase data.")
				Log("Aircraft Type voice line: " .. contact_callout_data.aircraft_type_voice_phrase)
				Log("Aircraft Type article: " .. contact_callout_data.aircraft_type_phrase_data.thatsaoran)
			end
		end

		--Get the article from the phrase.
		contact_callout_data.article_phrase = "a"
		if contact_callout_data.aircraft_type_has_phrase then
			if aircraft_type_phrase_data.thatsaoran == "ThatsA" then
				contact_callout_data.article_phrase = "a"
			else
				contact_callout_data.article_phrase = "an"
			end
		end

		--Set Coalition phrase type.
		contact_callout_data.coalition_phrase = "contacts_iff/bogey"
		contact_callout_data.is_friendly = false
		contact_callout_data.is_hostile = false
		if contact:Is(Labels.friendly) then
			contact_callout_data.coalition_phrase = "contacts_iff/friendly"
			contact_callout_data.is_friendly = true
		elseif contact:Is(Labels.hostile) then
			contact_callout_data.coalition_phrase = "contacts_iff/bandit"
			contact_callout_data.is_hostile = true
		end

		return contact_callout_data

	end

	return false

end


-- Construct Sentence for a single ship bandit. Returns a table later unpacked in a Sentence argument list so JESTER says it.
function ReportWVRContacts:ConstructCalloutSentence(contact, anding, count)

	if contact then

		local debug_contact_announcement = false
		local contact_callout_data = self:GetRelevantContactData(contact) or false
		if not contact_callout_data then
			Log("Contact data is not valid. WVR callout will not be initiated.")
			return { "failed_sentence" }
		end

		local aircraft_type_has_phrase = contact_callout_data.aircraft_type_has_phrase
		local coalition_phrase = contact_callout_data.coalition_phrase
		local aircraft_type_voice_phrase = contact_callout_data.aircraft_type_voice_phrase
		local contact_oclock_phrase = contact_callout_data.contact_oclock_phrase
		local contact_distance_phrase = contact_callout_data.contact_distance_phrase

		--Lets deal with the initial phrase, starting with no AND-ing. Groups have coalition specific phrases due to legacy reasons.
		local initial_phrase = 'spotting/wehavea'           -- Single - coalition neutral base case.

		--So, non -anding case:
		if not anding then

			initial_phrase = 'spotting/wehavea'           -- Single - coalition neutral.

			--Group case, for legacy reasons voice lines include coalition.
			if count > 1 then

				initial_phrase = 'contacts_iff/therearebogs'        --Neutral

				if contact_callout_data.is_hostile then
					initial_phrase = 'contacts_iff/therearebans'    --Bandits
				end

				if contact_callout_data.is_friendly then
					initial_phrase = 'contacts_iff/therearefriends' --Friendlies.
				end
			end
		end

		--If second in a chain, we are AND-ing and need to select based on that.
		if anding then

			--Single AND case.
			initial_phrase = 'contacts_iff/andabog'

			if contact_callout_data.is_hostile then
				initial_phrase = 'contacts_iff/andaban'
			end
			if contact_callout_data.is_friendly then
				initial_phrase = 'contacts_iff/andafriend'
			end

			--Group AND case.
			if count > 1 then
				initial_phrase = 'contacts_iff/andsomebogs'
				if contact_callout_data.is_hostile then
					initial_phrase = 'contacts_iff/andsomebans'
				end
				if contact_callout_data.is_friendly then
					initial_phrase = 'contacts_iff/andsomefriends'
				end
			end
		end

		--Construct final sentence.
		local final_sentence = {}

		-- SINGLE SHIP SENTENCE CONSTRUCTION --------------------------------
		if count == 1 then

			if not anding then
				if aircraft_type_has_phrase then
					final_sentence = { initial_phrase,
					                   coalition_phrase,
					                   aircraft_type_voice_phrase,
					                   contact_oclock_phrase,
					                   contact_distance_phrase }
				else
					final_sentence = { initial_phrase,
					                   coalition_phrase,
					                   contact_oclock_phrase,
					                   contact_distance_phrase }
				end
			end

			if anding then
				if aircraft_type_has_phrase then
					final_sentence = { initial_phrase,
					                   aircraft_type_voice_phrase,
					                   contact_oclock_phrase,
					                   contact_distance_phrase }
				else
					final_sentence = { initial_phrase,
					                   contact_oclock_phrase,
					                   contact_distance_phrase }
				end
			end
		end

		-- GROUP SENTENCE CONSTRUCTION -------------------------------------
		if count > 1 then

			if not anding then
				final_sentence = { initial_phrase,
				                   contact_oclock_phrase,
				                   contact_distance_phrase }
			end

			if anding then
				final_sentence = { initial_phrase,
				                   contact_oclock_phrase,
				                   contact_distance_phrase }
			end
		end

		--Crash protection - all sentence elements must be strings.
		if Utilities.AreAllStrings(unpack(final_sentence)) then
			return final_sentence
		else
			Log("Callout Sentence was malformed! (not all strings.)")
			return { "failed_sentence" }
		end

	end

	return { "failed_sentence" } --If contact was not valid, etc.
end


-- Main Tick - Announce contacts every few seconds and announce dead contacts when close and noticed.
-----------------------------------------------------------
function ReportWVRContacts:Tick()

	local dt = Utilities.GetTime().dt
	time_since_spawn = time_since_spawn + dt

	--Inhibit these WVR callouts on ground.
	if GetJester().awareness:GetObservation("touching_ground") then
		return
	end

	--If we're close to an airfield; and not in danger, we don't do WVR reporting anymore, since we'll have traffic calls instead.
	local distance_to_nearest_airfield = GetJester().awareness.GetDistanceToClosestFriendlyOrNeutralAirfield()
	local in_danger = GetJester().awareness:GetInCombatOrDanger()
	if distance_to_nearest_airfield < NM(15) and not in_danger then
		return
	end

	local debug_final_announcement_sentences = false
	local jester = GetJester()
	local contacts = jester.awareness:GetAirborneAirplaneContacts()

	--[[
	if #contacts and contacts[1] then
		local contact_velocity = contacts[1].ned_velocity
		local contact_velocity_x = contacts[1].ned_velocity.x
		Log("Contact Dotproduct test: " .. tostring(contact_velocity_x))
	end --]]

	--No contacts, return early. Shit will crash otherwise yo.
	if not Utilities.HasElements(contacts) then
		return
	end

	--Announce dead. Always runs even when we're in a dogfight.
	self:AnnounceDeadAircraft(contacts)

	--If we're in a dogfight; don't do WVR advisories.
	local closest_enemy = jester.awareness:GetClosestAirThreat() or false
	if closest_enemy then
		if closest_enemy.polar_body.length:ConvertTo(NM) < Constants.dogfight_distance then
			return
		end
	end

	--ANNOUNCE CONTACTS:
	-- We only group and announce contacts every few seconds to make sure that aircraft can enter our bubble together as a group.
	local announce_on_this_tick = false
	announcement_timer = announcement_timer + Utilities.GetTime().dt
	if announcement_timer >= announcement_frequency then
		announcement_timer = s(0)
		announce_on_this_tick = true
	end

	--We're announcing on this tick - lets announce contacts:
	if announce_on_this_tick then

		--If we're within the spawn dead-zone, mark all contacts in this reporting tick as already reported.
		if time_since_spawn < reporting_spawn_deadzone then
			for _, contact in ipairs(contacts) do
				contact.announced = true
				contact.announced_timestamp = Utilities.GetTime().mission_time
				jester.awareness:AddOrUpdateContact(contact) --To force Touch().
			end
		end

		--First, grab unannounced contacts from Awareness, and sort them into groups. A group can have one contact in it or several.
		--TODO sort by range?
		local unannounced_groups = self:SortAndGroupContacts(contacts) or false

		--Construct sentences from unannounced groups and store them.
		local announcement_sentences = {}

		--Construct sentences.
		if Utilities.HasElements(unannounced_groups) then
			for count, group in ipairs(unannounced_groups) do

				--Limit to two announcements / sentences per announcement cycle.
				if count < 3 then

					--First group is not AND-ing, as it's first in line, so construct a first sentence sans anding.
					if count == 1 then

						local anding = false

						local sentence = self:ConstructCalloutSentence(group[1], anding, #group)
						table.insert(announcement_sentences, sentence)

					--Second group and onwards is AND-ing, so construct a sentence with anding accounted for.
					else
						local anding = true
						local sentence = self:ConstructCalloutSentence(group[1], anding, #group)
						table.insert(announcement_sentences, sentence)
					end

					--Mark as announced.
					for _, contact in ipairs(group) do
						contact.announced = true
						contact.announced_timestamp = Utilities.GetTime().mission_time
						jester.awareness:AddOrUpdateContact(contact) --To force Touch().
						Log("Announcing UID: " .. tostring(contact.true_id))
					end
				end
			end

			--Finally, say the sentences.
			local final_sentence_tbl = {}

			--More than just one contact or group? Append the two sentences together.
			if #announcement_sentences > 1 then

				final_sentence_tbl = announcement_sentences[1]
				Utilities.AppendTable(final_sentence_tbl, announcement_sentences[2])

				--Debug print the final announcement sentence
				if debug_final_announcement_sentences then
					Log("Final sentence table:")
					local test = {unpack(final_sentence_tbl)}
					for _, lines in ipairs(test) do
						Log("Lines: " .. lines)
					end
				end

			 --Just the one group to report.
			elseif #announcement_sentences == 1 then

				final_sentence_tbl = {unpack(announcement_sentences[1])}

				--Debug helper.
				if debug_final_announcement_sentences then
					Log("Final sentence table:")
					local test = {unpack(final_sentence_tbl)}
					for _, lines in ipairs(test) do
						Log("Lines: " .. lines)
					end
				end
			end

			--Feed sentence table to Jester.
			if Utilities.HasElements(final_sentence_tbl) then
				local say_task = SayTask:new(Sentence(unpack(final_sentence_tbl)))
				jester:AddTask(say_task)
			end

		end

		announce_on_this_tick = false

	end

end

ReportWVRContacts:Seal()
return ReportWVRContacts


--Code graveyard. ------------------------------------------------

--[[
--Don't call anything that is around on spawn.
if not first_tick_has_run and contacts then
	for _, contact in ipairs(contacts) do
		contact.announced = true
		contact.announced_dead = true
		GetJester().awareness:AddOrUpdateContact(contact)
	end
	first_tick_has_run = true
end --]]



