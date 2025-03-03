---// Intention.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights planerved.
---

local HighLevelBrainNode = require 'base.HighLevelBrainNode'
local Class = require 'base.Class'
local Set = require 'base.Set'

local Intention = Class(HighLevelBrainNode)

Intention.activation_conditions = {}
Intention.deactivation_conditions = {}
Intention.plans = {}
Intention.active = false

function Intention:Constructor(args)
	HighLevelBrainNode.Constructor(self)
	if args == nil or args.active then -- Default: Activate
		self:Activate()
	end
end

function Intention:OnActivation()
end

function Intention:OnDeactivation()
end

function Intention:AddPlan(plan)
	if not self.plans[plan] then
		local jester = GetJester()
		local instance = jester.plans[plan]
		if not instance then
			instance = plan:new()
			jester.plans[plan] = instance
		end
		self.plans[plan] = instance
		instance:AddReferencingNode(self)
	end
	return self.plans[plan]
end

function Intention:RemovePlan(plan)
	local instance = self.plans[plan]
	if instance then
		instance:RemoveReferencingNode(self)
		if instance:GetReferencingNodeCount() == 0 then
			local jester = GetJester()
			jester.plans[plan] = nil
			self.plans[plan] = nil
		end
	end
end

function Intention:HasPlan(plan)
	return self.plans[plan] ~= nil
end

function Intention:RemoveAllPlans()
	local jester = GetJester()
	for plan, instance in pairs(self.plans) do
		instance:RemoveReferencingNode(self)
		if instance:GetReferencingNodeCount() == 0 then
			jester.plans[plan] = nil
		end
	end
	self.plans = {}
end

function Intention:Activate()
	self:OnActivation()
	self.active = true
end

function Intention:Deactivate()
	self:OnDeactivation()
	self.active = false
	self:RemoveAllPlans()
end

function Intention:CheckConditions()
	local should_activate = false
	local should_deactivate = false
	if not self.active then
		for i = 1, #self.activation_conditions do
			if self.activation_conditions[i]:Check() then
				should_activate = true
				break
			end
		end
	end
	if self.active or should_activate then
		for i = 1, #self.deactivation_conditions do
			if self.deactivation_conditions[i]:Check() then
				should_activate = false
				should_deactivate = true
				break
			end
		end
	end
	if not self.active and should_activate then
		self:Activate()
	end
	if self.active and should_deactivate then
		self:Deactivate()
	end
end

function Intention:AddActivationConditions(...)
	local conditions_list = {...}
	for _, v in ipairs(conditions_list) do
		table.insert(self.activation_conditions, v)
	end
end

function Intention:AddDeactivationConditions(...)
	local conditions_list = {...}
	for _, v in ipairs(conditions_list) do
		table.insert(self.deactivation_conditions, v)
	end
end

function Intention:IsActive()
	return self.active
end

Intention:Seal()

return Intention
