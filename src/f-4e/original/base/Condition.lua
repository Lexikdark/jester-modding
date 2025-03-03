---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require 'base.Class'

local Condition = Class()

local mt = getmetatable(Condition)
mt.__call = function(self,...)
	return self:new(...)
end

function Condition:Check()
	return false
end

-- Logical operations

-- AND
local AndCondition = Class(Condition)

function AndCondition:Constructor(subconditions)
	self.subconditions = {}
	if subconditions then
		for _, v in ipairs(subconditions) do
			if Class.IsClass(v) then
				table.insert(self.subconditions, v:new())
			else
				table.insert(self.subconditions, v)
			end
		end
	end
end

function AndCondition:Check()
	if self.subconditions then
		local result = true
		for _, v in ipairs(self.subconditions) do
			result = result and v:Check()
		end
		return result
	end
	return false
end

AndCondition:Seal()

-- OR
local OrCondition = Class(Condition)

function OrCondition:Constructor(subconditions)
	self.subconditions = {}
	if subconditions then
		for _, v in ipairs(subconditions) do
			if Class.IsClass(v) then
				table.insert(self.subconditions, v:new())
			else
				table.insert(self.subconditions, v)
			end
		end
	end
end

function OrCondition:Check()
	if self.subconditions then
		local result = false
		for _, v in ipairs(self.subconditions) do
			result = result or v:Check()
		end
		return result
	end
	return false
end

OrCondition:Seal()

-- NOT

local NotCondition = Class(Condition)

function NotCondition:Constructor(subcondition)
	if Class.IsClass(subcondition) then
		self.subconditions = subcondition:new()
	else
		self.subconditions = subcondition
	end
end

function NotCondition:Check()
	return self.subcondition and not self.subcondition:Check()
end

NotCondition:Seal()

-- Logical helpers

function Condition.And(self, ...)
	local conditions_list = {self, ...}
	return AndCondition:new(conditions_list)
end

function Condition.Or(self, ...)
	local conditions_list = {self, ...}
	return OrCondition:new(conditions_list)
end

function Condition.Not(self)
	return NotCondition:new(self)
end

Condition:Seal()

return Condition
