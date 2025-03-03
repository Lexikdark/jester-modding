---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require('base.Class')
local Math = require('base.Math')
local SayAction = require('actions.SayAction')
local Task = require('base.Task')

local SaySteering = Class(Task)

function SaySteering:Constructor(steering_body_vector)
	Task.Constructor(self)
	local on_activation = function()
		self:RemoveAllActions()

		local steering = steering_body_vector:ConvertTo(m)

		if steering:GetLength() < m(1) then
			-- Too close to comment
			return
		end

		local x = steering.x -- Forward/Aft
		local y = steering.y -- Right/Left
		local z = steering.z -- Down/Up
		local absX = Math.Abs(x)
		local absY = Math.Abs(y)
		local absZ = Math.Abs(z)

		-- Choose biggest steering axis
		local direction = "aft"
		if absX > absY and absX > absZ then
			if x < m(0) then
				direction = "aft"
			else
				direction = "forward"
			end
		elseif absY > absX and absY > absZ then
			if y < m(0) then
				direction = "left"
			else
				direction = "right"
			end
		else
			if z < m(0) then
				direction = "up"
			else
				direction = "down"
			end
		end

		local prefix = ""
		if steering:GetLength() < m(3) then
			prefix = "abit"
		else
			prefix = "move"
		end

		local phrase = "misc/" .. prefix .. direction
		self:AddAction(SayAction(phrase))
	end
	self:AddOnActivationCallback(on_activation)
end

SaySteering:Seal()
return SaySteering
