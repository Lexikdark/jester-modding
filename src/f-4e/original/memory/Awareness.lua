---// Awareness.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require 'base.Class'
local Labels = require 'base.Labels'
local Observation = require 'base.Observation'
local Utilities = require 'base.Utilities'
local Interactions = require 'base.Interactions'

local Awareness = Class()
local wvr_distance = NM(6)

local hard_landing_timeout_timer = s(0)
local HARD_LANDING_TIMEOUT_SECONDS = s(30)
local hard_landing_timeout = false
local time_since_repeated_hard_landing_event = s(1000)
local time_since_last_hard_landing = s(1000)
local buffered_airborne_state = false
local last_time_airborne = s(-500)
local last_time_on_ground = s(-500)

Awareness.is_in_danger_or_combat = false
Awareness.has_close_radar_bandit = false
Awareness.danger_or_combat_timer = s(30)
Awareness.DANGER_OR_COMBAT_EXPIRY_LENGTH = s(240)

Awareness.observations = {}
Awareness.contacts = {}

local function sort_contact_by_distance(a, b)
	if a.polar_ned and b.polar_ned then
		return a.polar_ned.length < b.polar_ned.length
	end
	return false
end


function Awareness:AddOrUpdateContact(contact)
	if contact == nil or false then
		return false -- Crash protection. When Contacts were malformed or empty. /Nick.
	end

	local most_compatible_existing_contact = self:GetMostCompatibleContact(contact)
	if most_compatible_existing_contact then
		most_compatible_existing_contact:UpdateFromContact(contact)
	else
		--Contact was not in awareness; but can be in memory. If not in memory, a new mem object will be created.
		if contact:Is(Labels.dead) then
			contact.announced_dead = true   --inhibit calling if a new contact pops in that is already dead this way.
		end
		table.insert(self.contacts, contact)
		contact:AssignOrCreateMemoryObjects()
	end
end


--This function detects high oleo rates and fires some events and timestamps for things like landing quality comments, etc.
function Awareness:DetectLandingQuality()

	if Utilities.GetTime().mission_time < s(10) then
		return --Because the suspension etc jumps on spawn.
	end

	--Here, we check whether the oleo rate has been high, indicating a hard landing.
	--If yes; we fire an event which we then use down the line in the landing comment behaviours.
	--If we have a repeated hard landing; we fire a different event to make Jester truly angry or comment on the bounce.
	local dt = Utilities.GetTime().dt

	local hard_landing_rate = 0.4   --Hard landing callouts above.
	local harsh_landing_rate = 0.3  --Inhibits nice landing call.
	local hard_landing_rate_front = 0.53   --Hard landing callouts above.
	local harsh_landing_rate_front = 0.3  --Inhibits nice landing call.

	--Hard landing check -> event. We time it out to avoid firing the hard landing event more than once per landing.
	local oleo_rate_front = self:GetObservation("front_oleo_rate") or false
	local oleo_rate_left = self:GetObservation("left_oleo_rate") or false
	local oleo_rate_right = self:GetObservation("right_oleo_rate") or false

	if oleo_rate_front and oleo_rate_left and oleo_rate_right then
		if oleo_rate_front > hard_landing_rate_front or oleo_rate_left > hard_landing_rate or oleo_rate_right > hard_landing_rate then

			if not hard_landing_timeout then
				--TODO: Only fire if on runway maybe? Otherwise something like "Holy shit!"
				Dispatch("hard_landing")
				GetJester().memory:SetLastHardLandingTimestamp(Utilities.GetTime().mission_time)
			end

			--We're close to the previous hard landing; so we know it's repeated - i.e. this is a bounced landing.
			if hard_landing_timeout then
				if time_since_last_hard_landing > s(2) and time_since_repeated_hard_landing_event > s(10) then  --Need to bounce for 2 seconds?
					Dispatch("repeated_hard_landing")
					time_since_repeated_hard_landing_event = s(0)
				end
			end

			--Timeout to truuu
			hard_landing_timeout = true
		end
	end

	if self:GetObservation("last_significant_oleo_rate_time") == nil then
		self:AddOrUpdateObservation("last_significant_oleo_rate_time", s(-1000))
	end

	--If an oleo rate is above some number, it's not a very smooth landing experience, lets timestamp it and we can use
	--it in our quality behaviour commentary.
	if oleo_rate_front and oleo_rate_left and oleo_rate_right then
		if oleo_rate_front > harsh_landing_rate_front or oleo_rate_left > harsh_landing_rate or oleo_rate_right > harsh_landing_rate then
			self:AddOrUpdateObservation("last_significant_oleo_rate_time", Utilities.GetTime().mission_time)
		end
	end

	--We have a hard landing timeout; to avoid triggering it several times on a bouncy landing.
	if hard_landing_timeout then
		hard_landing_timeout_timer = hard_landing_timeout_timer + dt
		if hard_landing_timeout_timer > HARD_LANDING_TIMEOUT_SECONDS then
			hard_landing_timeout_timer = s(0)
			hard_landing_timeout = false
		end
	end

	--Timestamps for various purposes.
	time_since_repeated_hard_landing_event = time_since_repeated_hard_landing_event + dt
	time_since_last_hard_landing = Utilities.GetTime().mission_time - GetJester().memory:GetLastHardLandingTimestamp()

	self:AddOrUpdateObservation("time_since_last_hard_landing", time_since_last_hard_landing)
	self:AddOrUpdateObservation("time_since_repeated_hard_landing_event", time_since_repeated_hard_landing_event)
