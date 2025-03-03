---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

require('base.Interactions')
local RadarApi = require('radar.Api')

local radar_op_mode = {
    active = "ready",
    standby = "standby"
}

ListenTo("radar_op", "RadarMenu", function(task, mode)
    task:Roger()
    RadarApi.SetOperatingMode(task, radar_op_mode[mode])
end)
