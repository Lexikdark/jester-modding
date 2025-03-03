---// ReportIAS.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require('base.Class')
local Behavior = require('base.Behavior')
local Math = require('base.Math')
local Urge = require('base.Urge')
local SaySpeed = require('tasks.common.SaySpeed')
local StressReaction = require('base.StressReaction')

local ReportIAS = Class(Behavior)
ReportIAS.last_ias_reported = nil

local default_report_ias_interval = s(10)

function ReportIAS:Constructor()
	Behavior.Constructor(self)

	local say_speed_task_creator = function ()
		if self.ias_property and self.ias_property:IsValid() then
			local jester = GetJester()
			self.last_ias_reported = self.ias_property.value
			local say_speed_task = SaySpeed:new(self.last_ias_reported)
			jester:AddTask(say_speed_task)
			return {say_speed_task}
		else
			io.stderr:write("ReportIAS IAS property invalid\n")
		end
	end

	self.report_ias_urge = Urge:new(
			{
				time_to_release = default_report_ias_interval,
				on_release_function = say_speed_task_creator,
				stress_reaction = StressReaction.ignorance,
			})
	self.report_ias_urge:Restart()
end

function ReportIAS:SetIASProperty(property)
	self.ias_property = property
end

function ReportIAS:Tick()
	if self.report_ias_urge then
		if self.last_ias_reported and self.ias_property and self.ias_property:IsValid() then
			local ias_delta = Math.Abs(self.ias_property.value - self.last_ias_reported):ConvertTo(kt)
			local ias_delta_factor = Math.Clamp(Math.Lerp(1, 10, kt(30), kt(300), ias_delta), 0.25, 10)
			if self.ias_property.value < kt(250) then
				ias_delta_factor = 2 * ias_delta_factor
			end
			self.report_ias_urge:SetGainRateMultiplier(ias_delta_factor)
		end

		self.report_ias_urge:Tick()
	end
end

ReportIAS:Seal()
return ReportIAS
