local ExampleMod = require 'ExampleMod'

-- Add your init method to mod_init, it will be invoked during launch
mod_init[#mod_init+1] = function(jester)
    jester.behaviors[ExampleMod] = ExampleMod:new()
end
