---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.
---
local Class = require('base.Class')
local SayTask = require('tasks.common.SayTask')
local Task = require('base.Task')
local Interactions = require('base.Interactions')
local NavInteractions = require('tasks.navigation.NavInteractions')

local CheckFuelDialog = Class(Task)

local onFuelGood = function(task)
	-- TODO Replace with proper actions
	--ClickRaw(Interactions.devices.EJECTION_SEAT_SYSTEM, Interactions.device_commands.WSO_EJECT_INSTANT, 1)
end

local function NavigateToTanker(tanker_no)
	if type(tanker_no) ~= "number" or tanker_no < 1 or tanker_no > 4 then
		return
	end

	local i = 0
	for _, obj in ipairs(nav_tac_objects or {}) do
		if obj and obj.is_tanker then
			i = i + 1
			if i == tanker_no then
				local lat = obj.latitude.value
				local lon = obj.longitude.value

				if lat ~= nil and lon ~= nil then
					local act_val = tostring(lat) .. ";" .. tostring(lon)
					local task = Task:new()
					NavInteractions.DivertWithTGT1(task, act_val)
					GetJester():AddTask(task)
					return
				end
			end
		end
	end
	return
end

local function NavigateToAirport(airport_no)
	if type(airport_no) ~= "number" or airport_no < 1 or airport_no > 4 then
		return
	end

	local i = 0
	for _, obj in ipairs(nearby_airfields or {}) do
		if obj then
			i = i + 1
			if i == airport_no then
				local lat = obj.latitude.value
				local lon = obj.longitude.value

				if lat ~= nil and lon ~= nil then
					local act_val = tostring(lat) .. ";" .. tostring(lon)
					local task = Task:new()
					NavInteractions.DivertWithTGT1(task, act_val)
					GetJester():AddTask(task)
					return
				end
			end
		end
	end
	return
end

function CheckFuelDialog:Constructor()
	Task.Constructor(self)

	local on_activation = function()
		self:RemoveAllActions()
		-- TODO voice lines

		local CreateTankersMenu = function() -- Maybe tune the radio too in the future?
			local items = {}
			local i = 1
			local max_tankers_no = 4
			for _, obj in ipairs(nav_tac_objects or {}) do
				if i > max_tankers_no then
					break
				end

				local lat = obj.latitude.value
				local lon = obj.longitude.value

				if obj.is_tanker and obj.text ~= nil and lat ~= nil and lon ~= nil then
					items[i] = Dialog.Option:new({
						response = obj.text:gsub("\n", " "),
						action = "divert_tanker_" .. tostring(i),
					})

					i = i + 1
				end
			end

			local tankers_nearby = #items > 0
			local wrapping_item = nil

			if tankers_nearby then
				wrapping_item = Dialog.Option:new({
					response = "Rejoin with Tanker",
					follow_up_question = Dialog.FollowUpQuestion:new({
						name = "Jester",
						content = "Which tanker you want to rejoin with?",
						phrase = "phrases/WhichTanker",
						options = items,
					}),
				})
			end

			return wrapping_item
		end

		local CreateAirfieldsMenu = function()
			local items = {}
			local i = 1
			local max_airfields_no = 4
			for _, obj in ipairs(nearby_airfields or {}) do
				if i > max_airfields_no then
					break
				end

				local lat = obj.latitude.value
				local lon = obj.longitude.value

				if obj.name ~= nil and lat ~= nil and lon ~= nil then
					items[i] = Dialog.Option:new({
						response = obj.name,
						action = "divert_airfield_" .. tostring(i),
					})

					i = i + 1
				end
			end

			local airfields_nearby = #items > 0
			local wrapping_item = nil

			if airfields_nearby then
				wrapping_item = Dialog.Option:new({
					response = "Divert to Airfield",
					follow_up_question = Dialog.FollowUpQuestion:new({
						name = "Jester",
						content = "Which airfield do you want to navigate to?",
						phrase = "phrases/Fuel_WhereWeGoing",
						options = items,
					}),
				})
			end

			return wrapping_item
		end

		local hb_option = Dialog.Option:new({
			response = "Navigate to Homebase",
			action = "divert_homebase",
		})

		local tankers_menu = CreateTankersMenu()
		local airfields_menu = CreateAirfieldsMenu()

		local follow_up_options = {
			Dialog.Option:new({
				response = "Remain on Mission",
				action = "fuel_remain_on_mission",
			}),
		}

		if airfields_menu ~= nil then
			table.insert(follow_up_options, airfields_menu)
		end

		if tankers_menu ~= nil then
			table.insert(follow_up_options, tankers_menu)
		end

		if homebase ~= nil then
			table.insert(follow_up_options, hb_option)
		end

		local question = Dialog.Question:new({
			name = "Jester",
			content = "How is the fuel?",
			phrase = "phrases/Fuel_FuelCheck",
			label = "Fuel Check",
			timing = Dialog.Timing:new({
				question = s(10),
				action = s(15),
			}),
			options = {
				Dialog.Option:new({
					response = "We are good",
					action = "fuel_good",
				}),
				Dialog.Option:new({
					response = "Fuel is low",
					follow_up_question = Dialog.FollowUpQuestion:new({
						name = "Jester",
						content = "Okay, how do you want to proceed?",
						phrase = "phrases/Fuel_WhereWeGoing",
						options = follow_up_options,
					}),
				}),
			},
		})
		Dialog.Push(question)
	end

	self:AddOnActivationCallback(on_activation)
end

ListenTo("divert_homebase", "CheckFuelDialog", function()
	if ( homebase ) then
		local lat = homebase.latitude.value
		local lon = homebase.longitude.value

		if lat ~= nil and lon ~= nil then
			local act_val = tostring(lat) .. ";" .. tostring(lon)
			local task = Task:new()
			NavInteractions.DivertWithTGT1(task, act_val)
			GetJester():AddTask(task)
			return
		end
	end
end)

ListenTo("divert_tanker_1", "CheckFuelDialog", function()
	NavigateToTanker(1)
end)

ListenTo("divert_tanker_2", "CheckFuelDialog", function()
	NavigateToTanker(2)
end)

ListenTo("divert_tanker_3", "CheckFuelDialog", function()
	NavigateToTanker(3)
end)

ListenTo("divert_tanker_4", "CheckFuelDialog", function()
	NavigateToTanker(4)
end)

ListenTo("divert_airfield_1", "CheckFuelDialog", function()
	NavigateToAirport(1)
end)

ListenTo("divert_airfield_2", "CheckFuelDialog", function()
	NavigateToAirport(2)
end)

ListenTo("divert_airfield_3", "CheckFuelDialog", function()
	NavigateToAirport(3)
end)

ListenTo("divert_airfield_4", "CheckFuelDialog", function()
	NavigateToAirport(4)
end)

ListenTo("msfs_fuel_check", "CheckFuelDialog", function()
	GetJester():AddTask(SayTask:new('phrases/Fuel_FuelCheck'))
end)

CheckFuelDialog:Seal()
return CheckFuelDialog
