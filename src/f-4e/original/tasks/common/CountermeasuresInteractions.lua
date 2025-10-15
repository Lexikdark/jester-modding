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

function CountermeasuresInteractions.GetPhraseForQuantity(quantity)
    local hundreds = quantity % 1000 - quantity % 100
    local tens = quantity % 100 - quantity % 10
    local ones = quantity % 10

    local phrase_hundreds =   'Numbers/' .. Utilities.NumberToText(hundreds)
    local phrase_tens =       'Numbers/' .. Utilities.NumberToText(tens, true) -- true for misspellForty
    local phrase_ones =       'Numbers/' .. Utilities.NumberToText(ones)

    if phrase_hundreds == 'Numbers/onehundred' then
        phrase_hundreds = 'Numbers/hundred'
    end

    if quantity > 100 and quantity < 120 then
        phrase_tens = ''
        phrase_ones = 'Numbers/' .. Utilities.NumberToText(quantity - hundreds)
    end

    if quantity < 100 then
        phrase_hundreds = ''
    end

    if quantity < 20 then
        phrase_tens = ''
        phrase_ones = 'Numbers/' .. Utilities.NumberToText(quantity)
    end

    local phrase_empty = ''
    if quantity == 0 then
        phrase_empty = 'misc/negative'
        phrase_ones = ''
    end

    return phrase_empty, phrase_hundreds, phrase_tens, phrase_ones
end

function CountermeasuresInteractions.CheckQuantity(task)
    local chaff_quantity = GetJester().awareness:GetObservation("chaff_counter")
    local flare_quantity = GetJester().awareness:GetObservation("flare_counter")

    chaff_phrase_empty, chaff_phrase_hundreds, chaff_phrase_tens, chaff_phrase_ones = CountermeasuresInteractions.GetPhraseForQuantity(chaff_quantity)
    flare_phrase_empty, flare_phrase_hundreds, flare_phrase_tens, flare_phrase_ones = CountermeasuresInteractions.GetPhraseForQuantity(flare_quantity)

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