end


local time_stamp_number_of_air_threats = s(0)
local number_of_air_threats = 0
function Awareness:GetNumberOfAirThreats()
	local time = Utilities.GetTime().mission_time
	if time > time_stamp_number_of_air_threats then
		time_stamp_number_of_air_threats = time
		local counter = 0
		for _, v in ipairs(self.contacts) do
			if v:CanBe(Labels.hostile) and v:CanBe(Labels.aircraft) and not v:Is(Labels.dead) then
				counter = counter + 1
			end
		end
		number_of_air_threats = counter
	end
	return number_of_air_threats
end


local time_stamp_air_threats = s(0)
local air_threats = {}
function Awareness:GetAirThreats()
	local time = Utilities.GetTime().mission_time
	if time > time_stamp_air_threats then
		time_stamp_air_threats = time
		air_threats = {}
		for _, v in ipairs(self.contacts) do
			if v:CanBe(Labels.hostile) and v:CanBe(Labels.aircraft) and not v:Is(Labels.dead) and v:Is(Labels.airborne)then
				table.insert(air_threats, v)
			end
		end
	end
	return air_threats
end


function Awareness:GetClosestAirThreat()
	local all_threats = self:GetAirThreats()
	if #all_threats > 0 then
		return all_threats[1]
	end
	return nil
end


--Sort all contacts; so its just done once, and doesn't have to be done in other functions to e.g. get closest air threat..
function Awareness:SortContacts()
	table.sort(self.contacts, sort_contact_by_distance)
end

function Awareness:GetContacts()
	return self.contacts
end

function Awareness:GetAirplaneContacts()
	local contacts = {}
	for _, v in ipairs(self.contacts) do
		if v:CanBe(Labels.aircraft) then
			table.insert(contacts, v)
		end
	end
	return contacts
end

function Awareness:GetAirborneAirplaneContacts()
	local contacts = {}
	for _, v in ipairs(self.contacts) do
		if v:CanBe(Labels.aircraft) and v:Is(Labels.airborne) then
			table.insert(contacts, v)
		end
	end
	return contacts
end

local time_stamp_number_of_wvr_air_threats = s(0)
local number_of_wvr_air_threats = 0
function Awareness:GetNumberOfWVRAirThreats()
	local time = Utilities.GetTime().mission_time
	if time > time_stamp_number_of_wvr_air_threats then
		time_stamp_number_of_wvr_air_threats = time
		local counter = 0
		for _, v in ipairs(self.contacts) do
			if v:CanBe(Labels.hostile) and not v:Is(Labels.dead) and v:CanBe(Labels.aircraft) and v.polar_ned and v.polar_ned.length < wvr_distance then
				counter = counter + 1
			end
		end
		number_of_wvr_air_threats = counter
	end
	return number_of_wvr_air_threats
end

local time_stamp_wvr_air_threats = s(0)
local wvr_air_threats = 0
function Awareness:GetWVRAirThreats()
	local time = Utilities.GetTime().mission_time
	if time > time_stamp_wvr_air_threats then
		time_stamp_wvr_air_threats = time
		wvr_air_threats = {}
		for _, v in ipairs(self.contacts) do
			if v:CanBe(Labels.hostile) and not v:Is(Labels.dead) and v:CanBe(Labels.aircraft) and v.polar_ned and v.polar_ned.length < wvr_distance then
				table.insert(wvr_air_threats, v)
			end
		end
	end
	return wvr_air_threats
