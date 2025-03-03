---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Task = require 'base.Task'
local Timer = require 'base.Timer'

-- The following functions are created from C++:
-- ClickRaw(device_id, command_id, value)

-- For knobs or switches that have \c count many positions and animate from 0 to 1.
-- Sets it to the given \c position. The first position is 1, valid positions are 1 to count.
function ClickRawKnob(device_id, command_id, position, count)
	if position < 1 or position > count then
		error("Position must be [1, count], but was " .. position .. "(device_id: " .. device_id .. ", command_id: " .. command_id .. ")")
		return
	end

	local delta = 1.0 / (count - 1)
	local value = (position - 1) * delta

	Timer:new(s(1), function() ClickRaw(device_id, command_id, value) end)
end

function ClickRawButton(device_id, command_id)
	Timer:new(s(2), function()
		ClickRaw(device_id, command_id, 1)
		Timer:new(s(1), function() ClickRaw(device_id, command_id, 0) end)
	end)

end

-- Jester Wheel UI
-- The following functions are created from C++:
-- Wheel.ReplaceMainMenu(main_menu)
-- Wheel.ReplaceSubMenu(sub_menu, menu_location)
-- Wheel.AddItem(item, menu_location)
-- Wheel.RemoveItem(item_name, menu_location)
-- Wheel.ReplaceItem(item, item_name, menu_location)
-- Wheel.RenameItem(new_item_name, current_item_name, menu_location)
-- Wheel.SetMenuInfo(info_text, menu_location)
-- Wheel.NavigateTo(menu_location)
Wheel.MAX_MENU_ITEMS = 8
Wheel.MAX_OUTER_MENU_ITEMS = 18

-- Jester Dialog UI
-- The following functions are created from C++:
-- Dialog.Push(question)

-- Event System
event_callbacks = {}
-- Register an event handler whose callback will be triggered whenever the given event is fired.
-- @param event the name of the event to listen to
-- @param handler_name the name of the handler to link to this event, must be unique within the group of handlers listening to that event.
--  If a second handler_name with same name is registered for this event, the previous binding will be overriden.
ListenTo = function(event, handler_name, callback)
	if not event or not handler_name or not callback then
		error("ListenTo requires event, handler_name and callback")
	end

	local callbacks = event_callbacks[event] or {}
	callbacks[handler_name] = callback

	event_callbacks[event] = callbacks
end
Dispatch = function(event)
	Log("  --Dispatching: " .. event)
	local callbacks = event_callbacks[event] or {}
	for handler_name, callback in pairs(callbacks) do
		Log("  ---To: " .. handler_name)
		local task = Task:new()
		callback(task)
		GetJester():AddTask(task)
	end
end
Dispatch = function(event, value)
	Log("  --Dispatching: " .. event .. ":" .. tostring(value))
	local callbacks = event_callbacks[event] or {}
	for handler_name, callback in pairs(callbacks) do
		Log("  ---To: " .. handler_name)
		local task = Task:new()
		callback(task, value)
		GetJester():AddTask(task)
	end
end

local Interactions = { _G = _G }
setmetatable(Interactions, {__index = _G} )

local function RequireOrAlternateInteractionsTable(module, table)
	local function require_(mod)
		setfenv(1, Interactions)
		require(mod)
	end
	res = pcall(require_, module)
	if not(res) then
		Interactions[table] = {}
		setmetatable(Interactions[table], {__index = function(_, _) return 0 end})
	end
end

RequireOrAlternateInteractionsTable('devices', 'devices')
RequireOrAlternateInteractionsTable('command_defs', 'device_commands')

return Interactions
