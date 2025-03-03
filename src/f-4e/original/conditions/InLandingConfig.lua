
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require 'base.Class'
local Condition = require 'base.Condition'

local InLandingConfig = {}
InLandingConfig.True = Class(Condition)
InLandingConfig.False = Class(Condition)

function InLandingConfigCondition()


	--Check the landing gear indicators for 3 green.
	--local left_gear_indicator = 'Pilot Front Panel/Left Sub Panel/Left Gear Indicator'
	--local right_gear_indicator = 'Pilot Front Panel/Left Sub Panel/Right Gear Indicator'
	--local nose_gear_indicator = 'Pilot Front Panel/Left Sub Panel/Nose Gear Indicator'

	--local gear_indicator_1 = GetProperty(left_gear_indicator, 'Indicator Position').value or false
	--local gear_indicator_2 = GetProperty(right_gear_indicator, 'Indicator Position').value or false
	--local gear_indicator_3 = GetProperty(nose_gear_indicator, 'Indicator Position').value or false

	local gear_indicator_1 = GetJester().awareness:GetObservation("left_gear_indicator")
	local gear_indicator_2 = GetJester().awareness:GetObservation("right_gear_indicator")
	local gear_indicator_3 = GetJester().awareness:GetObservation("nose_gear_indicator")

	local three_green = false
	if gear_indicator_1 ~= nil and gear_indicator_2 ~= nil and gear_indicator_3 ~= nil then
		if gear_indicator_1 > 0.9 and gear_indicator_2 > 0.9 and gear_indicator_3 > 0.9 then
			three_green = true
		end
	end
	if not three_green then
		return false
	end

	local altitude = GetJester().awareness:GetObservation("barometric_altitude") or false
	if altitude > ft(4000) then
		return false
	end

	return true
end

function InLandingConfig.True:Check()
	return InLandingConfigCondition()
end

function InLandingConfig.False:Check()
	return not InLandingConfigCondition()
end

InLandingConfig.True:Seal()
InLandingConfig.False:Seal()
return InLandingConfig