end

function Awareness:GetNumberOfBVRAirThreats()
	return 0
end

function Awareness:GetNumberOfMissileThreats()
	return 0
end

function Awareness:GetNumberOfSAMThreats()
	return 0
end

function Awareness:GetNumberOfNavalThreats()
	return 0
end

function Awareness:GetNumberOfAAAThreats()
	return 0
end

function Awareness:GetCloseSinger() -- is there active SINGER (Radar warning receiver indication of SAM launch) in close proximity
    if not rwr_contacts then
        return false
    end

    for index, contact in ipairs(rwr_contacts) do
        if contact.activity == "launch" and contact.range < 0.5 then
            return true
        end
    end

	return false
end

function Awareness:GetCloseMissile() -- is there any missile (not necessarily a threat) in close proximity
    for _, contact in ipairs(self:GetContacts()) do
        if contact:Is(Labels.missile) then
            local distance = contact.polar_body.length
            if (distance < NM(5)) then
                return true
            end
        end
    end

	return false
end

local time_stamp_number_of_hostile_aircraft = s(0)
local number_of_hostile_aircraft = 0
function Awareness:GetNumberOfHostileAircraft()
	local time = Utilities.GetTime().mission_time
	if time > time_stamp_number_of_hostile_aircraft then
		time_stamp_number_of_hostile_aircraft = time
		local counter = 0
		for _, v in ipairs(self.contacts) do
			if v:CanBe(Labels.hostile) and v:CanBe(Labels.aircraft) and not v:Is(Labels.dead) then
				counter = counter + 1
			end
		end
		number_of_hostile_aircraft = counter
	end
	return number_of_hostile_aircraft
end

local time_stamp_hostile_aircraft = s(0)
local hostile_aircraft = {}
function Awareness:GetHostileAircraft()
	local time = Utilities.GetTime().mission_time
	if time > time_stamp_hostile_aircraft then
		time_stamp_hostile_aircraft = time
		hostile_aircraft = {}
		for _, v in ipairs(self.contacts) do
			if v:CanBe(Labels.hostile) and v:CanBe(Labels.aircraft) and not v:Is(Labels.dead) then
				table.insert(hostile_aircraft, v)
			end
		end
	end
	return hostile_aircraft
end


function Awareness:GetClosestHostileAircraft()
	local all_aircraft = self:GetHostileAircraft()
	if #all_aircraft > 0 then
		return all_aircraft[1]
	end
	return nil
end


local time_stamp_friendly_tankers = s(0)
local friendly_tankers = {}
function Awareness:GetFriendlyTankers()
	local time = Utilities.GetTime().mission_time
	if time > time_stamp_friendly_tankers then
		time_stamp_friendly_tankers = time
		friendly_tankers = {}
		for _, v in ipairs(self.contacts) do
			if v:CanBe(Labels.friendly) and v:CanBe(Labels.aircraft) and v:CanBe(Labels.tanker) and not v:Is(Labels.dead) then
				table.insert(friendly_tankers, v)
			end
		end
	end
	return friendly_tankers
end


function Awareness:GetClosestFriendlyTanker()
	local tankers = self:GetFriendlyTankers()
	if #tankers > 0 then
		return tankers[1]
	end
	return nil
end

function Awareness:GetDistanceToClosestAirfield()
	local airfields = nearby_airfields or {}
	if #airfields > 0 then
		local nearest_airfield = airfields[1]
		return nearest_airfield.position:ConvertToPolar().length:ConvertTo(NM)
	end
	return NM(1000) --Its just super far away.
end

function Awareness:GetDistanceToClosestFriendlyAirfield()
	local list = nearby_airfields or {}
	if #list > 0 then
		for _, airfield in ipairs(list) do
			if not airfield.friendly then
				return airfield.position:ConvertToPolar().length:ConvertTo(NM)
			end
		end
	end
	return NM(1000) --Its just super far away.
end

function Awareness:GetDistanceToClosestFriendlyOrNeutralAirfield()
	local list = nearby_airfields or {}
	if #list > 0 then
		for _, airfield in ipairs(list) do
			if not airfield.hostile then
				return airfield.position:ConvertToPolar().length:ConvertTo(NM)
			end
		end
	end
	return NM(1000) --Its just super far away.
