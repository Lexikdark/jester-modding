---// Land.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

Land = Intention:new(
		{
		}
)

Land.name = "Land"

local do_not_crash = Append(Land.plans, DoNotCrash:new())