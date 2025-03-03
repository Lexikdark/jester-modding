---// MemoryObject.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require 'base.Class'
local Set = require 'base.Set'
local Utilities = require 'base.Utilities'

local MemoryObject = Class()

MemoryObject.last_seen_time_stamp = s(0)
MemoryObject.is = {labels = Set:new(), type = Set:new()}
MemoryObject.can_be = {labels = Set:new(), type = Set:new()}
MemoryObject.cannot_be = {labels = Set:new(), type = Set:new()}
MemoryObject.true_id = nil

function MemoryObject:Touch()
	self.last_seen_time_stamp = Utilities.GetTime().mission_time
end

function MemoryObject:Is(what)
	return self.is.labels[what] or self.is.type[what] or false
end

function MemoryObject:CanBe(what)
	return self.is.labels[what] or self.is.type[what] or self.can_be.labels[what] or self.can_be.type[what] or false
end

function MemoryObject:CannotBe(what)
	return self.cannot_be.labels[what] or self.cannot_be.type[what] or false
end

function MemoryObject:SetIsLabels(...)
	self.is.labels:Add(...)
	self.can_be.labels:Remove(...)
end

function MemoryObject:RemoveIsLabels(...)
	self.is.labels:Remove(...)
end

function MemoryObject:SetIsType(type)
	self.is.type:Add(type)
	self.can_be.type:Remove(label)
end

function MemoryObject:SetCanBeLabels(...)
	self.can_be.labels:Add(...)
end

function MemoryObject:RemoveCanBeLabels(...)
	self.can_be.labels:Remove(...)
end

function MemoryObject:SetCanBeType(type)
	self.can_be.type:Add(type)
end

function MemoryObject:SetCannotBeLabels(...)
	self.cannot_be.labels:Add(...)
end

function MemoryObject:SetCannotBeType(type)
	self.cannot_be.type:Add(type)
end

function MemoryObject:RemoveCannotBeLabels(...)
	self.cannot_be.labels:Remove(...)
end

function MemoryObject:UpdateFromContact(contact)
	self:Touch()
	self.type = contact.type or self.type
	self.is.labels:Append(contact.is.labels)
	self.true_id = contact.true_id or self.true_id
	self.position_ned = contact.position_ned or self.position_ned
	self.position_body = contact.position_body or self.position_body
	self.polar_ned = contact.polar_ned or self.polar_ned
	self.polar_body = contact.polar_body or self.polar_body
	self.size = contact.size or self.size
	self.angular_size = contact.angular_size or self.angular_size
	self.velocity_ned = contact.velocity_ned or self.velocity_ned
	self.velocity_body = contact.velocity_body or self.velocity_body
	self.announced = contact.announced or self.announced
	self.announced_dead = contact.announced_dead or self.announced_dead
	self.announced_traffic = contact.announced_traffic or self.announced_traffic
end

MemoryObject:Seal()

return MemoryObject
