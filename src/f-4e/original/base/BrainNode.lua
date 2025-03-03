---// BrainNode.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require 'base.Class'
local Set = require 'base.Set'

local BrainNode = Class()

function BrainNode:Constructor()
	self.referencing_nodes = Set:new()
	local mt = getmetatable(self.referencing_nodes)
	mt.__mode = 'k'
end

function BrainNode:AddReferencingNode(obj)
	self.referencing_nodes:Add(obj)
end

function BrainNode:RemoveReferencingNode(obj)
	self.referencing_nodes:Remove(obj)
end

function BrainNode:GetReferencingNodeCount()
	local i = 0
	for _, v in pairs(self.referencing_nodes) do
		if v then
			i = i + 1
		end
	end
	return i
end

BrainNode:Seal()

return BrainNode
