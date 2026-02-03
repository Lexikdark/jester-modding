
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Class = require 'base.Class'
local Condition = require 'base.Condition'

local RecentHardLanding = {}
RecentHardLanding.True = Class(Condition)
RecentHardLanding.False = Class(Condition)

function HadRecentHardLandingCondition()

end

function CheckHardLanding()

	--TODO if needed as a condition that expires after a while.
	--Timestamp the hard landing event and check if it's been more than 30 seconds since the last one.
	--TODO: Maybe repeated ones trigger QnA about landing tips?

end

function RecentHardLanding.True:Check()
	return HadRecentHardLandingCondition()
end

function RecentHardLanding.False:Check()
	return not HadRecentHardLandingCondition()
end

RecentHardLanding.True:Seal()
RecentHardLanding.False:Seal()
return RecentHardLanding