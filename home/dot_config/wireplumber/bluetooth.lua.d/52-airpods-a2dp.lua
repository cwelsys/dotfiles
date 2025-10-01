-- Force AirPods Pro to use A2DP profile (headphones only, no mic)
rule = {
  matches = {
    {
      { "device.name", "equals", "bluez_card.10_CF_0F_F1_40_2D" },
    },
  },
  apply_properties = {
    ["device.profile"] = "a2dp-sink",
  },
}

table.insert(bluez_monitor.rules, rule)
