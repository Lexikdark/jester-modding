---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

require('base.Interactions')

local ejection_mode = {
    wso = "OFF",
    both = "ON",
}

local talking_mode = {
    silence = "OFF",
    talk = "ON",
}

ListenTo("crew_ejection", "CrewMenu", function(task, mode)
    task:Roger():Click("Ejection Command Selector", ejection_mode[mode])
end)

-- NOTE: crew_presence is handled on C++ to ensure it works even with Jester disabled

ListenTo("crew_talking", "CrewMenu", function(task, mode)
    -- Option for player (jester_voice is for mission designers)
    task:Click("Allowed to Talk", talking_mode[mode])
    if talking_mode[mode] == talking_mode.talk then
        -- Must be said after enabling voice again
        task:Roger()
    end
end)

ListenTo("jester_voice", "CrewMenu", function(task, mode)
    -- Option for mission designers (crew_talking is for players)
    task:Click("Allowed to Talk", talking_mode[mode])
end)

ListenTo("jester_start_alignment", "CrewMenu", function(task)
    GetJester().memory:SetReadyForInsAlignment(true)
    GetJester().memory:SetStartAlignmentOption(false)
    task:Roger()
end)

ListenTo("crew_countermeasures", "CrewMenu", function(task, mode)
    GetJester().memory:SetJesterCountermeasuresDispensingAllowed(mode == "jester")
    task:Roger()
end)
