---// Manipulator.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require('base.Class')

local Manipulator = Class()

function Manipulator:Constructor(init_data)
    assert(init_data)
    self.component_path = init_data.component_path
    self.connector = init_data.connector
    assert(self.component_path)
    self.component_manipulator = ComponentManipulator.new(self.component_path or "")
    if not self.component_manipulator:IsValid() then
        io.stderr:write("Component " .. self.component_path .. " is not a valid Manipulator\n")
    end
end

function Manipulator:SetState(state)
    return self.component_manipulator:SetState(state)
end

function Manipulator:GetState(state)
    return self.component_manipulator:GetState(state)
end

Manipulator:Seal()

return Manipulator
