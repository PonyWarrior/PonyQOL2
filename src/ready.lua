---@meta _
-- globals we define are private to our plugin!
---@diagnostic disable: lowercase-global

-- here is where your mod sets up all the things it will do.
-- this file will not be reloaded if it changes during gameplay
-- 	so you will most likely want to have it reference
--	values and functions later defined in `reload.lua`.

mod = modutil.mod.Mod.Register(_PLUGIN.guid)

-- ModUtil.LoadOnce(function()
-- 	rom.data.reload_game_data()
-- end)

data = modutil.mod.Mod.Register(_PLUGIN.guid).Data

if config.AlwaysEncounterStoryRooms.Enabled then
	RoomSetData.F.F_Story01.ForceAtBiomeDepthMin = 4
	RoomSetData.F.F_Story01.ForceAtBiomeDepthMax = 8

	RoomSetData.G.G_Story01.ForceAtBiomeDepthMin = 3
	RoomSetData.G.G_Story01.ForceAtBiomeDepthMax = 6

	RoomSetData.N.N_Story01.ForceAtBiomeDepthMin = 0
	RoomSetData.N.N_Story01.ForceAtBiomeDepthMax = 1

	RoomSetData.O.O_Story01.ForceAtBiomeDepthMin = 3
	RoomSetData.O.O_Story01.ForceAtBiomeDepthMax = 5

	RoomSetData.P.P_Story01.ForceAtBiomeDepthMin = 2
	RoomSetData.P.P_Story01.ForceAtBiomeDepthMax = 7

	-- I_Story01 (Hades) natively forced
end

if config.GodMode.Enabled then
	ModUtil.Path.Override("CalcEasyModeMultiplier", function(...)
		local easyModeMultiplier = 1 - config.GodMode.FixedValue
		return easyModeMultiplier
	end)
end

if config.UltraWide.Enabled then
	ModUtil.Path.Wrap("UpdateConfigOptionCache", function(base)
		base()
		ScreenState.NeedsLetterbox = false
		ScreenState.NeedsPillarbox = false
	end)
end

