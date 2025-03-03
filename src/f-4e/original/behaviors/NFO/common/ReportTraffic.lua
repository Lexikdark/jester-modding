
---// ReportTraffic.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.


local Class = require('base.Class')
local Behavior = require('base.Behavior')
local Utilities = require('base.Utilities')
local Math = require('base.Math')
local Labels = require('base.Labels')
local SayTask = require('tasks.common.SayTask')
local Sentence = require 'voice.Sentence'

local ReportTraffic = Class(Behavior)

local unannounced_traffic_contacts = {}
local announcement_interval = s(15)
local traffic_timer = s(0)

function ReportTraffic:Constructor()
	Behavior.Constructor(self)
end


--Check if we're within our thresholds for azimuth and elevation between two contacts, as well as separation for traffic.
function ReportTraffic:AreContactsGroup(azimuth_threshold, elevation_threshold, contact1, contact2)

	local azimuth_delta = Math.Abs(Math.Wrap180(contact1.polar_body.azimuth:ConvertTo(deg) - contact2.polar_body.azimuth:ConvertTo(deg)))
	local elevation_delta = Math.Abs(contact1.polar_body.elevation:ConvertTo(deg) - contact2.polar_body.elevation:ConvertTo(deg))
	local separation = Math.Abs(contact1.polar_ned.length:ConvertTo(ft) - contact2.polar_ned.length:ConvertTo(ft))

	return azimuth_delta < azimuth_threshold and elevation_delta < elevation_threshold --and separation < ft(10000)

end


--Group contacts based on azimuth and elevation thresholds.
function ReportTraffic:SortAndGroupContacts(contacts)

	-- Clear the unannounced contacts table to refresh it from the Awareness contacts.
	local debug_group_info = true

	-- Group contacts based on azimuth and elevation thresholds.
	local azimuth_grouping_threshold = deg(25)
	local elevation_grouping_threshold = deg(90)
	local groups = {}   --Table to hold grouped contacts.
	local grouped = {}  --Grouped flags to avoid regrouping.

	--Group based on azimuth and elevation thresholds.
	for i, contact1 in ipairs(contacts) do
		if not grouped[i] then
			local group = {contact1}
			grouped[i] = true

			for j, contact2 in ipairs(contacts) do
				if i ~= j and self:AreContactsGroup(azimuth_grouping_threshold, elevation_grouping_threshold, contact1, contact2) then
					table.insert(group, contact2)
					grouped[j] = true
				end
			end
			table.insert(groups, group)
		end
	end

	--Sort groups by distance
	if #groups > 1 then
		table.sort(groups, function(a, b)
			return a[1].polar_ned.length < b[1].polar_ned.length
		end)
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

function ReportTraffic:Tick()

	--First of all; do nothing if we just took off.
	local time_since_on_ground = GetJester().memory:GetTimeSinceOnGround()
	if time_since_on_ground < s(30) then
		return
	end

	--Secondly; lets check our main criteria: Speed, Distance to airfield and below 10k ft.
	local ias = GetJester().awareness:GetObservation("indicated_airspeed")
	local altitude = GetJester().awareness:GetObservation("height_above_airfield"):ConvertTo(ft)
	local distance_to_airport = GetJester().awareness.GetDistanceToClosestFriendlyAirfield()

	if ias > kt(500) or altitude > ft(10000) or distance_to_airport > NM(15) or altitude < ft(200) then
		return
	end

	--And finally, if we're in any sort of danger, we also don't report traffic.
	if GetJester().awareness:GetInCombatOrDanger() then
		return
	end

	--Criteria are OK, let's report some traffic jim.

	--Once our interval fires; collect our friendly aircraft, sort and group them, and announce traffic.
	local announce_on_this_tick = false
	traffic_timer = traffic_timer + Utilities.GetTime().dt
	if traffic_timer >= announcement_interval then
		traffic_timer = s(0)
		announce_on_this_tick = true
	end

	if announce_on_this_tick then

		local friendly_contacts = GetJester().awareness:GetFriendlyAircraft()
		local unannounced_traffic_contacts = {}

		--Crashfix; if we have no friendly contacts, return early.
		if #friendly_contacts < 1 then
			return
		end

		--Get unannounced traffic contacts and filter for airborne ones only. TODO: Exclude texaco.
		for _, contact in ipairs(friendly_contacts) do
			if contact:Is(Labels.airborne) and not contact.announced_traffic and contact.polar_ned.length > ft(3000) then
				table.insert(unannounced_traffic_contacts, contact)
			end
		end

		local grouped_traffic = self:SortAndGroupContacts(unannounced_traffic_contacts)
		if #grouped_traffic < 1 then
			return
		end

		--Construct sentences for the two closest traffic groups and add them to our final sentence tbl.
		local final_sentence = {}
		local groups_announced = 0
		for i, group in pairs(grouped_traffic) do

			if i == 1 then
				local traffic_phrase = 'phrases/' .. 'traffic' .. Utilities.AngleToOClock(Math.Wrap360(group[1].polar_body.azimuth))
						.. 'oclock'

				table.insert(final_sentence, traffic_phrase)
				group.mark_as_announced = true
				groups_announced = groups_announced + 1

				Log("calling first traffic sentence.")
			end

			--Second sentence is "..and traffic at X"
			--Inhibit it if the direction is the same to avoid dumb sounding doubled call. I.e. "Traffic at 12 oclock and traffic at 12 oclock".
			if i > 1 then

				--Check if angle call is the same, and if so, don't do anything this iteration.
				local first_angle_to_oclock = Utilities.AngleToOClock(Math.Wrap360(grouped_traffic[1][1].polar_body.azimuth))
				local current_angle_oclock = Utilities.AngleToOClock(Math.Wrap360(group[1].polar_body.azimuth))

				if first_angle_to_oclock ~= current_angle_oclock then
					local traffic_phrase = 'phrases/' .. 'andtraffic' .. Utilities.AngleToOClock(Math.Wrap360(group[1].polar_body.azimuth))
							.. 'oclock'

					Log("calling... and traffic")
					group.mark_as_announced = true
					table.insert(final_sentence, traffic_phrase)
					groups_announced = groups_announced + 1
				end
			end

			--Only call two traffic groups/contacts max.
			if groups_announced == 2 then
				break
			end
		end

		--Call the traffic sentence.
		if #final_sentence > 0 then
			local traffic_call = SayTask:new(Sentence(unpack(final_sentence)))
			GetJester():AddTask(traffic_call)
		end

		--Mark contacts in announced groups as announced.
		for _, group in pairs(grouped_traffic) do
			if group.mark_as_announced then
				for _, contact in ipairs(group) do
					contact.announced_traffic = true
					contact.announced = true
					jester.awareness:AddOrUpdateContact(contact) --To force Touch().
				end
			end
		end

	end
end

ReportTraffic:Seal()
return ReportTraffic
