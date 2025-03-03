---// Situation.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.
---

local BrainNode = require 'base.BrainNode'
local Class = require 'base.Class'
local Set = require 'base.Set'

local Situation = Class(BrainNode)

Situation.activation_conditions = {}
Situation.deactivation_conditions = {}
Situation.behaviors = {}
Situation.active = false

--owner = nil,
--base_priority_modifier = 0,
--priority_modifier = 0,

function Situation:Constructor()
    BrainNode.Constructor(self)
end

function Situation:OnActivation()
end

function Situation:OnDeactivation()
end

function Situation:AddBehavior(res)
    if not self.behaviors[res] then
        local jester = GetJester()
        local instance = jester.behaviors[res]
        if not instance then
            instance = res:new()
            jester.behaviors[res] = instance
        end
        self.behaviors[res] = instance
        instance:AddReferencingNode(self)
    end
    return self.behaviors[res]
end

function Situation:RemoveBehavior(res)
    local instance = self.behaviors[res]
    if instance then
        instance:RemoveReferencingNode(self)
        if instance:GetReferencingNodeCount() == 0 then
            local jester = GetJester()
            jester.behaviors[res] = nil
            self.behaviors[res] = nil
        end
    end
end

function Situation:HasBehavior(res)
    return self.behaviors[res] ~= nil
end

function Situation:RemoveAllBehaviors()
    local jester = GetJester()
    for behavior, instance in pairs(self.behaviors) do
        instance:RemoveReferencingNode(self)
        if instance:GetReferencingNodeCount() == 0 then
            jester.behaviors[behavior] = nil
        end
    end
    self.behaviors = {}
end

function Situation:Deactivate()
    self:OnDeactivation()
    self.active = false
    self:RemoveAllBehaviors()
end

function Situation:CheckConditions()
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
        self.active = true
        self:OnActivation()
    end
    if self.active and should_deactivate then
        self:Deactivate()
    end
end

function Situation:AddActivationConditions(...)
    local conditions_list = {...}
    for _, v in ipairs(conditions_list) do
        table.insert(self.activation_conditions, v)
    end
end

function Situation:AddDeactivationConditions(...)
    local conditions_list = {...}
    for _, v in ipairs(conditions_list) do
        table.insert(self.deactivation_conditions, v)
    end
end

function Situation:IsActive()
    return self.active
end

Situation:Seal()

return Situation