if config.BossNumericHealth.Enabled then
	ModUtil.Path.Override("CreateBossHealthBar", function(boss)
		local encounter = CurrentRun.CurrentRoom.Encounter
		if encounter ~= nil and encounter.UseGroupHealthBar ~= nil then
			if not boss.HasHealthBar then
				local offsetY = -155
				boss.HasHealthBar = true
				if boss.Scale ~= nil then
					offsetY = offsetY * boss.Scale
				end
				if boss.HealthBarOffsetY then
					offsetY = boss.HealthBarOffsetY
				end
				-- Invisible health bar for effect purposes
				local screenId = SpawnObstacle({ Name = "BlankObstacle", Group = "Combat_UI_World", DestinationId = boss.ObjectId, Attach = true, OffsetY = offsetY, TriggerOnSpawn = false })
				EnemyHealthDisplayAnchors[boss.ObjectId] = screenId
			end
			if not encounter.HasHealthBar then
				CreateGroupHealthBar(encounter)
			end
			return
		end
		if boss.HasHealthBar then
			return
		end
		boss.HasHealthBar = true

		if ScreenAnchors.BossHealthTitles == nil then
			ScreenAnchors.BossHealthTitles = {}
		end
		local index = TableLength(ScreenAnchors.BossHealthTitles)
		local numBars = GetNumBossHealthBars()
		local yOffset = 0
		local xScale = 1 / numBars
		boss.BarXScale = xScale
		local totalWidth = ScreenWidth * xScale
		local xOffset = (totalWidth / (2 * numBars)) * (1 + index * 2) + (ScreenWidth - totalWidth) / 2

		if numBars == 0 then
			return
		end

		ScreenAnchors.BossHealthBack = CreateScreenObstacle({ Name = "BossHealthBarBack", Group = "Combat_UI", X = xOffset, Y = 70 + yOffset })
		ScreenAnchors.BossHealthTitles[boss.ObjectId] = ScreenAnchors.BossHealthBack

		local fallOffBar = CreateScreenObstacle({ Name = "BossHealthBarFillFalloff", Group = "Combat_UI", X = xOffset, Y = 72 + yOffset })
		SetColor({ Id = fallOffBar, Color = Color.HealthFalloff })
		SetAnimationFrameTarget({ Name = "EnemyHealthBarFillSlowBoss", Fraction = 0, DestinationId = fallOffBar, Instant = true })

		ScreenAnchors.BossHealthFill = CreateScreenObstacle({ Name = "BossHealthBarFill", Group = "Combat_UI", X = xOffset, Y = 72 + yOffset })

		CreateAnimation({ Name = "BossNameShadow", DestinationId = ScreenAnchors.BossHealthBack })

		SetScaleX({ Ids = { ScreenAnchors.BossHealthBack, ScreenAnchors.BossHealthFill, fallOffBar }, Fraction = xScale, Duration = 0 })

		local bossName = boss.HealthBarTextId or boss.Name

		if boss.AltHealthBarTextIds ~= nil then
			local eligibleTextIds = {}
			for k, altTextIdData in pairs(boss.AltHealthBarTextIds) do
				if IsGameStateEligible(CurrentRun, altTextIdData.Requirements) then
					table.insert(eligibleTextIds, altTextIdData.TextId)
				end
			end
			if not IsEmpty(eligibleTextIds) then
				bossName = GetRandomValue(eligibleTextIds)
			end
		end

		CreateTextBox({
			Id = ScreenAnchors.BossHealthBack,
			Text = bossName,
			Font = "CaesarDressing",
			FontSize = 22,
			ShadowRed = 0,
			ShadowBlue = 0,
			ShadowGreen = 0,
			OutlineColor = { 0, 0, 0, 1 },
			OutlineThickness = 2,
			ShadowAlpha = 1.0,
			ShadowBlur = 0,
			ShadowOffsetY = 3,
			ShadowOffsetX = 0,
			Justification = "Center",
			OffsetY = -30,
			OpacityWithOwner = false,
			AutoSetDataProperties = true,
		})
		--Mod start
		boss.NumericHealthbar = CreateScreenObstacle({ Name = "BlankObstacle", Group = "Combat_UI", X = xOffset, Y = 112 + yOffset })
		CreateTextBox({
			Id = boss.NumericHealthbar,
			Text = boss.Health .. "/" .. boss.MaxHealth,
			FontSize = 18,
			ShadowRed = 0,
			ShadowBlue = 0,
			ShadowGreen = 0,
			OutlineColor = { 0, 0, 0, 1 },
			OutlineThickness = 2,
			ShadowAlpha = 1.0,
			ShadowBlur = 0,
			ShadowOffsetY = 3,
			ShadowOffsetX = 0,
			Justification = "Center",
			OffsetY = 0,
			OpacityWithOwner = false,
			AutoSetDataProperties = true,
		})
		--Mod end

		ModifyTextBox({ Id = ScreenAnchors.BossHealthBack, FadeTarget = 0, FadeDuration = 0 })
		SetAlpha({ Id = ScreenAnchors.BossHealthBack, Fraction = 0.01, Duration = 0.0 })
		SetAlpha({ Id = ScreenAnchors.BossHealthBack, Fraction = 1.0, Duration = 2.0 })
		EnemyHealthDisplayAnchors[boss.ObjectId .. "back"] = ScreenAnchors.BossHealthBack

		boss.HealthBarFill = "EnemyHealthBarFillBoss"
		SetAnimationFrameTarget({ Name = "EnemyHealthBarFillBoss", Fraction = boss.Health / boss.MaxHealth, DestinationId = screenId })
		SetAlpha({ Ids = { ScreenAnchors.BossHealthFill, fallOffBar }, Fraction = 0.01, Duration = 0.0 })
		SetAlpha({ Ids = { ScreenAnchors.BossHealthFill, fallOffBar }, Fraction = 1, Duration = 2.0 })
		EnemyHealthDisplayAnchors[boss.ObjectId] = ScreenAnchors.BossHealthFill
		EnemyHealthDisplayAnchors[boss.ObjectId .. "falloff"] = fallOffBar
		--Mod start
		EnemyHealthDisplayAnchors[boss.ObjectId .. "numeric"] = boss.NumericHealthbar
		--Mod end
		thread(BossHealthBarPresentation, boss)
	end)

	ModUtil.Path.Override("CreateGroupHealthBar", function(encounter)
		encounter.HasHealthBar = true

		local xOffset = ScreenWidth / 2
		local yOffset = 0
		if ScreenAnchors.BossHealthTitles == nil then
			ScreenAnchors.BossHealthTitles = {}
		end

		ScreenAnchors.BossHealthBack = CreateScreenObstacle({ Name = "BossHealthBarBack", Group = "Combat_UI", X = xOffset, Y = 70 + yOffset })
		ScreenAnchors.BossHealthTitles[encounter.Name] = ScreenAnchors.BossHealthBack

		local fallOffBar = CreateScreenObstacle({ Name = "BossHealthBarFillFalloff", Group = "Combat_UI", X = xOffset, Y = 72 + yOffset })
		SetColor({ Id = fallOffBar, Color = Color.HealthFalloff })
		SetAnimationFrameTarget({ Name = "EnemyHealthBarFillSlowBoss", Fraction = 0, DestinationId = fallOffBar, Instant = true })

		ScreenAnchors.BossHealthFill = CreateScreenObstacle({ Name = "BossHealthBarFill", Group = "Combat_UI", X = xOffset, Y = 72 + yOffset })

		CreateAnimation({ Name = "BossNameShadow", DestinationId = ScreenAnchors.BossHealthBack })

		SetScaleX({ Ids = { ScreenAnchors.BossHealthBack, ScreenAnchors.BossHealthFill, fallOffBar }, Fraction = 1, Duration = 0 })

		local barName = EncounterData[encounter.Name].HealthBarTextId or encounter.Name

		CreateTextBox({
			Id = ScreenAnchors.BossHealthBack,
			Text = barName,
			Font = "CaesarDressing",
			FontSize = 22,
			ShadowRed = 0,
			ShadowBlue = 0,
			ShadowGreen = 0,
			OutlineColor = { 0, 0, 0, 1 },
			OutlineThickness = 2,
			ShadowAlpha = 1.0,
			ShadowBlur = 0,
			ShadowOffsetY = 3,
			ShadowOffsetX = 0,
			Justification = "Center",
			OffsetY = -30,
			OpacityWithOwner = false,
			AutoSetDataProperties = true,
		})
		--Mod start
		ScreenAnchors.NumericHealthbar = CreateScreenObstacle({ Name = "BlankObstacle", Group = "Combat_UI", X = xOffset, Y = 112 + yOffset })
		CreateTextBox({
			Id = ScreenAnchors.NumericHealthbar,
			Text = encounter.GroupHealth .. "/" .. encounter.GroupMaxHealth,
			FontSize = 18,
			ShadowRed = 0,
			ShadowBlue = 0,
			ShadowGreen = 0,
			OutlineColor = { 0, 0, 0, 1 },
			OutlineThickness = 2,
			ShadowAlpha = 1.0,
			ShadowBlur = 0,
			ShadowOffsetY = 3,
			ShadowOffsetX = 0,
			Justification = "Center",
			OffsetY = 0,
			OpacityWithOwner = false,
			AutoSetDataProperties = true,
		})
		--Mod end

		ModifyTextBox({ Id = ScreenAnchors.BossHealthBack, FadeTarget = 0, FadeDuration = 0 })
		SetAlpha({ Id = ScreenAnchors.BossHealthBack, Fraction = 0.01, Duration = 0.0 })
		SetAlpha({ Id = ScreenAnchors.BossHealthBack, Fraction = 1.0, Duration = 2.0 })
		EnemyHealthDisplayAnchors[encounter.Name .. "back"] = ScreenAnchors.BossHealthBack

		encounter.HealthBarFill = "EnemyHealthBarFillBoss"
		SetAnimationFrameTarget({ Name = "EnemyHealthBarFillBoss", Fraction = 1, DestinationId = ScreenAnchors.BossHealthFill })
		SetAlpha({ Ids = { ScreenAnchors.BossHealthFill, fallOffBar }, Fraction = 0.01, Duration = 0.0 })
		SetAlpha({ Ids = { ScreenAnchors.BossHealthFill, fallOffBar }, Fraction = 1, Duration = 2.0 })
		EnemyHealthDisplayAnchors[encounter.Name] = ScreenAnchors.BossHealthFill
		EnemyHealthDisplayAnchors[encounter.Name .. "falloff"] = fallOffBar
		--Mod start
		EnemyHealthDisplayAnchors[encounter.Name .. "numeric"] = ScreenAnchors.NumericHealthbar
		--Mod end
		thread(GroupHealthBarPresentation, encounter)
	end)

	ModUtil.Path.Override("UpdateHealthBarReal", function(args)
		local enemy = args[1]

		if enemy.UseGroupHealthBar then
			UpdateGroupHealthBarReal(args)
			return
		end

		local screenId = args[2]
		local scorchId = args[3]
		--Mod start
		local numericHealthBar = EnemyHealthDisplayAnchors[enemy.ObjectId .. "numeric"]
		--Mod end

		if enemy.IsDead then
			if enemy.UseBossHealthBar then
				CurrentRun.BossHealthBarRecord[enemy.Name] = 0
			end
			SetAnimationFrameTarget({ Name = enemy.HealthBarFill or "EnemyHealthBarFill", Fraction = 1, DestinationId = scorchId, Instant = true })
			SetAnimationFrameTarget({ Name = enemy.HealthBarFill or "EnemyHealthBarFill", Fraction = 1, DestinationId = screenId, Instant = true })
			--Mod start
			if numericHealthBar ~= nil then
				Destroy({ Id = numericHealthBar })
			end
			--Mod end
			return
		end


		local maxHealth = enemy.MaxHealth
		local currentHealth = enemy.Health
		if currentHealth == nil then
			currentHealth = maxHealth
		end

		UpdateHealthBarIcons(enemy)

		if enemy.UseBossHealthBar then
			local healthFraction = currentHealth / maxHealth
			CurrentRun.BossHealthBarRecord[enemy.Name] = healthFraction
			SetAnimationFrameTarget({ Name = enemy.HealthBarFill or "EnemyHealthBarFill", Fraction = 1 - healthFraction, DestinationId = screenId, Instant = true })
			--Mod start
			ModifyTextBox({ Id = numericHealthBar, Text = round(currentHealth) .. "/" .. maxHealth })
			--Mod end
			if enemy.HitShields > 0 then
				SetColor({ Id = screenId, Color = Color.HitShield })
			else
				SetColor({ Id = screenId, Color = Color.Red })
			end
			thread(UpdateBossHealthBarFalloff, enemy)
			return
		end

		local displayedHealthPercent = 1
		local predictedHealthPercent = 1

		if enemy.CursedHealthBarEffect then
			if enemy.HitShields ~= nil and enemy.HitShields > 0 then
				SetColor({ Id = screenId, Color = Color.CurseHitShield })
			elseif enemy.HealthBuffer ~= nil and enemy.HealthBuffer > 0 then
				SetColor({ Id = screenId, Color = Color.CurseHealthBuffer })
			else
				SetColor({ Id = screenId, Color = Color.CurseHealth })
			end
			SetColor({ Id = backingScreenId, Color = Color.CurseFalloff })
		elseif enemy.Charmed then
			SetColor({ Id = screenId, Color = Color.CharmHealth })
			SetColor({ Id = backingScreenId, Color = Color.HealthBufferFalloff })
		else
			if enemy.HitShields ~= nil and enemy.HitShields > 0 then
				SetColor({ Id = screenId, Color = Color.HitShield })
			elseif enemy.HealthBuffer ~= nil and enemy.HealthBuffer > 0 then
				SetColor({ Id = screenId, Color = Color.HealthBuffer })
				SetColor({ Id = backingScreenId, Color = Color.HealthBufferFalloff })
			else
				SetColor({ Id = screenId, Color = Color.Red })
				SetColor({ Id = backingScreenId, Color = Color.HealthFalloff })
			end
		end

		if enemy.HitShields ~= nil and enemy.HitShields > 0 then
			displayedHealthPercent = 1
			predictedHealthPercent = 1
		elseif enemy.HealthBuffer ~= nil and enemy.HealthBuffer > 0 then
			displayedHealthPercent = enemy.HealthBuffer / enemy.MaxHealthBuffer
			if enemy.ActiveEffects and enemy.ActiveEffects.BurnEffect then
				predictedHealthPercent = math.max(0, enemy.HealthBuffer - enemy.ActiveEffects.BurnEffect) / enemy.MaxHealthBuffer
			else
				predictedHealthPercent = displayedHealthPercent
			end
		else
			displayedHealthPercent = currentHealth / maxHealth
			if enemy.ActiveEffects and enemy.ActiveEffects.BurnEffect then
				predictedHealthPercent = math.max(0, currentHealth - enemy.ActiveEffects.BurnEffect) / maxHealth
			else
				predictedHealthPercent = displayedHealthPercent
			end
		end
		enemy.DisplayedHealthFraction = displayedHealthPercent
		SetAnimationFrameTarget({ Name = enemy.HealthBarFill or "EnemyHealthBarFill", Fraction = 1 - predictedHealthPercent, DestinationId = screenId, Instant = true })
		SetAnimationFrameTarget({ Name = enemy.HealthBarFill or "EnemyHealthBarFill", Fraction = 1 - displayedHealthPercent, DestinationId = scorchId, Instant = true })
		thread(UpdateEnemyHealthBarFalloff, enemy)
	end)

	ModUtil.Path.Override("UpdateGroupHealthBarReal", function(args)
		local enemy = args[1]
		local screenId = args[2]
		local encounter = CurrentRun.CurrentRoom.Encounter
		local backingScreenId = EnemyHealthDisplayAnchors[encounter.Name .. "falloff"]

		local maxHealth = encounter.GroupMaxHealth
		local currentHealth = 0
		--Mod start
		local numericHealthBar = ScreenAnchors.NumericHealthbar
		--Mod end

		for k, unitId in pairs(encounter.HealthBarUnitIds) do
			local unit = ActiveEnemies[unitId]
			if unit ~= nil then
				currentHealth = currentHealth + unit.Health
			end
		end
		encounter.GroupHealth = currentHealth

		local healthFraction = currentHealth / maxHealth
		CurrentRun.BossHealthBarRecord[encounter.Name] = healthFraction
		--Mod start
		ModifyTextBox({ Id = numericHealthBar, Text = round(currentHealth) .. "/" .. maxHealth })
		--Mod end

		SetAnimationFrameTarget({ Name = encounter.HealthBarFill or "EnemyHealthBarFill", Fraction = 1 - healthFraction, DestinationId = screenId, Instant = true })
		thread(UpdateGroupHealthBarFalloff, encounter)
	end)

	ModUtil.Path.Wrap("BossChillKillPresentation", function(base, unit)
		if EnemyHealthDisplayAnchors[unit.ObjectId .. "numeric"] ~= nil then
			local numericHealthBar = EnemyHealthDisplayAnchors[unit.ObjectId .. "numeric"]
			Destroy({ Id = numericHealthBar })
		end
		base(unit)
	end)
