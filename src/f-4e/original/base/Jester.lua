local Awareness = require 'memory.Awareness'
local Class = require 'base.Class'
local EarsMk1 = require 'senses.EarsMk1'
local EyeballsMk1 = require 'senses.EyeballsMk1'
local Memory = require 'memory.Memory'
local SixthSense = require 'senses.SixthSense'
local Stats = require 'stats.Stats'
local TaskPool = require 'base.TaskPool'
local Timer = require 'base.Timer'
local Voice = require 'voice.Voice'

jester_factories = {}

function RegisterJesterFactory(name, factory)
    if jester_factories[name] ~= nil then
        error( 'Jester factory ' .. name .. ' already exists' )
    end
    print("Adding factory ".. name)
    jester_factories[name] = factory
end

Jester = Class()

Jester.cockpit = nil
Jester.senses = {}
Jester.stats = Stats:new()
Jester.situations = {}
Jester.behaviors = {}
Jester.intentions = {}
Jester.plans = {}
Jester.awareness = Awareness:new()
Jester.memory = Memory:new()
Jester.voice = Voice:new()
Jester.tasks = {}
Jester.current_task = nil

function Jester.__pairs(tbl)
    local function stateless_iter(tbl, k)
        local ktmp, v
        if k == nil or rawget(tbl, k) then
            ktmp, v = next(tbl, k)
            if nil~=v then
                return ktmp, v
            else
                local meta = getmetatable(tbl)
                if meta~=nil and meta.__index~=nil then
                    return stateless_iter(meta, nil)
                end
            end
        else
            local meta = getmetatable(tbl)
            if meta~=nil and meta.__index~=nil then
                return stateless_iter(meta, k)
            end
        end
    end

    return stateless_iter, tbl, nil
end

function Jester:Constructor()
    jester = self
    self.task_pool = TaskPool:new(self.tasks)
end

function Jester:SetCockpit(cockpit)
    self.cockpit = cockpit
end

function Jester:GetCockpit()
    return self.cockpit
end

function Jester:AddSense(name, sense)
    local sense_entry = {name=name, sense=sense}
    self.senses[#self.senses+1] = sense_entry
end

function Jester:AddTask(task)
    table.insert(self.tasks, task)
end

local function TickIntentions(jester)
    for _, v in pairs(jester.intentions) do
        v:CheckConditions()
        if v:IsActive() and v.Tick then
            v:Tick()
        end
    end
end

local function TickPlans(jester)
    for _, plan in pairs(jester.plans) do
        if plan.Tick then
            plan:Tick()
        end
    end
end

local function TickSituations(jester)
    for _, v in pairs(jester.situations) do
        v:CheckConditions()
        if v:IsActive() and v.Tick then
            v:Tick()
        end
    end
end

local function TickBehaviors(jester)
    for _, res in pairs(jester.behaviors) do
        if res.Tick then
            res:Tick()
        end
    end
end

local function TickSenses(jester)
    for i, v in pairs(jester.senses) do
        local sense = v.sense
        if sense.Tick then
            sense:Tick()
            for _, contact in pairs(sense.contacts) do
                jester.awareness:AddOrUpdateContact(contact)
            end
        end
        if sense.UpdateAwareness then
            sense:UpdateAwareness(jester.awareness)
        end
    end
end

local function TickAwareness(jester)
    jester.awareness:Tick()
end

local function TickMemory(jester)
    jester.memory:Tick()
end

local function TickTasks(jester)
    if #jester.tasks == 0 then
        return
    end
    table.sort(jester.tasks, function(a, b) return a.priority > b.priority end)
    jester.task_pool:Tick()
end


function Jester:Tick()
    Timer.Tick()

    self.stats:ClearModifiers()

    TickSenses(self)
    if self.cockpit then
        self.cockpit:Tick()
    end
    TickAwareness(self)
    TickIntentions(self)
    TickPlans(self)
    TickSituations(self)
    TickBehaviors(self)
    TickTasks(self)
    TickMemory(self)
end

function Jester:TickVoice()
    self.voice:Tick()
end

function Jester:SetHeadPosition(...)
    jester_c:SetHeadPosition(...)
end

function Jester:GetHeadPosition()
    return jester_c:GetHeadPosition()
end

function Jester:SetHeadRotation(...)
    jester_c:SetHeadRotation(...)
end

function Jester:GetHeadRotation()
    return jester_c:GetHeadRotation()
end

function Jester:SetCockpitPosition(...)
    jester_c:SetCockpitPosition(...)
end

Jester:AddSense("Eyeballs", EyeballsMk1:new())
Jester:AddSense("Ears", EarsMk1:new())
Jester:AddSense("Sixth Sense", SixthSense:new())

function Jester:GetEyeballs()
    return self.senses[1].sense
end

function Jester:GetEars()
    return self.senses[2].sense
end

function Jester:GetSixthSense()
    return self.senses[3].sense
end

function Jester:AddSituations(...)
    local situations_list = {...}
    print("Using AddSituations(...) is slightly deprecated. Consider adding situations through higher level brain nodes: Intentions and Plans.")
    for _, v in ipairs(situations_list) do
        table.insert(self.situations, v)
    end
end

function Jester:AddIntentions(...)
    local intentions_list = {...}
    for _, v in ipairs(intentions_list) do
        table.insert(self.intentions, v)
    end
end

Jester:Seal()

return Jester
