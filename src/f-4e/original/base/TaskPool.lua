---// TaskPool.lua
---// Copyright (c) 2024 Heatblur Simulations. All rights reserved.

local Class = require 'base.Class'
local ActionSwimlane = require 'base.ActionSwimlane'

local TaskPool = Class()

TaskPool.swimlanes = {}
TaskPool.task_queue = {}

function TaskPool:Constructor(task_queue)
	assert(task_queue)
	self.task_queue = task_queue
	self:AddSwimlane('voice')
	self:AddSwimlane('hands')
	self:AddSwimlane('eyes')
end

local function AreAllSwimlanesBlocked(taskpool)
	local blocked = true
	for _, sl in ipairs(taskpool.swimlanes) do
		blocked = blocked and sl:IsBlocked()
	end
	return blocked
end

local function RemoveCompletedActionsAndTasks(taskpool)
	local swimlanes_with_completed_actions = {}
	for _, sl in ipairs(taskpool.swimlanes) do
		if sl.current_action and sl.current_action:IsFinished() then
			--Log('Swimlane ' .. sl.tag .. ' has a completed action, adding to remove')
			table.insert(swimlanes_with_completed_actions, sl)
		end
	end
	--if #swimlanes_with_completed_actions > 0 then
	--	Log('There are ' .. tostring(#swimlanes_with_completed_actions) .. ' actions to be removed')
	--end
	table.sort(swimlanes_with_completed_actions, function(a, b)
		if a.current_task_index > b.current_task_index then
			return true
		elseif a.current_task_index == b.current_task_index then
			return a.current_action_index > b.current_action_index
		else
			return false
		end
	end)
	for _, sl in ipairs(swimlanes_with_completed_actions) do
		table.remove(sl.current_task.actions_queue, sl.current_action_index)
		if #sl.current_task.actions_queue == 0 then
			sl.current_task:OnFinished()
			--Log(sl.tag .. ' removing task ' .. tostring(sl.current_task_index))
			table.remove(sl.task_queue, sl.current_task_index)
			sl.current_task = nil
		end
	end
end

function TaskPool:Tick()
	--Log('Ticking taskpool')
	for _, sl in ipairs(self.swimlanes) do
		sl:Reset()
	end
	self:Swim()
	for _, sl in ipairs(self.swimlanes) do
		sl:Tick()
	end
	RemoveCompletedActionsAndTasks(self)
end

function TaskPool:Swim()
	repeat
		for _, sl in ipairs(self.swimlanes) do
			sl:Swim()
		end
	until AreAllSwimlanesBlocked(self)
end

function TaskPool:AddSwimlane(tag)
	assert(tag)
	table.insert(self.swimlanes, ActionSwimlane:new(tag, self.task_queue))
end

TaskPool:Seal()

return TaskPool