end

if config.QuitAnywhere.Enabled then
	ModUtil.Path.Override("InvalidateCheckpoint", function()
		ValidateCheckpoint({ Value = true })
	end)
end

if config.ProximityIndicator.Enabled then
	--TODO : remake as a boon startup function, see WeakCrowdMana for example
	-- also make the coloring an effect instead
	OnPlayerMoveStarted {
		function(args)
			local threshold = GetProximityThreshold()
			if threshold ~= nil then
				data.ProximityFlag = true
				if not HasThread("TagEnemiesInProximityRange") then
					thread(TagEnemiesInProximityRange, threshold)
				end
			else
				data.ProximityFlag = false
				killTaggedThreads("TagEnemiesInProximityRange")
			end
		end
	}

	function GetProximityThreshold()
		if HeroHasTrait("AphroditeWeaponBoon") or HeroHasTrait("AphroditeSpecialBoon") then
			-- 430
			return TraitData.AphroditeWeaponBoon.AddOutgoingDamageModifiers.ProximityThreshold
		else
			return nil
		end
	end

	ModUtil.Path.Wrap("Kill", function(base, victim, triggerArgs)
		if victim == nil then
			return
		end
		if victim.ProximityTagged then
			SetColor({ Id = victim.ObjectId, Color = { 255, 255, 255, 255 }, Duration = 0.005 })
		end
		base(victim, triggerArgs)
	end)

	function TagEnemiesInProximityRange(threshold)
		if data == nil or data.ProximityFlag == nil then
			return
		end
		while data.ProximityFlag == true do
			for enemyId, enemy in pairs(ActiveEnemies) do
				if IsValidEnemy(enemy) then
					if enemy.ProximityTagged == nil then
						enemy.ProximityTagged = false
					end
					if GetDistance({ Id = CurrentRun.Hero.ObjectId, DestinationId = enemyId }) <= threshold then
						if not enemy.ProximityTagged then
							enemy.ProximityTagged = true
							SetColor({ Id = enemyId, Color = { 255, 0, 255, 255 }, Duration = 0.005 })
						end
					else
						enemy.ProximityTagged = false
						SetColor({ Id = enemyId, Color = { 255, 255, 255, 255 }, Duration = 0.005 })
					end
				end
			end
			wait(0.3, RoomThreadName)
		end
	end

	function IsValidEnemy(enemy)
		if enemy.IsDead or enemy.InvalidForProximity then
			return false
		end
		if not enemy.RequiredKill then
			enemy.InvalidForProximity = true
			return false
		end
		return true
	end
