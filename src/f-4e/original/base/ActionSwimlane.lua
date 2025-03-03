---// ActionSwimlane.lua
---// Copyright (c) 2024 Heatblur Simulations. All rights reserved.

local Class = require 'base.Class'

local ActionSwimlane = Class()

ActionSwimlane.tag = nil
ActionSwimlane.task_queue = nil -- reference to the task queue from TaskPool
ActionSwimlane.current_task = nil
ActionSwimlane.ticked = false
ActionSwimlane.blocked = false
ActionSwimlane.current_action = nil
ActionSwimlane.current_task_index = 1
ActionSwimlane.current_action_index = 1

function ActionSwimlane:Constructor(tag, task_queue)
	self.tag = tag
	self.task_queue = task_queue
	self:Reset()
	assert(self.tag)
	assert(self.task_queue)
end

function ActionSwimlane:IsBlocked()
	return self.blocked
end

local function GetTaskSwimmersCount(task)
	return task.swimmers_count or 0
end

local function AddSwimmerToTask(task, swimmer)
	local tag = swimmer.tag
	if not task.active then
		task:Restart()
	end
	if task.paused then
		task:Unpause()
	end

	if task.swimmers == nil then
		local swimmers = {}
		swimmers[tag] = true
		task.swimmers = swimmers
		task.swimmers_count = 1
	else
		if task.swimmers[tag] then
			return
		else
			task.swimmers[tag] = true
			task.swimmers_count = task.swimmers_count + 1
		end
	end
end

local function RemoveSwimmerFromTask(task, swimmer)
	local tag = swimmer.tag
	if task.swimmers == nil then
		return
	else
		if task.swimmers[tag] then
			task.swimmers[tag] = nil
			task.swimmers_count = task.swimmers_count - 1
		end
	end

	if GetTaskSwimmersCount(task) == 0 then
		if task.active then
			task:Pause()
		end
	end
end

local function AddSwimmerToAction(action, swimmer)
	local tag = swimmer.tag
	if action.swimmers == nil then
		local swimmers = {}
		swimmers[tag] = true
		action.swimmers = swimmers
	else
		if action.swimmers[tag] then
			return
		else
			action.swimmers[tag] = true
		end
	end
end

local function RemoveSwimmerFromAction(action, swimmer)
	local tag = swimmer.tag
	if action.swimmers == nil then
		return
	else
		if action.swimmers[tag] then
			action.swimmers[tag] = nil
		end
	end
end

function ActionSwimlane:Swim()
	if self.blocked then
		return
	end
	if self.current_task_index <= #self.task_queue then
		-- remove empty tasks we find on our way/swim
		local current_task = self.task_queue[self.current_task_index]
		repeat
			current_task = self.task_queue[self.current_task_index]
			AddSwimmerToTask(current_task, self)
			if #current_task.actions_queue == 0 then
				RemoveSwimmerFromTask(current_task, self)
				current_task:OnFinished()
				table.remove(self.task_queue, self.current_task_index)
			end
		until #current_task.actions_queue ~= 0 or self.current_task_index >= #self.task_queue
		-- search for the first non finished action which requires this swim lane, iterate over tasks and actions
		if self.current_action_index <= #current_task.actions_queue then
			local current_action = current_task.actions_queue[self.current_action_index]
			if current_action.requires[self.tag] then
				if not current_action:IsFinished() then
					--Log('Swimmer ' .. self.tag .. ' found blocking action ' .. tostring(self.current_task_index) .. ' : ' .. tostring(self.current_action_index))
					self.blocked = true
					self.current_action = current_action
					AddSwimmerToAction(current_action, self)
					if current_task ~= self.current_task then
						if self.current_task then
							RemoveSwimmerFromTask(self.current_task, self)
						end
						self.current_task = current_task
					end
					return
				end
			end
			self.current_action_index = self.current_action_index + 1
			return
		end
		-- not found in the current task, moving to the next task
		self.current_action_index = 1
		RemoveSwimmerFromTask(current_task, self)
		self.current_task_index = self.current_task_index + 1
		return
	end
	-- no valid action requiring this lane, stalling
	self.blocked = true
	self.current_action = nil
	if self.current_task then
		if self.current_task then
			RemoveSwimmerFromTask(self.current_task, self)
		end
		self.current_task = nil
	end
end

function ActionSwimlane:Reset()
	if self.current_action then
		RemoveSwimmerFromAction(self.current_action, self)
		self.current_action = nil
	end
	self.current_task_index = 1
	self.current_action_index = 1
	self.blocked = false
	self.ticked = false
end

function ActionSwimlane:Tick()
	if self.current_action then
		if self.current_action:IsFinished() then
			RemoveSwimmerFromAction(self.current_action, self)
			self.current_action = nil
			--Log('Swimmer ' .. self.tag .. ' action already finished for task ' .. self.current_task_index .. ' action ' .. self.current_action_index)
		else
			local do_tick = true
			-- checking if the action has all swimlanes required to tick
			for k, v in pairs(self.current_action.requires) do
				if v and not self.current_action.swimmers[k] then
					do_tick = false
				end
			end
			if do_tick then
				--Log('Swimmer ' .. self.tag .. ' ticking task ' .. self.current_task_index .. ' action ' .. self.current_action_index)
				self.current_action:Tick()
				self.ticked = true
			--else
			--  Log('Swimmer ' .. self.tag .. ' waiting for other swimmers at task ' .. self.current_task_index .. ' action ' .. self.current_action_index)
			end
			-- we remove ourselves so the action won't tick for the next swimlane if more then one swimlane is required
			RemoveSwimmerFromAction(self.current_action, self)
		end
	--else
	--	Log('Swimmer ' .. self.tag .. ' idling')
	end
end

ActionSwimlane:Seal()

return ActionSwimlane
