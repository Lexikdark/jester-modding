---// Copyright (c) 2024 Heatblur Simulations. All rights reserved.

local Task = require('base.Task')
local SayTask = require('tasks.common.SayTask')
local Utilities = require('base.Utilities')
local CountermeasuresDispensing = require('behaviors.CountermeasuresDispensing')

require('base.Interactions')

local CountermeasuresInteractions = {}

function CountermeasuresInteractions.StartDispensingIfAllowed()
    if GetJester().memory:GetJesterCountermeasuresDispensingAllowed() then
        GetJester().behaviors[CountermeasuresDispensing]:StartDispensing()
    end
end

function CountermeasuresInteractions.StartDispensingChaffIfAllowed()
    if GetJester().memory:GetJesterCountermeasuresDispensingAllowed() then
        GetJester().behaviors[CountermeasuresDispensing]:StartDispensingChaff()
    end
end

function CountermeasuresInteractions.StartDispensingFlareIfAllowed()
    if GetJester().memory:GetJesterCountermeasuresDispensingAllowed() then
        GetJester().behaviors[CountermeasuresDispensing]:StartDispensingFlare()
    end
end

function CountermeasuresInteractions.FlaresJettison(task)
    return task:Click("Ripple Switch", "ON")
               :Click("Ripple Switch", "OFF", s(10), true)
end

function CountermeasuresInteractions.CheckQuantity(task)
    local chaff_quantity = GetJester().awareness:GetObservation("chaff_counter")
    local flare_quantity = GetJester().awareness:GetObservation("flare_counter")

    local chaff_phrase_empty = ''
    if chaff_quantity == 0 then
        chaff_phrase_empty = 'misc/negative'
    end
    local chaff_phrase_hundreds =   'Numbers/' .. Utilities.NumberToText(chaff_quantity % 1000 - chaff_quantity % 100)
    local chaff_phrase_tens =       'Numbers/' .. Utilities.NumberToText(chaff_quantity % 100 - chaff_quantity % 10)
    local chaff_phrase_ones =       'Numbers/' .. Utilities.NumberToText(chaff_quantity % 10)

    local flare_phrase_empty = ''
    if flare_quantity == 0 then
        flare_phrase_empty = 'misc/negative'
    end
    local flare_phrase_hundreds =   'Numbers/' .. Utilities.NumberToText(flare_quantity % 1000 - flare_quantity % 100)
    local flare_phrase_tens =       'Numbers/' .. Utilities.NumberToText(flare_quantity % 100 - flare_quantity % 10)
    local flare_phrase_ones =       'Numbers/' .. Utilities.NumberToText(flare_quantity % 10)

--     Log('CMS, chaff: ' .. tostring(chaff_quantity))
--     Log('CMS, flare: ' .. tostring(flare_quantity))

    return task
        :Say(chaff_phrase_empty)
        :Say(chaff_phrase_hundreds)
        :Say(chaff_phrase_tens)
        :Say(chaff_phrase_ones)
--         :Wait(s(1))
        :Say(flare_phrase_empty)
        :Say(flare_phrase_hundreds)
        :Say(flare_phrase_tens)
        :Say(flare_phrase_ones)
end

return CountermeasuresInteractions