end

if config.SprintHitbox.Enabled then
	local shitfile = rom.path.combine(rom.paths.Content, 'Game/Weapons/PlayerWeapons.sjson')

	sjson.hook(shitfile, function(sjsonData)
		return sjson_Weapon(sjsonData)
	end)

	function sjson_Weapon(sjsonData)
		local order = { 'Trigger', 'Name', 'Type', 'Active', 'Duration', 'FrontFx' }
		for _, v in ipairs(sjsonData.Weapons) do
			if v.Name == "WeaponSprint" then
				table.insert(v.Effects, sjson.to_object({
					Trigger = "Fire",
					Name = "SprintFx2",
					Type = "TAG",
					Active = true,
					Duration = 3600,
					FrontFx = "BattleStandardFxEmitter"
				}, order))
				table.insert(v.Effects, sjson.to_object({
					Trigger = "FireEnd",
					Name = "SprintFx2",
					Type = "TAG",
					Active = true,
					Duration = 0.01,
					FrontFx = "null"
				}, order))
			end
		end
	end
end

if config.ChronosPause.Enabled then
	ModUtil.Path.Override("SetupPauseMenuTakeover", function(source, args)
		-- do nothing
	end)
end

if config.SlowEffectsOnTimer.Enabled then
	ModUtil.Path.Override("UpdateTimers", function(elapsed)
		if CurrentRun == nil then
			return
		end

		GameState.TotalTime = GameState.TotalTime + elapsed
		-- MOD START
		local timeMultEnv = GetGameplayElapsedTimeMultiplier()
		local timeMultPlayer = GetPlayerGameplayElapsedTimeMultiplier()
		elapsed = elapsed * timeMultEnv
		elapsed = elapsed * timeMultPlayer
		-- MOD END
		CurrentRun.TotalTime = CurrentRun.TotalTime + elapsed

		if CurrentRun.Hero.IsDead then
			return
		end

		if not IsEmpty( CurrentRun.BlockTimerFlags ) or not IsEmpty( MapState.BlockTimerFlags ) then
			return
		end

		GameState.GameplayTime = GameState.GameplayTime + elapsed
		CurrentRun.GameplayTime = CurrentRun.GameplayTime + elapsed

		if HeroHasTrait("TimedBuffKeepsake") then
			if not IsBiomeTimerPaused() then
				local traitData = GetHeroTrait("TimedBuffKeepsake")
				traitData.CurrentTime = traitData.CurrentTime or 0
				traitData.CurrentTime = traitData.CurrentTime - elapsed
				if traitData.CurrentTime <= 0 and (traitData.CurrentTime + elapsed) > 0 then
					traitData.CustomName = traitData.ZeroBonusTrayText
					EndTimedBuff(traitData)
					thread(TimedBuffExpiredPresentation, traitData)
					ReduceTraitUses(traitData, { Force = true })
				end
			end
		end
		
		if HeroHasTrait("ChaosTimeCurse") then
			if not IsBiomeTimerPaused() then
				local traitData = GetHeroTrait("ChaosTimeCurse")
				traitData.CurrentTime = traitData.CurrentTime or 0

				traitData.CurrentTime = traitData.CurrentTime - elapsed
				local threshold = 30
				if traitData.CurrentTime <= threshold and (traitData.CurrentTime + elapsed) > threshold then
					ChaosTimerAboutToExpirePresentation(threshold)
				elseif traitData.CurrentTime <= 0 and (traitData.CurrentTime + elapsed) > 0 then
					if not CurrentRun.Hero.InvulnerableFlags.BlockDeath then
						CurrentRun.CurrentRoom.Encounter.TookChaosCurseDamage = true
						CurrentRun.CurrentRoom.KilledByChaosCurse = true
						thread(SacrificeHealth, { SacrificeHealthMin = traitData.Damage, SacrificeHealthMax = traitData.Damage, MinHealth = 0, AttackerName = "TrialUpgrade" })
					end
					if not CurrentRun.Hero.IsDead then
						thread(RemoveTraitData, CurrentRun.Hero, traitData)
					end
				end
			end
		end

		if CurrentRun.ActiveBiomeTimer and not IsBiomeTimerPaused() then
			CurrentRun.BiomeTime = CurrentRun.BiomeTime - elapsed
			local threshold = 30
			if CurrentRun.BiomeTime <= threshold and (CurrentRun.BiomeTime + elapsed) > threshold then
				BiomeTimerAboutToExpirePresentation(threshold )
			elseif CurrentRun.BiomeTime <= 0 and (CurrentRun.BiomeTime + elapsed) > 0 then
				BiomeTimerExpiredPresentation()
			end
		end
	end)
