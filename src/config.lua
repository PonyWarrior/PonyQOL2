---@meta PonyWarrior-PonyQOL2-config
local config = {
	enabled = true,
	AlwaysEncounterStoryRooms = {
		Enabled = true
	},
	GodMode =
	{
		Enabled = false,
		FixedValue = 0.2,
	},
	UltraWide =
	{
		Enabled = false
	},
	BossNumericHealth = {
		Enabled = true
	},
	QuitAnywhere = {
		Enabled = true
	},
	ProximityIndicator = {
		Enabled = true,
	},
	SprintHitbox = {
		Enabled = true,
	},
	ChronosPause = {
		Enabled = false
	},
}

local description = {
	enabled = "Set to true to enable the mod, set to false to disable it.",
	AlwaysEncounterStoryRooms = {
		Enabled = "Enable to always encounter story rooms during your runs"
	},
	GodMode =
	{
		Enabled = "Enable to set a fixed damage resistance value for god mode",
		FixedValue = "Percentage of damage resistance; 0 = 0%, 0.5 = 50%, 1.0 = 100%",
	},
	UltraWide =
	{
		Enabled = "Enable to always disable pillarboxing on ultrawide resolutions"
	},
	BossNumericHealth = {
		Enabled = "Enable to see the numeric health display of bosses"
	},
	QuitAnywhere = {
		Enabled = "Enable to be able to Quit anywhere and anytime"
	},
	ProximityIndicator = {
		Enabled = "Enable to show an indicator on close enemies when using Aphrodite boons",
	},
	SprintHitbox = {
		Enabled = "Enable to show the sprint's hitbox."
	},
	ChronosPause = {
		Enabled = "Enable to be able to pause during the Chronos boss fight without having performed the incantation."
	},
}

return config, description
