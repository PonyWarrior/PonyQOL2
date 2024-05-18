local mod = PonyQOL2

if not mod.Config.Enabled then return end

if mod.Config.AllUnlockedToolsUsable.Enabled then
	ModUtil.Path.Override("HasAccessToTool", function(toolName)
		if GameState.WorldUpgrades[toolName] then
			return true
		end
		if HasFamiliarTool(toolName) then
			return true
		end

		return false
	end, mod)
end

if mod.Config.AlwaysEncounterStoryRooms.Enabled then
	--Arachne
	RoomSetData.F.F_Story01.ForceAtBiomeDepthMin = 1
	RoomSetData.F.F_Story01.ForceAtBiomeDepthMax = 8

	--Narcissus
	RoomSetData.G.G_Story01.ForceAtBiomeDepthMin = 1
	RoomSetData.G.G_Story01.ForceAtBiomeDepthMax = 6

	-- RoomSetData.N.N_Story01.ForceAtBiomeDepthMin = 0
	-- RoomSetData.N.N_Story01.ForceAtBiomeDepthMax = 1

	RoomSetData.O.O_Story01.ForceAtBiomeDepthMin = 1
	RoomSetData.O.O_Story01.ForceAtBiomeDepthMax = 5
end

if mod.Config.GodMode.Enabled then
	ModUtil.Path.Override("CalcEasyModeMultiplier", function(...)
		local easyModeMultiplier = 1 - mod.Config.GodMode.FixedValue
		return easyModeMultiplier
	end, mod)
end

if mod.Config.UltraWide.Enabled then
	ModUtil.Path.Wrap("UpdateConfigOptionCache", function(base)
		base()
		ScreenState.NeedsLetterbox = false
		ScreenState.NeedsPillarbox = false
	end, mod)
end

if mod.Config.BossNumericHealth then
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
	end, mod)

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
				Destroy({Id = numericHealthBar})
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
			ModifyTextBox({ Id = numericHealthBar, Text = currentHealth .. "/" .. maxHealth })
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
	end, mod)

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
		ModifyTextBox({ Id = numericHealthBar, Text = currentHealth .. "/" .. maxHealth })
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
	end, mod)
end

if mod.Config.QuitAnywhere.Enabled then
	ModUtil.Path.Override("InvalidateCheckpoint", function()
		ValidateCheckpoint({ Value = true })
	end, mod)
end