end

if config.DoorIndicators.Enabled then

	ModUtil.Path.Override("PopulateDoorRewardPreviewSubIcons", function(exitDoor, args)
		return PopulateDoorRewardPreviewSubIcons_override(exitDoor, args)
	end)

	ModUtil.Path.Override("AddDoorInfoIcon", function(args)
		return AddDoorInfoIcon_override(args)
	end)

	local vfxFile = rom.path.combine(rom.paths.Content, 'Game/Animations/GUI_VFX.sjson')

	sjson.hook(vfxFile, function(sjsonData)
		return sjson_DoorIcons(sjsonData)
	end)

	function sjson_DoorIcons(sjsonData)
		for _, v in ipairs(sjsonData.Animations) do
			if v.Name == "BaseMiniRoomPreviewIcon" then
				v.Scale = 0.75
			end
		end
	end

	local bgFile = rom.path.combine(rom.paths.Content, 'Game/Obstacles/Backgrounds.sjson')

	local order_1 = {
		"Name", "InheritFrom", "DisplayInEditor", "NeedsLife", "Thing"
	}

	local order_2 = {
		"EditorOutlineDrawBounds", "Graphic", "TriggerOnSpawn"
	}

	local newSubItem = sjson.to_object({
		EditorOutlineDrawBounds = false,
		Graphic = "Dev\\Circle",
		TriggerOnSpawn = false
	}, order_2)

	local newItem = sjson.to_object({
		Name = "circle01",
		InheritFrom = "1_BaseTerrainTile",
		DisplayInEditor = true,
		NeedsLife = false,
		Thing = newSubItem,
	}, order_1)

	sjson.hook(bgFile, function(data)
		table.insert(data.Obstacles, newItem)
	end)

	ObstacleData.EphyraExitDoor.SkipResourcePinIcons = false
