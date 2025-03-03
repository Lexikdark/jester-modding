local Class = require 'base.Class'

local Attributes = Class()

Attributes.perception = 0
Attributes.endurance = 0
Attributes.memory = 0
Attributes.intelligence = 0
Attributes.steadiness = 0

function Attributes:Reset()
    self.perception = 0
    self.endurance = 0
    self.memory = 0
    self.intelligence = 0
    self.steadiness = 0
end

Attributes:Seal()

return Attributes
