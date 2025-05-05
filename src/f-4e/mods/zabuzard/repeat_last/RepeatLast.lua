local Class = require('base.Class')
local Behavior = require('base.Behavior')
require('base.Interactions')

local RepeatLast = Class(Behavior)
RepeatLast.is_registered = false

function RepeatLast:Constructor()
	Behavior.Constructor(self)
end

function RepeatLast:Register()
	local event_name = "repeat_last"
    -- Handler
    ListenTo(event_name, "RepeatLast", function(task)
		-- Defined in overridden action/SayAction.lua
        if last_spoken_sentence then
            task:Say(last_spoken_sentence)
        else
            task:CantDo()
        end
	end)

    -- Wheel Entry
    local location = {"Crew Contract"}
    local item = Wheel.Item:new( { name = "Repeat Last", action = event_name, reaction = Wheel.Reaction.CLOSE_REMEMBER} )
    Wheel.AddItem(item, location )
end

function RepeatLast:Tick()
	if self.is_registered then
		return
	end

	self:Register()
	self.is_registered = true
end

RepeatLast:Seal()
return RepeatLast
