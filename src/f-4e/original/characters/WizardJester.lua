require 'base.Jester'
local Airborne = require 'conditions.Airborne'
local Awareness = require 'memory.Awareness'
local Class = require 'base.Class'
-- local FinalApproach = require 'situations.FinalApproach'
-- local TakeoffRoll = require 'situations.TakeoffRoll'
local Dogfight = require 'situations.NFO.Dogfight'
local Labels = require 'base.Labels'
local Math = require 'base.Math'
local Phrase = require 'voice.Phrase'
local Sentence = require 'voice.Sentence'
local SixthSense = require 'senses.SixthSense'
local Utilities = require 'base.Utilities'
local Condition = require 'base.Condition'

-- This is a test class for trying out the Jester LUA interface. It is executed during startup.
-- Also, it can be executed without DCS using the 'HeatblurJester_Test' run configuration.
WizardJester = Class(Jester)

function WizardJester:Tick()
    Jester.Tick(self)
    print("Total contacts: ", #self.awareness.contacts)
    for i, v in ipairs(self.awareness.contacts) do
        print("Contact ", i, ": ", v.true_id, " labels: " )
        for k, l in pairs(v.is.labels) do
            print( ".  ", k, ": ", l )
        end
    end
    print("Total number or air threats: ", self.awareness:GetNumberOfAirThreats())
    print("Total number or wvr air threats: ", self.awareness:GetNumberOfWVRAirThreats())
end

function MakeWizardJester( )
    local wizard = WizardJester:new()
    wizard:AddSituations(Dogfight:new())
    -- wizard:AddSituations(FinalApproach:new())
    -- wizard:AddSituations(TakeoffRoll:new())
    print("Hello world, I'm Wizard Jester!")
    feet = Unit.new("ft")
    print(feet)
    print("Valid: " .. tostring(feet:IsValid()) .. ", SI: " .. tostring(feet:IsSI()))
    local speed = mps(200)
    print(speed)
    print(speed:ConvertTo(Unit.new("mph")))
    print(speed:ConvertTo("kmph"))
    local speed_kt = speed:ConvertTo(kt)
    print(speed_kt)
    print(speed_kt:ConvertToSI())
    local velocity = BodyVector.new(2, 4, 6, mps)
    print(velocity)
    velocity.x = kt(10)
    print(velocity)
    local other_velocity = Vector(coords.Body, mps(10), mps(20), mps(30))
    print(other_velocity)
    other_velocity = Vector(coords.Body, mps(10), mps(20), mps(30), kt)
    print(other_velocity)
    local angular_velocity = PseudoVector(coords.Body, 1, 2, 3, degps)
    print(angular_velocity)
    wizard:SetHeadPosition(m(1), m(2), m(3))
    print( "Head position: " )
    print( wizard:GetHeadPosition() )
    print( "Memory: " ..  tostring( wizard.stats.attributes.memory ) )
    wizard.stats.attributes:Reset()
    print( "Memory: " ..  tostring( wizard.stats.attributes.memory ) )
    local airborne = Airborne.True:new()
    print( "Flying: " .. tostring(airborne:Check()) )
    print( "Mission time: " .. tostring(Utilities.GetTime().mission_time))
    return wizard
end

print(tostring(Sentence('spotting/heis', 'spotting/fiveoclockhigh')))
local speed = Phrase('Numbers/threehundred') .. Phrase('misc/knots')
print(tostring(speed))
--speed:Say()
print("10 degrees ->", Utilities.AngleToOClock(deg(10)), "o'clock")
print("40 degrees ->", Utilities.AngleToOClock(deg(40)), "o'clock")
print("270 degrees ->", Utilities.AngleToOClock(deg(270)), "o'clock")
print("180 degrees ->", Utilities.AngleToOClock(rad(3.14)), "o'clock")
print("6.5 wrap 2", Math.Wrap(6.5, 2))
print("-6.5 wrap 2", Math.Wrap(-6.5, 2))
print("6.5 deg wrap 2 deg", Math.Wrap(deg(6.5), deg(2)))
print("0.0256 m wrap 1 inch", Math.Wrap(m(0.0256), inch(1)))
print("373 deg wrap 360", Math.Wrap360(deg(373)))
print("353 deg wrap 180", Math.Wrap180(deg(353)))

local multi = s(8) * percent(20)
print("8 s * 20 % == ", multi)

local nd = NormalDistribution.new(5.0, 1.0, s)
print(nd)
print("Normal distribution generation result: ", nd())
local ud = UniformDistribution.new(5.0, 8.0, ft)
print(ud)
print("Uniform distribution generation result: ", nd())

local d6 = Dice.new(6)
print("Dice:", d6, "roll:", d6:Roll(), d6:Roll(), d6:Roll(), d6:Roll())

local d7 = Dice.new(-10, 10)
print("Dice:", d7, "roll:", d7:Roll(), d7:Roll(), d7:Roll(), d7:Roll())

print('3 ->', Utilities.NumberToText(3))
print('10 ->', Utilities.NumberToText(10))
print('12 ->', Utilities.NumberToText(12))
print('20 ->', Utilities.NumberToText(20))
print('99 ->', Utilities.NumberToText(99))
print('100 ->', Utilities.NumberToText(100))
print('111 ->', Utilities.NumberToText(111))
print('777 ->', Utilities.NumberToText(777))
print('1234 ->', Utilities.NumberToText(1234))
print('3000 ->', Utilities.NumberToText(3000))
print('70001 ->', Utilities.NumberToText(70001))
print('0 ->', Utilities.NumberToText(0))

print('247 kt rounded to 10 kt ==', Math.RoundTo(kt(247), kt(10)))

local wheel_item_1 = Wheel.Item.new()
local wheel_item_2 = Wheel.Item:new()
local wheel_item_3 = Wheel.Item.new({
    name = "wheel 3",
    category = Wheel.Category.NAVIGATION,
    reaction = Wheel.Reaction.CLOSE_REMEMBER,
})
assert(wheel_item_3.name == "wheel 3")
assert(wheel_item_3.category == Wheel.Category.NAVIGATION)
assert(wheel_item_3.reaction == Wheel.Reaction.CLOSE_REMEMBER)

local wheel_item_4 = Wheel.Item:new({
    name = "wheel 4",
    category = Wheel.Category.DEFENSIVE,
    reaction = Wheel.Reaction.CLOSE_TO_MAIN_MENU,
})
assert(wheel_item_4.name == "wheel 4")
assert(wheel_item_4.category == Wheel.Category.DEFENSIVE)
assert(wheel_item_4.reaction == Wheel.Reaction.CLOSE_TO_MAIN_MENU)

local menu = Wheel.Menu:new({
  name = "Outer Menu",
  items = {
      Wheel.Item:new({
          name = "Item 1",
          action = "outer",
      }),
      Wheel.Item:new({
          name = "Item 2",
          outer_menu = Wheel.Menu:new({
              name = "Inner Menu",
              items = {
                  Wheel.Item:new({
                      name = "Inner Item",
                      action = "inner",
                  }),
              },
          }),
      }),
  },
})

assert(menu.name == "Outer Menu")
assert(#menu.items == 2)
assert(menu.items[1].name == "Item 1")
assert(menu.items[1].action == "outer")
assert(menu.items[2].name == "Item 2")
assert(menu.items[2].outer_menu.name == "Inner Menu")
assert(menu.items[2].outer_menu.items[1].name == "Inner Item")

local dialog = Dialog.Question:new({
    name = "Jester",
    content = "We are Bingo fuel, how do you want to proceed?",
    phrase = "dialog/bingo",
    label = "Joker",
    timing = Dialog.Timing:new({
        question = s(15),
        action = s(10),
    }),
    options = {
        Dialog.Option:new({
            response = "Remain on Mission",
            action = "bingo_remain_on_mission",
        }),
        Dialog.Option:new({
            response = "Abort mission, RTB",
            action = "bingo_abort_mission",
        }),
        Dialog.Option:new({
            response = "RTB for rearm and refuel",
            action = "bingo_rtb_rearm",
        }),
        Dialog.Option:new({
            response = "Rejoin with Tanker",
            follow_up_question = Dialog.FollowUpQuestion:new({
                name = "Jester",
                content = "Which tanker you want to rejoin with?",
                phrase = "dialog/tanker_rejoin",
                options = {
                    Dialog.Option:new({
                        response = "Tanker 1",
                        action = "bingo_rejoin_tanker_1",
                    }),
                    Dialog.Option:new({
                        response = "Tanker 2",
                        action = "bingo_rejoin_tanker_2",
                    }),
                    Dialog.Option:new({
                        response = "Tanker 3",
                        action = "bingo_rejoin_tanker_3",
                    }),
                    Dialog.Option:new({
                        response = "Tanker 4",
                        action = "bingo_rejoin_tanker_4",
                    }),
                },
            }),
        }),
    }
})

assert(dialog.name == "Jester")
assert(dialog.timing.question == s(15))
assert(#dialog.options == 4)
assert(dialog.options[1].response == "Remain on Mission")
assert(dialog.options[4].follow_up_question.phrase == "dialog/tanker_rejoin")
assert(dialog.options[4].follow_up_question.options[4].response == "Tanker 4")

local refuel_pos = Vector(coords.Body, 23, 0, -8, m)
print("pos: ", refuel_pos)

local condition_counter = 1
local Condition1 = Class(Condition)
function Condition1:Check()
    local state = condition_counter > 1
    print("Condition 1 state", state)
    return state
end
Condition1:Seal()

local Condition2 = Class(Condition)
function Condition2:Check()
    local state = condition_counter > 2
    print("Condition 2 state", state)
    return state
end
Condition2:Seal()

local conditions_and = Condition1:And(Condition2)
local conditions_or = Condition1:Or(Condition2)
print( "Conditions 1 check   AND:", conditions_and:Check(), " OR:", conditions_or:Check())
condition_counter = 2
print( "Conditions 2 check   AND:", conditions_and:Check(), " OR:", conditions_or:Check())
condition_counter = 3
print( "Conditions 3 check   AND:", conditions_and:Check(), " OR:", conditions_or:Check())

RegisterJesterFactory("Wizard Jester", MakeWizardJester)
