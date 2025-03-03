---// DoNotCrash.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require('base.Class')
local Plan = require('base.Plan')

local DoNotCrash = Class(Plan)

function DoNotCrash:Constructor()
	Plan.Constructor(self)
end

function DoNotCrash:Tick()

end

DoNotCrash:Seal()
return DoNotCrash
