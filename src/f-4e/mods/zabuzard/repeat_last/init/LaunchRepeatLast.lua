local RepeatLast = require 'RepeatLast'

mod_init[#mod_init+1] = function(jester)
    -- Idea by user generic_luke, thanks
    jester.behaviors[RepeatLast] = RepeatLast:new()
end