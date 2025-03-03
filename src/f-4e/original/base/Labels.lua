---// MemoryObjectLabels.lua
---// Copyright (c) 2023 Heatblur Simulations. All rights reserved.

local Labels = {}

local function AddLabel(label)
	Labels[label] = label
end

AddLabel("friendly")
AddLabel("neutral")
AddLabel("hostile")

AddLabel("mission_critical")

AddLabel("dead")

AddLabel("civilian")

AddLabel("aircraft")
AddLabel("surface_vehicle")
AddLabel("missile")

AddLabel("airplane")
AddLabel("helicopter")

AddLabel("visual")
AddLabel("from_radar")
AddLabel("from_rwr")
AddLabel("from_tgp")
AddLabel("from_radio")
AddLabel("from_crew")
AddLabel("from_datalink")

AddLabel("fighter")
AddLabel("bomber")
AddLabel("attack")
AddLabel("trainer")
AddLabel("tanker")
AddLabel("AWACS")
AddLabel("general_aviation")
AddLabel("airliner")
AddLabel("transport_helicopter")
AddLabel("attack_helicopter")
AddLabel("recon_helicopter")

AddLabel("airborne")

return Labels
