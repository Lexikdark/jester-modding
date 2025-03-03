---// Copyright (c) 2024 Heatblur Simulations. All rights reserved.
---
local Class = require('base.Class')
local Task = require('base.Task')

local CapTimeDialog = Class(Task)

function CapTimeDialog:Constructor()
	Task.Constructor(self)

	local on_activation = function()
		self:RemoveAllActions()

		local question = Dialog.Question:new({
			name = "Jester",
			content = "How long do we want to stay on CAP station?",
			phrase = "misc/caphowlong",
			label = "CAP time",
			timing = Dialog.Timing:new({
				question = s(45),
				action = s(30),
			}),
			options = {
				Dialog.Option:new({
					response = "15 min",
					action = "cap_15min",
				}),
				Dialog.Option:new({
					response = "30 min",
					action = "cap_30min",
				}),
				Dialog.Option:new({
					response = "45 min",
					action = "cap_45min",
				}),
				Dialog.Option:new({
					response = "60 min",
					action = "cap_60min",
				}),
			},
		})
		Dialog.Push(question)
	end

	self:AddOnActivationCallback(on_activation)
end

-- Listen To functions inside Navigate

CapTimeDialog:Seal()
return CapTimeDialog