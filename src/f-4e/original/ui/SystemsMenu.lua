---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

require('base.Interactions')
local CountermeasuresInteractions = require('tasks.common.CountermeasuresInteractions')

local chaff_mode = {
    off = "OFF",
    single = "SGL",
    multiple = "MULT",
    program = "PROG",
}

local flare_mode = {
    off = "OFF",
    single = "SGL",
    program = "PROG",
}

local jammer_mode = {
    standby = "STBY",
    xmit = "BOTH",
}

local avtr_mode = {
    off = "OFF",
    standby = "STANDBY",
    record = "RECORD",
}

ListenTo("systems_chaff", "SystemsMenu", function(task, mode)
    task:Roger():Click("Chaff Mode", chaff_mode[mode])
end)

ListenTo("systems_flare", "SystemsMenu", function(task, mode)
    task:Roger():Click("Flare Mode", flare_mode[mode])
end)

ListenTo("systems_jammer", "SystemsMenu", function(task, mode)
    task:Roger()
        :Click("ECM Mode Left", jammer_mode[mode])
        :Click("ECM Mode Right", jammer_mode[mode])
end)

ListenTo("systems_avtr_recorder", "SystemsMenu", function(task, mode)
    task:Roger():Click("AVTR Mode", avtr_mode[mode])
end)

ListenTo("systems_flares_jettison", "SystemsMenu", function(task)
    task:Roger()
    CountermeasuresInteractions.FlaresJettison(task)
end)

ListenTo("systems_countermeasures_quantity", "SystemsMenu", function(task)
    CountermeasuresInteractions.CheckQuantity(task)
end)
