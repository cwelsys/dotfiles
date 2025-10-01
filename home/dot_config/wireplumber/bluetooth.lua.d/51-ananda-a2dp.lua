-- Don't need a mic on these boys
rule = {
  matches = {
    {
      { "device.name", "equals", "bluez_card.CC_39_8C_01_E4_FC" },
    },
  },
  apply_properties = {
    ["device.profile"] = "a2dp-sink",
  },
}

table.insert(bluez_monitor.rules, rule)
