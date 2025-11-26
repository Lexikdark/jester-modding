
require 'base.Jester'
local Class = require 'base.Class'
local Phrase = require 'voice.Phrase'
local SixthSense = require 'senses.SixthSense'
local Dogfight = require 'situations.NFO.Dogfight'
local StayAirborne = require 'intentions.StayAirborne'
local HighAltitudeFlight = require 'situations.HighAltitudeFlight'
--local TakeoffRoll = require 'situations.TakeoffRoll'
local FlightMSFS = require 'situations.FlightMSFS'
local FuelDumping = require 'situations.FuelDumping'
local AAR = require 'situations.AAR'
local Bombing = require 'situations.Bombing'
local InAircraft = require 'situations.InAircraft'
local F_4E_WSO_Cockpit = require 'cockpit.F_4E_WSO_Cockpit'
local Landing = require 'situations.Landing'
local TakeOff = require 'situations.TakeOff'
local Taxiing = require 'situations.Taxiing'
local StartUp = require 'situations.StartUp'
local GroundOperations = require 'situations.GroundOperations'
local GroundPowerConnected = require 'situations.GroundPowerConnected'
local AircraftCold = require 'situations.AircraftCold'
local PowerOnAndOnGround = require 'situations.PowerOnAndOnGround'
local PostTakeoff = require 'situations.PostTakeoff'
local AlignmentRestart = require 'situations.AlignmentReset'
local EngineMasterSwitchesOn = require 'situations.EngineMasterSwitchesOn'
local DoAlways = require 'situations.DoAlways'

F_4E_MSFS_WSO_Jester = Class(Jester)

function CreateF4EMSFSWSOJester ( )
    local wso = F_4E_MSFS_WSO_Jester:new()
    local Task = require 'base.Task'
    local Action = require 'base.Action'
    local DelayAction = require 'actions.DelayAction'
    local SayAction = require 'actions.SayAction'
    wso:SetCockpit(F_4E_WSO_Cockpit:new())
    wso:SetCockpitPosition(m(5.10364), m(0), m(-0.77765))
    wso:SetHeadPosition(m(3.65), m(0), m(-1.1))

    --local test_say_task = Task:new()
    --test_say_task.name = 'Test task'
    --test_say_task:AddAction(DelayAction(s(3)))
    --test_say_task:AddAction(SayAction('phrases/PigsInSpace'))
    --wso:AddTask(test_say_task)
    wso:AddIntentions(StayAirborne:new())
--     wso:AddSituations(Dogfight:new())
    wso:AddSituations(HighAltitudeFlight:new())
    wso:AddSituations(FlightMSFS:new())
    wso:AddSituations(FuelDumping:new())
--     wso:AddSituations(AAR:new())
--     wso:AddSituations(Bombing:new())
    wso:AddSituations(InAircraft:new())
    wso:AddSituations(Landing:new())
    wso:AddSituations(TakeOff:new())
    wso:AddSituations(Taxiing:new())
    wso:AddSituations(StartUp:new())
    wso:AddSituations(GroundOperations:new())
    wso:AddSituations(GroundPowerConnected:new())
    wso:AddSituations(AircraftCold:new())
    wso:AddSituations(PowerOnAndOnGround:new())
    wso:AddSituations(PostTakeoff:new())
    wso:AddSituations(AlignmentRestart:new())
    wso:AddSituations(EngineMasterSwitchesOn:new())
    wso:AddSituations(DoAlways:new())
    --wso:AddSituation(OnFinal:new())

    -- Loading user mods who registered a callback at mod_init
    for _, callback in pairs(mod_init) do
        callback(wso)
    end

    return wso
end

RegisterJesterFactory( "F-4E MSFS WSO", CreateF4EMSFSWSOJester )
