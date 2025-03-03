---// Set.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Set = {}

function Set:new(t)
	local set = {}
	if t then
		for _, l in ipairs(t) do set[l] = true end
	end
	self.__index = self
	setmetatable(set, self)
	return set
end

function Set:Add(...)
	local list = {...}
	for _, v in pairs(list) do
		self[v] = true
	end
end

function Set:Remove(...)
	local list = {...}
	for _, v in pairs(list) do
		self[v] = nil
	end
end

function Set:Append(other)
	for k in pairs(other) do self[k] = true end
end

function Set.Union(a, b)
	local res = Set.new{}
	for k in pairs(a) do res[k] = true end
	for k in pairs(b) do res[k] = true end
	return res
end

function Set.Intersection(a, b)
	local res = Set.new{}
	for k in pairs(a) do
		res[k] = b[k]
	end
	return res
end

function Set.Difference(a, b)
	local res = Set.new{}
	for k in pairs(a) do
		if not b[k] then
			res[k] = true
		end
	end
	return res
end

function Set:Clear()
	self = Set:new()
end

return Set
