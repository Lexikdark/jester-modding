---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require('base.Class')
local Behavior = require('base.Behavior')
local Urge = require('base.Urge')
local StressReaction = require('base.StressReaction')
local Math = require('base.Math')
local Utilities = require 'base.Utilities'
local SayTask = require('tasks.common.SayTask')
local Interactions = require('base.Interactions')
local SayAarDrifting = require('tasks.aar.SayAarDrifting')
local SayAarSteering = require('tasks.aar.SayAarSteering')

local fuel_system = '/Fuel System'
local refuel_pos_kc_135 = Vector(coords.Body, 22, 0, -9, m) -- hardcoded for KC-135, eyeballed and fine-tuned from tracks
local refueling_green_zone = ft(6) -- see https://i.imgur.com/a5PGZsZ.png, tweaked a bit for DCS
local refueling_green_zone_good = ft(3)
local connected_cues_after = s(5)

local AssistAAR = Class(Behavior)
AssistAAR.has_called_disconnected = false
AssistAAR.has_called_connected = false
AssistAAR.has_called_falling_off = false
AssistAAR.has_called_charging_boom = false
AssistAAR.has_called_ready_pre_contact = false
AssistAAR.previous_connected_pos_error = nil
AssistAAR.previous_not_connected_pos_error = nil
AssistAAR.connected_timer = s(0)

local IsReadyLight = function()
	return GetProperty(fuel_system, 'Air-Refuel Ready/Waiting').value or false
end

local IsDisconnected = function()
	return GetProperty(fuel_system, 'Air-Refuel Requires Reset').value or false
end

local IsConnected = function()
	local ready_light = GetProperty(fuel_system, 'Air-Refuel Ready/Waiting').value
	if ready_light == nil then
		ready_light = true
	end
	local disconnect_light = GetProperty(fuel_system, 'Air-Refuel Requires Reset').value or false

	return not ready_light and not disconnect_light
end

local GetRefuelPosError = function()
	local tanker = GetJester().awareness:GetClosestFriendlyTanker()
	if tanker == nil then
		return nil
	end
	if tanker.type ~= 'KC-135' and tanker.type ~= 'KC135MPRS' then
		-- If another boom-tanker is added, adjust this condition and figure out the correct refuel_pos (see 'refuel_pos_kc_135')
		return nil
	end
	return tanker.position_body - refuel_pos_kc_135
end

local IsTooCloseToTanker = function(refuel_pos_error)
	local x = refuel_pos_error.x -- Forward/Aft
	local z = refuel_pos_error.z -- Down/Up
	local absX = Math.Abs(x)
	local absZ = Math.Abs(z)

	-- Choose biggest steering axis (ignoring Left/Right)
	if absX > absZ then
		-- Forward: too close, Aft: falling off
		return x < ft(0)
	else
		-- Up: too close, Down: falling off
		return z > ft(0)
	end
end

function AssistAAR:SteerNotConnected()
	local pos_error = GetRefuelPosError()
	if pos_error == nil or pos_error:GetLength() > ft(25) or IsConnected() then
		-- Either still too far away or already connected
		return
	end

	local task = SayAarSteering:new(pos_error, self.previous_not_connected_pos_error)
	GetJester():AddTask(task)

	self.previous_not_connected_pos_error = pos_error
	return { task }
end

function AssistAAR:SteerConnected()
	if not IsConnected() or self.connected_timer < connected_cues_after then
		self.previous_connected_pos_error = nil
		return
	end

	local pos_error = GetRefuelPosError()
	local task = SayAarDrifting:new(pos_error, self.previous_connected_pos_error)
	GetJester():AddTask(task)

	self.previous_connected_pos_error = pos_error
	return { task }
end

function AssistAAR:CommentEvents()
	local pos_error = GetRefuelPosError()

	local tasks = {}

	-- Callout Disconnected
	local is_disconnected = IsDisconnected()
	if is_disconnected and not self.has_called_disconnected then
		local task = SayTask:new('misc/fuelbasketmiss')
		GetJester():AddTask(task)
		tasks[#tasks + 1] = task
		self.has_called_disconnected = true
	elseif not is_disconnected then
		self.has_called_disconnected = false
	end

	-- Callout Connected
	local is_connected = IsConnected()
	if is_connected and not self.has_called_connected then
		local task = SayTask:new('misc/fuelprobeconnect')
		GetJester():AddTask(task)
		tasks[#tasks + 1] = task
		self.has_called_connected = true
	elseif not is_connected then
		self.has_called_connected = false
	end

	-- Callout "about to disconnect"
	if is_connected and self.connected_timer > connected_cues_after then
		local distance = pos_error:GetLength()
		local is_about_to_disconnect = distance > refueling_green_zone
		if is_about_to_disconnect then
			local is_too_close_to_tanker = IsTooCloseToTanker(pos_error)
			if is_too_close_to_tanker and not self.has_called_charging_boom then
				local task = SayTask:new('refueling/ChargingTheBoom')
				GetJester():AddTask(task)
				tasks[#tasks + 1] = task
				self.has_called_charging_boom = true
			elseif not is_too_close_to_tanker and not self.has_called_falling_off then
				local task = SayTask:new('refueling/AboutToFallOff')
				GetJester():AddTask(task)
				tasks[#tasks + 1] = task
				self.has_called_falling_off = true
			end
		elseif distance <= refueling_green_zone_good then
			self.has_called_charging_boom = false
			self.has_called_falling_off = false
		end
	else
		self.has_called_charging_boom = false
		self.has_called_falling_off = false
	end

	return tasks
end

function AssistAAR:PreContactTanker()
	-- "Ready Pre-Contact" Tanker
	local is_ready_pre_contact = IsReadyLight() and not IsConnected()
	if is_ready_pre_contact then
		if not self.has_called_ready_pre_contact then
			-- DCS ignores the command if it is send when it makes no sense and is not available in the menu
			ClickRawButton(Interactions.devices.ICS, Interactions.device_commands.TANKER_PRE_CONTACT, 1)
			self.has_called_ready_pre_contact = true
		end
	else
		self.has_called_ready_pre_contact = false
	end
end

function AssistAAR:Constructor()
	Behavior.Constructor(self)

	self.steer_not_connected = Urge:new({
		time_to_release = s(10),
		on_release_function = function()
			self:SteerNotConnected()
		end,
		stress_reaction = StressReaction.fixation,
	})
	self.steer_not_connected:Restart()

	self.steer_connected = Urge:new({
		time_to_release = s(5),
		on_release_function = function()
			self:SteerConnected()
		end,
		stress_reaction = StressReaction.fixation,
	})
	self.steer_connected:Restart()

	self.comment_events = Urge:new({
		time_to_release = s(0.5),
		on_release_function = function()
			self:CommentEvents()
		end,
		stress_reaction = StressReaction.fixation,
	})
	self.comment_events:Restart()

	self.pre_contact_tanker = Urge:new({
		time_to_release = s(2),
		on_release_function = function()
			self:PreContactTanker()
		end,
		stress_reaction = StressReaction.fixation,
	})
	self.pre_contact_tanker:Restart()
end

function AssistAAR:Tick()
	if IsConnected() then
		self.connected_timer = self.connected_timer + Utilities.GetTime().dt
	else
		self.connected_timer = s(0)
	end

	if self.steer_not_connected then
		self.steer_not_connected:Tick()
	end
	if self.steer_connected then
		self.steer_connected:Tick()
	end
	if self.comment_events then
		self.comment_events:Tick()
	end
	if self.pre_contact_tanker then
		self.pre_contact_tanker:Tick()
	end
end

AssistAAR:Seal()
return AssistAAR
