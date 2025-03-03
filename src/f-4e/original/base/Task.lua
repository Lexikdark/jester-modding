---// Task.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require 'base.Class'
local BasicAction = require 'actions.BasicAction'
local DelayAction = require 'actions.DelayAction'
local BarrierAction = require 'actions.BarrierAction'
local DelayUntilAction = require 'actions.DelayUntilAction'
local SayAction = require('actions.SayAction')
local SayRandomAction = require('actions.SayRandomAction')
local SwitchAction = require('actions.SwitchAction')
local SwitchTemporarilyAction = require('actions.SwitchTemporarilyAction')


local Task = Class()

Task.name = ''
Task.actions_queue = {}
Task.priority = 0
Task.active = false
Task.paused = false
Task.on_activation_callback = {}
Task.on_cancelled_callback = {}
Task.on_finished_callback = {}
Task.finished = false
Task.estimated_time_to_finish = s(0)

function Task:AddAction(action)
	if Class.IsClass(action) then
		table.insert(self.actions_queue, action:new())
	else
		table.insert(self.actions_queue, action)
	end
	-- Fluent-API, e.g. task:Roger():Wait(s(3)):Click('foo', 'bar'):Then(function() ... end)
	return self
end

function Task:Then(action_function, requires)
	return self:AddAction(BasicAction:new(action_function, requires))
end

function Task:NextTask(next_task)
	self:AddOnFinishedCallback(function()
		GetJester():AddTask(next_task)
	end)
	return self
end

-- requires: table with bool entries "hands", "eyes", "voice"
function Task:Require(requires)
	return self:AddAction(BarrierAction:new(requires))
end

function Task:Wait(time, requires)
	return self:AddAction(DelayAction:new(time, requires))
end

-- max_delay is optional (uses reasonable default then)
function Task:WaitUntil(predicate, max_delay, requires)
	return self:AddAction(DelayUntilAction:new(predicate, max_delay, requires))
end

function Task:Say(...)
	return self:AddAction(SayAction:new(...))
end

function Task:Roger()
	local calls = {{'misc/roger', percent(60)}, {'misc/copy', percent(30)}, {'misc/wilco', percent(10)}}
	return self:AddAction(SayRandomAction( calls ))
end

function Task:CantDo()
	local calls = {{'misc/cantdo', percent(70)}, {'misc/unable', percent(30)}}
	return self:AddAction(SayRandomAction( calls ))
end

-- Preferred way to click anything in the cockpit. Make sure to setup the
-- manipulator in F_4E_WSO_Cockpit.lua first.
-- If this is not possible, fallback to the ClickRaw methods defined in Interactions.lua.
-- delay_time is optional, can be used for high priority actions
-- do_force_click is optional, if set, the task will not be skipped if the manipulator is already in the desired state
function Task:Click(manipulator_name, state_name, delay_time, do_force_click)
	if not do_force_click and GetJester():GetCockpit():GetManipulator(manipulator_name):GetState() == state_name then
		Log("  (--Skip click: " .. manipulator_name .. "': " .. state_name .. ")") -- Set do_force_click or use ClickSequence if skipped unintentionally
		return self
	end
	return self:AddAction(SwitchAction:new(manipulator_name, state_name, delay_time))
end

-- The click is executed very fast without longer delay.
-- do_force_click is optional, if set, the task will not be skipped if the manipulator is already in the desired state
function Task:ClickFast(manipulator_name, state_name, do_force_click)
	return self:Click(manipulator_name, state_name, s(0.2), do_force_click)
end

-- The click is executed instant without any delay.
-- do_force_click is optional, if set, the task will not be skipped if the manipulator is already in the desired state
function Task:ClickInstant(manipulator_name, state_name, do_force_click)
	return self:Click(manipulator_name, state_name, s(0), do_force_click)
end

-- Clicks only short and then returns to the previous position.
-- Useful for momentary push buttons.
-- hold_time is optional
function Task:ClickShort(manipulator_name, state_name, hold_time, delay_time)
	return self:AddAction(SwitchTemporarilyAction:new(manipulator_name, state_name, hold_time, delay_time))
end

-- Clicks only short and then returns to the previous position. The click is executed very fast without longer delay.
-- Useful for momentary push buttons.
-- hold_time is optional
function Task:ClickShortFast(manipulator_name, state_name, hold_time)
	return self:AddAction(SwitchTemporarilyAction:new(manipulator_name, state_name, hold_time, s(0.2)))
end

-- The sequence of clicks is executed very fast without longer delay.
function Task:ClickSequenceFast(manipulator_name, ...)
	local state_names = { n = select("#", ...), ... }
	for i = 1, state_names.n do
		self:ClickFast(manipulator_name, state_names[i], true)
	end
	return self
end

function Task:SetPriority(prior)
	if type(prior) ~= "number" then
		error("Invalid argument: priority should be a number.")
	end
	self.priority = prior
end

function Task:Pause()
	self.paused = true
end

function Task:Unpause()
	if self.paused then
		self:Activate()
		self.paused = false
	end
end

function Task:AddOnActivationCallback(callback)
	if type(callback) == 'function' then
		table.insert(self.on_activation_callback, callback)
	else
		io.stderr:write("ActivationCallback is not a function.\n")
	end
end

function Task:AddOnCancelledCallback(callback)
	if type(callback) == 'function' then
		table.insert(self.on_cancelled_callback, callback)
	else
		io.stderr:write("CancelledCallback is not a function.\n")
	end
end

function Task:AddOnFinishedCallback(callback)
	if type(callback) == 'function' then
		table.insert(self.on_finished_callback, callback)
	else
		io.stderr:write("FinishedCallback is not a function.\n")
	end
end

function Task:RemoveAllActions()
	for _, _ in ipairs(self.actions_queue) do
		table.remove(self.actions_queue)
	end
end

function Task:OnFinished()
	self.finished = true
	for _, callback in ipairs(self.on_finished_callback) do
		callback(self)
	end
end

function Task:Cancel()
	self.finished = true
	for _, callback in ipairs(self.on_cancelled_callback) do
		callback(self)
	end
end

function Task:IsFinished()
	return self.finished
end

function Task:Activate()
	self.active = true
	for _, callback in ipairs(self.on_activation_callback) do
		callback(self)
	end
end

function Task:Restart()
	self:Activate()
end

Task.Constructor = function(self,...)
	for _, v in ipairs({...}) do
		self:AddAction(v)
	end
end

local mt = getmetatable(Task)
mt.__call = function(self,...)
	return self:new(...)
end

Task:Seal()

return Task
