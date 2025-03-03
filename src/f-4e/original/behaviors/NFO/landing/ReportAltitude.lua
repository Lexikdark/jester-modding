

---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require('base.Class')
local Behavior = require('base.Behavior')
local Math = require('base.Math')
local SayApproachAltitude = require('tasks.common.SayApproachAltitude')
local Utilities = require('base.Utilities')
local Awareness = require('memory.Awareness')

local ReportAltitude = Class(Behavior)

local last_call_threshold_time = s(45)
local altitude_margin = ft(25)

function ReportAltitude:Constructor()
    Behavior.Constructor(self)
    self.last_called_1000_time = -s(1000)
    self.last_called_500_time = -s(1000)
    self.last_called_400_time = -s(1000)
    self.last_called_300_time = -s(1000)
    self.last_called_200_time = -s(1000)
    self.last_called_100_time = -s(1000)
    self.last_called_50_time = -s(1000)
    self.last_called_30_time = -s(1000)
    self.last_called_10_time = -s(1000)

    local say_altitude_task_creator = function ( altitude )
        local jester = GetJester()
        local say_altitude_task = SayApproachAltitude:new( altitude )
        jester:AddTask(say_altitude_task)
        return {say_altitude_task}
    end

    self.say_altitude_task_creator = say_altitude_task_creator
end

function ReportAltitude:SetAltitudeProperty( property )
    self.altitude_property = property
end

function ReportAltitude:Tick()

    local altitude_relative = GetJester().awareness:GetObservation("height_above_airfield"):ConvertTo(ft)
    local in_approach_cone = GetJester().awareness:GetObservation("in_approach_cone")
    --local distance_to_airport = GetJester().awareness:GetObservation("distance_to_nearest_airfield")

    local current_time = Utilities.GetTime().mission_time:ConvertTo(s);

    if in_approach_cone then
        if altitude_relative < ( SayApproachAltitude.thousand_ft + altitude_margin ) and
                altitude_relative > ( SayApproachAltitude.thousand_ft - altitude_margin ) and
                (current_time - self.last_called_1000_time) > last_call_threshold_time then
            self.say_altitude_task_creator( SayApproachAltitude.thousand_ft )
            self.last_called_1000_time = current_time

        elseif altitude_relative < ( SayApproachAltitude.five_hundred_ft + altitude_margin ) and
                altitude_relative > ( SayApproachAltitude.five_hundred_ft - altitude_margin ) and
                (current_time - self.last_called_500_time) > last_call_threshold_time then
            self.say_altitude_task_creator( SayApproachAltitude.five_hundred_ft )
            self.last_called_1000_time = current_time
            self.last_called_500_time = current_time

            --[[
        elseif altitude_relative < ( SayApproachAltitude.four_hundred_ft + altitude_margin ) and
                altitude_relative > ( SayApproachAltitude.four_hundred_ft - altitude_margin ) and
                (current_time - self.last_called_400_time) > last_call_threshold_time then
            self.say_altitude_task_creator( SayApproachAltitude.four_hundred_ft )
            self.last_called_1000_time = current_time
            self.last_called_500_time = current_time
            self.last_called_400_time = current_time --]]

        elseif altitude_relative < ( SayApproachAltitude.three_hundred_ft + altitude_margin ) and
                altitude_relative > ( SayApproachAltitude.three_hundred_ft - altitude_margin ) and
                (current_time - self.last_called_300_time) > last_call_threshold_time then
            self.say_altitude_task_creator( SayApproachAltitude.three_hundred_ft )
            self.last_called_1000_time = current_time
            self.last_called_500_time = current_time
            self.last_called_400_time = current_time
            self.last_called_300_time = current_time

            --[[
        elseif altitude_relative < ( SayApproachAltitude.two_hundred_ft + altitude_margin ) and
                altitude_relative > ( SayApproachAltitude.two_hundred_ft - altitude_margin ) and
                (current_time - self.last_called_200_time) > last_call_threshold_time then
            self.say_altitude_task_creator( SayApproachAltitude.two_hundred_ft )
            self.last_called_1000_time = current_time
            self.last_called_500_time = current_time
            self.last_called_400_time = current_time
            self.last_called_300_time = current_time
            self.last_called_200_time = current_time --]]

        elseif altitude_relative < ( SayApproachAltitude.one_hundred_ft + altitude_margin ) and
                altitude_relative > ( SayApproachAltitude.one_hundred_ft - altitude_margin ) and
                (current_time - self.last_called_100_time) > last_call_threshold_time then
            self.say_altitude_task_creator( SayApproachAltitude.one_hundred_ft )
            self.last_called_1000_time = current_time
            self.last_called_500_time = current_time
            self.last_called_400_time = current_time
            self.last_called_300_time = current_time
            self.last_called_200_time = current_time
            self.last_called_100_time = current_time

            --[[
	  elseif altitude_relative < ( SayApproachAltitude.fifty_ft + altitude_margin ) and
			  altitude_relative > ( SayApproachAltitude.fifty_ft - altitude_margin ) and
			  (current_time - self.last_called_50_time) > last_call_threshold_time then
		  self.say_altitude_task_creator( SayApproachAltitude.fifty_ft )
		  self.last_called_1000_time = current_time
		  self.last_called_500_time = current_time
		  self.last_called_400_time = current_time
		  self.last_called_300_time = current_time
		  self.last_called_200_time = current_time
		  self.last_called_100_time = current_time
		  self.last_called_50_time = current_time

	  elseif altitude_relative < ( SayApproachAltitude.thirty_ft + altitude_margin ) and
			  altitude_relative > ( SayApproachAltitude.thirty_ft - altitude_margin ) and
			  (current_time - self.last_called_30_time) > last_call_threshold_time then
		  self.say_altitude_task_creator( SayApproachAltitude.thirty_ft )
		  self.last_called_1000_time = current_time
		  self.last_called_500_time = current_time
		  self.last_called_400_time = current_time
		  self.last_called_300_time = current_time
		  self.last_called_200_time = current_time
		  self.last_called_100_time = current_time
		  self.last_called_50_time = current_time
		  self.last_called_30_time = current_time

	  elseif altitude_relative < ( SayApproachAltitude.ten_ft + altitude_margin ) and
			  altitude_relative > ( SayApproachAltitude.ten_ft - altitude_margin ) and
			  (current_time - self.last_called_10_time) > last_call_threshold_time then
		  self.say_altitude_task_creator( SayApproachAltitude.ten_ft )
		  self.last_called_1000_time = current_time
		  self.last_called_500_time = current_time
		  self.last_called_400_time = current_time
		  self.last_called_300_time = current_time
		  self.last_called_200_time = current_time
		  self.last_called_100_time = current_time
		  self.last_called_50_time = current_time
		  self.last_called_30_time = current_time
		  self.last_called_10_time = current_time --]]
        end
    end

end

ReportAltitude:Seal()
return ReportAltitude
