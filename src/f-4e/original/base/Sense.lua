---// Sense.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require 'base.Class'
local Set = require 'base.Set'

local Sense = Class()

Sense.contacts = {}
Sense.observations = Set:new {}
Sense.input =
{
    contacts = {},
    observations = Set:new {},
}

function Sense:AddContact(contact)
    table.insert(self.contacts, contact)
end

function Sense:ClearContacts()
    self.contacts = {}
end

function Sense:ClearObservations()
    self.observations = {}
end

function Sense:SetObservation(observation, state)
    self.observations[observation] = state
end

function Sense:RemoveObservation(observation)
    self.observations[observation] = false
end

function Sense:IsObserved(observation)
    return self.observations[observation]
end

function Sense:AddInputContact(contact)
    table.insert(self.input.contacts, contact)
end

function Sense:ClearInputContacts()
    self.input.contacts = {}
end

function Sense:ClearInputObservations()
    self.input.observations = {}
end

function Sense:SetInputObservation(observation, state)
    if type(state) == 'userdata' and state.new then
        self.input.observations[observation] = state.new(state)
    else
        self.input.observations[observation] = state
    end
end

Sense:Seal()

return Sense
