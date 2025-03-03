---// HighLevelBrainNode.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.
---

local BrainNode = require 'base.BrainNode'
local Class = require 'base.Class'
local Set = require 'base.Set'

local HighLevelBrainNode = Class(BrainNode)

HighLevelBrainNode.behaviors = {}
HighLevelBrainNode.situations = {}

function HighLevelBrainNode:Constructor()
    BrainNode.Constructor(self)
end

function HighLevelBrainNode:AddBehavior(res)
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

function HighLevelBrainNode:RemoveBehavior(res)
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

function HighLevelBrainNode:HasBehavior(res)
    return self.behaviors[res] ~= nil
end

function HighLevelBrainNode:RemoveAllBehaviors()
    local jester = GetJester()
    for behavior, instance in pairs(self.behaviors) do
        instance:RemoveReferencingNode(self)
        if instance:GetReferencingNodeCount() == 0 then
            jester.behaviors[behavior] = nil
        end
    end
    self.behaviors = {}
end

function HighLevelBrainNode:AddSituation(res)
    if not self.situations[res] then
        local jester = GetJester()
        local instance = jester.situations[res]
        if not instance then
            instance = res:new()
            jester.situations[res] = instance
        end
        self.situations[res] = instance
        instance:AddReferencingNode(self)
    end
    return self.situations[res]
end

function HighLevelBrainNode:RemoveSituation(res)
    local instance = self.situations[res]
    if instance then
        instance:RemoveReferencingNode(self)
        if instance:GetReferencingNodeCount() == 0 then
            local jester = GetJester()
            jester.situations[res] = nil
            self.situations[res] = nil
        end
    end
end

function HighLevelBrainNode:HasSituation(res)
    return self.situations[res] ~= nil
end

function HighLevelBrainNode:RemoveAllSituations()
    local jester = GetJester()
    for behavior, instance in pairs(self.situations) do
        instance:RemoveReferencingNode(self)
        if instance:GetReferencingNodeCount() == 0 then
            jester.situations[behavior] = nil
        end
    end
    self.situations = {}
end

HighLevelBrainNode:Seal()

return HighLevelBrainNode