end


local time_stamp_friendly_aircraft = s(0)
local friendly_aircraft = {}
function Awareness:GetFriendlyAircraft()
	local time = Utilities.GetTime().mission_time
	if time > time_stamp_friendly_aircraft then
		time_stamp_friendly_aircraft = time
		friendly_aircraft = {}
		for _, v in ipairs(self.contacts) do
			if v:CanBe(Labels.friendly) and v:CanBe(Labels.aircraft) and not v:Is(Labels.dead) then
				table.insert(friendly_aircraft, v)
			end
		end
	end
	return friendly_aircraft
end

function Awareness:GetClosestFriendlyAircraft()
	local closest_friendly_ac = self:GetFriendlyAircraft()
	if #closest_friendly_ac > 0 then
		return closest_friendly_ac[1]
	end
end


function Awareness:GetNumberOfBogeyAircraft()
	return 0
end

function Awareness:GetNumberOfFriendlyAircraft()
	return 0
end


function Awareness:GetMostCompatibleContact(contact)

	if contact == nil or false then
		return false -- Crash protection. When Contacts were malformed or empty. /Nick.
	end

	for _, v in pairs(self.contacts) do
		if (v.true_id or contact.true_id) and v.true_id == contact.true_id then
			return v
		end
	end
end

function Awareness:AddOrUpdateObservation(name, observation_data)
	if self.observations[name] then
		self.observations[name]:Update(observation_data)
	else
		self.observations[name] = Observation:new(observation_data)
	end
end

function Awareness:GetObservation(name)
	local observation = self.observations[name]
	if observation then
		return observation:GetValue()
	end
end

function Awareness:IsObservationValid(name)
	local observation = self.observations[name]
	if observation then
		return observation:IsValid()
	end
end


--Main Function to make JESTER aware we are in a dangerous situation, combat, or otherwise a situation which would
--Basically make JESTER go to HI mode.
function Awareness:UpdateIsInCombatOrDangerState()

	--if conditions are true; set Jester to be in danger.
	--If we're outside of combat conditions, tick down the timer. If it expires, we're no longer in danger.

	local in_danger = false

	--TRUE Conditions -----------------------------------------
	local closest_enemy_ac = self:GetClosestAirThreat()
	if closest_enemy_ac then
		if closest_enemy_ac.polar_ned.length:ConvertTo(NM) < NM(20) then
			in_danger = true
		end
	end

    if self:GetCloseSinger() then
        in_danger = true
    end

    if self:GetCloseMissile() then
        in_danger = true
    end

	if self.has_close_radar_bandit then
		in_danger = true
	end

	--FALSE Conditions -----------------------------------------
	if not self:GetObservation("airborne") then
		in_danger = false
	end

	--If we're in danger or combat, set the timer.
	--If not; tick it down, once expired; we're no longer in danger.
	if in_danger then
		self.is_in_danger_or_combat = true
		self.danger_or_combat_timer = DANGER_OR_COMBAT_EXPIRY_LENGTH
	else
		self.danger_or_combat_timer = self.danger_or_combat_timer - Utilities.GetTime().dt
		if self.danger_or_combat_timer < s(0) then
			self.is_in_danger_or_combat = false
		end
	end

	-- TODO Conditions:
	-- If we're near hostile aircraft.
	-- If we're damaged (though with expiry, so we're not HI 10 minutes after damage.)
	-- Probably something mission related, e.g. getting close to IP and danger area in mission.
	-- RWR stuff; Spike, missiles, etc.

	-- Deactivate if we're on the ground.
	-- Other stuff?
end

function Awareness:GetInCombatOrDanger()
	return self.is_in_danger_or_combat
end

local function RemoveOldContacts(self)
	local current_time = Utilities.GetTime().mission_time
	local remove_older_than_time_stamp = current_time - s(7)
	Utilities.ArrayRemove(self.contacts, function(t, i, _) return t[i].last_seen_time_stamp > remove_older_than_time_stamp end)
end

local function TickObservations(self)
	for _, observation in pairs(self.observations) do
		observation:Tick()
	end
end

function Awareness:Tick()

	RemoveOldContacts(self)

	self:DetectLandingQuality()
	self:UpdateIsInCombatOrDangerState()

	--if type(jit) == 'table' then
		--Log(tostring(jit.version))
	--end

	TickObservations(self)

	self:SortContacts()

end

Awareness:Seal()

return Awareness