end

if config.PermanentLocationCount.Enabled then
	ModUtil.Path.Wrap("ShowHealthUI", function(base)
		base()
		ShowDepthCounter()
	end)

	ModUtil.Path.Wrap("TraitTrayScreenClose", function(base, ...)
		base(...)
		ShowDepthCounter()
	end)
end

if config.RepeatableChaosTrials.Enabled then
	ModUtil.Path.Override("BountyBoardScreenDisplayCategory", function(screen, categoryIndex)
		BountyBoardScreenDisplayCategory_override(screen, categoryIndex)
	end)

	ModUtil.Path.Wrap("MouseOverBounty", function(base, button)
		base(button)
		if GameState.PackagedBountyClears[button.Data.Name] then
			SetAlpha({ Id = button.Screen.Components.SelectButton.Id, Fraction = 1.0, Duration = 0.2 })
		end
	end)
end

if config.Skip.Enabled then
	if config.Skip.RunEndCutscene then

		ModUtil.Path.Override("EndEarlyAccessPresentation", function()
			AddInputBlock({ Name = "EndEarlyAccessPresentation" })
			SetPlayerInvulnerable("EndEarlyAccessPresentation")

			CurrentRun.Hero.Mute = true
			CurrentRun.ActiveBiomeTimer = false
			ToggleCombatControl(CombatControlsDefaults, false, "EarlyAccessPresentation")

			wait(0.1)
			StopAmbientSound({ All = true })
			SetAudioEffectState({ Name = "Reverb", Value = 1.5 })
			EndAmbience(0.5)
			EndAllBiomeStates()
			FadeOut({ Duration = 0.375, Color = Color.Black })

			-- first production / early access
			EndBiomeRecords()
			RecordRunCleared()

			-- destroy the player / back to DeathArea
			SetPlayerVulnerable("EndEarlyAccessPresentation")
			RemoveInputBlock({ Name = "EndEarlyAccessPresentation" })
			ToggleCombatControl(CombatControlsDefaults, true, "EarlyAccessPresentation")

			CurrentRun.Hero.Mute = false
			thread(Kill, CurrentRun.Hero)
			wait(0.15)

			FadeIn({ Duration = 0.5 })
		end)

		if config.Skip.RunEndCutscene.RespawnInTrainingGrounds then
			ModUtil.Path.Context.Wrap("KillHero", function(base, victim, triggerArgs)
				ModUtil.Path.Wrap("LoadMap", function(base, argTable)
					rom.log.warning(argTable.Name)
					if argTable.Name == "Hub_Main" then -- Realistically we don't want to accidentally break any other cutscenes (mini mel)
						argTable.Name = "Hub_PreRun"
					end
					base(argTable)
				end)
			end)
		end
	end

	if config.Skip.RunDialog then
		ModUtil.Path.Wrap("PlayTextLines", function(base, source, textLines, args)
			-- current not in a Run
			if CurrentRun.Hero.IsDead then
				return base(source, textLines, args)
			end

			-- some encounters have ```textLines`` empty
			-- like after Hecate boss fight
			if not textLines then
				return
			end

			-- TODO: maybe this could be a var in config, 
			-- like if its a mainStory line u dont wanna skip
			-- but in general i think ppl wanna trigger main lines
			if textLines.StatusAnimation == 'StatusIconWantsToTalk' then
				return base(source, textLines, args)
			end

			if textLines.PrePortraitExitFunctionName then
				-- special NPCs has a choice exit function
				hasChoice, _ = string.find(textLines.PrePortraitExitFunctionName, 'Choice')
				if hasChoice then
					return base(source, textLines, args)
				end
			end
			
			-- skips text lines for everyone else
			return

		end)
	end

	if config.Skip.DeathCutScene then
		ModUtil.Path.Context.Wrap("DeathPresentation", function()
			ModUtil.Path.Wrap("wait", function(...)
				return
			end)
		end)
	end
end
