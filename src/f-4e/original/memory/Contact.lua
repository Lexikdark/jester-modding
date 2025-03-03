---// Contact.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require 'base.Class'
local MemoryObject = require 'memory.MemoryObject'
local Utilities = require 'base.Utilities'

local Contact = Class(MemoryObject)

Contact.compatible_memory_objects = {}

--Update a contact object. See fields in MemoryObject:UpdateFromContact for more assignments.
function Contact:UpdateFromContact(contact)

	MemoryObject.UpdateFromContact(self, contact)

	--Assign fields to memory objects for some stuff here.
	for _, k in pairs(self.compatible_memory_objects) do

		self.announced = contact.announced or self.announced
		self.announced_dead = contact.announced_dead or self.announced_dead
		self.announced_traffic = contact.announced_traffic or self.announced_traffic

		--Update the compatible memory objects with the fields by calling UpdateFromContact.
		k:UpdateFromContact(contact)

	end
end


--Update memory objects or create a new memory object if none exists for this contact.
function Contact:AssignOrCreateMemoryObjects()
	local memory = GetJester().memory
	self.compatible_memory_objects = memory:GetCompatibleObjects(self)

	--There is an associated memory contact/object; so update it with the new data.
	if #self.compatible_memory_objects > 0 then
		for _, k in pairs(self.compatible_memory_objects) do

			self.announced = k.announced or self.announced
			self.announced_dead = k.announced_dead or self.announced_dead
			self.announced_traffic = k.announced_traffic or self.announced_traffic

			k:UpdateFromContact(self)
		end
	else
		local object = memory:CreateNewObject()
		object:UpdateFromContact(self)
		table.insert(self.compatible_memory_objects, object)
	end
end

Contact:Seal()

return Contact
