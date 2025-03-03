---// SayRandomAction.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.
---
local Class = require('base.Class')
local SayAction = require('actions.SayAction')

local SayRandomAction = Class(SayAction)

-- Pairs list contains the sentence and it's probability in each pair, like this: {{sentence_1, probability_1}, {sentence_2, probability_2}, ...etc}
function SayRandomAction:Constructor( calls_list )

	local random = percent(Dice.new(100):Roll())
	local probability_sum = percent(0)
	local last_phrase = nil
	local constructed = false

	for i, call_pair in ipairs(calls_list) do
		local phrase = call_pair[1]
		last_phrase = phrase
		local probability = call_pair[2]

		probability_sum = probability_sum + probability
		if random < probability_sum then
			SayAction.Constructor(self, phrase)
			constructed = true
			break
		end
	end

	if not constructed then
		SayAction.Constructor(self, last_phrase) --just for safety, shouldn't get here if the sum of probability is 100%
	end

end

local mt = getmetatable(SayRandomAction)
mt.__call = function(self,...)
	return self:new(...)
end


SayRandomAction:Seal()
return SayRandomAction
