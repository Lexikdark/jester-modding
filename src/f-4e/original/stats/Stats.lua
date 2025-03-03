local Class = require 'base.Class'
local Attributes = require 'stats.Attributes'

local Stats = Class()
--local Stats = Class {
--    attributes = Attributes:new()
--}
Stats.attributes = Attributes:new()
Stats.attributes.base = Attributes:new()
Stats.attributes.modifiers = Attributes:new()

function Stats:ClearModifiers()
    self.attributes.modifiers:Reset()
end

function Stats:GetReactionTimeModifier()
    return Real:new(1)
end

Stats:Seal()

return Stats
