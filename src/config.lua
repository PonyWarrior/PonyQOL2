local config = {
	Enabled = true,
	AllUnlockedToolsUsable = {
		-- Enable to be able to use any tool you've unlocked to harvest resources
		-- Doesn't do anything since patch 1
		Enabled = false
	},
	AlwaysEncounterStoryRooms = {
		-- Enable to always encounter story rooms during your runs
		Enabled = true
	},
	GodMode =
	{
		-- Enable to set a fixed damage resistance value for god mode
		Enabled = false,
		FixedValue = 0.2, -- Percentage of damage resistance; 0 = 0%, 0.5 = 50%, 1.0 = 100%
	},
	UltraWide =
	{
		-- Enable to always disable pillarboxing on ultrawide resolutions
		Enabled = false
	},
	BossNumericHealth = {
		-- Enable to see the numeric health of bosses
		Enabled = true
	},
	QuitAnywhere = {
		--Enable to be able to Quit anywhere and anytime
		Enabled = true
	}
}
PonyQOL2.Config = config
return config